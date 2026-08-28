import SwiftUI
import IntentOSKit

@main
struct IntentOSApp: App {
    var body: some Scene {
        WindowGroup {
            IntentOSControlPanel()
                .onAppear {
                    Task {
                        await IntentOSSession.shared.requestPermissions()
                    }
                }
        }
    }
}
