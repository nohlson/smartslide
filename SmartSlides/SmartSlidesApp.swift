import SwiftUI

@main
struct SmartSlidesApp: App {
    @StateObject private var settingsViewModel = SettingsViewModel()
    @State private var slideshowController: SlideshowWindowController?

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: settingsViewModel, onStartSlideshow: startSlideshow)
        }
        .windowResizability(.contentSize)
    }

    private func startSlideshow() {
        guard settingsViewModel.canStartSlideshow else { return }
        let controller = SlideshowWindowController(settingsViewModel: settingsViewModel)
        controller.onExit = {
            slideshowController = nil
        }
        slideshowController = controller
    }
}
