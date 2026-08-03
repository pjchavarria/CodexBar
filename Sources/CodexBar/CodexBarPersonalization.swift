import CodexBarCore
import Foundation

/// Fork-owned presentation choices kept behind one seam so upstream updates stay easy to merge.
@MainActor
enum CodexBarPersonalization {
    #if DEBUG
    static var compactOverviewEnabledOverrideForTesting: Bool?
    #endif

    /// The fork replaces the merged provider switcher with a compact, overview-only menu.
    /// Tests keep the upstream interaction model unless they exercise the compact view directly.
    static var compactOverviewEnabled: Bool {
        #if DEBUG
        if let override = self.compactOverviewEnabledOverrideForTesting {
            return override
        }
        #endif
        return !SettingsStore.isRunningTests
    }

    nonisolated static func usesCompactOverview(
        featureEnabled: Bool,
        mergeIcons: Bool,
        enabledProviderCount: Int) -> Bool
    {
        featureEnabled && mergeIcons && enabledProviderCount > 1
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
