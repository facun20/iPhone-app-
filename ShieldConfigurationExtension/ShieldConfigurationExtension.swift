import ManagedSettings
import ManagedSettingsUI
import UIKit

/// Customizes the appearance of the shield shown over blocked apps
class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        return createConfiguration(
            title: application.localizedDisplayName ?? "App Blocked"
        )
    }

    override func configuration(
        shielding application: Application,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        return createConfiguration(
            title: application.localizedDisplayName ?? "App Blocked"
        )
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        return createConfiguration(
            title: webDomain.domain ?? "Site Blocked"
        )
    }

    override func configuration(
        shielding webDomain: WebDomain,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        return createConfiguration(
            title: webDomain.domain ?? "Site Blocked"
        )
    }

    private func createConfiguration(title: String) -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: UIColor.black.withAlphaComponent(0.9),
            icon: UIImage(systemName: "lock.open.rotation"),
            title: ShieldConfiguration.Label(
                text: "\(title) is locked",
                color: .white
            ),
            subtitle: ShieldConfiguration.Label(
                text: "Open EarnIt to complete your challenge and unlock",
                color: .lightGray
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Open EarnIt",
                color: .white
            ),
            primaryButtonBackgroundColor: UIColor.purple,
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Stay Focused",
                color: .lightGray
            )
        )
    }
}
