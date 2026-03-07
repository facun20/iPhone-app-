import SwiftUI
import FamilyControls

@main
struct FocusSnapApp: App {
    @StateObject private var authManager = AuthorizationManager()
    @StateObject private var sessionManager = SessionManager()
    @StateObject private var profileManager = ProfileManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(sessionManager)
                .environmentObject(profileManager)
                .onAppear {
                    authManager.requestAuthorization()
                }
        }
    }
}
