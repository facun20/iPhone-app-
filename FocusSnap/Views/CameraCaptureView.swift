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
            Color.black.ignoresSafeArea()

            if cameraService.capturedImage == nil {
                CameraPreviewView(session: cameraService.session)
                    .ignoresSafeArea()
            } else if let image = cameraService.capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }

            VStack {
                topBar
                Spacer()
                challengePrompt
                verificationStatus
                bottomControls
            }
        }
        .onAppear { cameraService.startSession() }
        .onDisappear { cameraService.stopSession() }
    }

    private var topBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.title3)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            Spacer()
            Text("EarnIt")
                .font(.headline)
                .foregroundColor(.white)
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

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

    @ViewBuilder
    private var verificationStatus: some View {
        switch verificationState {
        case .ready, .captured:
            EmptyView()
        case .verifying:
            HStack(spacing: 8) {
                ProgressView().tint(.white)
                Text("Verifying your photo...")
                    .foregroundColor(.white)
            }
            .padding(12)
            .background(Color.black.opacity(0.7))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.bottom, 8)
        case .verified(let label):
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                Text("Verified: \(label)").foregroundColor(.green)
            }
            .padding(12)
            .background(Color.black.opacity(0.7))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.bottom, 8)
        case .rejected(let reason):
            VStack(spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.red)
                    Text("Not quite right").foregroundColor(.red).font(.headline)
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

    private var bottomControls: some View {
        HStack(spacing: 40) {
            if cameraService.capturedImage != nil {
                Button(action: retake) {
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise").font(.title2)
                        Text("Retake").font(.caption)
                    }
                    .foregroundColor(.white)
                }

                Button(action: verifyPhoto) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                }
                .disabled(verificationState == .verifying)
            } else {
                Button(action: capturePhoto) {
                    ZStack {
                        Circle().stroke(Color.white, lineWidth: 4).frame(width: 72, height: 72)
                        Circle().fill(Color.white).frame(width: 60, height: 60)
                    }
                }
            }
        }
        .padding(.bottom, 40)
    }

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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { onVerified() }
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
