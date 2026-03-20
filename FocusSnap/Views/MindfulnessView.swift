import SwiftUI

/// Full-screen timer for meditation, prayer, or breathing sessions
struct MindfulnessView: View {
    let condition: UnlockCondition
    let onComplete: () -> Void
    @Environment(\.dismiss) var dismiss
    @StateObject private var service = MindfulnessService()

    private var label: String {
        condition.mindfulnessLabel ?? "Meditation"
    }

    private var targetMinutes: Int {
        condition.targetMindfulnessMinutes ?? 5
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            Image(systemName: iconName)
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .symbolEffect(.pulse, isActive: service.isActive)

            // Title
            Text(label)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("\(targetMinutes) minute\(targetMinutes == 1 ? "" : "s")")
                .font(.subheadline)
                .foregroundColor(.gray)

            // Timer ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 8)
                    .frame(width: 200, height: 200)

                Circle()
                    .trim(from: 0, to: service.progress)
                    .stroke(
                        LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: service.progress)

                VStack(spacing: 4) {
                    if service.isComplete {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.green)
                    } else if service.isActive {
                        Text(service.timeRemainingFormatted)
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("remaining")
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else {
                        Text(String(format: "%d:00", targetMinutes))
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("tap to begin")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }

            // Motivational text
            if service.isActive {
                Text(activeMessage)
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()

            // Action buttons
            if service.isComplete {
                Button(action: {
                    onComplete()
                    dismiss()
                }) {
                    Text("Done")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            } else if service.isActive {
                Button(action: { service.stop() }) {
                    Text("Cancel")
                        .font(.subheadline)
                        .foregroundColor(.orange.opacity(0.7))
                }
            } else {
                Button(action: { service.start(targetMinutes: targetMinutes) }) {
                    HStack(spacing: 12) {
                        Image(systemName: "play.fill")
                        Text("Begin \(label)")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(colors: gradientColors, startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }

            Button("Close") { dismiss() }
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.bottom, 16)
        }
        .padding()
        .background(Color.black.ignoresSafeArea())
    }

    // MARK: - Helpers

    private var iconName: String {
        switch label.lowercased() {
        case "prayer": return "hands.and.sparkles.fill"
        case "breathing": return "wind"
        default: return "brain.head.profile.fill"
        }
    }

    private var gradientColors: [Color] {
        switch label.lowercased() {
        case "prayer": return [.yellow, .orange]
        case "breathing": return [.cyan, .blue]
        default: return [.purple, .indigo]
        }
    }

    private var activeMessage: String {
        switch label.lowercased() {
        case "prayer":
            return "Take this time to connect with your faith. Stay present."
        case "breathing":
            return "Breathe in slowly... hold... breathe out..."
        default:
            return "Be still. Let your thoughts pass without judgment."
        }
    }
}
