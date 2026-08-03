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
    func `compact overview keeps the requested quota rows and fixed menu width`() throws {
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
        let codexMetrics = [
            Self.metric(id: "primary", title: "Session", percent: 80),
            Self.metric(id: "secondary", title: "Weekly", percent: 61),
            Self.metric(id: "codex-spark-weekly", title: "Codex Spark Weekly", percent: 100),
            Self.metric(id: "code-review", title: "Code review", percent: 66),
        ]
        let claudeMetrics = [
            Self.metric(id: "primary", title: "Session", percent: 92),
            Self.metric(id: "secondary", title: "Weekly", percent: 38),
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
            planText: "Max 20x",
            metrics: claudeMetrics,
            dashboard: dashboard)
        let codexModel = CompactOverviewProviderCardModel(
            providerModel: codexAccount,
            accountModels: [
                (id: "codex-personal", model: codexAccount),
                (id: "codex-work", model: Self.model(
                    provider: .codex,
                    email: "Work",
                    planText: "Team 10x",
                    metrics: codexMetrics,
                    dashboard: dashboard)),
            ])
        let claudeModel = CompactOverviewProviderCardModel(
            providerModel: claudeAccount,
            accountModels: [
                (id: "claude-personal", model: claudeAccount),
                (id: "claude-work", model: Self.model(
                    provider: .claude,
                    email: "Work",
                    planText: "Team 5x",
                    metrics: claudeMetrics,
                    dashboard: dashboard)),
            ])

        #expect(codexModel.accounts.allSatisfy { $0.metrics.map(\.id) == ["secondary"] })
        #expect(claudeModel.accounts.allSatisfy {
            $0.metrics.map(\.id) == ["secondary", "primary", "claude-weekly-scoped-fable"]
        })
        #expect(claudeModel.accounts.allSatisfy { $0.weeklyMetric?.id == "secondary" })
        #expect(claudeModel.accounts.allSatisfy {
            $0.weeklyDetails.map(\.id) == ["primary", "claude-weekly-scoped-fable"]
        })
        let aggregateDashboard = try #require(CompactOverviewDashboard.aggregate([dashboard, dashboard]))
        #expect(aggregateDashboard.detailLines.isEmpty)
        #expect(aggregateDashboard.costAggregation?.todayCost == 24)
        #expect(aggregateDashboard.costAggregation?.historyCost == 32)
        #expect(aggregateDashboard.costAggregation?.latestTokens == 200)
        #expect(aggregateDashboard.costAggregation?.historyTokens == 2000)
        #expect(aggregateDashboard.points.map(\.value) == [8, 24])

        let width = StatusItemController.menuCardBaseWidth
        let preview = VStack(spacing: 0) {
            CompactOverviewProviderCardView(model: codexModel, width: width)
            Divider()
            CompactOverviewProviderCardView(model: claudeModel, width: width)
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
    func `compact overview routing is limited to merged multi-provider menus`() {
        #expect(CodexBarPersonalization.usesCompactOverview(
            featureEnabled: true,
            mergeIcons: true,
            enabledProviderCount: 2))
        #expect(!CodexBarPersonalization.usesCompactOverview(
            featureEnabled: true,
            mergeIcons: true,
            enabledProviderCount: 1))
        #expect(!CodexBarPersonalization.usesCompactOverview(
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
        #expect(!CodexBarPersonalization.needsAllAccounts(
            featureEnabled: true,
            mergeIcons: true,
            enabledProviderCount: 1,
            providerSupportsCompactAccounts: true,
            usesStackedLayout: false))
        #expect(CodexBarPersonalization.supportsCompactAccounts(for: .codex))
        #expect(CodexBarPersonalization.supportsCompactAccounts(for: .claude))
        #expect(!CodexBarPersonalization.supportsCompactAccounts(for: .openai))
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
    }

    private static func metric(
        id: String,
        title: String,
        percent: Double) -> UsageMenuCardView.Model.Metric
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
            pacePercent: nil,
            paceOnTop: true)
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
        email: String = "steipete@gmail.com",
        planText: String? = "Pro 20x",
        metrics: [UsageMenuCardView.Model.Metric] = [],
        usageNotes: [String] = [],
        creditsText: String? = nil,
        placeholder: String? = nil,
        dashboard: InlineUsageDashboardModel? = nil) -> UsageMenuCardView.Model
    {
        UsageMenuCardView.Model(
            provider: provider,
            providerName: provider == .claude ? "Claude" : "Codex",
            email: email,
            subtitleText: "Not fetched yet",
            subtitleStyle: .info,
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
            progressColor: .blue)
    }
}
