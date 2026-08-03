import CodexBarCore
import Foundation

extension UsageStore {
    func compactOverviewNeedsAllAccounts(for provider: UsageProvider) -> Bool {
        CodexBarPersonalization.needsAllAccounts(
            for: provider,
            settings: self.settings,
            enabledProviderCount: self.enabledProvidersForDisplay().count)
    }
}
