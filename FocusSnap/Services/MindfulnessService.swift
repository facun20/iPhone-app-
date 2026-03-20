import Foundation
import HealthKit

/// Manages in-app mindfulness timer sessions (meditation, prayer, breathing)
/// and writes completed sessions to HealthKit as mindful minutes
@MainActor
class MindfulnessService: ObservableObject {
    @Published var isActive = false
    @Published var elapsedSeconds: Int = 0
    @Published var targetSeconds: Int = 300  // 5 min default
    @Published var isComplete = false

    private var timer: Timer?
    private let healthStore = HKHealthStore()

    var elapsedMinutes: Double {
        Double(elapsedSeconds) / 60.0
    }

    var targetMinutes: Double {
        Double(targetSeconds) / 60.0
    }

    var progress: Double {
        guard targetSeconds > 0 else { return 0 }
        return min(Double(elapsedSeconds) / Double(targetSeconds), 1.0)
    }

    var timeRemainingFormatted: String {
        let remaining = max(targetSeconds - elapsedSeconds, 0)
        let mins = remaining / 60
        let secs = remaining % 60
        return String(format: "%d:%02d", mins, secs)
    }

    var elapsedFormatted: String {
        let mins = elapsedSeconds / 60
        let secs = elapsedSeconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    // MARK: - Timer Control

    func start(targetMinutes: Int) {
        self.targetSeconds = targetMinutes * 60
        self.elapsedSeconds = 0
        self.isComplete = false
        self.isActive = true

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.elapsedSeconds += 1
                if self.elapsedSeconds >= self.targetSeconds {
                    self.complete()
                }
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isActive = false
    }

    func reset() {
        stop()
        elapsedSeconds = 0
        isComplete = false
    }

    private func complete() {
        timer?.invalidate()
        timer = nil
        isActive = false
        isComplete = true

        // Write session to HealthKit so it counts toward mindful minutes
        saveMindfulSession()
    }

    // MARK: - HealthKit Integration

    private func saveMindfulSession() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        guard let mindfulType = HKCategoryType.categoryType(forIdentifier: .mindfulSession) else { return }

        let now = Date()
        let start = now.addingTimeInterval(-Double(elapsedSeconds))

        let sample = HKCategorySample(
            type: mindfulType,
            value: HKCategoryValue.notApplicable.rawValue,
            start: start,
            end: now
        )

        // Request write permission if needed, then save
        let writeTypes: Set<HKSampleType> = [mindfulType]
        healthStore.requestAuthorization(toShare: writeTypes, read: []) { [weak self] success, _ in
            guard success else { return }
            self?.healthStore.save(sample) { _, _ in }
        }
    }
}
