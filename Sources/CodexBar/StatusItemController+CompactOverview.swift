import AppKit
import CodexBarCore

extension StatusItemController {
    func personalCompactOverviewProviders(for menu: NSMenu? = nil) -> [UsageProvider]? {
        guard CodexBarPersonalization.compactOverviewEnabled else { return nil }
        if let menu, let mergedMenu = self.mergedMenu, menu !== mergedMenu { return nil }
        return self.store.enabledProvidersForDisplay()
    }

    struct PersonalizedOverviewCardContext {
        let provider: UsageProvider
        let model: UsageMenuCardView.Model
        let storageText: String?
        let menuWidth: CGFloat
        let submenu: NSMenu?
        let interactionMenu: NSMenu
        let identifier: String
        let usesCompactOverview: Bool
    }

    func usesCompactOverview(enabledProviders: [UsageProvider]) -> Bool {
        CodexBarPersonalization.usesCompactOverview(
            mergeIcons: self.shouldMergeIcons,
            enabledProviderCount: enabledProviders.count)
    }

    func personalizedSwitcherSelection(
        enabledProviders: [UsageProvider],
        includesOverview: Bool) -> ProviderSwitcherSelection?
    {
        if self.usesCompactOverview(enabledProviders: enabledProviders) {
            return .overview
        }
        guard self.shouldMergeIcons, enabledProviders.count > 1 else { return nil }
        return self.resolvedSwitcherSelection(
            enabledProviders: enabledProviders,
            includesOverview: includesOverview)
    }

    func personalizedMenuWidth(
        usesCompactOverview: Bool,
        enabledProviders: [UsageProvider],
        selectedProvider: UsageProvider?,
        descriptor: MenuDescriptor) -> CGFloat
    {
        if usesCompactOverview {
            return CodexBarPersonalization.compactOverviewMenuWidth
        }
        return self.menuCardWidth(
            for: enabledProviders,
            selectedProvider: selectedProvider,
            descriptor: descriptor)
    }

    func makePersonalizedOverviewCardItem(_ context: PersonalizedOverviewCardContext) -> NSMenuItem {
        let provider = context.provider
        let model = context.model
        let onClick: (() -> Void)? = context.usesCompactOverview
            ? nil
            : { [weak self, weak interactionMenu = context.interactionMenu] in
                guard let self, let interactionMenu else { return }
                self.selectOverviewProvider(provider, menu: interactionMenu)
            }
        let item = self.makeMenuCardItem(
            OverviewMenuCardRowView(model: model, storageText: context.storageText, width: context.menuWidth),
            id: context.identifier,
            width: context.menuWidth,
            heightCacheScope: provider.rawValue,
            heightCacheFingerprint: model.heightFingerprint(
                section: "overview",
                additional: [UsageMenuCardView.Model.heightFingerprintField("storage", context.storageText)]),
            submenu: context.submenu,
            containsInteractiveControls: model.subtitleStyle == .error || model.usesLiveSubtitle,
            usesGPUSelection: true,
            onClick: onClick)
        if !context.usesCompactOverview, context.submenu == nil {
            // Keep plain rows wired for keyboard activation and accessibility action paths.
            item.target = self
            item.action = #selector(self.selectOverviewProvider(_:))
        }
        return item
    }

    func personalizedActionSections(
        _ sections: [MenuDescriptor.Section],
        usesCompactOverview: Bool) -> [MenuDescriptor.Section]
    {
        guard usesCompactOverview else { return sections }
        let entries = sections.flatMap(\.entries).compactMap { entry -> MenuDescriptor.Entry? in
            guard case let .action(title, action) = entry else { return nil }
            switch action {
            case .refresh, .settings, .quit:
                return .action(title, action)
            default:
                return nil
            }
        }
        return entries.isEmpty ? [] : [.init(entries: entries)]
    }

    func personalizedOverviewProviders(_ enabledProviders: [UsageProvider]) -> [UsageProvider] {
        if self.usesCompactOverview(enabledProviders: enabledProviders) {
            return enabledProviders
        }
        return self.settings.reconcileMergedOverviewSelectedProviders(activeProviders: enabledProviders)
    }

    func personalizedOverviewSubmenu(
        provider: UsageProvider,
        model: UsageMenuCardView.Model,
        width: CGFloat,
        usesCompactOverview: Bool) -> NSMenu?
    {
        guard !usesCompactOverview else { return nil }
        return self.makeOverviewRowSubmenu(provider: provider, model: model, width: width)
    }

    func makeCompactOverviewDashboardItem(
        _ dashboard: CompactOverviewDashboardModel,
        width: CGFloat) -> NSMenuItem
    {
        self.makeMenuCardItem(
            CompactOverviewDashboardView(model: dashboard, width: width),
            id: "compactOverviewDashboard",
            width: width,
            heightCacheScope: "compact-overview-dashboard",
            heightCacheFingerprint: dashboard.heightFingerprint,
            submenu: nil,
            containsInteractiveControls: false,
            usesGPUSelection: true)
    }

    func makeCompactOverviewAccountGridItem(
        _ grid: CompactOverviewAccountGridModel,
        width: CGFloat) -> NSMenuItem
    {
        self.makeMenuCardItem(
            CompactOverviewAccountGridView(model: grid, width: width),
            id: "compactOverviewAccountGrid",
            width: width,
            heightCacheScope: "compact-overview-account-grid",
            heightCacheFingerprint: grid.heightFingerprint,
            submenu: nil,
            containsInteractiveControls: false,
            usesGPUSelection: true)
    }

    func addCompactOverviewContent(
        _ rows: [(provider: UsageProvider, model: UsageMenuCardView.Model)],
        to menu: NSMenu,
        width: CGFloat)
    {
        let providerModels = rows.map { row in
            self.compactOverviewProviderCardModel(
                provider: row.provider,
                providerModel: row.model)
        }
        let grid = CompactOverviewAccountGridModel(providerModels: providerModels)
        menu.addItem(self.makeCompactOverviewAccountGridItem(grid, width: width))

        let dashboardInputs = rows.compactMap { row in
            row.model.inlineUsageDashboard.map { dashboard in
                CompactOverviewDashboard.Input(
                    provider: row.provider,
                    providerName: row.model.providerName,
                    dashboard: dashboard)
            }
        }
        guard let dashboard = CompactOverviewDashboard.aggregate(dashboardInputs) else { return }
        menu.addItem(.separator())
        menu.addItem(self.makeCompactOverviewDashboardItem(dashboard, width: width))
    }

    func compactOverviewProviderCardModel(
        provider: UsageProvider,
        providerModel: UsageMenuCardView.Model) -> CompactOverviewProviderCardModel
    {
        let accountModels: [(id: String, model: UsageMenuCardView.Model)] = switch provider {
        case .codex:
            self.compactOverviewCodexAccountModels(providerModel: providerModel)
        case .claude:
            self.compactOverviewClaudeAccountModels(providerModel: providerModel)
        default:
            [(id: provider.rawValue, model: providerModel)]
        }
        return CompactOverviewProviderCardModel(
            providerModel: providerModel,
            accountModels: accountModels.isEmpty
                ? [(id: provider.rawValue, model: providerModel)]
                : accountModels)
    }

    func hasKnownCompactOverviewAccounts(for provider: UsageProvider) -> Bool {
        switch provider {
        case .codex:
            return self.settings.codexVisibleAccountProjectionForMenuDisplay?.visibleAccounts.isEmpty == false
        case .claude:
            if ClaudeSwapMenuPrecedence.prefersClaudeSwap(
                provider: .claude,
                accountCount: self.store.claudeSwapAccountSnapshots.count,
                showSingleAccount: self.settings.claudeSwapShowSingleAccount)
            {
                return !self.store.claudeSwapAccountSnapshots.isEmpty
            }
            return !self.store.claudeSwapAccountSnapshots.isEmpty ||
                !self.settings.tokenAccounts(for: .claude).isEmpty
        default:
            return false
        }
    }

    private func compactOverviewCodexAccountModels(
        providerModel: UsageMenuCardView.Model) -> [(id: String, model: UsageMenuCardView.Model)]
    {
        guard let display = self.codexAccountMenuDisplay(for: .codex) else {
            return [(id: UsageProvider.codex.rawValue, model: providerModel)]
        }
        let snapshotsByAccountID = Dictionary(uniqueKeysWithValues: display.snapshots.map {
            ($0.account.id, $0)
        })
        return display.accounts.compactMap { account in
            let accountSnapshot = snapshotsByAccountID[account.id]
            let showsEveryAccount = self.store.compactOverviewShowsEveryAccount(for: .codex)
            if !showsEveryAccount,
               accountSnapshot == nil,
               account.id == display.activeVisibleAccountID || account.isActive
            {
                return (id: account.id, model: providerModel)
            }
            let accountError = accountSnapshot?.error ?? (showsEveryAccount
                ? self.store.userFacingError(for: .codex) ?? providerModel.placeholder
                : nil)
            let health = CodexAccountHealth.status(for: account, error: accountError)
            guard let model = self.menuCardModel(
                for: .codex,
                snapshotOverride: accountSnapshot?.snapshot,
                errorOverride: health.label,
                forceOverrideCard: accountSnapshot == nil,
                accountOverride: self.accountInfo(for: account),
                historySelectionOverride: self.store.codexPlanUtilizationHistorySelection(
                    forVisibleAccount: account))
            else { return nil }
            return (id: account.id, model: model)
        }
    }

    private func compactOverviewClaudeAccountModels(
        providerModel: UsageMenuCardView.Model) -> [(id: String, model: UsageMenuCardView.Model)]
    {
        let claudeSwapSnapshots = self.store.claudeSwapAccountSnapshots
        let showsEveryClaudeAccount = self.store.compactOverviewShowsEveryAccount(for: .claude)
        if showsEveryClaudeAccount && !claudeSwapSnapshots.isEmpty || ClaudeSwapMenuPrecedence.prefersClaudeSwap(
            provider: .claude,
            accountCount: claudeSwapSnapshots.count,
            showSingleAccount: self.settings.claudeSwapShowSingleAccount)
        {
            return claudeSwapSnapshots.compactMap { account in
                guard let model = self.menuCardModel(
                    for: .claude,
                    snapshotOverride: account.snapshot,
                    errorOverride: ClaudeSwapAccountProjection.displayError(
                        accountError: account.error,
                        adapterError: self.store.claudeSwapLastError,
                        switchError: self.store.claudeSwapTransientState.lastErrorAccountID == account.id
                            ? self.store.claudeSwapTransientState.lastError
                            : nil),
                    forceOverrideCard: account.snapshot == nil,
                    accountOverride: AccountInfo(email: account.displayLabel, plan: nil))
                else { return nil }
                return (id: account.id.opaqueID, model: model)
            }
        }

        guard let display = self.tokenAccountMenuDisplay(for: .claude) else {
            return [(id: UsageProvider.claude.rawValue, model: providerModel)]
        }
        let snapshotsByAccountID = Dictionary(uniqueKeysWithValues: display.snapshots.map {
            ($0.account.id, $0)
        })
        let selectedAccountID = self.settings.effectiveSelectedTokenAccount(for: .claude)?.id
        return display.accounts.compactMap { account in
            let accountSnapshot = snapshotsByAccountID[account.id]
            if accountSnapshot == nil, account.id == selectedAccountID {
                let label = account.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard let model = self.menuCardModel(
                    for: .claude,
                    snapshotOverride: self.store.presentationSnapshot(for: .claude),
                    errorOverride: self.store.userFacingError(for: .claude),
                    forceOverrideCard: true,
                    accountOverride: AccountInfo(email: label.isEmpty ? nil : label, plan: nil),
                    historySelectionOverride: self.store.planUtilizationHistorySelection(
                        for: .claude,
                        account: account))
                else { return nil }
                return (id: account.id.uuidString, model: model)
            }
            let label = account.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let model = self.menuCardModel(
                for: .claude,
                snapshotOverride: accountSnapshot?.snapshot,
                errorOverride: accountSnapshot?.error,
                forceOverrideCard: true,
                accountOverride: AccountInfo(email: label.isEmpty ? nil : label, plan: nil),
                historySelectionOverride: self.store.planUtilizationHistorySelection(
                    for: .claude,
                    account: account))
            else { return nil }
            return (id: account.id.uuidString, model: model)
        }
    }
}
