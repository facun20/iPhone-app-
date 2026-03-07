import SwiftUI
import FamilyControls

struct ProfilesView: View {
    @EnvironmentObject var profileManager: ProfileManager
    @State private var showCreateProfile = false
    @State private var editingProfile: FocusProfile?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(profileManager.profiles) { profile in
                        ProfileListCard(profile: profile) {
                            editingProfile = profile
                        }
                    }

                    // Add profile button
                    Button(action: { showCreateProfile = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                            Text("Create New Profile")
                                .font(.headline)
                        }
                        .foregroundColor(.purple)
                        .frame(maxWidth: .infinity)
                        .padding(20)
                        .background(Color.purple.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.purple.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
                        )
                    }
                }
                .padding()
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Profiles")
            .sheet(isPresented: $showCreateProfile) {
                EditProfileView(profile: nil)
            }
            .sheet(item: $editingProfile) { profile in
                EditProfileView(profile: profile)
            }
        }
    }
}

struct ProfileListCard: View {
    let profile: FocusProfile
    let onEdit: () -> Void

    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: 16) {
                Image(systemName: profile.icon)
                    .font(.title)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50)

                VStack(alignment: .leading, spacing: 6) {
                    Text(profile.name)
                        .font(.headline)
                        .foregroundColor(.white)

                    HStack(spacing: 12) {
                        Label(profile.challenge.type.displayName, systemImage: profile.challenge.type.icon)
                            .font(.caption)
                            .foregroundColor(.gray)

                        Label("\(profile.totalSessionsCompleted) sessions", systemImage: "checkmark.circle")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding(16)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}
