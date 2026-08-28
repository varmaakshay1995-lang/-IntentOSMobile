import SwiftUI

@main
struct IntentOSApp: App {
    var body: some Scene {
        WindowGroup {
            IntentOSControlPanel()
                .onAppear {
                    // Configure IntentOS session
                    Task {
                        await IntentOSSession.shared.requestPermissions()
                    }
                }
        }
    }
}
