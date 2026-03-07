import Foundation

/// Represents an active or completed focus session
struct FocusSession: Codable, Identifiable {
    let id: UUID
    let profileId: UUID
    let profileName: String
    let challengeType: ChallengeType
    let startedAt: Date
    var endedAt: Date?
    var wasEmergencyUnlock: Bool

    init(profile: FocusProfile) {
        self.id = UUID()
        self.profileId = profile.id
        self.profileName = profile.name
        self.challengeType = profile.challenge.type
        self.startedAt = Date()
        self.endedAt = nil
        self.wasEmergencyUnlock = false
    }

    var isActive: Bool {
        endedAt == nil
    }

    var duration: TimeInterval {
        let end = endedAt ?? Date()
        return end.timeIntervalSince(startedAt)
    }

    var durationFormatted: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}
