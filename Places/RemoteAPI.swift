import Foundation

// the sync engine talks to this, not to a concrete backend. that keeps it testable
// and lets you drop in firebase, supabase, or your own server later without
// changing sync logic. it also means the whole app runs today against the mock.
protocol RemoteAPI {
    // push a batch of local changes. returns the server's version of each place it
    // accepted, so we can clear the dirty flag and store the new version number.
    func pushBatch(_ places: [Place]) async throws -> [Place]

    // pull everything changed since the last token. delta sync, not full download.
    func pullDelta(since token: Date?) async throws -> (places: [Place], token: Date)
}

// a fake server backed by an in-memory dictionary. good enough to demo the full
// loop end to end. it bumps version on every accepted write, which is what lets
// the engine notice a conflict.
final class MockRemoteAPI: RemoteAPI {
    private var server: [String: Place] = [:]
    private let latency: UInt64

    init(latencyMillis: UInt64 = 300) {
        self.latency = latencyMillis * 1_000_000
    }

    func pushBatch(_ places: [Place]) async throws -> [Place] {
        try await Task.sleep(nanoseconds: latency)
        var accepted: [Place] = []
        for p in places {
            var stored = p
            stored.version = (server[p.id]?.version ?? 0) + 1
            stored.isDirty = false
            server[p.id] = stored
            accepted.append(stored)
        }
        return accepted
    }

    func pullDelta(since token: Date?) async throws -> (places: [Place], token: Date) {
        try await Task.sleep(nanoseconds: latency)
        let changed = server.values.filter { token == nil || $0.updatedAt > token! }
        return (Array(changed), Date())
    }

    // test hook: pretend another device edited a place, to force a conflict.
    func simulateRemoteEdit(id: String, title: String) {
        guard var p = server[id] else { return }
        p.title = title
        p.updatedAt = Date()
        p.version += 1
        server[id] = p
    }
}
