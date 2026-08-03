import CodexBarCore
import SwiftUI

enum CompactOverviewDashboard {
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
    let model: InlineUsageDashboardModel
    let width: CGFloat

    var body: some View {
        InlineUsageDashboardContent(model: self.model, chartHeight: 42)
            .padding(.horizontal, UsageMenuCardLayout.horizontalPadding)
            .padding(.vertical, 10)
            .frame(width: self.width, alignment: .leading)
    }
}
