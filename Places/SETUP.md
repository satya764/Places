# Places — starter skeleton

Offline-first saved-places app. Local store is the source of truth, changes queue and sync in the background, conflicts resolve on pull. This skeleton gives you the sync engine, the grid screen, and the tests. You build detail/edit and sync-status on top.

## What's here

- `Place.swift` — the model with sync metadata, plus the Mutation type
- `Persistence.swift` — file-backed local store and the outbound mutation queue
- `RemoteAPI.swift` — the backend protocol plus a mock so it runs with no server
- `SyncEngine.swift` — batched push, delta pull, conflict resolution (the part that matters)
- `PlacesViewModel.swift` — the MVVM layer
- `PlacesGridViewController.swift` — grid screen, all programmatic Auto Layout
- `SyncEngineTests.swift` — unit tests for the engine, drop in the test target

## Wire it up

1. New Xcode project → App → interface: **Storyboard**, language: **Swift**. Include tests.
2. Delete `Main.storyboard` and remove the storyboard name from Info.plist / target settings.
3. Add all the `.swift` files above to the app target (tests file to the test target).
4. In `SceneDelegate`, build the object graph and set the grid as root:

```swift
func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
           options connectionOptions: UIScene.ConnectionOptions) {
    guard let windowScene = scene as? UIWindowScene else { return }
    let store  = LocalStore()
    let queue  = MutationQueue()
    let engine = SyncEngine(store: store, queue: queue, api: MockRemoteAPI())
    let vm     = PlacesViewModel(store: store, queue: queue, engine: engine)

    let window = UIWindow(windowScene: windowScene)
    window.rootViewController = UINavigationController(
        rootViewController: PlacesGridViewController(viewModel: vm))
    window.makeKeyAndVisible()
    self.window = window
}
```

5. Run. Tap **+** a few times, watch the dots go orange (pending) then green (synced).

## Your build list, in order

1. **Detail / edit screen** — tap a card → edit title and note → `viewModel.edit(...)`. Add a MapKit pin here. This is your second screen.
2. **Sync status screen** — pending count, last sync, force-sync button, conflict log. This is where you show off the engine to anyone who opens the app.
3. **Real backend** — swap `MockRemoteAPI` for Firebase or Supabase. The engine does not change.
4. **Reachability** — `NWPathMonitor` to auto-sync when the connection returns.
5. **Ship to TestFlight** — the single biggest credibility jump. Put the link in your README and resume.

## Talking points for interviews

- Why local-first: user actions never block on the network, so the app works on the subway.
- Why a mutation queue and not just pushing rows: an offline create-then-edit both make it up, in order, in one batch.
- Why tombstones: a delete has to sync, not just vanish locally.
- Conflict resolution: you shipped last-write-wins; you can explain field-level merge and when you'd choose it. That tradeoff answer is the senior signal.
