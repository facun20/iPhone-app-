import Foundation
import FamilyControls
import ManagedSettings

/// A focus profile defines unlock rules for apps — each app/group can have its own unlock condition
struct FocusProfile: Codable, Identifiable {
    let id: UUID
    var name: String
    var icon: String

    // Legacy: single challenge for the whole profile (still supported for simple mode)
    var challenge: Challenge

    // New: per-app unlock rules — the core feature
    var unlockRules: [AppUnlockRule]

    // Fallback selection for apps not assigned to a specific rule
    var activitySelection: FamilyActivitySelection

    var emergencyUnlocksRemaining: Int
    var isActive: Bool
    var createdAt: Date
    var totalSessionsCompleted: Int
    var totalFocusMinutes: Int

    /// If true, uses per-app rules. If false, uses simple single-challenge mode.
    var usesPerAppRules: Bool

    init(
        name: String,
        icon: String = "moon.fill",
        challenge: Challenge,
        unlockRules: [AppUnlockRule] = [],
        activitySelection: FamilyActivitySelection = FamilyActivitySelection(),
        emergencyUnlocks: Int = 5,
        usesPerAppRules: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.challenge = challenge
        self.unlockRules = unlockRules
        self.activitySelection = activitySelection
        self.emergencyUnlocksRemaining = emergencyUnlocks
        self.isActive = false
        self.createdAt = Date()
        self.totalSessionsCompleted = 0
        self.totalFocusMinutes = 0
        self.usesPerAppRules = usesPerAppRules
    }

    /// All app tokens across all rules
    var allBlockedAppTokens: Set<ApplicationToken> {
        if usesPerAppRules {
            return unlockRules.reduce(into: Set<ApplicationToken>()) { result, rule in
                result.formUnion(rule.applicationTokens)
            }
        }
        return activitySelection.applicationTokens
    }

    /// All category tokens across all rules
    var allBlockedCategoryTokens: Set<ActivityCategoryToken> {
        if usesPerAppRules {
            return unlockRules.reduce(into: Set<ActivityCategoryToken>()) { result, rule in
                result.formUnion(rule.categoryTokens)
            }
        }
        return activitySelection.categoryTokens
    }

    static var defaultProfiles: [FocusProfile] {
        [
            FocusProfile(
                name: "Morning Routine",
                icon: "sunrise.fill",
                challenge: Challenge(type: .outdoor)
            ),
            FocusProfile(
                name: "Deep Work",
                icon: "brain.head.profile",
                challenge: Challenge(type: .workspace)
            ),
            FocusProfile(
                name: "Get Moving",
                icon: "figure.walk",
                challenge: Challenge(type: .outdoor),
                unlockRules: [
                    AppUnlockRule(
                        name: "Social Media",
                        condition: UnlockCondition(type: .steps)
                    ),
                    AppUnlockRule(
                        name: "Morning Apps",
                        condition: UnlockCondition(type: .photo)
                    )
                ],
                usesPerAppRules: true
            )
        ]
    }
}
