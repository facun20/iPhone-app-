import Foundation
import HealthKit

/// Reads step count, distance, workout, calories, and flights data from HealthKit to evaluate unlock conditions
@MainActor
class HealthKitService: ObservableObject {
    private let healthStore = HKHealthStore()

    @Published var isAuthorized = false
    @Published var todaySteps: Int = 0
    @Published var todayDistanceMeters: Double = 0
    @Published var todayWorkoutMinutes: Int = 0
    @Published var todayActiveCalories: Int = 0
    @Published var todayFlightsClimbed: Int = 0
    @Published var todayMindfulMinutes: Int = 0

    private var updateTimer: Timer?

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }

        let readTypes: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .flightsClimbed)!,
            HKObjectType.workoutType(),
            HKCategoryType.categoryType(forIdentifier: .mindfulSession)!
        ]

        do {
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)
            isAuthorized = true
            return true
        } catch {
            isAuthorized = false
            return false
        }
    }

    // MARK: - Live Monitoring

    /// Start polling HealthKit for live progress during a session
    func startMonitoring() {
        fetchAll()
        // Poll every 30 seconds for updated health data
        updateTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.fetchAll()
            }
        }
    }

    func stopMonitoring() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    private func fetchAll() {
        Task {
            async let steps = fetchTodaySteps()
            async let distance = fetchTodayDistance()
            async let workout = fetchTodayWorkoutMinutes()
            async let calories = fetchTodayActiveCalories()
            async let flights = fetchTodayFlightsClimbed()
            async let mindful = fetchTodayMindfulMinutes()

            todaySteps = await steps
            todayDistanceMeters = await distance
            todayWorkoutMinutes = await workout
            todayActiveCalories = await calories
            todayFlightsClimbed = await flights
            todayMindfulMinutes = await mindful
        }
    }

    // MARK: - Step Count

    func fetchTodaySteps() async -> Int {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return 0 }

        let predicate = todayPredicate()

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let steps = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: Int(steps))
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Distance

    func fetchTodayDistance() async -> Double {
        guard let distType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else { return 0 }

        let predicate = todayPredicate()

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: distType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let meters = result?.sumQuantity()?.doubleValue(for: .meter()) ?? 0
                continuation.resume(returning: meters)
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Workout Minutes

    func fetchTodayWorkoutMinutes() async -> Int {
        let predicate = todayPredicate()

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: .workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, _ in
                let workouts = samples as? [HKWorkout] ?? []
                let totalMinutes = workouts.reduce(0.0) { $0 + $1.duration / 60.0 }
                continuation.resume(returning: Int(totalMinutes))
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Active Calories

    func fetchTodayActiveCalories() async -> Int {
        guard let calType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return 0 }

        let predicate = todayPredicate()

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: calType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let cals = result?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                continuation.resume(returning: Int(cals))
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Flights Climbed

    func fetchTodayFlightsClimbed() async -> Int {
        guard let flightType = HKQuantityType.quantityType(forIdentifier: .flightsClimbed) else { return 0 }

        let predicate = todayPredicate()

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: flightType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let flights = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: Int(flights))
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Mindful Minutes (from Apple Health)

    func fetchTodayMindfulMinutes() async -> Int {
        guard let mindfulType = HKCategoryType.categoryType(forIdentifier: .mindfulSession) else { return 0 }

        let predicate = todayPredicate()

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: mindfulType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, _ in
                let sessions = samples as? [HKCategorySample] ?? []
                let totalMinutes = sessions.reduce(0.0) { total, sample in
                    total + sample.endDate.timeIntervalSince(sample.startDate) / 60.0
                }
                continuation.resume(returning: Int(totalMinutes))
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Condition Evaluation

    /// Check if a specific unlock condition is satisfied based on current health data
    func evaluateCondition(_ condition: UnlockCondition) -> ConditionProgress {
        switch condition.type {
        case .steps:
            let target = Double(condition.targetSteps ?? 5000)
            let current = Double(todaySteps)
            return ConditionProgress(
                id: condition.id,
                ruleName: "",
                condition: condition,
                currentValue: current,
                targetValue: target,
                isComplete: current >= target
            )

        case .distance:
            let target = condition.targetDistanceMeters ?? 1609.34
            let current = todayDistanceMeters
            return ConditionProgress(
                id: condition.id,
                ruleName: "",
                condition: condition,
                currentValue: current,
                targetValue: target,
                isComplete: current >= target
            )

        case .workout:
            let target = Double(condition.targetWorkoutMinutes ?? 30)
            let current = Double(todayWorkoutMinutes)
            return ConditionProgress(
                id: condition.id,
                ruleName: "",
                condition: condition,
                currentValue: current,
                targetValue: target,
                isComplete: current >= target
            )

        case .timeBased:
            let now = Calendar.current.dateComponents([.hour, .minute], from: Date())
            let currentMinutes = (now.hour ?? 0) * 60 + (now.minute ?? 0)
            let targetMinutes = (condition.unlockAfterHour ?? 9) * 60 + (condition.unlockAfterMinute ?? 0)
            return ConditionProgress(
                id: condition.id,
                ruleName: "",
                condition: condition,
                currentValue: Double(currentMinutes),
                targetValue: Double(targetMinutes),
                isComplete: currentMinutes >= targetMinutes
            )

        case .calories:
            let target = Double(condition.targetCalories ?? 200)
            let current = Double(todayActiveCalories)
            return ConditionProgress(
                id: condition.id,
                ruleName: "",
                condition: condition,
                currentValue: current,
                targetValue: target,
                isComplete: current >= target
            )

        case .flights:
            let target = Double(condition.targetFlights ?? 5)
            let current = Double(todayFlightsClimbed)
            return ConditionProgress(
                id: condition.id,
                ruleName: "",
                condition: condition,
                currentValue: current,
                targetValue: target,
                isComplete: current >= target
            )

        case .mindfulness:
            // Can be satisfied by in-app timer OR HealthKit mindful sessions
            let target = Double(condition.targetMindfulnessMinutes ?? 5)
            let current = Double(todayMindfulMinutes)
            return ConditionProgress(
                id: condition.id,
                ruleName: "",
                condition: condition,
                currentValue: current,
                targetValue: target,
                isComplete: current >= target
            )

        case .photo:
            // Photo conditions are evaluated separately via ImageVerificationService
            return ConditionProgress(
                id: condition.id,
                ruleName: "",
                condition: condition,
                currentValue: 0,
                targetValue: 1,
                isComplete: false
            )

        case .journaling:
            // Journaling conditions are evaluated via JournalingView word count
            return ConditionProgress(
                id: condition.id,
                ruleName: "",
                condition: condition,
                currentValue: 0,
                targetValue: Double(condition.targetWordCount ?? 50),
                isComplete: false
            )

        case .location:
            // Location conditions are evaluated via LocationService
            return ConditionProgress(
                id: condition.id,
                ruleName: "",
                condition: condition,
                currentValue: 0,
                targetValue: 1,
                isComplete: false
            )
        }
    }

    // MARK: - Helpers

    private func todayPredicate() -> NSPredicate {
        let start = Calendar.current.startOfDay(for: Date())
        return HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
    }
}
