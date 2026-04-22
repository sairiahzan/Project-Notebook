import SwiftUI

@main
struct Project_NotebookApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            MainLayoutView()
                .environmentObject(appState)
                .frame(minWidth: 800, minHeight: 600)
        }
    }
}
