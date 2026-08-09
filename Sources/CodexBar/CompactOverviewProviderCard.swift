import AppKit
import CodexBarCore
import SwiftUI

struct CompactOverviewProviderCardModel {
    struct Account: Identifiable {
        let id: String
        let identityText: String
        let statusText: String?
        let statusIsError: Bool
        let refreshedText: String?
        let metrics: [UsageMenuCardView.Model.Metric]
        let hoverDetailLines: [String]
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
            let statusText = Self.accountStatusText(account.model)
            return Account(
                id: account.id,
                identityText: Self.accountIdentityText(account.model),
                statusText: statusText,
                statusIsError: account.model.subtitleStyle == .error,
                refreshedText: statusText == nil ? account.model.subtitleText : nil,
                metrics: metrics,
                hoverDetailLines: Self.hoverDetailLines(for: account.model))
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

    /// Cost/token lines revealed on hover. Reuses the exact strings the full card's Cost
    /// section renders so the compact grid never re-derives or re-formats spend data.
    /// Comparison-period and hint lines stay in the full card: they are opt-in context that
    /// does not fit a glanceable panel bounded by the card's own height. The two short cost
    /// pairs (spend + percent, balance + personal) share a line: the panel must fit the
    /// shortest card, whose interior holds five caption lines, not seven.
    static func hoverDetailLines(for model: UsageMenuCardView.Model) -> [String] {
        var lines: [String] = []
        if let tokenUsage = model.tokenUsage {
            lines.append(tokenUsage.sessionLine)
            lines.append(tokenUsage.monthLine)
            if let meteredLine = tokenUsage.meteredLine {
                lines.append(meteredLine)
            }
            if let errorLine = tokenUsage.errorLine {
                lines.append(errorLine)
            }
        }
        if let cost = model.providerCost {
            lines.append(Self.joined("\(cost.title): \(cost.spendLine)", cost.percentLine))
            if cost.balanceLine != nil || cost.personalSpendLine != nil {
                lines.append(Self.joined(cost.balanceLine, cost.personalSpendLine))
            }
        }
        return lines
    }

    private static func joined(_ first: String?, _ second: String?) -> String {
        [first, second].compactMap(\.self).joined(separator: " · ")
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
        let refreshedText: String?
        let metrics: [UsageMenuCardView.Model.Metric]
        let hoverDetailLines: [String]
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
                    refreshedText: account.refreshedText,
                    metrics: account.metrics,
                    hoverDetailLines: account.hoverDetailLines,
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

    /// Returns `fresh` when it can replace this baked grid inside an already-measured menu item
    /// without changing any row height; otherwise keeps the baked grid (the menu shows the fresh
    /// content on its next open, matching the full card's frozen-layout behavior).
    func preferringLive(_ fresh: CompactOverviewAccountGridModel?) -> CompactOverviewAccountGridModel {
        guard let fresh, self.isStructurallyCompatible(with: fresh) else { return self }
        return fresh
    }

    /// Same cards, same rendered line structure. Single-line values (identity, refreshed text,
    /// metric percents/resets, hover lines) may change freely; anything that could re-wrap or
    /// add/remove a row must match.
    func isStructurallyCompatible(with candidate: CompactOverviewAccountGridModel) -> Bool {
        guard self.cards.count == candidate.cards.count else { return false }
        return zip(self.cards, candidate.cards).allSatisfy { current, fresh in
            current.id == fresh.id &&
                current.identityText == fresh.identityText &&
                current.statusText == fresh.statusText &&
                (current.refreshedText == nil) == (fresh.refreshedText == nil) &&
                current.metrics.count == fresh.metrics.count &&
                zip(current.metrics, fresh.metrics).allSatisfy { lhs, rhs in
                    lhs.id == rhs.id &&
                        lhs.title == rhs.title &&
                        (lhs.statusText == nil) == (rhs.statusText == nil) &&
                        (lhs.resetText == nil) == (rhs.resetText == nil)
                }
        }
    }
}

struct CompactOverviewAccountGridView: View {
    nonisolated static var columnCount: Int {
        CompactOverviewAccountGridModel.columnCount
    }

    let model: CompactOverviewAccountGridModel
    let width: CGFloat
    /// Rebuilds the grid from live store state so an open menu can pick up completed refreshes
    /// through the observed `MenuCardRefreshMonitor` without an NSMenu rebuild.
    var resolveLiveModel: (@MainActor () -> CompactOverviewAccountGridModel?)?
    @Environment(\.menuItemHighlighted) private var isHighlighted
    @Environment(\.menuCardRefreshMonitor) private var refreshMonitor
    @State private var hoveredCardID: String?
    @State private var hoverRevealTask: Task<Void, Never>?
    @State private var pendingHoverCardID: String?

    init(
        model: CompactOverviewAccountGridModel,
        width: CGFloat,
        resolveLiveModel: (@MainActor () -> CompactOverviewAccountGridModel?)? = nil,
        initialHoveredCardID: String? = nil)
    {
        self.model = model
        self.width = width
        self.resolveLiveModel = resolveLiveModel
        self._hoveredCardID = State(initialValue: initialHoveredCardID)
    }

    /// Reading `isManualRefreshInFlight` registers this view with the monitor's observation, so
    /// refresh start ("Refreshing…") and completion (fresh grid) both re-render the open menu.
    private var displayModel: CompactOverviewAccountGridModel {
        guard let refreshMonitor else { return self.model }
        if refreshMonitor.isManualRefreshInFlight { return self.model }
        return self.model.preferringLive(self.resolveLiveModel?())
    }

    var body: some View {
        CompactOverviewPairedGridLayout(
            columnCount: Self.columnCount,
            horizontalSpacing: 8,
            verticalSpacing: 8)
        {
            ForEach(self.displayModel.cards) { card in
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
                        ? MenuHighlightStyle.error(self.isHighlighted)
                        : MenuHighlightStyle.secondary(self.isHighlighted))
                    .lineLimit(2)
            }

            ForEach(card.metrics) { metric in
                self.metric(metric, tint: card.progressColor)
            }

            if let refreshedText = card.refreshedText {
                Text(self.refreshMonitor?.isManualRefreshInFlight(for: card.provider) == true
                    ? "\(L("Refreshing"))…"
                    : refreshedText)
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                    .lineLimit(1)
                    .padding(.top, 3)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        // On hover the card content fades out but keeps its layout, and the detail lines render
        // inside the card's own fill. The clip sits on the card AFTER the overlay so no panel
        // pixel can cross the card's bounds, whatever height the line stack resolves to; the
        // stroke comes after the clip so the border stays crisp.
        .opacity(self.hoveredCardID == card.id && !card.hoverDetailLines.isEmpty ? 0 : 1)
        .background {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.72))
        }
        .overlay {
            if self.hoveredCardID == card.id, !card.hoverDetailLines.isEmpty {
                self.hoverDetailPanel(card)
                    .transition(.opacity)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        }
        .onHover { hovering in
            self.setHovered(card, hovering: hovering)
        }
        .help(card.hoverDetailLines.joined(separator: "\n"))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(card.providerName), \(card.identityText)")
        .accessibilityValue(card.hoverDetailLines.joined(separator: ", "))
    }

    /// Same-size cost/token reveal so the cached menu-item height never changes on hover.
    /// The lines render inside the card's own fill (the card content is faded out underneath),
    /// carry no repeated identity header, and center vertically in the card's footprint. The
    /// panel owns no fill, clip, or stroke — the card applies all three around it.
    private func hoverDetailPanel(_ card: CompactOverviewAccountGridModel.Card) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            ForEach(Array(card.hoverDetailLines.enumerated()), id: \.offset) { _, line in
                Text(line)
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(MenuHighlightStyle.primary(self.isHighlighted))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .accessibilityHidden(true)
    }

    private func setHovered(_ card: CompactOverviewAccountGridModel.Card, hovering: Bool) {
        if hovering {
            self.hoverRevealTask?.cancel()
            self.pendingHoverCardID = card.id
            // Short reveal delay so sweeping the cursor across the menu doesn't flip cards.
            self.hoverRevealTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 250_000_000)
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 0.12)) {
                    self.hoveredCardID = card.id
                }
            }
        } else {
            // Only this card's exit may cancel the pending reveal: sibling enter/exit events
            // have no guaranteed order, so an A-exit must not kill B's freshly scheduled task.
            if self.pendingHoverCardID == card.id {
                self.hoverRevealTask?.cancel()
                self.hoverRevealTask = nil
                self.pendingHoverCardID = nil
            }
            if self.hoveredCardID == card.id {
                withAnimation(.easeInOut(duration: 0.12)) {
                    self.hoveredCardID = nil
                }
            }
        }
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
