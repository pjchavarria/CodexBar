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
            let metrics = Self.visibleMetrics(for: account.model)
            return Account(
                id: account.id,
                identityText: Self.accountIdentityText(account.model),
                planText: account.model.planText,
                statusText: Self.accountStatusText(account.model),
                metrics: metrics)
        }
        self.progressColor = providerModel.progressColor
        self.heightFingerprint = accountModels.map { account in
            "\(account.id):\(account.model.heightFingerprint(section: "compact-overview-account"))"
        }.joined(separator: "|")
    }

    static func visibleMetrics(
        for model: UsageMenuCardView.Model) -> [UsageMenuCardView.Model.Metric]
    {
        switch model.provider {
        case .codex:
            model.metrics.filter { $0.id == "secondary" }
        case .claude:
            model.metrics.filter { $0.id == "primary" } +
                model.metrics.filter { $0.id == "secondary" } +
                model.metrics.filter(self.isFableOnly)
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
}

struct CompactOverviewProviderCardView: View {
    static let accountColumnCount = 2

    let model: CompactOverviewProviderCardModel
    let width: CGFloat
    @Environment(\.menuItemHighlighted) private var isHighlighted

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            self.providerHeader
            Divider()
            self.accountGrid
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .frame(width: self.width, alignment: .leading)
    }

    private var accountGrid: some View {
        LazyVGrid(
            columns: Array(
                repeating: GridItem(.flexible(minimum: 0), spacing: 10, alignment: .topLeading),
                count: Self.accountColumnCount),
            alignment: .leading,
            spacing: 10)
        {
            ForEach(self.model.accounts) { account in
                self.account(account)
            }
        }
        .overlay {
            if self.model.accounts.count > 1 {
                Rectangle()
                    .fill(Color(nsColor: .separatorColor))
                    .frame(width: 1)
            }
        }
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
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }

    private func account(_ account: CompactOverviewProviderCardModel.Account) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(account.identityText)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(MenuHighlightStyle.primary(self.isHighlighted))
                    .lineLimit(1)
                    .truncationMode(.middle)
                if let planText = account.planText, !planText.isEmpty {
                    Text(Self.compactPlanText(planText))
                        .font(.caption2)
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
        let tint = self.model.progressColor
        return VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(metric.title)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(MenuHighlightStyle.primary(self.isHighlighted))
                    .lineLimit(1)
                if metric.statusText == nil {
                    Text(UsageFormatter.percentString(metric.percent))
                        .font(.caption2)
                        .foregroundStyle(MenuHighlightStyle.progressTint(self.isHighlighted, fallback: tint))
                        .lineLimit(1)
                }
                Spacer(minLength: 2)
                if let resetText = metric.resetText {
                    Text(Self.compactResetText(resetText))
                        .font(.caption2)
                        .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                        .lineLimit(1)
                        .accessibilityLabel(resetText)
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
            }
        }
        .accessibilityElement(children: .combine)
    }

    private static func compactPlanText(_ planText: String) -> String {
        planText.split(whereSeparator: { $0.isWhitespace }).last.map(String.init) ?? planText
    }

    private static func compactResetText(_ resetText: String) -> String {
        let parts = resetText.split(whereSeparator: { $0.isWhitespace })
        guard parts.count > 2 else { return resetText }
        return parts.suffix(2).joined(separator: " ")
    }
}
