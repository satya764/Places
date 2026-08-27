import Foundation

// the local store is the source of truth. the app reads and writes here always,
// online or not. the network is a background reconciler on top of this, never in
// the critical path of a user action. that is what "offline-first" means.
//
// backing it with a json file keeps the demo simple. swap for core data or
// sqlite later without touching the sync engine, since it only talks to this api.
final class LocalStore {
    private let url: URL
    private var byID: [String: Place] = [:]

    init(filename: String = "places.json") {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.url = dir.appendingPathComponent(filename)
        load()
    }

    // active places for the ui: not deleted, newest first
    func visiblePlaces() -> [Place] {
        byID.values
            .filter { !$0.isDeleted }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    func allPlaces() -> [Place] { Array(byID.values) }

    func place(_ id: String) -> Place? { byID[id] }

    func upsert(_ place: Place) {
        byID[place.id] = place
        save()
    }

    func remove(_ id: String) {
        byID[id] = nil
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: url),
              let list = try? JSONDecoder.iso.decode([Place].self, from: data) else { return }
        byID = Dictionary(uniqueKeysWithValues: list.map { ($0.id, $0) })
    }

    private func save() {
        guard let data = try? JSONEncoder.iso.encode(Array(byID.values)) else { return }
        try? data.write(to: url, options: .atomic)
    }
}

// the outbound queue. every local change appends a mutation here. the sync engine
// drains it in one batch when there is a connection, which mirrors real batched
// apis instead of firing one request per row.
final class MutationQueue {
    private let url: URL
    private var pending: [Mutation] = []

    init(filename: String = "queue.json") {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.url = dir.appendingPathComponent(filename)
        load()
    }

    var count: Int { pending.count }

    func enqueue(_ m: Mutation) {
        pending.append(m)
        save()
    }

    func snapshot() -> [Mutation] { pending }

    // drop the mutations that just synced ok. anything added while the push was in
    // flight stays, so we never lose a change.
    func clear(_ done: [Mutation]) {
        let ids = Set(done.map { $0.id })
        pending.removeAll { ids.contains($0.id) }
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: url),
              let list = try? JSONDecoder.iso.decode([Mutation].self, from: data) else { return }
        pending = list
    }

    private func save() {
        guard let data = try? JSONEncoder.iso.encode(pending) else { return }
        try? data.write(to: url, options: .atomic)
    }
}

extension JSONEncoder {
    static let iso: JSONEncoder = {
        let e = JSONEncoder(); e.dateEncodingStrategy = .iso8601; return e
    }()
}
extension JSONDecoder {
    static let iso: JSONDecoder = {
        let d = JSONDecoder(); d.dateDecodingStrategy = .iso8601; return d
    }()
}
