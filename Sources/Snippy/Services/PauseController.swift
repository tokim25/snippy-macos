import Foundation

/// Runtime-only — deliberately not persisted, so relaunching Snippy always
/// starts unpaused rather than leaving you wondering why nothing expands.
final class PauseController: ObservableObject {
    @Published var isPaused = false

    func toggle() {
        isPaused.toggle()
    }
}
