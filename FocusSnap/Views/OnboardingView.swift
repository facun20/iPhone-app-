import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var authManager: AuthorizationManager

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Logo
            VStack(spacing: 16) {
                Image(systemName: "lock.open.rotation")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("EarnIt")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("by infinit3 Development")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            // Feature list
            VStack(alignment: .leading, spacing: 20) {
                FeatureRow(
                    icon: "lock.fill",
                    title: "Lock Any App",
                    description: "Block distracting apps until you earn them back"
                )
                FeatureRow(
                    icon: "figure.walk",
                    title: "Set Your Terms",
                    description: "Steps, photos, workouts, or time — you choose per app"
                )
                FeatureRow(
                    icon: "chart.bar.fill",
                    title: "Build Habits",
                    description: "Track streaks and see your real-world progress"
                )
            }
            .padding(.horizontal, 24)

            Spacer()

            // Auth button
            VStack(spacing: 12) {
                Button(action: {
                    authManager.requestAuthorization()
                }) {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                if let error = authManager.authorizationError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                Text("EarnIt needs Screen Time access to manage app locks")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color.black.ignoresSafeArea())
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
}
