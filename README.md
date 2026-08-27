# Places

An offline-first iOS app for saving and organizing places, built to demonstrate a production-style sync architecture. It works fully offline; changes queue locally and sync when a connection is available, with conflict resolution on top.

## What this demonstrates

- **Offline-first architecture** — the local store is the source of truth; the network is a background reconciler, never in the path of a user action.
- **A real sync engine** — an outbound mutation queue, batched pushes, delta pulls, and last-write-wins conflict resolution.
- **UIKit + programmatic Auto Layout** across three screens (grid, detail/edit, sync status), no storyboards.
- **MVVM** with a protocol-based design so the backend and store are swappable and testable.
- **Unit-tested sync logic** — conflict resolution and queue behavior are covered by tests.

## Screens

- **Grid** — a `UICollectionView` (compositional layout + diffable data source) of saved places, each showing a sync-state dot: green (synced), orange (pending), red (conflict).
- **Detail / Edit** — edit a place's title and note; changes write locally and sync in the background.
- **Sync Status** — pending queue count, last-synced time, conflicts resolved, and a force-sync action.

## Architecture

```
View (UIKit) -> ViewModel (@MainActor) -> Store (local, source of truth)
 \-> SyncEngine -> RemoteAPI (protocol)
 |
 MockRemoteAPI / FirebaseRemoteAPI
```

The `RemoteAPI` protocol makes the backend a swappable dependency. The app runs today against an in-memory mock, and the same sync engine can talk to a real backend (e.g. Firebase) without any change to the sync logic. That seam is the main design decision — the UI never knows how or where data syncs.

## Sync design

- Every record carries `updatedAt`, `isDirty`, `isDeleted` (a tombstone), and a `version`.
- Local changes are recorded as mutations and flushed in a single batch when online, rather than one request per row.
- Deletes propagate as tombstones so a deletion syncs instead of only disappearing on the local device.
- Delta pulls fetch only what changed since the last sync token.
- Conflicts resolve last-write-wins by timestamp; field-level merge is the documented next step for production.

## Tech

Swift, UIKit, MVVM, programmatic Auto Layout, `UICollectionView` with compositional layout and a diffable data source, async/await, XCTest.

## Testing

The sync engine is tested as pure logic with no UI or real network — conflict resolution picks the correct winner, the mutation queue flushes and clears correctly, and tombstones propagate. Run with `Cmd+U` in Xcode.

## Status

A working local app with a full sync engine and passing unit tests.

Roadmap:
- Real backend (Firebase) for genuine cross-device sync
- A visible conflict-resolution demo (simulate a remote edit and watch it resolve)
- A MapKit thumbnail per place
- Ship to TestFlight

## Author

Satya — [github.com/satya764](https://github.com/satya764)
