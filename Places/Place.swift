import Foundation

nonisolated struct Place: Codable, Identifiable, Hashable {
    let id: String
    var title: String
    var note: String
    var latitude: Double
    var longitude: Double
    var updatedAt: Date
    var isDirty: Bool
    var isDeleted: Bool
    var version: Int

    init(id: String = UUID().uuidString,
         title: String,
         note: String = "",
         latitude: Double,
         longitude: Double,
         updatedAt: Date = Date(),
         isDirty: Bool = true,
         isDeleted: Bool = false,
         version: Int = 0) {
        self.id = id
        self.title = title
        self.note = note
        self.latitude = latitude
        self.longitude = longitude
        self.updatedAt = updatedAt
        self.isDirty = isDirty
        self.isDeleted = isDeleted
        self.version = version
    }
}

nonisolated enum SyncState {
    case synced
    case pending
    case conflict
}

extension Place {
    nonisolated var syncState: SyncState {
        if isDirty { return .pending }
        return .synced
    }
}

nonisolated struct Mutation: Codable, Identifiable {
    enum Kind: String, Codable { case upsert, delete }
    let id: String
    let placeID: String
    let kind: Kind
    let createdAt: Date

    init(placeID: String, kind: Kind) {
        self.id = UUID().uuidString
        self.placeID = placeID
        self.kind = kind
        self.createdAt = Date()
    }
}
