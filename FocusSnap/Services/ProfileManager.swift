import Foundation
import FamilyControls

/// Manages focus profiles (create, edit, delete, persist)
@MainActor
class ProfileManager: ObservableObject {
    @Published var profiles: [FocusProfile] = []

    private let storageKey = "focusSnap.profiles"

    init() {
        loadProfiles()
        if profiles.isEmpty {
            profiles = FocusProfile.defaultProfiles
            saveProfiles()
        }
    }

    func addProfile(_ profile: FocusProfile) {
        profiles.append(profile)
        saveProfiles()
    }

    func updateProfile(_ profile: FocusProfile) {
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = profile
            saveProfiles()
        }
    }

    func deleteProfile(_ profile: FocusProfile) {
        profiles.removeAll { $0.id == profile.id }
        saveProfiles()
    }

    func profile(for id: UUID) -> FocusProfile? {
        profiles.first { $0.id == id }
    }

    private func saveProfiles() {
        if let data = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadProfiles() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let loaded = try? JSONDecoder().decode([FocusProfile].self, from: data) {
            profiles = loaded
        }
    }
}
