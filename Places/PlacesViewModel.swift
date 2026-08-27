import Foundation

@MainActor
final class PlacesViewModel {
    private let store: LocalStore
    private let queue: MutationQueue
    private let engine: SyncEngine

    var onChange: (() -> Void)?

    private(set) var places: [Place] = []

    init(store: LocalStore, queue: MutationQueue, engine: SyncEngine) {
        self.store = store
        self.queue = queue
        self.engine = engine
        self.engine.onStateChange = { [weak self] in
            Task { @MainActor in self?.reload() }
        }
        reload()
    }

    var pendingCount: Int { engine.pendingCount }
    var lastSyncedAt: Date? { engine.lastSyncedAt }
    var conflictCount: Int { engine.lastConflictCount }

    func forceSync() {
        engine.forceSync()
    }

    func place(_ id: String) -> Place? {
        store.place(id)
    }

    func reload() {
        places = store.visiblePlaces()
        onChange?()
    }

    func add(title: String, note: String, latitude: Double, longitude: Double) {
        let place = Place(title: title, note: note, latitude: latitude, longitude: longitude)
        store.upsert(place)
        queue.enqueue(Mutation(placeID: place.id, kind: .upsert))
        reload()
        triggerSync()
    }

    func edit(_ id: String, title: String, note: String) {
        guard var p = store.place(id) else { return }
        p.title = title
        p.note = note
        p.updatedAt = Date()
        p.isDirty = true
        store.upsert(p)
        queue.enqueue(Mutation(placeID: id, kind: .upsert))
        reload()
        triggerSync()
    }

    func delete(_ id: String) {
        guard var p = store.place(id) else { return }
        p.isDeleted = true
        p.isDirty = true
        p.updatedAt = Date()
        store.upsert(p)
        queue.enqueue(Mutation(placeID: id, kind: .delete))
        reload()
        triggerSync()
    }

    func triggerSync() {
        Task { await engine.sync() }
    }
}
