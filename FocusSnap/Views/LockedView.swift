import SwiftUI

/// Shown when a session is active — the user must complete the photo challenge to unlock
struct LockedView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var profileManager: ProfileManager
    @State private var showCamera = false
    @State private var showEmergencyConfirm = false
    @State private var verificationMessage: String?
    @State private var isVerifying = false
    @State private var pulseAnimation = false

    private var activeProfile: FocusProfile? {
        guard let session = sessionManager.activeSession else { return nil }
        return profileManager.profile(for: session.profileId)
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Lock animation
            lockIcon

            // Session info
            sessionInfo

            Spacer()

            // Challenge description
            challengeSection

            // Verification feedback
            if let message = verificationMessage {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 12)
            }

            Spacer()

            // Action buttons
            actionButtons
        }
        .background(
            LinearGradient(
                colors: [Color.black, Color(red: 0.1, green: 0.0, blue: 0.2)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .fullScreenCover(isPresented: $showCamera) {
            CameraCaptureView(
                challenge: activeProfile?.challenge ?? Challenge(type: .outdoor),
                onVerified: {
                    showCamera = false
                    sessionManager.endSession()
                },
                onRejected: { reason in
                    verificationMessage = reason
                }
            )
        }
        .alert("Emergency Unlock", isPresented: $showEmergencyConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Unlock", role: .destructive) {
                performEmergencyUnlock()
            }
        } message: {
            let remaining = activeProfile?.emergencyUnlocksRemaining ?? 0
            Text("You have \(remaining) emergency unlocks remaining. Use one now?")
        }
    }

    // MARK: - Lock Icon

    private var lockIcon: some View {
        ZStack {
            Circle()
                .fill(Color.purple.opacity(0.15))
                .frame(width: 160, height: 160)
                .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                .animation(
                    .easeInOut(duration: 2).repeatForever(autoreverses: true),
                    value: pulseAnimation
                )

            Circle()
                .fill(Color.purple.opacity(0.1))
                .frame(width: 120, height: 120)

            Image(systemName: "lock.fill")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .onAppear { pulseAnimation = true }
    }

    // MARK: - Session Info

    private var sessionInfo: some View {
        VStack(spacing: 8) {
            Text("Session Active")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            if let session = sessionManager.activeSession {
                Text("Started \(session.startedAt, style: .relative) ago")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            if let profile = activeProfile {
                Text(profile.name)
                    .font(.headline)
                    .foregroundColor(.purple)
                    .padding(.top, 4)
            }
        }
        .padding(.top, 24)
    }

    // MARK: - Challenge Section

    private var challengeSection: some View {
        VStack(spacing: 16) {
            if let profile = activeProfile {
                HStack(spacing: 8) {
                    Image(systemName: profile.challenge.type.icon)
                        .foregroundColor(.purple)
                    Text("Challenge to Unlock")
                        .font(.headline)
                        .foregroundColor(.white)
                }

                Text(profile.challenge.displayDescription)
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 16) {
            // Main unlock button
            Button(action: { showCamera = true }) {
                HStack(spacing: 12) {
                    Image(systemName: "camera.fill")
                        .font(.title3)
                    Text("Take Photo to Unlock")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            // Emergency unlock
            Button(action: { showEmergencyConfirm = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                    Text("Emergency Unlock")
                        .font(.subheadline)
                }
                .foregroundColor(.orange.opacity(0.7))
            }

            let remaining = activeProfile?.emergencyUnlocksRemaining ?? 0
            Text("\(remaining) emergency unlocks remaining")
                .font(.caption2)
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }

    // MARK: - Emergency Unlock

    private func performEmergencyUnlock() {
        guard var profile = activeProfile else { return }
        if sessionManager.emergencyUnlock(profile: &profile) {
            profileManager.updateProfile(profile)
        }
    }
}
