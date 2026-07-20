import Foundation

struct Snippet: Identifiable, Codable, Equatable {
    let id: UUID
    var trigger: String
    var expansion: String
    var folder: String?
    var createdAt: Date
    var updatedAt: Date

    init(trigger: String, expansion: String, folder: String? = nil) {
        self.id = UUID()
        self.trigger = trigger
        self.expansion = expansion
        self.folder = folder
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
