import CodexBarCore
import Foundation

/// Fork-owned status-item content: one column per provider, one row per account, and every value in
/// its own lane so percentages and reset countdowns line up across rows instead of drifting with the
/// width of the value before them.
///
/// The model is deliberately layout-free strings. `MenuBarAccountGridRenderer` owns fonts, column
/// widths and drawing; keeping the two apart lets the composition be tested without AppKit.
struct MenuBarAccountGrid: Equatable {
    /// The menu bar gives two text lines at status-item type sizes. Providers with more accounts than
    /// that keep their first `maxRows` here; the overview menu remains the complete census.
    static let maxRows = 2

    static let missingValue = "–"

    struct Row: Equatable {
        /// One entry per lane, `nil` where this account has no value for that lane (rendered as a dash).
        let values: [String?]
        let reset: String?
        /// The instant `reset` was compacted from, kept so the refresh scheduler can wake on the same
        /// boundary this row displays rather than re-parsing the drawn text.
        let resetsAt: Date?
        let accessibilityLabel: String
    }

    struct Column: Equatable {
        let provider: UsageProvider
        let providerName: String
        let rows: [Row]

        var laneCount: Int {
            self.rows.map(\.values.count).max() ?? 0
        }

        var hasReset: Bool {
            self.rows.contains { $0.reset != nil }
        }
    }

    let columns: [Column]

    var rowCount: Int {
        self.columns.map(\.rows.count).max() ?? 0
    }

    var isEmpty: Bool {
        self.columns.allSatisfy(\.rows.isEmpty)
    }

    /// Every reset instant currently drawn on the bar. The grid shows a countdown per account on every
    /// row, so keeping the item truthful means waking for all of them — not for the one window the
    /// upstream single-provider modes happen to render.
    var resetDates: [Date] {
        self.columns.flatMap(\.rows).compactMap(\.resetsAt)
    }

    var accessibilityLabel: String {
        self.columns.flatMap { column in
            column.rows.map { "\(column.providerName) \($0.accessibilityLabel)" }
        }.joined(separator: ", ")
    }

    /// Compact render key: every string that can change a drawn pixel, and nothing else.
    var signature: String {
        self.columns.map { column in
            let rows = column.rows.map { row in
                row.values.map { $0 ?? Self.missingValue }.joined(separator: ",") + ";" + (row.reset ?? "")
            }.joined(separator: "/")
            return "\(column.provider.rawValue)=\(rows)"
        }.joined(separator: "|")
    }
}

extension MenuBarAccountGrid {
    /// Lanes a provider contributes to the bar, in display order.
    ///
    /// Codex publishes one weekly quota; Claude publishes a session quota and a weekly quota, which is
    /// why its column is one lane wider. Fable and other extra Claude windows stay in the overview —
    /// the bar carries the two quotas that gate whether work can start right now.
    static func laneIDs(for provider: UsageProvider) -> [String] {
        switch provider {
        case .codex: ["secondary"]
        case .claude: ["primary", "secondary"]
        default: ["primary"]
        }
    }

    /// Largest-unit countdown sized for a status item: `7d`, `23h`, `14m`, `now`.
    ///
    /// The card's own reset line stays a localized sentence. Compacting it here from the concrete
    /// instant — rather than from that sentence — keeps the bar correct in every locale.
    static func compactReset(from date: Date?, now: Date) -> String? {
        guard let date else { return nil }
        let seconds = date.timeIntervalSince(now)
        // Same bare token `UsageFormatter.resetCountdownDescription` uses, so the bar and the card
        // speak one countdown vocabulary.
        guard seconds > 0 else { return "now" }
        let totalMinutes = max(1, Int(ceil(seconds / 60)))
        let days = totalMinutes / (24 * 60)
        if days > 0 { return "\(days)d" }
        let hours = totalMinutes / 60
        if hours > 0 { return "\(hours)h" }
        return "\(totalMinutes)m"
    }

    /// How long until `compactReset(from:now:)` would print something different for `date`.
    ///
    /// The countdown is largest-unit, so a `6d` row must not wake the bar every minute: its text only
    /// changes when the day bucket does. Minute ticks are real only inside the final hour, which is
    /// exactly where this returns them.
    static func compactResetChangeDelay(for date: Date, now: Date) -> TimeInterval? {
        let remaining = date.timeIntervalSince(now)
        guard remaining > 0 else { return nil }
        let minutes = max(1, Int(ceil(remaining / 60)))
        let bucket = if minutes >= 24 * 60 { 24 * 60 } else if minutes >= 60 { 60 } else { 1 }
        // The text changes the moment the displayed minute count drops below this bucket's floor.
        let nextMinutes = max(0, (minutes / bucket) * bucket - 1)
        return remaining - TimeInterval(nextMinutes * 60)
    }

    init(providerModels: [CompactOverviewProviderCardModel], now: Date) {
        self.columns = providerModels.compactMap { providerModel in
            let lanes = Self.laneIDs(for: providerModel.provider)
            let rows = providerModel.accounts.prefix(Self.maxRows).map { account in
                Self.row(account: account, lanes: lanes, now: now)
            }
            guard !rows.isEmpty else { return nil }
            return Column(
                provider: providerModel.provider,
                providerName: providerModel.providerName,
                rows: Array(rows))
        }
    }

    private static func row(
        account: CompactOverviewProviderCardModel.Account,
        lanes: [String],
        now: Date)
        -> Row
    {
        let metrics = Dictionary(
            account.metrics.map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first })
        let values = lanes.map { lane -> String? in
            guard let metric = metrics[lane], metric.statusText == nil else { return nil }
            return UsageFormatter.percentString(metric.percent)
        }
        // The reset belongs to the last lane: the weekly window for both providers that publish one.
        // A session countdown would tick every minute and re-render the whole item for a number the
        // percentages already imply.
        let resetsAt = lanes.last.flatMap { metrics[$0] }?.resetsAt
        let reset = Self.compactReset(from: resetsAt, now: now)
        return Row(
            values: values,
            reset: reset,
            resetsAt: reset == nil ? nil : resetsAt,
            accessibilityLabel: Self.accessibilityLabel(
                account: account,
                lanes: lanes,
                metrics: metrics,
                values: values,
                reset: reset))
    }

    private static func accessibilityLabel(
        account: CompactOverviewProviderCardModel.Account,
        lanes: [String],
        metrics: [String: UsageMenuCardView.Model.Metric],
        values: [String?],
        reset: String?)
        -> String
    {
        var parts = [account.identityText]
        for (lane, value) in zip(lanes, values) {
            let title = metrics[lane]?.title ?? lane
            guard let value else {
                parts.append(L("%@ unavailable", title))
                continue
            }
            parts.append("\(title) \(value)")
        }
        if let reset {
            parts.append(L("Resets %@", reset))
        }
        return parts.joined(separator: ", ")
    }
}
