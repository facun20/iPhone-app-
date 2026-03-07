import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthorizationManager

    var body: some View {
        NavigationStack {
            List {
                // About
                Section("About") {
                    HStack {
                        Image(systemName: "camera.viewfinder")
                            .foregroundColor(.purple)
                        VStack(alignment: .leading) {
                            Text("FocusSnap")
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
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }

                // Screen Time
                Section("Screen Time") {
                    HStack {
                        Text("Authorization Status")
                        Spacer()
                        Text(authManager.isAuthorized ? "Authorized" : "Not Authorized")
                            .foregroundColor(authManager.isAuthorized ? .green : .red)
                    }

                    if !authManager.isAuthorized {
                        Button("Request Authorization") {
                            authManager.requestAuthorization()
                        }
                    }
                }

                // How It Works
                Section("How It Works") {
                    VStack(alignment: .leading, spacing: 12) {
                        InstructionRow(number: 1, text: "Create a profile and select apps to block")
                        InstructionRow(number: 2, text: "Choose an unlock challenge (outdoor photo, book, gym, etc.)")
                        InstructionRow(number: 3, text: "Tap \"Start Session\" to instantly lock those apps")
                        InstructionRow(number: 4, text: "Take a real photo matching your challenge to unlock")
                    }
                    .padding(.vertical, 8)
                }

                // Privacy
                Section("Privacy") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your data stays on your device")
                            .font(.subheadline.bold())
                        Text("FocusSnap processes all images on-device using Apple's Vision framework. No photos are uploaded to any server. No tracking, no analytics, no ads.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                // Support
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
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())

            Text(text)
                .font(.subheadline)
        }
    }
}
