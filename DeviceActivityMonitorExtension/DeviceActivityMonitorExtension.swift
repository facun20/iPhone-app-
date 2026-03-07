import DeviceActivity
import ManagedSettings
import FamilyControls
import Foundation

/// Monitors device activity and applies/removes shields on schedule boundaries
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    let store = ManagedSettingsStore()

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        // Load the saved activity selection and apply shields
        if let selection = loadActivitySelection() {
            store.shield.applications = selection.applicationTokens
            store.shield.applicationCategories = ShieldSettings
                .ActivityCategoryPolicy
                .specific(selection.categoryTokens)
            store.shield.webDomains = selection.webDomainTokens
        }
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        // Remove all shields when the scheduled interval ends
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
    }

    override func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        super.eventDidReachThreshold(event, activity: activity)
        // Could be used for usage-based triggers in the future
    }

    // MARK: - Shared Data

    private func loadActivitySelection() -> FamilyActivitySelection? {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.infinit3dev.focussnap"),
              let data = sharedDefaults.data(forKey: "activitySelection"),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
        else {
            return nil
        }
        return selection
    }
}
