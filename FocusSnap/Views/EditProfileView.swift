import SwiftUI
import FamilyControls

struct EditProfileView: View {
    @EnvironmentObject var profileManager: ProfileManager
    @Environment(\.dismiss) var dismiss

    let profile: FocusProfile?

    @State private var name: String = ""
    @State private var selectedIcon: String = "moon.fill"
    @State private var selectedChallenge: ChallengeType = .outdoor
    @State private var customKeywords: String = ""
    @State private var activitySelection = FamilyActivitySelection()
    @State private var showAppPicker = false

    private var isEditing: Bool { profile != nil }

    private let iconOptions = [
        "moon.fill", "sunrise.fill", "sun.max.fill", "moon.stars.fill",
        "brain.head.profile", "book.fill", "dumbbell.fill", "leaf.fill",
        "briefcase.fill", "graduationcap.fill", "heart.fill", "star.fill"
    ]

    var body: some View {
        NavigationStack {
            Form {
                // Name section
                Section("Profile Name") {
                    TextField("e.g. Morning Routine", text: $name)
                }

                // Icon section
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(iconOptions, id: \.self) { icon in
                            Button(action: { selectedIcon = icon }) {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundColor(selectedIcon == icon ? .white : .gray)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        selectedIcon == icon
                                        ? AnyShapeStyle(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        : AnyShapeStyle(Color.white.opacity(0.1))
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Challenge section
                Section("Unlock Challenge") {
                    ForEach(ChallengeType.allCases) { type in
                        Button(action: { selectedChallenge = type }) {
                            HStack(spacing: 12) {
                                Image(systemName: type.icon)
                                    .foregroundColor(.purple)
                                    .frame(width: 28)

                                VStack(alignment: .leading) {
                                    Text(type.displayName)
                                        .font(.subheadline.bold())
                                        .foregroundColor(.primary)
                                    Text(type.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                if selectedChallenge == type {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.purple)
                                }
                            }
                        }
                    }
                }

                // Apps to block
                Section("Apps to Block") {
                    Button(action: { showAppPicker = true }) {
                        HStack {
                            Image(systemName: "app.badge")
                                .foregroundColor(.purple)
                            Text("Select Apps & Categories")
                            Spacer()
                            let count = activitySelection.applicationTokens.count +
                                        activitySelection.categoryTokens.count
                            if count > 0 {
                                Text("\(count) selected")
                                    .foregroundColor(.gray)
                            }
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                }

                // Delete profile
                if isEditing {
                    Section {
                        Button(role: .destructive, action: deleteProfile) {
                            HStack {
                                Spacer()
                                Text("Delete Profile")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Profile" : "New Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveProfile() }
                        .disabled(name.isEmpty)
                }
            }
            .familyActivityPicker(isPresented: $showAppPicker, selection: $activitySelection)
            .onAppear { loadExisting() }
        }
    }

    private func loadExisting() {
        guard let profile = profile else { return }
        name = profile.name
        selectedIcon = profile.icon
        selectedChallenge = profile.challenge.type
        activitySelection = profile.activitySelection
    }

    private func saveProfile() {
        let challenge = Challenge(
            type: selectedChallenge,
            customKeywords: selectedChallenge == .custom
                ? customKeywords.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
                : []
        )

        if var existing = profile {
            existing.name = name
            existing.icon = selectedIcon
            existing.challenge = challenge
            existing.activitySelection = activitySelection
            profileManager.updateProfile(existing)
        } else {
            let newProfile = FocusProfile(
                name: name,
                icon: selectedIcon,
                challenge: challenge,
                activitySelection: activitySelection
            )
            profileManager.addProfile(newProfile)
        }

        dismiss()
    }

    private func deleteProfile() {
        if let profile = profile {
            profileManager.deleteProfile(profile)
        }
        dismiss()
    }
}
