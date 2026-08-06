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
    static let columnCount = 2

    struct Row: Identifiable {
        let id: String
        let cards: [Card]
    }

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
    let rows: [Row]
    let heightFingerprint: String

    init(providerModels: [CompactOverviewProviderCardModel]) {
        let cards = providerModels.flatMap { providerModel in
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
        self.cards = cards
        self.rows = stride(from: 0, to: cards.count, by: Self.columnCount).map { start in
            let end = min(start + Self.columnCount, cards.count)
            let rowCards = Array(cards[start..<end])
            return Row(
                id: rowCards.map(\.id).joined(separator: "|"),
                cards: rowCards)
        }
        self.heightFingerprint = providerModels.map { model in
            "\(model.provider.rawValue):\(model.heightFingerprint)"
        }.joined(separator: "|")
    }
}

struct CompactOverviewAccountGridView: View {
    nonisolated static var columnCount: Int {
        CompactOverviewAccountGridModel.columnCount
    }

    let model: CompactOverviewAccountGridModel
    let width: CGFloat
    @Environment(\.menuItemHighlighted) private var isHighlighted

    var body: some View {
        CompactOverviewPairedGridLayout(
            columnCount: Self.columnCount,
            horizontalSpacing: 8,
            verticalSpacing: 8)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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

private struct CompactOverviewPairedGridLayout: Layout {
    let columnCount: Int
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache _: inout Void) -> CGSize
    {
        let width = self.resolvedWidth(proposal: proposal, subviews: subviews)
        let rowHeights = self.rowHeights(width: width, subviews: subviews)
        let verticalSpacing = CGFloat(max(0, rowHeights.count - 1)) * self.verticalSpacing
        return CGSize(
            width: width,
            height: rowHeights.reduce(0, +) + verticalSpacing)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal _: ProposedViewSize,
        subviews: Subviews,
        cache _: inout Void)
    {
        let rowHeights = self.rowHeights(width: bounds.width, subviews: subviews)
        let columnWidth = self.columnWidth(for: bounds.width)
        var y = bounds.minY
        for (index, subview) in subviews.enumerated() {
            let row = index / self.columnCount
            let column = index % self.columnCount
            guard row < rowHeights.count else { continue }
            let x = bounds.minX + CGFloat(column) * (columnWidth + self.horizontalSpacing)
            subview.place(
                at: CGPoint(x: x, y: y),
                anchor: .topLeading,
                proposal: ProposedViewSize(width: columnWidth, height: rowHeights[row]))
            if column == self.columnCount - 1 || index == subviews.count - 1 {
                y += rowHeights[row] + self.verticalSpacing
            }
        }
    }

    private func resolvedWidth(proposal: ProposedViewSize, subviews: Subviews) -> CGFloat {
        if let width = proposal.width { return width }
        let widest = subviews.map { $0.sizeThatFits(.unspecified).width }.max() ?? 0
        return widest * CGFloat(self.columnCount) +
            CGFloat(max(0, self.columnCount - 1)) * self.horizontalSpacing
    }

    private func columnWidth(for width: CGFloat) -> CGFloat {
        let spacing = CGFloat(max(0, self.columnCount - 1)) * self.horizontalSpacing
        return max(0, (width - spacing) / CGFloat(max(1, self.columnCount)))
    }

    private func rowHeights(width: CGFloat, subviews: Subviews) -> [CGFloat] {
        let columnWidth = self.columnWidth(for: width)
        return stride(from: 0, to: subviews.count, by: self.columnCount).map { start in
            let end = min(start + self.columnCount, subviews.count)
            return subviews[start..<end].map {
                $0.sizeThatFits(ProposedViewSize(width: columnWidth, height: nil)).height
            }.max() ?? 0
        }
    }
}
