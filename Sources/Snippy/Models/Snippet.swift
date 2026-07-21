import Foundation

struct RestrictedApp: Codable, Equatable, Identifiable {
    let bundleIdentifier: String
    let displayName: String
    var id: String { bundleIdentifier }
}

struct Snippet: Identifiable, Codable, Equatable {
    let id: UUID
    var trigger: String
    var expansion: String
    var folder: String?
    var createdAt: Date
    var updatedAt: Date
    /// Apps this snippet is allowed to fire in. Empty means "everywhere".
    var restrictedApps: [RestrictedApp]

    init(trigger: String, expansion: String, folder: String? = nil, restrictedApps: [RestrictedApp] = []) {
        self.id = UUID()
        self.trigger = trigger
        self.expansion = expansion
        self.folder = folder
        self.createdAt = Date()
        self.updatedAt = Date()
        self.restrictedApps = restrictedApps
    }

    private enum CodingKeys: String, CodingKey {
        case id, trigger, expansion, folder, createdAt, updatedAt, restrictedApps
    }

    /// Custom decode so snippets saved before `restrictedApps` existed still load.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        trigger = try container.decode(String.self, forKey: .trigger)
        expansion = try container.decode(String.self, forKey: .expansion)
        folder = try container.decodeIfPresent(String.self, forKey: .folder)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        restrictedApps = try container.decodeIfPresent([RestrictedApp].self, forKey: .restrictedApps) ?? []
    }
}
