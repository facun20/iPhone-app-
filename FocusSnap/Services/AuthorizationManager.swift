import Foundation
import FamilyControls

/// Manages FamilyControls authorization for Screen Time access
@MainActor
class AuthorizationManager: ObservableObject {
    @Published var isAuthorized = false
    @Published var authorizationError: String?

    func requestAuthorization() {
        Task {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                isAuthorized = true
                authorizationError = nil
            } catch {
                isAuthorized = false
                authorizationError = error.localizedDescription
            }
        }
    }

    func checkAuthorizationStatus() {
        isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
    }
}
