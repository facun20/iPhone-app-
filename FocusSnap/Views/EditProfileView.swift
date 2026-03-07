import SwiftUI
import FamilyControls

struct EditProfileView: View {
    @EnvironmentObject var profileManager: ProfileManager
    @Environment(\.dismiss) var dismiss

    let profile: FocusProfile?

    @State private var name: String = ""
    @State private var selectedIcon: String = "moon.fill"
    @State private var selectedChallenge: ChallengeType = .outdoor
    @State private var activitySelection = FamilyActivitySelection()
    @State private var showAppPicker = false
    @State private var usesPerAppRules = false
    @State private var unlockRules: [AppUnlockRule] = []
    @State private var showAddRule = false

    private var isEditing: Bool { profile != nil }

    private let iconOptions = [
        "moon.fill", "sunrise.fill", "sun.max.fill", "moon.stars.fill",
        "brain.head.profile", "book.fill", "dumbbell.fill", "leaf.fill",
        "figure.walk", "graduationcap.fill", "heart.fill", "star.fill"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile Name") {
                    TextField("e.g. Morning Routine", text: $name)
                }

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

                // Mode toggle
                Section("Unlock Mode") {
                    Toggle(isOn: $usesPerAppRules) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Per-App Rules")
                                .font(.subheadline.bold())
                            Text("Set different unlock conditions for different apps")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .tint(.purple)
                }

                if usesPerAppRules {
                    // Per-app rules
                    Section("Unlock Rules") {
                        ForEach(unlockRules) { rule in
                            UnlockRuleRow(rule: rule)
                        }
                        .onDelete(perform: deleteRule)

                        Button(action: { showAddRule = true }) {
                            Label("Add Rule", systemImage: "plus.circle.fill")
                                .foregroundColor(.purple)
                        }
                    }
                } else {
                    // Simple mode
                    Section("Unlock Challenge") {
                        ForEach(ChallengeType.allCases) { type in
                            Button(action: { selectedChallenge = type }) {
                                HStack(spacing: 12) {
                                    Image(systemName: type.icon)
                                        .foregroundColor(.purple)
                                        .frame(width: 28)
                                    VStack(alignment: .leading) {
                                        Text(type.displayName).font(.subheadline.bold()).foregroundColor(.primary)
                                        Text(type.description).font(.caption).foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    if selectedChallenge == type {
                                        Image(systemName: "checkmark.circle.fill").foregroundColor(.purple)
                                    }
                                }
                            }
                        }
                    }

                    Section("Apps to Block") {
                        Button(action: { showAppPicker = true }) {
                            HStack {
                                Image(systemName: "app.badge").foregroundColor(.purple)
                                Text("Select Apps & Categories")
                                Spacer()
                                let count = activitySelection.applicationTokens.count + activitySelection.categoryTokens.count
                                if count > 0 {
                                    Text("\(count) selected").foregroundColor(.gray)
                                }
                                Image(systemName: "chevron.right").foregroundColor(.gray)
                            }
                        }
                    }
                }

                if isEditing {
                    Section {
                        Button(role: .destructive, action: deleteProfile) {
                            HStack { Spacer(); Text("Delete Profile"); Spacer() }
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
            .sheet(isPresented: $showAddRule) {
                AddUnlockRuleView(onSave: { rule in
                    unlockRules.append(rule)
                })
            }
            .onAppear { loadExisting() }
        }
    }

    private func loadExisting() {
        guard let profile = profile else { return }
        name = profile.name
        selectedIcon = profile.icon
        selectedChallenge = profile.challenge.type
        activitySelection = profile.activitySelection
        usesPerAppRules = profile.usesPerAppRules
        unlockRules = profile.unlockRules
    }

    private func deleteRule(at offsets: IndexSet) {
        unlockRules.remove(atOffsets: offsets)
    }

    private func saveProfile() {
        let challenge = Challenge(type: selectedChallenge)

        if var existing = profile {
            existing.name = name
            existing.icon = selectedIcon
            existing.challenge = challenge
            existing.activitySelection = activitySelection
            existing.usesPerAppRules = usesPerAppRules
            existing.unlockRules = unlockRules
            profileManager.updateProfile(existing)
        } else {
            let newProfile = FocusProfile(
                name: name,
                icon: selectedIcon,
                challenge: challenge,
                unlockRules: unlockRules,
                activitySelection: activitySelection,
                usesPerAppRules: usesPerAppRules
            )
            profileManager.addProfile(newProfile)
        }
        dismiss()
    }

    private func deleteProfile() {
        if let profile = profile { profileManager.deleteProfile(profile) }
        dismiss()
    }
}

// MARK: - Rule Row

struct UnlockRuleRow: View {
    let rule: AppUnlockRule

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: rule.condition.type.icon)
                .foregroundColor(.purple)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(rule.name)
                    .font(.subheadline.bold())
                Text(rule.condition.displaySummary)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            let appCount = rule.applicationTokens.count + rule.categoryTokens.count
            if appCount > 0 {
                Text("\(appCount) apps")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}

// MARK: - Add Unlock Rule Sheet

struct AddUnlockRuleView: View {
    let onSave: (AppUnlockRule) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var conditionType: UnlockConditionType = .steps
    @State private var targetSteps = 5000
    @State private var targetDistanceMiles = 1.0
    @State private var targetWorkoutMinutes = 30
    @State private var unlockHour = 9
    @State private var unlockMinute = 0
    @State private var challengeType: ChallengeType = .outdoor
    @State private var appSelection = FamilyActivitySelection()
    @State private var showAppPicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Rule Name") {
                    TextField("e.g. Social Media, Morning Apps", text: $name)
                }

                Section("Unlock Condition") {
                    ForEach(UnlockConditionType.allCases) { type in
                        Button(action: { conditionType = type }) {
                            HStack(spacing: 12) {
                                Image(systemName: type.icon)
                                    .foregroundColor(.purple)
                                    .frame(width: 28)
                                VStack(alignment: .leading) {
                                    Text(type.displayName).font(.subheadline.bold()).foregroundColor(.primary)
                                    Text(type.description).font(.caption).foregroundColor(.secondary)
                                }
                                Spacer()
                                if conditionType == type {
                                    Image(systemName: "checkmark.circle.fill").foregroundColor(.purple)
                                }
                            }
                        }
                    }
                }

                // Condition-specific settings
                Section("Settings") {
                    switch conditionType {
                    case .steps:
                        Stepper("Target: \(targetSteps.formatted()) steps", value: $targetSteps, in: 1000...50000, step: 1000)
                    case .distance:
                        Stepper("Target: \(String(format: "%.1f", targetDistanceMiles)) miles", value: $targetDistanceMiles, in: 0.5...26.2, step: 0.5)
                    case .workout:
                        Stepper("Target: \(targetWorkoutMinutes) min", value: $targetWorkoutMinutes, in: 5...120, step: 5)
                    case .timeBased:
                        Picker("Hour", selection: $unlockHour) {
                            ForEach(0..<24, id: \.self) { h in
                                Text("\(h > 12 ? h - 12 : (h == 0 ? 12 : h)) \(h >= 12 ? "PM" : "AM")").tag(h)
                            }
                        }
                        Picker("Minute", selection: $unlockMinute) {
                            ForEach([0, 15, 30, 45], id: \.self) { m in
                                Text(String(format: ":%02d", m)).tag(m)
                            }
                        }
                    case .photo:
                        ForEach(ChallengeType.allCases) { type in
                            Button(action: { challengeType = type }) {
                                HStack {
                                    Image(systemName: type.icon).foregroundColor(.purple).frame(width: 28)
                                    Text(type.displayName).foregroundColor(.primary)
                                    Spacer()
                                    if challengeType == type {
                                        Image(systemName: "checkmark.circle.fill").foregroundColor(.purple)
                                    }
                                }
                            }
                        }
                    }
                }

                Section("Apps for This Rule") {
                    Button(action: { showAppPicker = true }) {
                        HStack {
                            Image(systemName: "app.badge").foregroundColor(.purple)
                            Text("Select Apps")
                            Spacer()
                            let count = appSelection.applicationTokens.count + appSelection.categoryTokens.count
                            if count > 0 {
                                Text("\(count) selected").foregroundColor(.gray)
                            }
                            Image(systemName: "chevron.right").foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationTitle("Add Rule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .disabled(name.isEmpty)
                }
            }
            .familyActivityPicker(isPresented: $showAppPicker, selection: $appSelection)
        }
    }

    private func save() {
        var condition = UnlockCondition(type: conditionType)

        switch conditionType {
        case .steps:
            condition.targetSteps = targetSteps
        case .distance:
            condition.targetDistanceMeters = targetDistanceMiles * 1609.34
        case .workout:
            condition.targetWorkoutMinutes = targetWorkoutMinutes
        case .timeBased:
            condition.unlockAfterHour = unlockHour
            condition.unlockAfterMinute = unlockMinute
        case .photo:
            condition.challengeType = challengeType
        }

        let rule = AppUnlockRule(
            name: name,
            condition: condition,
            applicationTokens: appSelection.applicationTokens,
            categoryTokens: appSelection.categoryTokens
        )

        onSave(rule)
        dismiss()
    }
}
