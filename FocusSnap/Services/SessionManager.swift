import Foundation
import ManagedSettings
import FamilyControls

/// Manages focus sessions — starting (locking apps) and ending (unlocking via conditions)
/// Supports both simple mode (one challenge unlocks all) and per-app rules
@MainActor
class SessionManager: ObservableObject {
    @Published var activeSession: FocusSession?
    @Published var sessionHistory: [FocusSession] = []
    @Published var activeProfile: FocusProfile?
    @Published var unlockedRuleIds: Set<UUID> = []

    private let store = ManagedSettingsStore()
    private let storageKey = "earnit.sessionHistory"

    init() {
        loadHistory()
        loadActiveSession()
    }

    // MARK: - Start Session (Lock Apps)

    /// One-tap lock — shields all apps across all rules in the profile
    func startSession(profile: FocusProfile) {
        activeProfile = profile
        unlockedRuleIds = []

        // Shield all apps from all rules + fallback selection
        let allAppTokens = profile.allBlockedAppTokens
        let allCategoryTokens = profile.allBlockedCategoryTokens

        store.shield.applications = allAppTokens
        store.shield.applicationCategories = ShieldSettings
            .ActivityCategoryPolicy
            .specific(allCategoryTokens)
        store.shield.webDomains = profile.activitySelection.webDomainTokens

        // Create session record
        let session = FocusSession(profile: profile)
        activeSession = session
        saveActiveSession()
    }

    // MARK: - Per-App Unlock

    /// Unlock a specific rule's apps (e.g., user hit 10K steps, unlock Twitter)
    func unlockRule(_ rule: AppUnlockRule) {
        unlockedRuleIds.insert(rule.id)

        // Recalculate which apps should still be shielded
        guard let profile = activeProfile else { return }
        reapplyShields(for: profile)

        // If all rules are unlocked, end the session
        if profile.usesPerAppRules {
            let allRuleIds = Set(profile.unlockRules.map { $0.id })
            if unlockedRuleIds.isSupersetOf(allRuleIds) {
                endSession()
            }
        }
    }

    /// Recalculate shields based on which rules are still locked
    private func reapplyShields(for profile: FocusProfile) {
        if profile.usesPerAppRules {
            var remainingApps = Set<ApplicationToken>()
            var remainingCategories = Set<ActivityCategoryToken>()

            for rule in profile.unlockRules {
                if !unlockedRuleIds.contains(rule.id) {
                    remainingApps.formUnion(rule.applicationTokens)
                    remainingCategories.formUnion(rule.categoryTokens)
                }
            }

            if remainingApps.isEmpty && remainingCategories.isEmpty {
                store.shield.applications = nil
                store.shield.applicationCategories = nil
            } else {
                store.shield.applications = remainingApps
                store.shield.applicationCategories = ShieldSettings
                    .ActivityCategoryPolicy
                    .specific(remainingCategories)
            }
        }
    }

    // MARK: - End Session (Unlock All)

    /// Removes all shields — called after all conditions met or simple mode unlock
    func endSession(wasEmergency: Bool = false) {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil

        if var session = activeSession {
            session.endedAt = Date()
            session.wasEmergencyUnlock = wasEmergency
            sessionHistory.insert(session, at: 0)
            activeSession = nil
            activeProfile = nil
            unlockedRuleIds = []
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
            UserDefaults.standard.set(data, forKey: "earnit.activeSession")
        }
        if let data = try? JSONEncoder().encode(activeProfile) {
            UserDefaults.standard.set(data, forKey: "earnit.activeProfile")
        }
    }

    private func loadActiveSession() {
        if let data = UserDefaults.standard.data(forKey: "earnit.activeSession"),
           let session = try? JSONDecoder().decode(FocusSession.self, from: data) {
            activeSession = session
        }
        if let data = UserDefaults.standard.data(forKey: "earnit.activeProfile"),
           let profile = try? JSONDecoder().decode(FocusProfile.self, from: data) {
            activeProfile = profile
        }
    }

    private func clearActiveSession() {
        UserDefaults.standard.removeObject(forKey: "earnit.activeSession")
        UserDefaults.standard.removeObject(forKey: "earnit.activeProfile")
    }
}
