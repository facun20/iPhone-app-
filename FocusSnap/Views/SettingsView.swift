import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthorizationManager
    @EnvironmentObject var healthService: HealthKitService

    var body: some View {
        NavigationStack {
            List {
                Section("About") {
                    HStack {
                        Image(systemName: "lock.open.rotation")
                            .foregroundColor(.purple)
                        VStack(alignment: .leading) {
                            Text("EarnIt")
                                .font(.headline)
                            Text("by infinit3 Development")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)

                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0").foregroundColor(.secondary)
                    }
                }

                Section("Permissions") {
                    HStack {
                        Text("Screen Time")
                        Spacer()
                        Text(authManager.isAuthorized ? "Authorized" : "Not Authorized")
                            .foregroundColor(authManager.isAuthorized ? .green : .red)
                    }

                    HStack {
                        Text("HealthKit")
                        Spacer()
                        Text(healthService.isAuthorized ? "Authorized" : "Not Authorized")
                            .foregroundColor(healthService.isAuthorized ? .green : .red)
                    }

                    if !authManager.isAuthorized {
                        Button("Request Screen Time Access") {
                            authManager.requestAuthorization()
                        }
                    }

                    if !healthService.isAuthorized {
                        Button("Request Health Access") {
                            Task { await healthService.requestAuthorization() }
                        }
                    }
                }

                Section("How It Works") {
                    VStack(alignment: .leading, spacing: 12) {
                        InstructionRow(number: 1, text: "Create a profile and select apps to block")
                        InstructionRow(number: 2, text: "Set unlock conditions per app — steps, photos, workouts, or time")
                        InstructionRow(number: 3, text: "Tap \"Start Session\" to instantly lock those apps")
                        InstructionRow(number: 4, text: "Earn each app back by meeting its condition")
                    }
                    .padding(.vertical, 8)
                }

                Section("Privacy") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your data stays on your device")
                            .font(.subheadline.bold())
                        Text("EarnIt processes all images on-device using Apple's Vision framework. Health data is read from HealthKit and never leaves your device. No tracking, no analytics, no ads.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section("Support") {
                    Link(destination: URL(string: "mailto:support@infinit3dev.com")!) {
                        Label("Contact Support", systemImage: "envelope.fill")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct InstructionRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption.bold())
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(
                    LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .clipShape(Circle())
            Text(text).font(.subheadline)
        }
    }
}
