import Foundation

/// Represents a photo challenge the user must complete to unlock their phone
enum ChallengeType: String, Codable, CaseIterable, Identifiable {
    case outdoor = "outdoor"
    case book = "book"
    case gym = "gym"
    case nature = "nature"
    case food = "food"
    case pet = "pet"
    case workspace = "workspace"
    case custom = "custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .outdoor: return "Go Outside"
        case .book: return "Read a Book"
        case .gym: return "Hit the Gym"
        case .nature: return "Touch Grass"
        case .food: return "Make a Meal"
        case .pet: return "Pet Your Pet"
        case .workspace: return "Get to Work"
        case .custom: return "Custom"
        }
    }

    var description: String {
        switch self {
        case .outdoor: return "Take a photo of something outside"
        case .book: return "Take a photo of a book you're reading"
        case .gym: return "Take a photo at the gym"
        case .nature: return "Take a photo of nature — trees, grass, sky"
        case .food: return "Take a photo of a meal you made"
        case .pet: return "Take a photo of your pet"
        case .workspace: return "Take a photo of your desk or workspace"
        case .custom: return "Take a photo matching your custom challenge"
        }
    }

    var icon: String {
        switch self {
        case .outdoor: return "sun.max.fill"
        case .book: return "book.fill"
        case .gym: return "dumbbell.fill"
        case .nature: return "leaf.fill"
        case .food: return "fork.knife"
        case .pet: return "pawprint.fill"
        case .workspace: return "desktopcomputer"
        case .custom: return "star.fill"
        }
    }

    /// Keywords the Vision classifier should match for this challenge type
    var classificationKeywords: [String] {
        switch self {
        case .outdoor:
            return ["outdoor", "sky", "street", "building", "sidewalk", "road",
                    "park", "garden", "yard", "patio", "sunlight", "cloud"]
        case .book:
            return ["book", "text", "page", "reading", "library", "bookshelf",
                    "novel", "magazine", "newspaper", "document"]
        case .gym:
            return ["gym", "weight", "dumbbell", "treadmill", "exercise",
                    "fitness", "barbell", "bench", "workout", "sport"]
        case .nature:
            return ["tree", "grass", "flower", "plant", "forest", "mountain",
                    "lake", "river", "ocean", "beach", "leaf", "garden", "nature"]
        case .food:
            return ["food", "meal", "plate", "cooking", "kitchen", "dish",
                    "fruit", "vegetable", "breakfast", "lunch", "dinner"]
        case .pet:
            return ["dog", "cat", "pet", "puppy", "kitten", "animal",
                    "bird", "fish", "hamster", "rabbit"]
        case .workspace:
            return ["desk", "computer", "monitor", "keyboard", "office",
                    "workspace", "laptop", "chair", "table"]
        case .custom:
            return []
        }
    }
}

struct Challenge: Codable, Identifiable {
    let id: UUID
    let type: ChallengeType
    var customKeywords: [String]
    var customDescription: String?

    init(type: ChallengeType, customKeywords: [String] = [], customDescription: String? = nil) {
        self.id = UUID()
        self.type = type
        self.customKeywords = customKeywords
        self.customDescription = customDescription
    }

    var keywords: [String] {
        type == .custom ? customKeywords : type.classificationKeywords
    }

    var displayDescription: String {
        customDescription ?? type.description
    }
}
