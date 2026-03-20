import SwiftUI
import FamilyControls

@main
struct EarnItApp: App {
    @StateObject private var authManager = AuthorizationManager()
    @StateObject private var sessionManager = SessionManager()
    @StateObject private var profileManager = ProfileManager()
    @StateObject private var healthService = HealthKitService()
    @StateObject private var locationService = LocationService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(sessionManager)
                .environmentObject(profileManager)
                .environmentObject(healthService)
                .environmentObject(locationService)
                .onAppear {
                    authManager.requestAuthorization()
                }
                .task {
                    await healthService.requestAuthorization()
                }
        }
    }
}
