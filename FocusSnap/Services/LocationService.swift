import Foundation
import CoreLocation

/// Monitors user location to evaluate "show up" unlock conditions (arrive at gym, school, office, etc.)
@MainActor
class LocationService: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()

    @Published var isAuthorized = false
    @Published var currentLocation: CLLocation?
    @Published var arrivedAtTarget = false
    @Published var distanceToTarget: Double?  // meters

    private var targetLocation: CLLocation?
    private var targetRadius: Double = 100  // meters
    private var monitoringConditionId: UUID?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = false
        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    private func checkAuthorizationStatus() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            isAuthorized = true
        default:
            isAuthorized = false
        }
    }

    // MARK: - Monitoring

    /// Start monitoring arrival at a target location for an unlock condition
    func startMonitoring(condition: UnlockCondition) {
        guard let lat = condition.locationLatitude,
              let lon = condition.locationLongitude else { return }

        targetLocation = CLLocation(latitude: lat, longitude: lon)
        targetRadius = condition.locationRadiusMeters ?? 100
        monitoringConditionId = condition.id
        arrivedAtTarget = false
        distanceToTarget = nil

        locationManager.startUpdatingLocation()
    }

    func stopMonitoring() {
        locationManager.stopUpdatingLocation()
        targetLocation = nil
        monitoringConditionId = nil
    }

    /// Evaluate whether the user has arrived at the target
    func evaluateCondition(_ condition: UnlockCondition) -> ConditionProgress {
        let arrived = arrivedAtTarget

        var progressValue: Double = 0
        if let distance = distanceToTarget, let radius = condition.locationRadiusMeters {
            // Show progress as distance closed — closer = more progress
            let maxDisplayDistance = max(radius * 10, 1000)  // show progress within ~1km
            progressValue = max(0, 1.0 - (distance / maxDisplayDistance))
        }

        return ConditionProgress(
            id: condition.id,
            ruleName: "",
            condition: condition,
            currentValue: arrived ? 1 : progressValue,
            targetValue: 1,
            isComplete: arrived
        )
    }

    // MARK: - Search for places

    /// Search for a place by name and return matching results
    func searchPlaces(query: String) async -> [LocationSearchResult] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        if let location = currentLocation {
            request.region = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: 10000,
                longitudinalMeters: 10000
            )
        }

        do {
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            return response.mapItems.prefix(5).map { item in
                LocationSearchResult(
                    name: item.name ?? "Unknown",
                    address: [item.placemark.thoroughfare, item.placemark.locality]
                        .compactMap { $0 }.joined(separator: ", "),
                    latitude: item.placemark.coordinate.latitude,
                    longitude: item.placemark.coordinate.longitude
                )
            }
        } catch {
            return []
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        Task { @MainActor in
            currentLocation = location

            if let target = targetLocation {
                let distance = location.distance(from: target)
                distanceToTarget = distance

                if distance <= targetRadius {
                    arrivedAtTarget = true
                    locationManager.stopUpdatingLocation()
                }
            }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            checkAuthorizationStatus()
        }
    }
}

// MARK: - MapKit import for search

import MapKit

/// A search result for location picking
struct LocationSearchResult: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
}
