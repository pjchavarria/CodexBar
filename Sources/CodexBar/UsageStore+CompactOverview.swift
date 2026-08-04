import CodexBarCore
import Foundation

extension UsageStore {
    func compactOverviewNeedsAllAccounts(for provider: UsageProvider) -> Bool {
        CodexBarPersonalization.needsAllAccounts(
            for: provider,
            settings: self.settings,
            enabledProviderCount: self.enabledProvidersForDisplay().count)
    }

    func compactOverviewShowsEveryAccount(for provider: UsageProvider) -> Bool {
        CodexBarPersonalization.showsEveryAccount(
            for: provider,
            settings: self.settings,
            enabledProviderCount: self.enabledProvidersForDisplay().count)
    }

    func compactOverviewCodexAccounts(
        from projection: CodexVisibleAccountProjection) -> [CodexVisibleAccount]
    {
        if self.compactOverviewShowsEveryAccount(for: .codex) {
            return CodexAccountPresentationOrdering.orderedAccounts(
                projection.visibleAccounts,
                snapshots: self.codexAccountSnapshots,
                activeVisibleAccountID: projection.activeVisibleAccountID)
        }
        return self.limitedCodexVisibleAccounts(
            projection.visibleAccounts,
            snapshots: self.codexAccountSnapshots,
            activeVisibleAccountID: projection.activeVisibleAccountID)
    }

    func compactOverviewTokenAccounts(
        _ accounts: [ProviderTokenAccount],
        selected: ProviderTokenAccount?,
        provider: UsageProvider) -> [ProviderTokenAccount]
    {
        self.compactOverviewShowsEveryAccount(for: provider)
            ? accounts
            : self.limitedTokenAccounts(accounts, selected: selected)
    }
}
