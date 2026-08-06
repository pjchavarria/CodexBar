import CodexBarCore
import Darwin
import Foundation

/// Fork-owned presentation choices kept behind one seam so upstream updates stay easy to merge.
@MainActor
enum CodexBarPersonalization {
    static let compactOverviewMenuWidth: CGFloat = 380

    private nonisolated static let accountScopedLaunchEnvironmentKeys = [
        "CODEX_HOME",
        "CLAUDE_CONFIG_DIR",
    ]

    #if DEBUG
    static var compactOverviewEnabledOverrideForTesting: Bool?
    #endif

    /// The fork has one runtime surface: Route B's compact overview.
    /// Tests keep the upstream interaction model unless they exercise the personalization directly.
    static var compactOverviewEnabled: Bool {
        #if DEBUG
        if let override = self.compactOverviewEnabledOverrideForTesting {
            return override
        }
        #endif
        return !SettingsStore.isRunningTests
    }

    nonisolated static func sanitizedLaunchEnvironment(
        featureEnabled: Bool,
        environment: [String: String]) -> [String: String]
    {
        guard featureEnabled else { return environment }
        return environment.filter { key, _ in
            !self.accountScopedLaunchEnvironmentKeys.contains(key)
        }
    }

    static func sanitizeProcessEnvironmentForLaunch() {
        guard self.compactOverviewEnabled else { return }
        for key in self.accountScopedLaunchEnvironmentKeys {
            unsetenv(key)
        }
    }

    nonisolated static func usesCompactOverview(
        featureEnabled: Bool,
        mergeIcons _: Bool,
        enabledProviderCount _: Int) -> Bool
    {
        featureEnabled
    }

    static func usesCompactOverview(mergeIcons: Bool, enabledProviderCount: Int) -> Bool {
        self.usesCompactOverview(
            featureEnabled: self.compactOverviewEnabled,
            mergeIcons: mergeIcons,
            enabledProviderCount: enabledProviderCount)
    }

    nonisolated static func needsAllAccounts(
        featureEnabled: Bool,
        mergeIcons: Bool,
        enabledProviderCount: Int,
        providerSupportsCompactAccounts: Bool,
        usesStackedLayout: Bool) -> Bool
    {
        usesStackedLayout || providerSupportsCompactAccounts && self.usesCompactOverview(
            featureEnabled: featureEnabled,
            mergeIcons: mergeIcons,
            enabledProviderCount: enabledProviderCount)
    }

    nonisolated static func supportsCompactAccounts(for provider: UsageProvider) -> Bool {
        provider == .codex || provider == .claude
    }

    nonisolated static func showsEveryAccount(
        featureEnabled: Bool,
        providerSupportsCompactAccounts: Bool) -> Bool
    {
        featureEnabled && providerSupportsCompactAccounts
    }

    /// Route B is the complete provider census, so an enabled provider remains visible when its
    /// current usage fetch fails. The upstream overview may still omit error-only providers.
    nonisolated static func includesOverviewProvider(
        isErrorOnly: Bool,
        usesCompactOverview: Bool,
        hasKnownAccounts: Bool) -> Bool
    {
        !isErrorOnly || usesCompactOverview || hasKnownAccounts
    }

    static func showsEveryAccount(
        for provider: UsageProvider,
        settings: SettingsStore,
        enabledProviderCount: Int) -> Bool
    {
        self.showsEveryAccount(
            featureEnabled: self.usesCompactOverview(
                mergeIcons: settings.mergeIcons,
                enabledProviderCount: enabledProviderCount),
            providerSupportsCompactAccounts: self.supportsCompactAccounts(for: provider))
    }

    static func needsAllAccounts(
        for provider: UsageProvider,
        settings: SettingsStore,
        enabledProviderCount: Int) -> Bool
    {
        self.needsAllAccounts(
            featureEnabled: self.compactOverviewEnabled,
            mergeIcons: settings.mergeIcons,
            enabledProviderCount: enabledProviderCount,
            providerSupportsCompactAccounts: self.supportsCompactAccounts(for: provider),
            usesStackedLayout: settings.multiAccountMenuLayout == .stacked)
    }
}
