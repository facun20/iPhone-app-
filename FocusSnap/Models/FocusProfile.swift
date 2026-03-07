import Foundation
import FamilyControls
import ManagedSettings

/// A focus profile defines which apps to block and what challenge to use for unlock
struct FocusProfile: Codable, Identifiable {
    let id: UUID
    var name: String
    var icon: String
    var challenge: Challenge
    var activitySelection: FamilyActivitySelection
    var emergencyUnlocksRemaining: Int
    var isActive: Bool
    var createdAt: Date
    var totalSessionsCompleted: Int
    var totalFocusMinutes: Int

    init(
        name: String,
        icon: String = "moon.fill",
        challenge: Challenge,
        activitySelection: FamilyActivitySelection = FamilyActivitySelection(),
        emergencyUnlocks: Int = 5
    ) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.challenge = challenge
        self.activitySelection = activitySelection
        self.emergencyUnlocksRemaining = emergencyUnlocks
        self.isActive = false
        self.createdAt = Date()
        self.totalSessionsCompleted = 0
        self.totalFocusMinutes = 0
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
                name: "Wind Down",
                icon: "moon.stars.fill",
                challenge: Challenge(type: .book)
            )
        ]
    }
}
