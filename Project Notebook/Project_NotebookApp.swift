import SwiftUI

@main
struct Project_NotebookApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            MainLayoutView()
                .environmentObject(appState)
                .frame(minWidth: 800, minHeight: 600)
                .onAppear {
                    setAppIcon()
                }
        }
    }
    
    private func setAppIcon() {
        // Run on main thread and with a slight delay to ensure environment is ready
        DispatchQueue.main.async {
            let renderer = ImageRenderer(content: AppLogo(size: 512))
            if let image = renderer.nsImage {
                NSApp.applicationIconImage = image
            }
        }
    }
}
