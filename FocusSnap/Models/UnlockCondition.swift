import Foundation
import FamilyControls

/// The core abstraction: any condition that must be met to unlock an app or group of apps
enum UnlockConditionType: String, Codable, CaseIterable, Identifiable {
    case photo = "photo"
    case steps = "steps"
    case distance = "distance"
    case workout = "workout"
    case timeBased = "time_based"
    case calories = "calories"
    case flights = "flights"
    case mindfulness = "mindfulness"
    case journaling = "journaling"
    case location = "location"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .photo: return "Take a Photo"
        case .steps: return "Walk Steps"
        case .distance: return "Walk Distance"
        case .workout: return "Complete Workout"
        case .timeBased: return "Wait Until Time"
        case .calories: return "Burn Calories"
        case .flights: return "Climb Stairs"
        case .mindfulness: return "Mindfulness"
        case .journaling: return "Journal Entry"
        case .location: return "Show Up"
        }
    }

    var description: String {
        switch self {
        case .photo: return "Take a real photo matching a challenge"
        case .steps: return "Reach a step count goal from HealthKit"
        case .distance: return "Walk or run a target distance"
        case .workout: return "Complete a workout of any type"
        case .timeBased: return "App unlocks after a specific time of day"
        case .calories: return "Burn active calories tracked by Apple Health"
        case .flights: return "Climb flights of stairs tracked by your phone"
        case .mindfulness: return "Complete a meditation or prayer session"
        case .journaling: return "Write a journal entry to reflect and unlock"
        case .location: return "Arrive at a place like the gym, school, or office"
        }
    }

    var icon: String {
        switch self {
        case .photo: return "camera.fill"
        case .steps: return "figure.walk"
        case .distance: return "map.fill"
        case .workout: return "dumbbell.fill"
        case .timeBased: return "clock.fill"
        case .calories: return "flame.fill"
        case .flights: return "figure.stairs"
        case .mindfulness: return "brain.head.profile.fill"
        case .journaling: return "pencil.and.scribble"
        case .location: return "location.fill"
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

    // Calories params
    var targetCalories: Int?

    // Flights climbed params
    var targetFlights: Int?

    // Mindfulness params (in minutes)
    var targetMindfulnessMinutes: Int?
    var mindfulnessLabel: String?  // "Meditation", "Prayer", "Breathing", or custom

    // Journaling params
    var targetWordCount: Int?
    var journalPrompt: String?

    // Location params
    var locationName: String?
    var locationLatitude: Double?
    var locationLongitude: Double?
    var locationRadiusMeters: Double?  // geofence radius

    // Deadline — optional "complete by" time for any condition
    var deadlineHour: Int?
    var deadlineMinute: Int?
    var hasDeadline: Bool { deadlineHour != nil }

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
        case .calories:
            self.targetCalories = 200
        case .flights:
            self.targetFlights = 5
        case .mindfulness:
            self.targetMindfulnessMinutes = 5
            self.mindfulnessLabel = "Meditation"
        case .journaling:
            self.targetWordCount = 50
        case .location:
            self.locationName = ""
            self.locationRadiusMeters = 100  // ~300 feet
        }
    }

    var displaySummary: String {
        let base: String
        switch type {
        case .photo:
            base = challengeType?.displayName ?? "Take a Photo"
        case .steps:
            let steps = targetSteps ?? 5000
            base = "\(steps.formatted()) steps"
        case .distance:
            let miles = (targetDistanceMeters ?? 1609.34) / 1609.34
            base = String(format: "%.1f miles", miles)
        case .workout:
            base = "\(targetWorkoutMinutes ?? 30) min workout"
        case .timeBased:
            let h = unlockAfterHour ?? 9
            let m = unlockAfterMinute ?? 0
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            var components = DateComponents()
            components.hour = h
            components.minute = m
            if let date = Calendar.current.date(from: components) {
                base = "After \(formatter.string(from: date))"
            } else {
                base = "After \(h):\(String(format: "%02d", m))"
            }
        case .calories:
            base = "\(targetCalories ?? 200) cal"
        case .flights:
            let f = targetFlights ?? 5
            base = "\(f) flight\(f == 1 ? "" : "s")"
        case .mindfulness:
            let label = mindfulnessLabel ?? "Meditation"
            base = "\(targetMindfulnessMinutes ?? 5) min \(label.lowercased())"
        case .journaling:
            base = "\(targetWordCount ?? 50) words"
        case .location:
            base = locationName?.isEmpty == false ? "Arrive at \(locationName!)" : "Arrive at location"
        }

        if let h = deadlineHour, let m = deadlineMinute {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            var components = DateComponents()
            components.hour = h
            components.minute = m
            if let date = Calendar.current.date(from: components) {
                return "\(base) by \(formatter.string(from: date))"
            }
            return "\(base) by \(h):\(String(format: "%02d", m))"
        }

        return base
    }

    var deadlineFormatted: String? {
        guard let h = deadlineHour, let m = deadlineMinute else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        var components = DateComponents()
        components.hour = h
        components.minute = m
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(h):\(String(format: "%02d", m))"
    }

    var isDeadlinePassed: Bool {
        guard let h = deadlineHour, let m = deadlineMinute else { return false }
        let now = Calendar.current.dateComponents([.hour, .minute], from: Date())
        let currentMinutes = (now.hour ?? 0) * 60 + (now.minute ?? 0)
        let deadlineMinutes = h * 60 + m
        return currentMinutes > deadlineMinutes
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
        case .calories:
            return "\(Int(currentValue)) / \(Int(targetValue)) cal"
        case .flights:
            return "\(Int(currentValue)) / \(Int(targetValue)) flights"
        case .mindfulness:
            let label = condition.mindfulnessLabel ?? "Meditation"
            if isComplete {
                return "\(label) complete"
            }
            return "\(Int(currentValue)) / \(Int(targetValue)) min"
        case .journaling:
            if isComplete {
                return "Entry complete"
            }
            return "\(Int(currentValue)) / \(Int(targetValue)) words"
        case .location:
            if isComplete {
                return "You arrived!"
            }
            return condition.locationName?.isEmpty == false ? "Go to \(condition.locationName!)" : "Head to your location"
        }
    }

    var deadlineText: String? {
        guard condition.hasDeadline, let formatted = condition.deadlineFormatted else { return nil }
        if condition.isDeadlinePassed && !isComplete {
            return "Deadline passed (\(formatted))"
        }
        return "Due by \(formatted)"
    }
}
