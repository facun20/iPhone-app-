import SwiftUI
import FamilyControls

struct HomeView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var profileManager: ProfileManager
    @State private var selectedProfile: FocusProfile?
    @State private var showProfilePicker = false
    @State private var showAppPicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Quick Start Button
                    startSessionSection

                    // Active profiles
                    profileCardsSection

                    // Recent sessions
                    recentSessionsSection
                }
                .padding()
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("")
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(greeting)
                        .font(.title2)
                        .foregroundColor(.gray)
                    Text("Ready to focus?")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                Spacer()

                // Streak badge
                VStack(spacing: 4) {
                    Text("\(sessionManager.currentStreak)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                    Text("streak")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .padding(12)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Start Session

    private var startSessionSection: some View {
        VStack(spacing: 12) {
            if let profile = selectedProfile ?? profileManager.profiles.first {
                Button(action: {
                    startSession(with: profile)
                }) {
                    HStack(spacing: 16) {
                        Image(systemName: "lock.fill")
                            .font(.title2)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Start Session")
                                .font(.title3.bold())
                            Text("\(profile.name) — \(profile.challenge.type.displayName)")
                                .font(.subheadline)
                                .opacity(0.8)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .padding(20)
                    .background(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .purple.opacity(0.4), radius: 16, y: 8)
                }

                Button(action: { showProfilePicker = true }) {
                    Text("Change profile")
                        .font(.subheadline)
                        .foregroundColor(.purple)
                }
            } else {
                Text("Create a profile to get started")
                    .foregroundColor(.gray)
            }
        }
        .sheet(isPresented: $showProfilePicker) {
            ProfilePickerSheet(selectedProfile: $selectedProfile)
        }
    }

    // MARK: - Profile Cards

    private var profileCardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Profiles")
                .font(.headline)
                .foregroundColor(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(profileManager.profiles) { profile in
                        ProfileCard(profile: profile) {
                            selectedProfile = profile
                        }
                    }
                }
            }
        }
    }

    // MARK: - Recent Sessions

    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Sessions")
                .font(.headline)
                .foregroundColor(.white)

            if sessionManager.sessionHistory.isEmpty {
                Text("No sessions yet. Start your first one!")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(sessionManager.sessionHistory.prefix(5)) { session in
                    SessionRow(session: session)
                }
            }
        }
    }

    // MARK: - Helpers

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Good night"
        }
    }

    private func startSession(with profile: FocusProfile) {
        guard !profile.activitySelection.applicationTokens.isEmpty ||
              !profile.activitySelection.categoryTokens.isEmpty else {
            showAppPicker = true
            return
        }
        sessionManager.startSession(profile: profile)
    }
}

// MARK: - Profile Card

struct ProfileCard: View {
    let profile: FocusProfile
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Image(systemName: profile.icon)
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text(profile.name)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)

                HStack(spacing: 4) {
                    Image(systemName: profile.challenge.type.icon)
                        .font(.caption2)
                    Text(profile.challenge.type.displayName)
                        .font(.caption2)
                }
                .foregroundColor(.gray)
            }
            .padding(16)
            .frame(width: 130, height: 130)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - Session Row

struct SessionRow: View {
    let session: FocusSession

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: session.challengeType.icon)
                .font(.title3)
                .foregroundColor(.purple)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.profileName)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                Text(session.startedAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(session.durationFormatted)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                if session.wasEmergencyUnlock {
                    Text("Emergency")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Profile Picker Sheet

struct ProfilePickerSheet: View {
    @EnvironmentObject var profileManager: ProfileManager
    @Binding var selectedProfile: FocusProfile?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List(profileManager.profiles) { profile in
                Button(action: {
                    selectedProfile = profile
                    dismiss()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: profile.icon)
                            .font(.title3)
                            .foregroundColor(.purple)

                        VStack(alignment: .leading) {
                            Text(profile.name)
                                .font(.headline)
                            Text(profile.challenge.type.displayName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if selectedProfile?.id == profile.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.purple)
                        }
                    }
                }
            }
            .navigationTitle("Choose Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
