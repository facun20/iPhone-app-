import Foundation
import ManagedSettings
import FamilyControls

/// Manages focus sessions — starting (locking apps) and ending (unlocking via photo)
@MainActor
class SessionManager: ObservableObject {
    @Published var activeSession: FocusSession?
    @Published var sessionHistory: [FocusSession] = []

    private let store = ManagedSettingsStore()
    private let storageKey = "focusSnap.sessionHistory"

    init() {
        loadHistory()
        loadActiveSession()
    }

    // MARK: - Start Session (Lock Apps)

    /// One-tap lock — shields all apps in the profile
    func startSession(profile: FocusProfile) {
        // Apply shields to selected apps
        store.shield.applications = profile.activitySelection.applicationTokens
        store.shield.applicationCategories = ShieldSettings
            .ActivityCategoryPolicy
            .specific(profile.activitySelection.categoryTokens)
        store.shield.webDomains = profile.activitySelection.webDomainTokens

        // Create session record
        let session = FocusSession(profile: profile)
        activeSession = session
        saveActiveSession()
    }

    // MARK: - End Session (Unlock Apps)

    /// Removes all shields — called after successful photo verification
    func endSession(wasEmergency: Bool = false) {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil

        if var session = activeSession {
            session.endedAt = Date()
            session.wasEmergencyUnlock = wasEmergency
            sessionHistory.insert(session, at: 0)
            activeSession = nil
            saveHistory()
            clearActiveSession()
        }
    }

    // MARK: - Emergency Unlock

    func emergencyUnlock(profile: inout FocusProfile) -> Bool {
        guard profile.emergencyUnlocksRemaining > 0 else { return false }
        profile.emergencyUnlocksRemaining -= 1
        endSession(wasEmergency: true)
        return true
    }

    // MARK: - Stats

    var totalFocusTime: TimeInterval {
        sessionHistory.reduce(0) { $0 + $1.duration }
    }

    var totalSessions: Int {
        sessionHistory.count
    }

    var currentStreak: Int {
        guard !sessionHistory.isEmpty else { return 0 }
        var streak = 0
        let calendar = Calendar.current
        var checkDate = calendar.startOfDay(for: Date())

        for session in sessionHistory.sorted(by: { $0.startedAt > $1.startedAt }) {
            let sessionDay = calendar.startOfDay(for: session.startedAt)
            if sessionDay == checkDate {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else if sessionDay < checkDate {
                break
            }
        }
        return max(streak, sessionHistory.isEmpty ? 0 : 1)
    }

    // MARK: - Persistence

    private func saveHistory() {
        if let data = try? JSONEncoder().encode(sessionHistory) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let history = try? JSONDecoder().decode([FocusSession].self, from: data) {
            sessionHistory = history
        }
    }

    private func saveActiveSession() {
        if let data = try? JSONEncoder().encode(activeSession) {
            UserDefaults.standard.set(data, forKey: "focusSnap.activeSession")
        }
    }

    private func loadActiveSession() {
        if let data = UserDefaults.standard.data(forKey: "focusSnap.activeSession"),
           let session = try? JSONDecoder().decode(FocusSession.self, from: data) {
            activeSession = session
        }
    }

    private func clearActiveSession() {
        UserDefaults.standard.removeObject(forKey: "focusSnap.activeSession")
    }
}
