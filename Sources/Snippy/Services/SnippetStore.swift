import Foundation
import Combine

final class SnippetStore: ObservableObject {
    @Published private(set) var snippets: [Snippet] = []
    @Published private(set) var lastSyncedAt: Date?

    let isICloudAvailable: Bool
    private let fileURL: URL
    private var directoryWatcher: DispatchSourceFileSystemObject?

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let cloudDocs = home.appendingPathComponent("Library/Mobile Documents/com~apple~CloudDocs", isDirectory: true)
        isICloudAvailable = FileManager.default.fileExists(atPath: cloudDocs.path)

        let dir = (isICloudAvailable ? cloudDocs : home.appendingPathComponent("Library/Application Support", isDirectory: true))
            .appendingPathComponent("Snippy", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("snippets.json")

        migrateLegacyLocalStoreIfNeeded()
        load()
        startWatchingForExternalChanges()
    }

    /// Snippets used to live only under Application Support. Bring them along
    /// the first time we switch a Mac over to the iCloud Drive location.
    private func migrateLegacyLocalStoreIfNeeded() {
        guard isICloudAvailable, !FileManager.default.fileExists(atPath: fileURL.path) else { return }
        let legacyURL = FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Snippy/snippets.json")
        guard FileManager.default.fileExists(atPath: legacyURL.path) else { return }
        try? FileManager.default.copyItem(at: legacyURL, to: fileURL)
    }

    func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([Snippet].self, from: data) else {
            snippets = SnippetStore.defaultSnippets
            save()
            return
        }
        snippets = decoded
        lastSyncedAt = modificationDate()
    }

    func save() {
        guard let data = try? JSONEncoder().encode(snippets) else { return }
        try? data.write(to: fileURL, options: .atomic)
        lastSyncedAt = modificationDate()
    }

    func add(trigger: String, expansion: String, folder: String?) throws {
        let cleanTrigger = trigger.trimmingCharacters(in: .whitespacesAndNewlines)
        try validate(trigger: cleanTrigger, excluding: nil)
        snippets.append(Snippet(trigger: cleanTrigger, expansion: expansion, folder: normalized(folder)))
        save()
    }

    func update(_ snippet: Snippet, trigger: String, expansion: String, folder: String?) throws {
        let cleanTrigger = trigger.trimmingCharacters(in: .whitespacesAndNewlines)
        try validate(trigger: cleanTrigger, excluding: snippet.id)
        guard let idx = snippets.firstIndex(where: { $0.id == snippet.id }) else { return }
        snippets[idx].trigger = cleanTrigger
        snippets[idx].expansion = expansion
        snippets[idx].folder = normalized(folder)
        snippets[idx].updatedAt = Date()
        save()
    }

    func remove(_ snippet: Snippet) {
        snippets.removeAll { $0.id == snippet.id }
        save()
    }

    var folders: [String] {
        Set(snippets.compactMap(\.folder)).sorted()
    }

    /// Watches the containing folder (not the file itself) because our own
    /// atomic saves replace the file via a temp-file rename, which a watch on
    /// the original file's descriptor would never see. iCloud's own sync
    /// writes the same way, so this also catches snippets arriving from
    /// another Mac.
    private func startWatchingForExternalChanges() {
        let dirPath = fileURL.deletingLastPathComponent().path
        let fd = open(dirPath, O_EVTONLY)
        guard fd >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fd, eventMask: .write, queue: .main)
        source.setEventHandler { [weak self] in
            self?.reloadIfChangedOnDisk()
        }
        source.setCancelHandler { close(fd) }
        source.resume()
        directoryWatcher = source
    }

    private func reloadIfChangedOnDisk() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([Snippet].self, from: data),
              decoded != snippets else { return }
        snippets = decoded
        lastSyncedAt = modificationDate()
    }

    private func modificationDate() -> Date? {
        (try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.modificationDate]) as? Date
    }

    private func normalized(_ folder: String?) -> String? {
        guard let trimmed = folder?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }

    private func validate(trigger: String, excluding id: UUID?) throws {
        guard !trigger.isEmpty else { throw SnippetStoreError.emptyTrigger }
        let isDuplicate = snippets.contains { $0.trigger == trigger && $0.id != id }
        if isDuplicate { throw SnippetStoreError.duplicateTrigger }
    }

    static let defaultSnippets: [Snippet] = [
        Snippet(trigger: ";addr", expansion: "123 Main St, Springfield, IL 62704"),
        Snippet(trigger: ";sig", expansion: "Best,\nTony")
    ]
}

enum SnippetStoreError: LocalizedError {
    case emptyTrigger
    case duplicateTrigger

    var errorDescription: String? {
        switch self {
        case .emptyTrigger:
            return "Trigger can't be empty."
        case .duplicateTrigger:
            return "Another snippet already uses this trigger."
        }
    }
}
