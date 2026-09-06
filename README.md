# Places
<img width="992" height="1778" alt="Screen Recording 2026-08-26 at 11 09 22 PM" src="https://github.com/user-attachments/assets/b83e71dd-e503-43dc-a6ba-ccf290d8739c" />


An offline-first iOS app for saving and organizing places, with real cloud sync. It works fully offline; changes queue locally and sync to a live backend when a connection is available, with conflict resolution on top.

## What this demonstrates

- **Offline-first architecture** — the local store is the source of truth; the network is a background reconciler, never in the path of a user action.
- **Real cloud sync** — writes go to a live Firebase Firestore database and are readable across devices, not a local mock.
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
 MockRemoteAPI / FirestoreRemoteAPI
```

The `RemoteAPI` protocol makes the backend a swappable dependency. The app was built and tested against an in-memory mock, then moved to a live Firebase Firestore backend by swapping a single implementation — the sync engine did not change. That seam is the main design decision: the UI and the sync engine never know how or where data is stored.

## Sync design

- Every record carries `updatedAt`, `isDirty`, `isDeleted` (a tombstone), and a `version`.
- Local changes are recorded as mutations and flushed in a single batch when online, rather than one request per row.
- Deletes propagate as tombstones so a deletion syncs instead of only disappearing on the local device.
- Delta pulls fetch only what changed since the last sync token.
- Conflicts resolve last-write-wins by timestamp; field-level merge is the documented next step for production.

## Backend

Live cloud sync runs on **Firebase Firestore**. Each place is a document in a `places` collection, keyed by its id. Adding or editing a place on the device writes the document to the cloud; the same data is readable from the Firebase console and from any other instance of the app.

## Tech

Swift, UIKit, MVVM, programmatic Auto Layout, `UICollectionView` with compositional layout and a diffable data source, async/await, Firebase Firestore, XCTest.

## Testing

The sync engine is tested as pure logic with no UI or real network — conflict resolution picks the correct winner, the mutation queue flushes and clears correctly, and tombstones propagate. Run with `Cmd+U` in Xcode.

## Status

A working app with a full sync engine, passing unit tests, and **live cloud sync via Firebase Firestore**.

Next steps:
- A visible conflict-resolution demo (simulate a remote edit and watch it resolve)
- A MapKit thumbnail per place
- Ship to TestFlight

## Development & AI-Assisted Workflow

Built this project using AI coding assistants (Claude, GitHub Copilot) as a
pair-programming tool, while owning the architecture and verifying every output.
I used AI to move faster on boilerplate and to explore approaches, then reviewed,
tested, and adjusted the generated code against the app's real requirements —
for example, validating the sync engine's conflict-resolution logic with unit
tests rather than trusting generated code as-is. The design decisions (offline-first
architecture, the swappable RemoteAPI protocol, last-write-wins conflict handling)
and the verification are mine.
## Author

Satya — [github.com/satya764](https://github.com/satya764)
