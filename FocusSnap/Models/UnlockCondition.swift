import Foundation
import FamilyControls

/// The core abstraction: any condition that must be met to unlock an app or group of apps
enum UnlockConditionType: String, Codable, CaseIterable, Identifiable {
    case photo = "photo"
    case steps = "steps"
    case distance = "distance"
    case workout = "workout"
    case timeBased = "time_based"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .photo: return "Take a Photo"
        case .steps: return "Walk Steps"
        case .distance: return "Walk Distance"
        case .workout: return "Complete Workout"
        case .timeBased: return "Wait Until Time"
        }
    }

    var description: String {
        switch self {
        case .photo: return "Take a real photo matching a challenge"
        case .steps: return "Reach a step count goal from HealthKit"
        case .distance: return "Walk or run a target distance"
        case .workout: return "Complete a workout of any type"
        case .timeBased: return "App unlocks after a specific time of day"
        }
    }

    var icon: String {
        switch self {
        case .photo: return "camera.fill"
        case .steps: return "figure.walk"
        case .distance: return "map.fill"
        case .workout: return "dumbbell.fill"
        case .timeBased: return "clock.fill"
        }
    }
}

/// A specific unlock condition with its parameters
struct UnlockCondition: Codable, Identifiable {
    let id: UUID
    let type: UnlockConditionType

    // Photo challenge params
    var challengeType: ChallengeType?

    // Steps params
    var targetSteps: Int?

    // Distance params (in meters)
    var targetDistanceMeters: Double?

    // Workout params (in minutes)
    var targetWorkoutMinutes: Int?

    // Time-based params
    var unlockAfterHour: Int?
    var unlockAfterMinute: Int?

    init(type: UnlockConditionType) {
        self.id = UUID()
        self.type = type

        // Set sensible defaults
        switch type {
        case .photo:
            self.challengeType = .outdoor
        case .steps:
            self.targetSteps = 5000
        case .distance:
            self.targetDistanceMeters = 1609.34 // 1 mile
        case .workout:
            self.targetWorkoutMinutes = 30
        case .timeBased:
            self.unlockAfterHour = 9
            self.unlockAfterMinute = 0
        }
    }

    var displaySummary: String {
        switch type {
        case .photo:
            return challengeType?.displayName ?? "Take a Photo"
        case .steps:
            let steps = targetSteps ?? 5000
            return "\(steps.formatted()) steps"
        case .distance:
            let miles = (targetDistanceMeters ?? 1609.34) / 1609.34
            return String(format: "%.1f miles", miles)
        case .workout:
            return "\(targetWorkoutMinutes ?? 30) min workout"
        case .timeBased:
            let h = unlockAfterHour ?? 9
            let m = unlockAfterMinute ?? 0
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            var components = DateComponents()
            components.hour = h
            components.minute = m
            if let date = Calendar.current.date(from: components) {
                return "After \(formatter.string(from: date))"
            }
            return "After \(h):\(String(format: "%02d", m))"
        }
    }
}

/// Maps a specific unlock condition to specific apps
/// This is the key model: "Twitter requires 10K steps, Instagram requires a photo"
struct AppUnlockRule: Codable, Identifiable {
    let id: UUID
    var name: String
    var condition: UnlockCondition
    var applicationTokens: Set<ApplicationToken>
    var categoryTokens: Set<ActivityCategoryToken>
    var isUnlocked: Bool
    var unlockedAt: Date?

    init(
        name: String,
        condition: UnlockCondition,
        applicationTokens: Set<ApplicationToken> = [],
        categoryTokens: Set<ActivityCategoryToken> = []
    ) {
        self.id = UUID()
        self.name = name
        self.condition = condition
        self.applicationTokens = applicationTokens
        self.categoryTokens = categoryTokens
        self.isUnlocked = false
        self.unlockedAt = nil
    }
}

/// Progress tracking for a condition during an active session
struct ConditionProgress: Identifiable {
    let id: UUID  // matches the AppUnlockRule id
    let ruleName: String
    let condition: UnlockCondition
    var currentValue: Double
    var targetValue: Double
    var isComplete: Bool

    var progressFraction: Double {
        guard targetValue > 0 else { return 0 }
        return min(currentValue / targetValue, 1.0)
    }

    var progressText: String {
        switch condition.type {
        case .photo:
            return isComplete ? "Photo verified" : "Photo required"
        case .steps:
            return "\(Int(currentValue).formatted()) / \(Int(targetValue).formatted()) steps"
        case .distance:
            let currentMiles = currentValue / 1609.34
            let targetMiles = targetValue / 1609.34
            return String(format: "%.1f / %.1f miles", currentMiles, targetMiles)
        case .workout:
            return "\(Int(currentValue)) / \(Int(targetValue)) min"
        case .timeBased:
            if isComplete {
                return "Time reached"
            }
            let h = condition.unlockAfterHour ?? 9
            let m = condition.unlockAfterMinute ?? 0
            return "Unlocks at \(h):\(String(format: "%02d", m))"
        }
    }
}
