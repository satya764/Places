import Foundation

// this is the part the target teams actually hire for. keep it clean and keep it
// pure enough to unit test without any ui or real network.
//
// the sync is two phases:
//   1. push: drain the mutation queue in one batch, mark those places synced
//   2. pull: fetch remote changes since the last token, merge them in
//
// merge is where conflicts live. a conflict is: the local copy has unsynced edits
// (isDirty) and the server version moved on without us. this demo resolves it with
// last-write-wins by updatedAt. field-level merge is the alternative you would
// reach for at scale, and being able to say why is the senior signal in an
// interview, so it is called out in resolve() below.
final class SyncEngine {
    private let store: LocalStore
    private let queue: MutationQueue
    private let api: RemoteAPI
    private var lastToken: Date?

    // simple observable count so the ui can show pending work
    var onStateChange: (() -> Void)?
    private(set) var lastConflictCount = 0

    init(store: LocalStore, queue: MutationQueue, api: RemoteAPI) {
        self.store = store
        self.queue = queue
        self.api = api
    }

    var pendingCount: Int { queue.count }
    var lastSyncedAt: Date?

        func forceSync() {
            Task { await sync() }
        }

    func sync() async {
        do {
            try await push()
            try await pull()
            lastSyncedAt = Date()
            await MainActor.run { self.onStateChange?() }
        } catch {
            // offline or server error. changes stay queued locally and go up on the
            // next successful sync. nothing is lost, which is the whole point.
        }
    }

    private func push() async throws {
        let mutations = queue.snapshot()
        guard !mutations.isEmpty else { return }

        // resolve each mutation to the current local row and push in one batch
        let placeIDs = Set(mutations.map { $0.placeID })
        let toPush = placeIDs.compactMap { store.place($0) }
        guard !toPush.isEmpty else { queue.clear(mutations); return }

        let accepted = try await api.pushBatch(toPush)
        for p in accepted { store.upsert(p) }   // stores server version, clears dirty
        queue.clear(mutations)
    }

    private func pull() async throws {
        let (remote, token) = try await api.pullDelta(since: lastToken)
        var conflicts = 0
        for incoming in remote {
            if let local = store.place(incoming.id) {
                if let merged = resolve(local: local, remote: incoming) {
                    store.upsert(merged)
                    if local.isDirty && incoming.version > local.version { conflicts += 1 }
                }
            } else {
                store.upsert(incoming)
            }
        }
        lastConflictCount = conflicts
        lastToken = token
    }

    // returns the winning row, or nil to keep local untouched.
    func resolve(local: Place, remote: Place) -> Place? {
        // no local edits pending: server always wins, straightforward.
        if !local.isDirty {
            return remote.version > local.version ? remote : nil
        }

        // local has unsynced edits AND server moved on: real conflict.
        // last-write-wins by timestamp. the loser is dropped.
        //
        // alternative for production: merge per field (e.g. keep local note, take
        // remote title) or surface both to the user. LWW is simplest and honest for
        // a portfolio, and you can explain the tradeoff out loud.
        if remote.version > local.version {
            if remote.updatedAt > local.updatedAt {
                return remote
            } else {
                // local wins: keep our edits but adopt the server version number so
                // the next push does not look like a stale write.
                var kept = local
                kept.version = remote.version
                return kept
            }
        }
        return nil
    }
}
