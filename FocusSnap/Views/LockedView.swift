import SwiftUI

/// Shown when a session is active — displays per-app unlock progress
struct LockedView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var profileManager: ProfileManager
    @EnvironmentObject var healthService: HealthKitService
    @State private var showCamera = false
    @State private var showEmergencyConfirm = false
    @State private var verificationMessage: String?
    @State private var activeCameraRule: AppUnlockRule?
    @State private var pulseAnimation = false

    private var activeProfile: FocusProfile? {
        sessionManager.activeProfile
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection

            ScrollView {
                VStack(spacing: 20) {
                    if let profile = activeProfile, profile.usesPerAppRules {
                        perAppRulesSection(profile: profile)
                    } else {
                        simpleModeSection
                    }
                }
                .padding()
            }

            bottomActions
        }
        .background(
            LinearGradient(
                colors: [Color.black, Color(red: 0.1, green: 0.0, blue: 0.2)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .onAppear {
            healthService.startMonitoring()
            pulseAnimation = true
        }
        .onDisappear {
            healthService.stopMonitoring()
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraCaptureView(
                challenge: activeCameraRule?.condition.challengeType.flatMap { Challenge(type: $0) }
                    ?? activeProfile?.challenge
                    ?? Challenge(type: .outdoor),
                onVerified: {
                    showCamera = false
                    if let rule = activeCameraRule {
                        sessionManager.unlockRule(rule)
                        activeCameraRule = nil
                    } else {
                        sessionManager.endSession()
                    }
                },
                onRejected: { reason in
                    verificationMessage = reason
                }
            )
        }
        .alert("Emergency Unlock", isPresented: $showEmergencyConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Unlock Everything", role: .destructive) {
                performEmergencyUnlock()
            }
        } message: {
            let remaining = activeProfile?.emergencyUnlocksRemaining ?? 0
            Text("You have \(remaining) emergency unlocks remaining. This will unlock ALL apps.")
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 100, height: 100)
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulseAnimation)

                Image(systemName: "lock.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(
                        LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }

            Text("Session Active")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            if let session = sessionManager.activeSession {
                Text("Started \(session.startedAt, style: .relative) ago")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            if let profile = activeProfile {
                Text(profile.name)
                    .font(.subheadline.bold())
                    .foregroundColor(.purple)
            }
        }
        .padding(.vertical, 24)
    }

    // MARK: - Per-App Rules

    private func perAppRulesSection(profile: FocusProfile) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Unlock Progress")
                .font(.headline)
                .foregroundColor(.white)

            ForEach(profile.unlockRules) { rule in
                let isUnlocked = sessionManager.unlockedRuleIds.contains(rule.id)
                let progress = getProgress(for: rule)

                UnlockRuleCard(
                    rule: rule,
                    progress: progress,
                    isUnlocked: isUnlocked,
                    onAction: {
                        handleRuleAction(rule: rule, progress: progress)
                    }
                )
            }
        }
    }

    // MARK: - Simple Mode

    private var simpleModeSection: some View {
        VStack(spacing: 20) {
            if let profile = activeProfile {
                VStack(spacing: 12) {
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
                }

                Button(action: {
                    activeCameraRule = nil
                    showCamera = true
                }) {
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
                        LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }

            if let message = verificationMessage {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Bottom Actions

    private var bottomActions: some View {
        VStack(spacing: 12) {
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
        .padding(.bottom, 32)
    }

    // MARK: - Helpers

    private func getProgress(for rule: AppUnlockRule) -> ConditionProgress {
        var progress = healthService.evaluateCondition(rule.condition)
        progress = ConditionProgress(
            id: rule.id,
            ruleName: rule.name,
            condition: rule.condition,
            currentValue: progress.currentValue,
            targetValue: progress.targetValue,
            isComplete: progress.isComplete
        )
        return progress
    }

    private func handleRuleAction(rule: AppUnlockRule, progress: ConditionProgress) {
        switch rule.condition.type {
        case .photo:
            activeCameraRule = rule
            showCamera = true
        case .steps, .distance, .workout, .timeBased:
            if progress.isComplete {
                sessionManager.unlockRule(rule)
            }
        }
    }

    private func performEmergencyUnlock() {
        guard var profile = activeProfile else { return }
        if sessionManager.emergencyUnlock(profile: &profile) {
            profileManager.updateProfile(profile)
        }
    }
}

// MARK: - Unlock Rule Card

struct UnlockRuleCard: View {
    let rule: AppUnlockRule
    let progress: ConditionProgress
    let isUnlocked: Bool
    let onAction: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: rule.condition.type.icon)
                    .font(.title2)
                    .foregroundColor(isUnlocked ? .green : .purple)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(rule.name)
                            .font(.headline)
                            .foregroundColor(.white)

                        if isUnlocked {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                    }

                    Text(rule.condition.displaySummary)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                Spacer()

                if !isUnlocked {
                    if rule.condition.type == .photo {
                        Button(action: onAction) {
                            Image(systemName: "camera.fill")
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.purple)
                                .clipShape(Circle())
                        }
                    } else if progress.isComplete {
                        Button(action: onAction) {
                            Text("Claim")
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.green)
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            if !isUnlocked && rule.condition.type != .photo {
                VStack(spacing: 4) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: progress.isComplete ? [.green, .green] : [.purple, .blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * progress.progressFraction, height: 8)
                        }
                    }
                    .frame(height: 8)

                    HStack {
                        Text(progress.progressText)
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(Int(progress.progressFraction * 100))%")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isUnlocked ? Color.green.opacity(0.08) : Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isUnlocked ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}
