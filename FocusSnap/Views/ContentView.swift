import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthorizationManager
    @EnvironmentObject var sessionManager: SessionManager

    var body: some View {
        Group {
            if !authManager.isAuthorized {
                OnboardingView()
            } else if sessionManager.activeSession != nil {
                LockedView()
            } else {
                MainTabView()
            }
        }
        .preferredColorScheme(.dark)
    }
}
