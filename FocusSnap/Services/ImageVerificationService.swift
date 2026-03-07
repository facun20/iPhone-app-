import Foundation
import UIKit
import Vision
import CoreML

/// Verifies that a captured photo matches the required challenge using on-device Vision classification
class ImageVerificationService {

    enum VerificationResult {
        case verified(confidence: Float, matchedLabel: String)
        case rejected(reason: String)
        case error(String)
    }

    /// Minimum confidence threshold to accept a classification match
    private let confidenceThreshold: Float = 0.15

    /// Verify that an image matches the challenge requirements
    func verify(image: UIImage, challenge: Challenge) async -> VerificationResult {
        // Step 1: Validate this is a fresh camera capture (not a screenshot)
        if let rejection = validateImageMetadata(image) {
            return .rejected(reason: rejection)
        }

        // Step 2: Run Vision classification
        guard let cgImage = image.cgImage else {
            return .error("Could not process image")
        }

        do {
            let results = try await classifyImage(cgImage)
            return matchResults(results, against: challenge)
        } catch {
            return .error("Classification failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Screenshot / Upload Prevention

    /// Checks image properties to detect screenshots or pre-existing photos
    private func validateImageMetadata(_ image: UIImage) -> String? {
        // Screenshots on iPhone are exactly screen-sized with scale factor
        let screenSize = UIScreen.main.bounds.size
        let screenScale = UIScreen.main.scale
        let screenshotWidth = screenSize.width * screenScale
        let screenshotHeight = screenSize.height * screenScale

        let imageWidth = CGFloat(image.cgImage?.width ?? 0)
        let imageHeight = CGFloat(image.cgImage?.height ?? 0)

        // Check if dimensions exactly match a screenshot
        if (imageWidth == screenshotWidth && imageHeight == screenshotHeight) ||
           (imageWidth == screenshotHeight && imageHeight == screenshotWidth) {
            return "This looks like a screenshot. Please take a fresh photo with your camera."
        }

        return nil
    }

    // MARK: - Vision Classification

    private func classifyImage(_ cgImage: CGImage) async throws -> [VNClassificationObservation] {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNClassifyImageRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let results = request.results as? [VNClassificationObservation] ?? []
                continuation.resume(returning: results)
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: - Match Results Against Challenge

    private func matchResults(
        _ results: [VNClassificationObservation],
        against challenge: Challenge
    ) -> VerificationResult {
        let keywords = challenge.keywords.map { $0.lowercased() }

        guard !keywords.isEmpty else {
            return .rejected(reason: "No keywords configured for this challenge")
        }

        // Find the best matching classification
        var bestMatch: (label: String, confidence: Float)?

        for observation in results {
            let label = observation.identifier.lowercased()
            let confidence = observation.confidence

            for keyword in keywords {
                if label.contains(keyword) || keyword.contains(label) {
                    if bestMatch == nil || confidence > bestMatch!.confidence {
                        bestMatch = (label: observation.identifier, confidence: confidence)
                    }
                }
            }
        }

        if let match = bestMatch, match.confidence >= confidenceThreshold {
            return .verified(
                confidence: match.confidence,
                matchedLabel: match.label
            )
        }

        // Build a helpful rejection message
        let topLabels = results.prefix(5).map { "\($0.identifier) (\(Int($0.confidence * 100))%)" }
        let detected = topLabels.joined(separator: ", ")

        return .rejected(
            reason: "Couldn't verify your photo matches the challenge. Detected: \(detected). Try taking a clearer photo."
        )
    }
}
