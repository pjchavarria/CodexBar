import AppKit
import CodexBarCore
import SwiftUI

struct CompactOverviewProviderCardModel {
    struct Account: Identifiable {
        let id: String
        let identityText: String
        let planText: String?
        let statusText: String?
        let metrics: [UsageMenuCardView.Model.Metric]
    }

    let provider: UsageProvider
    let providerName: String
    let updatedText: String
    let accounts: [Account]
    let dashboard: InlineUsageDashboardModel?
    let progressColor: Color
    let heightFingerprint: String

    init(
        providerModel: UsageMenuCardView.Model,
        accountModels: [(id: String, model: UsageMenuCardView.Model)])
    {
        self.provider = providerModel.provider
        self.providerName = providerModel.providerName
        self.updatedText = providerModel.subtitleText
        self.accounts = accountModels.map { account in
            Account(
                id: account.id,
                identityText: Self.accountIdentityText(account.model),
                planText: account.model.planText,
                statusText: Self.accountStatusText(account.model),
                metrics: Self.visibleMetrics(for: account.model))
        }
        self.dashboard = Self.displayDashboard(
            providerDashboard: providerModel.inlineUsageDashboard,
            accountModels: accountModels.map(\.model))
        self.progressColor = providerModel.progressColor
        self.heightFingerprint = accountModels.map { account in
            "\(account.id):\(account.model.heightFingerprint(section: "compact-overview-account"))"
        }.joined(separator: "|") + "|dashboard=\(providerModel.inlineUsageDashboard == nil ? 0 : 1)"
    }

    static func visibleMetrics(
        for model: UsageMenuCardView.Model) -> [UsageMenuCardView.Model.Metric]
    {
        switch model.provider {
        case .codex:
            model.metrics.filter { $0.id == "secondary" }
        case .claude:
            model.metrics.filter { metric in
                metric.id == "primary" || metric.id == "secondary" || Self.isFableOnly(metric)
            }
        default:
            model.metrics
        }
    }

    static func isFableOnly(_ metric: UsageMenuCardView.Model.Metric) -> Bool {
        metric.id.hasPrefix("claude-weekly-scoped-") &&
            (metric.id.localizedCaseInsensitiveContains("fable") ||
                metric.title.localizedCaseInsensitiveContains("fable"))
    }

    private static func accountIdentityText(_ model: UsageMenuCardView.Model) -> String {
        let identity = model.email.trimmingCharacters(in: .whitespacesAndNewlines)
        return identity.isEmpty ? L("Account") : identity
    }

    private static func accountStatusText(_ model: UsageMenuCardView.Model) -> String? {
        switch model.subtitleStyle {
        case .error:
            model.subtitleText
        case .info, .loading:
            self.visibleMetrics(for: model).isEmpty ? model.placeholder : nil
        }
    }

    private static func displayDashboard(
        providerDashboard: InlineUsageDashboardModel?,
        accountModels: [UsageMenuCardView.Model]) -> InlineUsageDashboardModel?
    {
        guard let dashboard = providerDashboard ?? accountModels.compactMap(\.inlineUsageDashboard).first else {
            return nil
        }
        return InlineUsageDashboardModel(
            accessibilityLabel: dashboard.accessibilityLabel,
            valueStyle: dashboard.valueStyle,
            kpis: dashboard.kpis,
            points: dashboard.points,
            detailLines: [],
            barColor: dashboard.barColor,
            currencyCode: dashboard.currencyCode)
    }
}

struct CompactOverviewProviderCardView: View {
    let model: CompactOverviewProviderCardModel
    let width: CGFloat
    @Environment(\.menuItemHighlighted) private var isHighlighted

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            self.providerHeader
            Divider()
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(self.model.accounts.enumerated()), id: \.element.id) { index, account in
                    if index > 0 {
                        Divider()
                            .padding(.vertical, 8)
                    }
                    self.account(account)
                }
            }
            .padding(.horizontal, UsageMenuCardLayout.horizontalPadding)
            .padding(.vertical, 8)

            if let dashboard = self.model.dashboard {
                Divider()
                InlineUsageDashboardContent(model: dashboard, chartHeight: 42)
                    .padding(.horizontal, UsageMenuCardLayout.horizontalPadding)
                    .padding(.vertical, 10)
            }
        }
        .frame(width: self.width, alignment: .leading)
    }

    private var providerHeader: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            if let icon = ProviderBrandIcon.image(for: self.model.provider) {
                Image(nsImage: icon)
                    .frame(width: 16, height: 16)
                    .accessibilityHidden(true)
            }
            Text(self.model.providerName)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(MenuHighlightStyle.primary(self.isHighlighted))
                .lineLimit(1)
            Text(self.model.updatedText)
                .font(.caption)
                .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, UsageMenuCardLayout.horizontalPadding)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }

    private func account(_ account: CompactOverviewProviderCardModel.Account) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(account.identityText)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(MenuHighlightStyle.primary(self.isHighlighted))
                    .lineLimit(1)
                    .truncationMode(.middle)
                if let planText = account.planText, !planText.isEmpty {
                    Text("·")
                        .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                    Text(planText)
                        .font(.subheadline)
                        .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }

            if let statusText = account.statusText {
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                    .lineLimit(2)
            }

            ForEach(account.metrics) { metric in
                self.metric(metric)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(account.identityText)
    }

    private func metric(_ metric: UsageMenuCardView.Model.Metric) -> some View {
        let tint = CompactOverviewProviderCardModel.isFableOnly(metric)
            ? Color(nsColor: .systemYellow)
            : self.model.progressColor
        return VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(metric.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(MenuHighlightStyle.primary(self.isHighlighted))
                    .lineLimit(1)
                if metric.statusText == nil {
                    Text("· \(metric.percentLabel)")
                        .font(.caption)
                        .foregroundStyle(MenuHighlightStyle.progressTint(self.isHighlighted, fallback: tint))
                        .lineLimit(1)
                }
                Spacer(minLength: 4)
                if let resetText = metric.resetText {
                    Text(resetText)
                        .font(.caption2)
                        .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                        .lineLimit(1)
                }
            }
            if let statusText = metric.statusText {
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                    .lineLimit(1)
            } else {
                UsageProgressBar(
                    percent: metric.percent,
                    tint: tint,
                    accessibilityLabel: metric.percentStyle.accessibilityLabel,
                    pacePercent: metric.pacePercent,
                    paceOnTop: metric.paceOnTop,
                    warningMarkerPercents: metric.warningMarkerPercents,
                    workdayMarkerPercents: metric.workdayMarkerPercents)
                if metric.detailLeftText != nil || metric.detailRightText != nil {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        if let detailLeftText = metric.detailLeftText {
                            Text(detailLeftText)
                                .font(.caption2)
                                .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                                .lineLimit(1)
                        }
                        Spacer(minLength: 4)
                        if let detailRightText = metric.detailRightText {
                            Text(detailRightText)
                                .font(.caption2)
                                .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
        .padding(.top, 2)
        .accessibilityElement(children: .combine)
    }
}
