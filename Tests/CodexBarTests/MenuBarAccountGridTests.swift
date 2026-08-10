import AppKit
import CodexBarCore
import Foundation
import XCTest
@testable import CodexBar

/// Composition and column alignment for the status-item account grid. The renderer's measurement is
/// exercised directly instead of through a live `NSStatusBar`, per the project's preference for
/// stable model seams over headless AppKit status-item flows.
@MainActor
final class MenuBarAccountGridTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_770_000_000)

    // MARK: - Fixtures

    private func metric(
        id: String,
        title: String,
        percent: Double,
        resetsAt: Date? = nil,
        statusText: String? = nil) -> UsageMenuCardView.Model.Metric
    {
        UsageMenuCardView.Model.Metric(
            id: id,
            title: title,
            percent: percent,
            percentStyle: .used,
            statusText: statusText,
            resetText: nil,
            resetsAt: resetsAt,
            detailText: nil,
            detailLeftText: nil,
            detailRightText: nil,
            pacePercent: nil,
            paceOnTop: true)
    }

    private func model(
        provider: UsageProvider,
        email: String,
        metrics: [UsageMenuCardView.Model.Metric]) -> UsageMenuCardView.Model
    {
        UsageMenuCardView.Model(
            provider: provider,
            providerName: provider == .claude ? "Claude" : "Codex",
            email: email,
            subtitleText: "Updated now",
            subtitleStyle: .info,
            planText: nil,
            metrics: metrics,
            usageNotes: [],
            openAIAPIUsage: nil,
            inlineUsageDashboard: nil,
            creditsText: nil,
            creditsRemaining: nil,
            creditsProgressPercent: nil,
            creditsScaleText: nil,
            creditsHintText: nil,
            creditsHintCopyText: nil,
            providerCost: nil,
            tokenUsage: nil,
            placeholder: nil,
            progressColor: UsageMenuCardView.Model.progressColor(for: provider))
    }

    private func providerCard(
        provider: UsageProvider,
        accounts: [(email: String, metrics: [UsageMenuCardView.Model.Metric])])
        -> CompactOverviewProviderCardModel
    {
        let providerModel = self.model(provider: provider, email: "provider", metrics: [])
        return CompactOverviewProviderCardModel(
            providerModel: providerModel,
            accountModels: accounts.enumerated().map { index, account in
                (
                    id: "account-\(index)",
                    model: self.model(
                        provider: provider,
                        email: account.email,
                        metrics: account.metrics))
            })
    }

    /// Two Codex accounts (weekly only) beside two Claude accounts (session + weekly).
    private func standardGrid() -> MenuBarAccountGrid {
        let weeklyReset = self.now.addingTimeInterval(7 * 24 * 3600)
        let codex = self.providerCard(provider: .codex, accounts: [
            (email: "codex-one@example.com", metrics: [
                self.metric(id: "secondary", title: "Weekly", percent: 100, resetsAt: weeklyReset),
            ]),
            (email: "codex-two@example.com", metrics: [
                self.metric(id: "secondary", title: "Weekly", percent: 30, resetsAt: weeklyReset),
            ]),
        ])
        let claude = self.providerCard(provider: .claude, accounts: [
            (email: "claude-one@example.com", metrics: [
                self.metric(id: "primary", title: "Session", percent: 51),
                self.metric(id: "secondary", title: "Weekly", percent: 18, resetsAt: weeklyReset),
            ]),
            (email: "claude-two@example.com", metrics: [
                self.metric(id: "primary", title: "Session", percent: 0),
                self.metric(id: "secondary", title: "Weekly", percent: 80, resetsAt: weeklyReset),
            ]),
        ])
        return MenuBarAccountGrid(providerModels: [codex, claude], now: self.now)
    }

    // MARK: - Composition

    func test_gridKeepsOneColumnPerProviderAndOneRowPerAccount() {
        let grid = self.standardGrid()
        XCTAssertEqual(grid.columns.map(\.provider), [.codex, .claude])
        XCTAssertEqual(grid.columns.map(\.rows.count), [2, 2])
        XCTAssertEqual(grid.rowCount, 2)
    }

    func test_codexShowsWeeklyOnlyAndClaudeShowsSessionThenWeekly() {
        let grid = self.standardGrid()
        XCTAssertEqual(grid.columns[0].rows.map(\.values), [["100%"], ["30%"]])
        XCTAssertEqual(grid.columns[1].rows.map(\.values), [["51%", "18%"], ["0%", "80%"]])
    }

    func test_valuesStayInSeparateLanesInsteadOfOneJoinedString() {
        let grid = self.standardGrid()
        for row in grid.columns[1].rows {
            XCTAssertEqual(row.values.count, 2)
            XCTAssertFalse(row.values.compactMap(\.self).contains { $0.contains("/") })
        }
    }

    func test_resetComesFromTheWeeklyLaneAndIsCompact() {
        let grid = self.standardGrid()
        XCTAssertEqual(grid.columns.flatMap { $0.rows.map(\.reset) }, ["7d", "7d", "7d", "7d"])
    }

    func test_compactResetUsesTheLargestUnit() {
        XCTAssertEqual(
            MenuBarAccountGrid.compactReset(from: self.now.addingTimeInterval(7 * 24 * 3600), now: self.now),
            "7d")
        XCTAssertEqual(
            MenuBarAccountGrid.compactReset(from: self.now.addingTimeInterval(5 * 3600), now: self.now),
            "5h")
        XCTAssertEqual(
            MenuBarAccountGrid.compactReset(from: self.now.addingTimeInterval(14 * 60), now: self.now),
            "14m")
        XCTAssertEqual(MenuBarAccountGrid.compactReset(from: self.now, now: self.now), "now")
        XCTAssertNil(MenuBarAccountGrid.compactReset(from: nil, now: self.now))
    }

    func test_accountWithoutUsageKeepsItsRowAndRendersADash() {
        let card = self.providerCard(provider: .codex, accounts: [
            (email: "healthy@example.com", metrics: [
                self.metric(id: "secondary", title: "Weekly", percent: 42),
            ]),
            (email: "failing@example.com", metrics: [
                self.metric(id: "secondary", title: "Weekly", percent: 0, statusText: "Login required"),
            ]),
        ])
        let grid = MenuBarAccountGrid(providerModels: [card], now: self.now)
        XCTAssertEqual(grid.columns[0].rows.count, 2)
        XCTAssertEqual(grid.columns[0].rows[1].values, [nil])
        let font = MenuBarAccountGridRenderer.font()
        XCTAssertEqual(
            MenuBarAccountGridRenderer.laneText(row: grid.columns[0].rows[1], lane: 0),
            MenuBarAccountGrid.missingValue)
        XCTAssertGreaterThan(
            MenuBarAccountGridRenderer.textWidth(MenuBarAccountGrid.missingValue, font: font),
            0)
    }

    func test_gridStopsAtTheTwoLinesTheMenuBarCanShow() {
        let card = self.providerCard(provider: .codex, accounts: (1...4).map { index in
            (
                email: "codex-\(index)@example.com",
                metrics: [self.metric(id: "secondary", title: "Weekly", percent: Double(index * 10))])
        })
        let grid = MenuBarAccountGrid(providerModels: [card], now: self.now)
        XCTAssertEqual(grid.columns[0].rows.count, MenuBarAccountGrid.maxRows)
        XCTAssertEqual(grid.columns[0].rows.map(\.values), [["10%"], ["20%"]])
    }

    func test_accessibilityLabelNamesEveryAccountLane() {
        let grid = self.standardGrid()
        let label = grid.accessibilityLabel
        XCTAssertTrue(label.contains("codex-one@example.com"))
        XCTAssertTrue(label.contains("claude-two@example.com"))
        XCTAssertTrue(label.contains("Session 51%"))
        XCTAssertTrue(label.contains("Weekly 18%"))
    }

    func test_signatureChangesWithValuesAndResets() {
        let grid = self.standardGrid()
        let same = self.standardGrid()
        XCTAssertEqual(grid.signature, same.signature)

        let later = MenuBarAccountGrid(
            providerModels: [self.providerCard(provider: .codex, accounts: [
                (email: "codex-one@example.com", metrics: [
                    self.metric(
                        id: "secondary",
                        title: "Weekly",
                        percent: 100,
                        resetsAt: self.now.addingTimeInterval(3600)),
                ]),
            ])],
            now: self.now)
        XCTAssertNotEqual(grid.signature, later.signature)
    }

    // MARK: - Column alignment

    func test_everyLaneGetsOneWidthSoRowsLineUp() {
        let grid = self.standardGrid()
        let font = MenuBarAccountGridRenderer.font()
        let claude = MenuBarAccountGridRenderer.measure(column: grid.columns[1], font: font)
        XCTAssertEqual(claude.laneWidths.count, 2)
        // "51%" and "0%" share lane 0's width; the shorter value is padded, not shifted.
        let widest = grid.columns[1].rows
            .map { MenuBarAccountGridRenderer.textWidth($0.values[0] ?? "", font: font) }
            .max() ?? 0
        XCTAssertEqual(claude.laneWidths[0], widest)
    }

    func test_resetColumnStartsAtTheSameOffsetOnEveryRow() {
        let grid = self.standardGrid()
        let font = MenuBarAccountGridRenderer.font()
        let claude = MenuBarAccountGridRenderer.measure(column: grid.columns[1], font: font)
        // The reset is the last column, so its offset is the column width minus its own width. That
        // is row-independent by construction: prove the lane widths it rests on are row-independent.
        let laneTotal = claude.laneWidths.reduce(0, +)
            + MenuBarAccountGridRenderer.laneGap * CGFloat(claude.laneWidths.count - 1)
        XCTAssertEqual(
            claude.width,
            MenuBarAccountGridRenderer.iconSize
                + MenuBarAccountGridRenderer.iconGap
                + laneTotal
                + MenuBarAccountGridRenderer.resetGap
                + claude.resetWidth,
            accuracy: 0.001)
    }

    func test_claudeColumnIsWiderThanCodexBecauseItCarriesTwoLanes() {
        let grid = self.standardGrid()
        let font = MenuBarAccountGridRenderer.font()
        let codex = MenuBarAccountGridRenderer.measure(column: grid.columns[0], font: font)
        let claude = MenuBarAccountGridRenderer.measure(column: grid.columns[1], font: font)
        XCTAssertEqual(codex.laneWidths.count, 1)
        XCTAssertGreaterThan(claude.width, codex.width)
    }

    func test_renderProducesATemplateImageThatFitsTheMenuBar() throws {
        let grid = self.standardGrid()
        let options = MenuBarAccountGridRenderOptions(barHeight: 24)
        let rendered = try XCTUnwrap(MenuBarAccountGridRenderer.render(grid: grid, options: options))
        XCTAssertTrue(rendered.image.isTemplate)
        XCTAssertEqual(rendered.image.size.height, 24)
        XCTAssertGreaterThan(rendered.image.size.width, 0)
        let font = MenuBarAccountGridRenderer.font()
        let expected = MenuBarAccountGridRenderer.totalWidth(
            grid.columns.map { MenuBarAccountGridRenderer.measure(column: $0, font: font) })
        XCTAssertEqual(rendered.image.size.width, ceil(expected), accuracy: 0.001)
    }

    func test_renderReturnsNilForAnEmptyGrid() {
        let grid = MenuBarAccountGrid(providerModels: [], now: self.now)
        XCTAssertTrue(grid.isEmpty)
        XCTAssertNil(MenuBarAccountGridRenderer.render(
            grid: grid,
            options: MenuBarAccountGridRenderOptions(barHeight: 24)))
    }
}
