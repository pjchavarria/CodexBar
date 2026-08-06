import AppKit
import CodexBarCore
import SwiftUI

struct CompactOverviewProviderCardModel {
    struct Account: Identifiable {
        let id: String
        let identityText: String
        let statusText: String?
        let statusIsError: Bool
        let metrics: [UsageMenuCardView.Model.Metric]
    }

    let provider: UsageProvider
    let providerName: String
    let accounts: [Account]
    let progressColor: Color
    let heightFingerprint: String

    init(
        providerModel: UsageMenuCardView.Model,
        accountModels: [(id: String, model: UsageMenuCardView.Model)])
    {
        self.provider = providerModel.provider
        self.providerName = providerModel.providerName
        self.accounts = accountModels.map { account in
            let metrics = Self.visibleMetrics(for: account.model)
            return Account(
                id: account.id,
                identityText: Self.accountIdentityText(account.model),
                statusText: Self.accountStatusText(account.model),
                statusIsError: account.model.subtitleStyle == .error,
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

struct CompactOverviewAccountGridModel {
    struct Card: Identifiable {
        let id: String
        let provider: UsageProvider
        let providerName: String
        let identityText: String
        let statusText: String?
        let statusIsError: Bool
        let metrics: [UsageMenuCardView.Model.Metric]
        let progressColor: Color
    }

    let cards: [Card]
    let heightFingerprint: String

    init(providerModels: [CompactOverviewProviderCardModel]) {
        self.cards = providerModels.flatMap { providerModel in
            providerModel.accounts.map { account in
                Card(
                    id: "\(providerModel.provider.rawValue):\(account.id)",
                    provider: providerModel.provider,
                    providerName: providerModel.providerName,
                    identityText: account.identityText,
                    statusText: account.statusText,
                    statusIsError: account.statusIsError,
                    metrics: account.metrics,
                    progressColor: providerModel.progressColor)
            }
        }
        self.heightFingerprint = providerModels.map { model in
            "\(model.provider.rawValue):\(model.heightFingerprint)"
        }.joined(separator: "|")
    }
}

struct CompactOverviewAccountGridView: View {
    static let columnCount = 2

    let model: CompactOverviewAccountGridModel
    let width: CGFloat
    @Environment(\.menuItemHighlighted) private var isHighlighted

    var body: some View {
        LazyVGrid(
            columns: Array(
                repeating: GridItem(.flexible(minimum: 0), spacing: 8, alignment: .topLeading),
                count: Self.columnCount),
            alignment: .leading,
            spacing: 8)
        {
            ForEach(self.model.cards) { card in
                self.card(card)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .frame(width: self.width, alignment: .leading)
    }

    private func card(_ card: CompactOverviewAccountGridModel.Card) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            self.cardHeader(card)

            Text(card.identityText)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(MenuHighlightStyle.primary(self.isHighlighted))
                .lineLimit(1)
                .truncationMode(.middle)
                .help(card.identityText)

            if let statusText = card.statusText {
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(card.statusIsError
                        ? Color(nsColor: .systemRed)
                        : MenuHighlightStyle.secondary(self.isHighlighted))
                    .lineLimit(2)
            }

            ForEach(card.metrics) { metric in
                self.metric(metric, tint: card.progressColor)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.72))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(card.providerName), \(card.identityText)")
    }

    private func cardHeader(_ card: CompactOverviewAccountGridModel.Card) -> some View {
        HStack(alignment: .center, spacing: 7) {
            if let icon = ProviderBrandIcon.image(for: card.provider) {
                Image(nsImage: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 15, height: 15)
                    .foregroundStyle(MenuHighlightStyle.progressTint(
                        self.isHighlighted,
                        fallback: card.progressColor))
                    .accessibilityHidden(true)
            }
            Text(card.providerName)
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundStyle(MenuHighlightStyle.primary(self.isHighlighted))
                .lineLimit(1)
            Spacer(minLength: 0)
        }
    }

    private func metric(
        _ metric: UsageMenuCardView.Model.Metric,
        tint: Color) -> some View
    {
        VStack(alignment: .leading, spacing: 3) {
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

    private static func compactResetText(_ resetText: String) -> String {
        let parts = resetText.split(whereSeparator: { $0.isWhitespace })
        guard parts.count > 2 else { return resetText }
        return parts.suffix(2).joined(separator: " ")
    }
}
