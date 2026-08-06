import AppKit
import CodexBarCore
import SwiftUI
import Testing
@testable import CodexBar

@MainActor
struct UsageMenuCardLayoutTests {
    private static let heightTolerance: CGFloat = 1

    @Test
    func `overview groups provider content without section dividers`() {
        #expect(OverviewMenuCardRowView.showsSectionDividers == false)
    }

    @Test
    func `header only menu card keeps comfortable padding`() {
        let model = Self.model()
        let width: CGFloat = 296

        let headerSize = NSHostingController(rootView: UsageMenuCardHeaderSectionView(
            model: model,
            showDivider: false,
            width: width))
            .sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude))
        let cardSize = NSHostingController(rootView: UsageMenuCardView(model: model, width: width))
            .sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude))

        #expect(headerSize.height > 0)
        #expect(abs(cardSize.height - headerSize.height) < Self.heightTolerance)
    }

    @Test
    func `full provider card matches overview height`() {
        let model = Self.model(metrics: [
            UsageMenuCardView.Model.Metric(
                id: "session",
                title: "Session",
                percent: 37,
                percentStyle: .left,
                resetText: "Resets in 41m",
                detailText: nil,
                detailLeftText: "24% in reserve",
                detailRightText: "Lasts until reset",
                pacePercent: nil,
                paceOnTop: true),
        ])
        let width: CGFloat = 296

        let fullCardSize = NSHostingController(rootView: UsageMenuCardView(model: model, width: width))
            .sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude))
        let overviewStyleSize = NSHostingController(rootView: UsageMenuCardHeaderAndUsageSectionView(
            model: model,
            layoutModel: model,
            bottomPadding: UsageMenuCardLayout.sectionBottomPadding,
            width: width))
            .sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude))

        #expect(UsageMenuCardLayout.postHeaderDividerContentSpacing == 16)
        #expect(UsageMenuCardLayout.headerOnlyVerticalPadding == 6)
        #expect(UsageMenuCardLayout.sectionTopPadding == 6)
        #expect(UsageMenuCardLayout.sectionBottomPadding == 6)

        #expect(abs(fullCardSize.height - overviewStyleSize.height) < Self.heightTolerance)
    }

    @Test
    func `detail card keeps compact divider gap without usage section`() {
        let metricsModel = Self.model(metrics: [
            UsageMenuCardView.Model.Metric(
                id: "session",
                title: "Session",
                percent: 37,
                percentStyle: .left,
                resetText: "Resets in 41m",
                detailText: nil,
                detailLeftText: "24% in reserve",
                detailRightText: "Lasts until reset",
                pacePercent: nil,
                paceOnTop: true),
        ])

        #expect(UsageMenuCardView.dividerBottomPadding(for: metricsModel) ==
            UsageMenuCardLayout.postHeaderDividerContentSpacing)
        #expect(UsageMenuCardView.dividerBottomPadding(for: Self.model(creditsText: "$12.34 remaining")) ==
            UsageMenuCardLayout.sectionBottomPadding)
        #expect(UsageMenuCardView.dividerBottomPadding(for: Self.model(usageNotes: ["Waiting for data"])) ==
            UsageMenuCardLayout.sectionBottomPadding)
        #expect(UsageMenuCardView.dividerBottomPadding(for: Self.model(placeholder: "No usage yet")) ==
            UsageMenuCardLayout.sectionBottomPadding)
    }

    @Test
    func `compact overview keeps the requested quota rows and readable two column width`() throws {
        let dashboard = InlineUsageDashboardModel(
            accessibilityLabel: "30 day usage",
            valueStyle: .currencyUSD,
            kpis: [
                .init(title: "Today", value: "$12.40", emphasis: true),
                .init(title: "30d", value: "$93.70", emphasis: false),
                .init(title: "Latest tokens", value: "2.7B", emphasis: false),
                .init(title: "30d tokens", value: "5B", emphasis: false),
            ],
            points: [
                .init(id: "1", label: "Mon", value: 4, accessibilityValue: "Monday: $4"),
                .init(id: "2", label: "Tue", value: 12, accessibilityValue: "Tuesday: $12"),
            ],
            detailLines: ["Top model: example", "Estimated from token usage"],
            currencyCode: "USD",
            costAggregation: .init(
                currencyCode: "USD",
                historyDays: 30,
                todayCost: 12,
                historyCost: 16,
                latestTokens: 100,
                historyTokens: 1000,
                points: [
                    .init(id: "1", label: "Mon", value: 4, accessibilityValue: "Monday: $4"),
                    .init(id: "2", label: "Tue", value: 12, accessibilityValue: "Tuesday: $12"),
                ]))
        let claudeDashboard = InlineUsageDashboardModel(
            accessibilityLabel: "30 day Claude usage",
            valueStyle: .currencyUSD,
            kpis: [],
            points: [],
            detailLines: [],
            currencyCode: "USD",
            costAggregation: .init(
                currencyCode: "USD",
                historyDays: 30,
                todayCost: 7,
                historyCost: 9,
                latestTokens: 30,
                historyTokens: 300,
                points: [
                    .init(id: "1", label: "Mon", value: 1, accessibilityValue: "Monday: $1"),
                    .init(id: "2", label: "Tue", value: 3, accessibilityValue: "Tuesday: $3"),
                ]))
        let codexMetrics = [
            Self.metric(id: "primary", title: "Session", percent: 80),
            Self.metric(id: "secondary", title: "Weekly", percent: 61, pacePercent: 78, paceOnTop: false),
            Self.metric(id: "codex-spark-weekly", title: "Codex Spark Weekly", percent: 100),
            Self.metric(id: "code-review", title: "Code review", percent: 66),
        ]
        let claudeMetrics = [
            Self.metric(id: "primary", title: "Session", percent: 92, pacePercent: 84, paceOnTop: false),
            Self.metric(id: "secondary", title: "Weekly", percent: 38, pacePercent: 72, paceOnTop: false),
            Self.metric(id: "claude-weekly-scoped-fable", title: "Fable only", percent: 23),
            Self.metric(id: "claude-routines", title: "Routines", percent: 50),
        ]
        let codexAccount = Self.model(
            provider: .codex,
            email: "Personal",
            planText: "Pro 20x",
            metrics: codexMetrics,
            dashboard: dashboard)
        let claudeAccount = Self.model(
            provider: .claude,
            email: "Personal",
            planText: "-swap",
            metrics: claudeMetrics,
            dashboard: dashboard)
        let codexModel = CompactOverviewProviderCardModel(
            providerModel: codexAccount,
            accountModels: (1...8).map { index in
                (id: "codex-\(index)", model: Self.model(
                    provider: .codex,
                    email: "reviewer0\(index)@example.com",
                    planText: "Pro 20x",
                    metrics: index == 8 ? [] : codexMetrics,
                    placeholder: index == 8 ? "Usage unavailable" : nil,
                    dashboard: dashboard))
            })
        let claudeModel = CompactOverviewProviderCardModel(
            providerModel: claudeAccount,
            accountModels: (1...8).map { index in
                (id: "claude-\(index)", model: Self.model(
                    provider: .claude,
                    email: "reviewer0\(index)@example.com",
                    planText: "-swap",
                    metrics: index == 8 ? [] : claudeMetrics,
                    placeholder: index == 8 ? "Usage unavailable" : nil,
                    dashboard: dashboard))
            })

        #expect(codexModel.accounts.count == 8)
        #expect(claudeModel.accounts.count == 8)
        #expect(codexModel.accounts.last?.statusText == "Usage unavailable")
        #expect(claudeModel.accounts.last?.statusText == "Usage unavailable")
        #expect(codexModel.accounts.dropLast().allSatisfy { $0.metrics.map(\.id) == ["secondary"] })
        #expect(codexModel.accounts.last?.metrics.isEmpty == true)
        #expect(claudeModel.accounts.dropLast().allSatisfy {
            $0.metrics.map(\.id) == ["primary", "secondary", "claude-weekly-scoped-fable"]
        })
        #expect(claudeModel.accounts.last?.metrics.isEmpty == true)
        let accountGrid = CompactOverviewAccountGridModel(providerModels: [codexModel, claudeModel])
        #expect(accountGrid.cards.count == 16)
        #expect(accountGrid.rows.count == 8 && accountGrid.rows.allSatisfy { $0.cards.count == 2 })
        #expect(accountGrid.cards.prefix(8).allSatisfy { $0.provider == .codex })
        #expect(accountGrid.cards.suffix(8).allSatisfy { $0.provider == .claude })
        #expect(CompactOverviewAccountGridView.columnCount == 2)
        let previewGrid = Self.previewGrid(
            codexAccount: codexAccount,
            claudeAccount: claudeAccount,
            codexMetrics: codexMetrics,
            claudeMetrics: claudeMetrics,
            dashboard: dashboard)
        #expect(previewGrid.cards.map(\.provider) == [
            .codex, .codex, .claude, .claude, .cursor, .grok, .antigravity,
        ])
        #expect(previewGrid.rows.map { $0.cards.map(\.provider) } == [
            [.codex, .codex],
            [.claude, .claude],
            [.cursor, .grok],
            [.antigravity],
        ])
        let aggregateDashboard = try #require(CompactOverviewDashboard.aggregate([
            .init(provider: .codex, providerName: "Codex", dashboard: dashboard),
            .init(provider: .claude, providerName: "Claude", dashboard: claudeDashboard),
        ]))
        #expect(aggregateDashboard.aggregate.detailLines.isEmpty)
        #expect(aggregateDashboard.aggregate.costAggregation?.todayCost == 19)
        #expect(aggregateDashboard.aggregate.costAggregation?.historyCost == 25)
        #expect(aggregateDashboard.aggregate.costAggregation?.latestTokens == 130)
        #expect(aggregateDashboard.aggregate.costAggregation?.historyTokens == 1300)
        #expect(aggregateDashboard.aggregate.points.map(\.value) == [5, 15])
        #expect(aggregateDashboard.providerSeries.map(\.provider) == [.codex, .claude])
        #expect(aggregateDashboard.providerSeries.map(\.providerName) == ["Codex", "Claude"])
        #expect(aggregateDashboard.days.map(\.total) == [5, 15])
        #expect(aggregateDashboard.days[0].segments.map(\.value) == [4, 1])
        #expect(aggregateDashboard.days[1].segments.map(\.value) == [12, 3])

        let width = CodexBarPersonalization.compactOverviewMenuWidth
        #expect(width == 420)
        let preview = VStack(spacing: 0) {
            CompactOverviewAccountGridView(model: previewGrid, width: width)
            Divider()
            CompactOverviewDashboardView(model: aggregateDashboard, width: width)
        }
        .frame(width: width)
        .background(Color(nsColor: .windowBackgroundColor))
        let controller = NSHostingController(rootView: preview)
        let size = controller.sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude))

        #expect(abs(size.width - width) < Self.heightTolerance)
        #expect(size.height > 0)
        try Self.writeSnapshotIfRequested(preview, size: size)
    }

    @Test
    func `route B is the only personalized runtime surface and shows every account`() {
        #expect(CodexBarPersonalization.usesCompactOverview(
            featureEnabled: true,
            mergeIcons: true,
            enabledProviderCount: 2))
        #expect(CodexBarPersonalization.usesCompactOverview(
            featureEnabled: true,
            mergeIcons: true,
            enabledProviderCount: 1))
        #expect(CodexBarPersonalization.usesCompactOverview(
            featureEnabled: true,
            mergeIcons: false,
            enabledProviderCount: 2))
        #expect(!CodexBarPersonalization.usesCompactOverview(
            featureEnabled: false,
            mergeIcons: true,
            enabledProviderCount: 2))
        #expect(CodexBarPersonalization.needsAllAccounts(
            featureEnabled: false,
            mergeIcons: false,
            enabledProviderCount: 1,
            providerSupportsCompactAccounts: false,
            usesStackedLayout: true))
        #expect(CodexBarPersonalization.needsAllAccounts(
            featureEnabled: true,
            mergeIcons: true,
            enabledProviderCount: 1,
            providerSupportsCompactAccounts: true,
            usesStackedLayout: false))
        #expect(CodexBarPersonalization.supportsCompactAccounts(for: .codex))
        #expect(CodexBarPersonalization.supportsCompactAccounts(for: .claude))
        #expect(!CodexBarPersonalization.supportsCompactAccounts(for: .openai))
        #expect(CodexBarPersonalization.showsEveryAccount(
            featureEnabled: true,
            providerSupportsCompactAccounts: true))
        #expect(!CodexBarPersonalization.showsEveryAccount(
            featureEnabled: false,
            providerSupportsCompactAccounts: true))
        #expect(!CodexBarPersonalization.showsEveryAccount(
            featureEnabled: true,
            providerSupportsCompactAccounts: false))
        #expect(!CodexBarPersonalization.needsAllAccounts(
            featureEnabled: true,
            mergeIcons: true,
            enabledProviderCount: 2,
            providerSupportsCompactAccounts: false,
            usesStackedLayout: false))
        #expect(CodexBarPersonalization.needsAllAccounts(
            featureEnabled: true,
            mergeIcons: true,
            enabledProviderCount: 2,
            providerSupportsCompactAccounts: false,
            usesStackedLayout: true))
        #expect(CodexBarPersonalization.includesOverviewProvider(
            isErrorOnly: true,
            usesCompactOverview: true,
            hasKnownAccounts: false))
        #expect(!CodexBarPersonalization.includesOverviewProvider(
            isErrorOnly: true,
            usesCompactOverview: false,
            hasKnownAccounts: false))
    }

    private static func metric(
        id: String,
        title: String,
        percent: Double,
        pacePercent: Double? = nil,
        paceOnTop: Bool = true) -> UsageMenuCardView.Model.Metric
    {
        UsageMenuCardView.Model.Metric(
            id: id,
            title: title,
            percent: percent,
            percentStyle: .left,
            resetText: "Resets in 2d 6h",
            detailText: nil,
            detailLeftText: nil,
            detailRightText: nil,
            pacePercent: pacePercent,
            paceOnTop: paceOnTop)
    }

    private static func previewGrid(
        codexAccount: UsageMenuCardView.Model,
        claudeAccount: UsageMenuCardView.Model,
        codexMetrics: [UsageMenuCardView.Model.Metric],
        claudeMetrics: [UsageMenuCardView.Model.Metric],
        dashboard: InlineUsageDashboardModel) -> CompactOverviewAccountGridModel
    {
        let cursor = Self.model(
            provider: .cursor,
            providerName: "Cursor",
            email: "cursor.account@gmail.com",
            subtitleText: "Session changed during refresh",
            subtitleStyle: .error)
        let grokMetrics = [Self.metric(id: "secondary", title: "Weekly", percent: 100)]
        let grok = Self.model(
            provider: .grok,
            providerName: "Grok",
            email: "grok.account@gmail.com",
            metrics: grokMetrics)
        let antigravityMetrics = [
            Self.metric(id: "primary", title: "Gemini", percent: 100),
            Self.metric(id: "secondary", title: "Claude/GPT", percent: 100),
        ]
        let antigravity = Self.model(
            provider: .antigravity,
            providerName: "Antigravity",
            email: "google.account@gmail.com",
            metrics: antigravityMetrics)

        return CompactOverviewAccountGridModel(providerModels: [
            CompactOverviewProviderCardModel(
                providerModel: codexAccount,
                accountModels: (1...2).map { index in
                    (id: "preview-codex-\(index)", model: Self.model(
                        provider: .codex,
                        email: index == 1 ? "primary.account@gmail.com" : "secondary.account@gmail.com",
                        metrics: codexMetrics,
                        dashboard: dashboard))
                }),
            CompactOverviewProviderCardModel(
                providerModel: claudeAccount,
                accountModels: (1...2).map { index in
                    (id: "preview-claude-\(index)", model: Self.model(
                        provider: .claude,
                        email: index == 1 ? "main.claude@gmail.com" : "purple.claude@gmail.com",
                        metrics: claudeMetrics,
                        dashboard: dashboard))
                }),
            CompactOverviewProviderCardModel(
                providerModel: cursor,
                accountModels: [(id: "preview-cursor", model: cursor)]),
            CompactOverviewProviderCardModel(
                providerModel: grok,
                accountModels: [(id: "preview-grok", model: grok)]),
            CompactOverviewProviderCardModel(
                providerModel: antigravity,
                accountModels: [(id: "preview-antigravity", model: antigravity)]),
        ])
    }

    private static func writeSnapshotIfRequested(
        _ view: some View,
        size: CGSize) throws
    {
        guard let path = ProcessInfo.processInfo.environment["CODEXBAR_COMPACT_OVERVIEW_SNAPSHOT_PATH"] else {
            return
        }
        let hostingView = NSHostingView(rootView: view)
        hostingView.appearance = NSAppearance(named: .darkAqua)
        hostingView.frame = NSRect(origin: .zero, size: size)
        hostingView.layoutSubtreeIfNeeded()
        guard let bitmap = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
            throw SnapshotError.bitmapUnavailable
        }
        hostingView.cacheDisplay(in: hostingView.bounds, to: bitmap)
        guard let data = bitmap.representation(using: .png, properties: [:]) else {
            throw SnapshotError.pngUnavailable
        }
        try data.write(to: URL(fileURLWithPath: path), options: .atomic)
    }

    private enum SnapshotError: Error {
        case bitmapUnavailable
        case pngUnavailable
    }

    private static func model(
        provider: UsageProvider = .codex,
        providerName: String? = nil,
        email: String = "steipete@gmail.com",
        subtitleText: String = "Not fetched yet",
        subtitleStyle: UsageMenuCardView.Model.SubtitleStyle = .info,
        planText: String? = "Pro 20x",
        metrics: [UsageMenuCardView.Model.Metric] = [],
        usageNotes: [String] = [],
        creditsText: String? = nil,
        placeholder: String? = nil,
        dashboard: InlineUsageDashboardModel? = nil) -> UsageMenuCardView.Model
    {
        UsageMenuCardView.Model(
            provider: provider,
            providerName: providerName ?? (provider == .claude ? "Claude" : "Codex"),
            email: email,
            subtitleText: subtitleText,
            subtitleStyle: subtitleStyle,
            planText: planText,
            metrics: metrics,
            usageNotes: usageNotes,
            openAIAPIUsage: nil,
            inlineUsageDashboard: dashboard,
            creditsText: creditsText,
            creditsRemaining: nil,
            creditsProgressPercent: nil,
            creditsScaleText: nil,
            creditsHintText: nil,
            creditsHintCopyText: nil,
            providerCost: nil,
            tokenUsage: nil,
            placeholder: placeholder,
            progressColor: UsageMenuCardView.Model.progressColor(for: provider))
    }
}
