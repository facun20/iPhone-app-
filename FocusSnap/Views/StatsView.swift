import SwiftUI

struct StatsView: View {
    @EnvironmentObject var sessionManager: SessionManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Stats cards
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        StatCard(
                            title: "Total Sessions",
                            value: "\(sessionManager.totalSessions)",
                            icon: "checkmark.circle.fill",
                            color: .purple
                        )

                        StatCard(
                            title: "Focus Time",
                            value: formatTotalTime(sessionManager.totalFocusTime),
                            icon: "clock.fill",
                            color: .blue
                        )

                        StatCard(
                            title: "Current Streak",
                            value: "\(sessionManager.currentStreak)",
                            icon: "flame.fill",
                            color: .orange
                        )

                        StatCard(
                            title: "Avg Session",
                            value: averageSessionTime,
                            icon: "chart.line.uptrend.xyaxis",
                            color: .green
                        )
                    }

                    // Session history
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Session History")
                            .font(.headline)
                            .foregroundColor(.white)

                        if sessionManager.sessionHistory.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "chart.bar")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                Text("Complete your first session to see stats")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            ForEach(sessionManager.sessionHistory) { session in
                                SessionRow(session: session)
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Stats")
        }
    }

    private func formatTotalTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    private var averageSessionTime: String {
        guard sessionManager.totalSessions > 0 else { return "0m" }
        let avg = sessionManager.totalFocusTime / Double(sessionManager.totalSessions)
        return formatTotalTime(avg)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
