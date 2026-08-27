import XCTest
@testable import Places

// test the sync engine as pure logic, no ui and no real network. this is the part
// worth testing and the part interviewers care about. drop this in the test target.
final class SyncEngineTests: XCTestCase {

    private func makeEngine() -> (SyncEngine, LocalStore, MutationQueue, MockRemoteAPI) {
        let store = LocalStore(filename: "test_places_\(UUID().uuidString).json")
        let queue = MutationQueue(filename: "test_queue_\(UUID().uuidString).json")
        let api = MockRemoteAPI(latencyMillis: 0)
        return (SyncEngine(store: store, queue: queue, api: api), store, queue, api)
    }

    // clean local (no pending edits): server wins if its version is newer
    func testServerWinsWhenLocalNotDirty() {
        let (engine, _, _, _) = makeEngine()
        let local = Place(title: "old", latitude: 0, longitude: 0,
                          isDirty: false, version: 1)
        var remote = local; remote.title = "new"; remote.version = 2
        let winner = engine.resolve(local: local, remote: remote)
        XCTAssertEqual(winner?.title, "new")
    }

    // clean local and server has nothing newer: no change
    func testNoChangeWhenNothingNewer() {
        let (engine, _, _, _) = makeEngine()
        let local = Place(title: "same", latitude: 0, longitude: 0,
                          isDirty: false, version: 2)
        var remote = local; remote.version = 2
        XCTAssertNil(engine.resolve(local: local, remote: remote))
    }

    // conflict, remote edited more recently: last-write-wins picks remote
    func testConflictRemoteNewerWins() {
        let (engine, _, _, _) = makeEngine()
        let now = Date()
        let local = Place(title: "mine", latitude: 0, longitude: 0,
                          updatedAt: now.addingTimeInterval(-10),
                          isDirty: true, version: 1)
        var remote = local; remote.title = "theirs"
        remote.updatedAt = now; remote.version = 2; remote.isDirty = false
        XCTAssertEqual(engine.resolve(local: local, remote: remote)?.title, "theirs")
    }

    // conflict, local edited more recently: keep local edits, adopt server version
    func testConflictLocalNewerKeepsLocalButBumpsVersion() {
        let (engine, _, _, _) = makeEngine()
        let now = Date()
        let local = Place(title: "mine", latitude: 0, longitude: 0,
                          updatedAt: now, isDirty: true, version: 1)
        var remote = local; remote.title = "theirs"
        remote.updatedAt = now.addingTimeInterval(-10); remote.version = 2
        let winner = engine.resolve(local: local, remote: remote)
        XCTAssertEqual(winner?.title, "mine")
        XCTAssertEqual(winner?.version, 2)   // so the next push is not seen as stale
    }

    // full loop: add offline, sync, it lands on the server and clears the queue
    func testPushDrainsQueueAndClearsDirty() async {
        let (engine, store, queue, _) = makeEngine()
        let p = Place(title: "spot", latitude: 1, longitude: 2)
        store.upsert(p)
        queue.enqueue(Mutation(placeID: p.id, kind: .upsert))
        XCTAssertEqual(queue.count, 1)

        await engine.sync()

        XCTAssertEqual(queue.count, 0)
        XCTAssertEqual(store.place(p.id)?.isDirty, false)
        XCTAssertEqual(store.place(p.id)?.version, 1)
    }
}
