import SwiftUI
import AVFoundation

/// Full-screen camera view for taking the unlock photo
struct CameraCaptureView: View {
    let challenge: Challenge
    let onVerified: () -> Void
    let onRejected: (String) -> Void

    @StateObject private var cameraService = CameraService()
    @State private var verificationState: VerificationState = .ready
    @Environment(\.dismiss) var dismiss

    private let verificationService = ImageVerificationService()

    enum VerificationState: Equatable {
        case ready
        case captured
        case verifying
        case verified(String)
        case rejected(String)
    }

    var body: some View {
        ZStack {
            // Camera preview
            Color.black.ignoresSafeArea()

            if cameraService.capturedImage == nil {
                CameraPreviewView(session: cameraService.session)
                    .ignoresSafeArea()
            } else if let image = cameraService.capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }

            // Overlay UI
            VStack {
                // Top bar
                topBar

                Spacer()

                // Challenge prompt
                challengePrompt

                // Verification status
                verificationStatus

                // Bottom controls
                bottomControls
            }
        }
        .onAppear {
            cameraService.startSession()
        }
        .onDisappear {
            cameraService.stopSession()
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.title3)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }

            Spacer()

            Text("FocusSnap")
                .font(.headline)
                .foregroundColor(.white)

            Spacer()

            // Placeholder for symmetry
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Challenge Prompt

    private var challengePrompt: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: challenge.type.icon)
                Text(challenge.type.displayName)
                    .font(.headline)
            }
            .foregroundColor(.white)

            Text(challenge.displayDescription)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(16)
        .background(Color.black.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }

    // MARK: - Verification Status

    @ViewBuilder
    private var verificationStatus: some View {
        switch verificationState {
        case .ready:
            EmptyView()
        case .captured:
            EmptyView()
        case .verifying:
            HStack(spacing: 8) {
                ProgressView()
                    .tint(.white)
                Text("Verifying your photo...")
                    .foregroundColor(.white)
            }
            .padding(12)
            .background(Color.black.opacity(0.7))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.bottom, 8)
        case .verified(let label):
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Verified: \(label)")
                    .foregroundColor(.green)
            }
            .padding(12)
            .background(Color.black.opacity(0.7))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.bottom, 8)
        case .rejected(let reason):
            VStack(spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                    Text("Not quite right")
                        .foregroundColor(.red)
                        .font(.headline)
                }
                Text(reason)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(12)
            .background(Color.black.opacity(0.7))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        HStack(spacing: 40) {
            if cameraService.capturedImage != nil {
                // Retake button
                Button(action: retake) {
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title2)
                        Text("Retake")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                }

                // Verify button
                Button(action: verifyPhoto) {
                    VStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
                .disabled(verificationState == .verifying)
            } else {
                // Capture button
                Button(action: capturePhoto) {
                    ZStack {
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .frame(width: 72, height: 72)
                        Circle()
                            .fill(Color.white)
                            .frame(width: 60, height: 60)
                    }
                }
            }
        }
        .padding(.bottom, 40)
    }

    // MARK: - Actions

    private func capturePhoto() {
        cameraService.capturePhoto()
        verificationState = .captured
    }

    private func retake() {
        cameraService.capturedImage = nil
        verificationState = .ready
    }

    private func verifyPhoto() {
        guard let image = cameraService.capturedImage else { return }
        verificationState = .verifying

        Task {
            let result = await verificationService.verify(image: image, challenge: challenge)

            await MainActor.run {
                switch result {
                case .verified(_, let label):
                    verificationState = .verified(label)
                    // Small delay for the user to see the success
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        onVerified()
                    }
                case .rejected(let reason):
                    verificationState = .rejected(reason)
                    onRejected(reason)
                case .error(let error):
                    verificationState = .rejected(error)
                    onRejected(error)
                }
            }
        }
    }
}
