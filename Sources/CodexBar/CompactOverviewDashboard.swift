import CodexBarCore
import SwiftUI

struct CompactOverviewDashboardModel {
    struct ProviderSeries: Identifiable {
        let provider: UsageProvider
        let providerName: String
        let color: Color
        let points: [InlineUsageDashboardModel.Point]

        var id: String {
            self.provider.rawValue
        }
    }

    struct Day: Identifiable {
        struct Segment: Identifiable {
            let provider: UsageProvider
            let providerName: String
            let value: Double
            let color: Color

            var id: String {
                self.provider.rawValue
            }
        }

        let id: String
        let label: String
        let segments: [Segment]
        let total: Double
        let accessibilityValue: String
    }

    let aggregate: InlineUsageDashboardModel
    let providerSeries: [ProviderSeries]
    let days: [Day]

    var heightFingerprint: String {
        let kpis = self.aggregate.kpis.map { "\($0.title)=\($0.value)" }.joined(separator: "|")
        let providers = self.providerSeries.map { "\($0.id)=\($0.providerName)" }.joined(separator: "|")
        return "\(kpis)|providers=\(providers)|days=\(self.days.count)"
    }
}

enum CompactOverviewDashboard {
    struct Input {
        let provider: UsageProvider
        let providerName: String
        let dashboard: InlineUsageDashboardModel
    }

    private struct Source {
        let provider: UsageProvider
        let providerName: String
        let dashboard: InlineUsageDashboardModel
        let aggregation: InlineUsageDashboardModel.CostAggregation
    }

    static func aggregate(_ inputs: [Input]) -> CompactOverviewDashboardModel? {
        let sources = inputs.compactMap { input -> Source? in
            guard let aggregation = input.dashboard.costAggregation else { return nil }
            return Source(
                provider: input.provider,
                providerName: input.providerName,
                dashboard: input.dashboard,
                aggregation: aggregation)
        }
        guard let aggregate = self.aggregate(sources.map(\.dashboard)),
              let currencyCode = aggregate.currencyCode
        else { return nil }

        let providerSeries = sources.map { source in
            CompactOverviewDashboardModel.ProviderSeries(
                provider: source.provider,
                providerName: source.providerName,
                color: UsageMenuCardView.Model.inlineDashboardBarColor(for: source.provider),
                points: self.aggregatePoints(source.aggregation.points, currencyCode: currencyCode))
        }
        let pointIDs = Set(providerSeries.flatMap { $0.points.map(\.id) })
        let days = pointIDs.sorted().map { id in
            let segments = providerSeries.map { series in
                CompactOverviewDashboardModel.Day.Segment(
                    provider: series.provider,
                    providerName: series.providerName,
                    value: series.points.first(where: { $0.id == id })?.value ?? 0,
                    color: series.color)
            }
            let total = segments.reduce(0) { $0 + $1.value }
            let label = providerSeries.lazy.compactMap { series in
                series.points.first(where: { $0.id == id })?.label
            }.first ?? id
            let breakdown = segments.map {
                "\($0.providerName): \(UsageFormatter.currencyString($0.value, currencyCode: currencyCode))"
            }.joined(separator: ", ")
            return CompactOverviewDashboardModel.Day(
                id: id,
                label: label,
                segments: segments,
                total: total,
                accessibilityValue: "\(label): " +
                    "\(UsageFormatter.currencyString(total, currencyCode: currencyCode)). \(breakdown)")
        }
        return CompactOverviewDashboardModel(
            aggregate: aggregate,
            providerSeries: providerSeries,
            days: days)
    }

    static func aggregate(_ dashboards: [InlineUsageDashboardModel]) -> InlineUsageDashboardModel? {
        let sources = dashboards.compactMap(\.costAggregation)
        guard !sources.isEmpty,
              Set(sources.map(\.currencyCode)).count == 1,
              Set(sources.map(\.historyDays)).count == 1,
              let currencyCode = sources.first?.currencyCode,
              let historyDays = sources.first?.historyDays
        else { return nil }

        let points = self.aggregatePoints(sources.flatMap(\.points), currencyCode: currencyCode)
        let todayCost = self.completeCostSum(sources.map(\.todayCost))
        let historyCost = self.completeCostSum(sources.map(\.historyCost))
        let latestTokens = self.completeTokenSum(sources.map(\.latestTokens))
        let historyTokens = self.completeTokenSum(sources.map(\.historyTokens))
        let historyCostTitle = historyDays == 30
            ? L("30d cost")
            : String(format: L("Last %d days cost"), historyDays)
        let historyTokensTitle = historyDays == 30
            ? L("30d tokens")
            : String(format: L("Last %d days tokens"), historyDays)
        let costString: (Double?) -> String = { value in
            value.map { UsageFormatter.currencyString($0, currencyCode: currencyCode) } ?? "—"
        }
        let tokenString: (Int?) -> String = { value in
            value.map(UsageFormatter.tokenCountString) ?? "—"
        }
        let aggregation = InlineUsageDashboardModel.CostAggregation(
            currencyCode: currencyCode,
            historyDays: historyDays,
            todayCost: todayCost,
            historyCost: historyCost,
            latestTokens: latestTokens,
            historyTokens: historyTokens,
            points: points)
        return InlineUsageDashboardModel(
            accessibilityLabel: L("Combined account usage"),
            valueStyle: UsageMenuCardView.Model.costValueStyle(currencyCode: currencyCode),
            kpis: [
                .init(title: L("Today"), value: costString(todayCost), emphasis: true),
                .init(title: historyCostTitle, value: costString(historyCost), emphasis: false),
                .init(title: L("Latest tokens"), value: tokenString(latestTokens), emphasis: false),
                .init(title: historyTokensTitle, value: tokenString(historyTokens), emphasis: false),
            ],
            points: points,
            detailLines: [],
            currencyCode: currencyCode,
            costAggregation: aggregation)
    }

    private static func aggregatePoints(
        _ points: [InlineUsageDashboardModel.Point],
        currencyCode: String) -> [InlineUsageDashboardModel.Point]
    {
        let grouped = Dictionary(grouping: points, by: \.id)
        return grouped.keys.sorted().compactMap { id in
            guard let dayPoints = grouped[id] else { return nil }
            let value = dayPoints.reduce(0) { $0 + $1.value }
            return InlineUsageDashboardModel.Point(
                id: id,
                label: dayPoints.first?.label ?? id,
                value: value,
                accessibilityValue: "\(id): \(UsageFormatter.currencyString(value, currencyCode: currencyCode))")
        }
    }

    private static func completeCostSum(_ values: [Double?]) -> Double? {
        guard values.allSatisfy({ $0 != nil }) else { return nil }
        let total = values.compactMap(\.self).reduce(0, +)
        return total.isFinite ? total : nil
    }

    private static func completeTokenSum(_ values: [Int?]) -> Int? {
        guard values.allSatisfy({ $0 != nil }) else { return nil }
        var total = 0
        for value in values.compactMap(\.self) {
            let addition = total.addingReportingOverflow(value)
            guard !addition.overflow else { return nil }
            total = addition.partialValue
        }
        return total
    }
}

struct CompactOverviewDashboardView: View {
    let model: CompactOverviewDashboardModel
    let width: CGFloat
    @Environment(\.menuItemHighlighted) private var isHighlighted

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            self.kpiGrid
            self.legend
            self.stackedChart
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(width: self.width, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(self.model.aggregate.accessibilityLabel)
    }

    private var kpiGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(minimum: 100), alignment: .leading),
                GridItem(.flexible(minimum: 100), alignment: .leading),
            ],
            alignment: .leading,
            spacing: 6)
        {
            ForEach(Array(self.model.aggregate.kpis.enumerated()), id: \.offset) { _, kpi in
                self.kpi(kpi)
            }
        }
    }

    private func kpi(_ kpi: InlineUsageDashboardModel.KPI) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(kpi.title)
                .font(.caption2)
                .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                .lineLimit(1)
            Text(kpi.value)
                .font(kpi.emphasis ? .headline : .subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(MenuHighlightStyle.primary(self.isHighlighted))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var legend: some View {
        HStack(spacing: 8) {
            Spacer(minLength: 0)
            ForEach(self.model.providerSeries) { series in
                HStack(spacing: 3) {
                    Circle()
                        .fill(self.legendColor(series.color))
                        .frame(width: 5, height: 5)
                    Text(series.providerName)
                        .font(.caption2)
                        .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                        .lineLimit(1)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    private var stackedChart: some View {
        let scale = UsageChartScale(values: self.model.days.map(\.total))
        return VStack(alignment: .trailing, spacing: 2) {
            if let currencyCode = self.model.aggregate.currencyCode, scale.maximum > 0 {
                Text(UsageFormatter.compactCurrencyString(scale.maximum, currencyCode: currencyCode))
                    .font(.caption2)
                    .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                    .monospacedDigit()
                    .lineLimit(1)
            }
            GeometryReader { geometry in
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(self.model.days) { day in
                        VStack(spacing: 0) {
                            ForEach(day.segments.reversed()) { segment in
                                Rectangle()
                                    .fill(self.barColor(segment.color))
                                    .frame(height: self.segmentHeight(
                                        segment.value,
                                        scale: scale,
                                        available: geometry.size.height))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 1.5, style: .continuous))
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(day.accessibilityValue)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .overlay(alignment: .bottomLeading) {
                    Rectangle()
                        .fill(MenuHighlightStyle.secondary(self.isHighlighted).opacity(0.22))
                        .frame(height: 1)
                }
            }
            .frame(height: 42)
        }
    }

    private func segmentHeight(
        _ value: Double,
        scale: UsageChartScale,
        available: CGFloat) -> CGFloat
    {
        guard scale.maximum > 0, value.isFinite, value > 0 else { return 0 }
        return CGFloat(value / scale.maximum) * available
    }

    private func legendColor(_ color: Color) -> Color {
        self.isHighlighted ? .white : color
    }

    private func barColor(_ color: Color) -> Color {
        self.isHighlighted ? .white.opacity(0.8) : color
    }
}
