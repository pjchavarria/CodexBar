import CodexBarCore
import Foundation
import XCTest
@testable import CodexBar

/// The account grid draws a countdown on every account row, so the menu-bar refresh timer has to wake on
/// those boundaries — not on the single window the upstream display modes schedule. These cover the
/// schedule seam directly: the boundary arithmetic, and the delay the controller derives from it.
final class MenuBarAccountGridCountdownTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_770_000_000)

    // MARK: - Boundary arithmetic

    /// The delay must land exactly on the text change: one second earlier still reads the old value.
    func test_changeDelayLandsOnTheInstantTheCompactTextChanges() throws {
        let remainingSeconds: [TimeInterval] = [
            30, 59, 60, 61, 90 * 60, 3600, 3599, 24 * 3600, 25 * 3600,
            7 * 24 * 3600, 7 * 24 * 3600 + 137,
        ]
        for remaining in remainingSeconds {
            let reset = self.now.addingTimeInterval(remaining)
            let before = MenuBarAccountGrid.compactReset(from: reset, now: self.now)
            let delay = try XCTUnwrap(
                MenuBarAccountGrid.compactResetChangeDelay(for: reset, now: self.now),
                "no boundary for \(remaining)s")

            XCTAssertNotEqual(
                MenuBarAccountGrid.compactReset(from: reset, now: self.now.addingTimeInterval(delay)),
                before,
                "text did not change after \(delay)s with \(remaining)s remaining")
            XCTAssertEqual(
                MenuBarAccountGrid.compactReset(
                    from: reset,
                    now: self.now.addingTimeInterval(delay - 1)),
                before,
                "text changed early with \(remaining)s remaining")
        }
    }

    /// Largest-unit text means a week-away reset costs one wake per day, not one per minute. Minute
    /// ticks are only real inside the final hour.
    func test_farAwayResetsWakeOnTheirOwnUnitInsteadOfEveryMinute() throws {
        let week = try XCTUnwrap(MenuBarAccountGrid.compactResetChangeDelay(
            for: self.now.addingTimeInterval(7 * 24 * 3600),
            now: self.now))
        XCTAssertEqual(week, 60, accuracy: 1) // "7d" → "6d" one minute later (7d is a bucket floor).

        let midWeek = try XCTUnwrap(MenuBarAccountGrid.compactResetChangeDelay(
            for: self.now.addingTimeInterval(6.5 * 24 * 3600),
            now: self.now))
        XCTAssertEqual(midWeek, 12 * 3600 + 60, accuracy: 1) // Next day boundary, not the next minute.

        let hours = try XCTUnwrap(MenuBarAccountGrid.compactResetChangeDelay(
            for: self.now.addingTimeInterval(5 * 3600 + 1800),
            now: self.now))
        XCTAssertEqual(hours, 1800 + 60, accuracy: 1) // "5h" holds until the hour bucket drops.

        let minutes = try XCTUnwrap(MenuBarAccountGrid.compactResetChangeDelay(
            for: self.now.addingTimeInterval(14 * 60 + 20),
            now: self.now))
        XCTAssertEqual(minutes, 20, accuracy: 1) // Final hour ticks per displayed minute.
    }

    func test_changeDelayIsAbsentForResetsThatHaveAlreadyPassed() {
        XCTAssertNil(MenuBarAccountGrid.compactResetChangeDelay(for: self.now, now: self.now))
        XCTAssertNil(MenuBarAccountGrid.compactResetChangeDelay(
            for: self.now.addingTimeInterval(-60),
            now: self.now))
    }

    // MARK: - Controller schedule seam

    /// Accounts on different reset cycles are the whole reason the grid exists; the timer has to follow
    /// the soonest of them rather than whichever provider happens to be primary.
    func test_scheduleDelayFollowsTheSoonestRowAcrossProviders() throws {
        let delay = try XCTUnwrap(StatusItemController.menuBarAccountGridRefreshDelay(
            resetDates: [
                self.now.addingTimeInterval(6 * 24 * 3600), // Wakes at the next day boundary.
                self.now.addingTimeInterval(9 * 60 + 30), // Wakes in 30s.
                self.now.addingTimeInterval(2 * 24 * 3600),
            ],
            now: self.now))
        XCTAssertEqual(delay, 30, accuracy: 1)
    }

    func test_scheduleDelayIsAbsentWithoutDrawnCountdowns() {
        XCTAssertNil(StatusItemController.menuBarAccountGridRefreshDelay(resetDates: [], now: self.now))
        XCTAssertNil(StatusItemController.menuBarAccountGridRefreshDelay(
            resetDates: [self.now.addingTimeInterval(-3600)],
            now: self.now))
    }

    /// The scheduler reads `resetDates`, so a row that draws a countdown must publish its instant and a
    /// row that draws none must not — otherwise the bar wakes for text it never shows.
    @MainActor
    func test_gridPublishesOneResetDatePerDrawnCountdown() {
        let weekly = self.now.addingTimeInterval(3 * 24 * 3600)
        let session = self.now.addingTimeInterval(90 * 60)
        let grid = MenuBarAccountGrid(
            providerModels: [
                self.card(
                    provider: .claude,
                    accounts: [
                        [
                            self.metric(id: "primary", percent: 51, resetsAt: session),
                            self.metric(id: "secondary", percent: 18, resetsAt: weekly),
                        ],
                        // Weekly window present but without a reset instant: no countdown to schedule.
                        [self.metric(id: "secondary", percent: 80, resetsAt: nil)],
                    ]),
            ],
            now: self.now)

        XCTAssertEqual(grid.columns[0].rows.map(\.reset), ["3d", nil])
        // Only the weekly lane draws, so the session reset must not arm the timer.
        XCTAssertEqual(grid.resetDates, [weekly])
    }

    // MARK: - Fixtures

    private func metric(
        id: String,
        percent: Double,
        resetsAt: Date?) -> UsageMenuCardView.Model.Metric
    {
        UsageMenuCardView.Model.Metric(
            id: id,
            title: id == "primary" ? "Session" : "Weekly",
            percent: percent,
            percentStyle: .used,
            resetText: nil,
            resetsAt: resetsAt,
            detailText: nil,
            detailLeftText: nil,
            detailRightText: nil,
            pacePercent: nil,
            paceOnTop: true)
    }

    @MainActor
    private func card(
        provider: UsageProvider,
        accounts: [[UsageMenuCardView.Model.Metric]]) -> CompactOverviewProviderCardModel
    {
        func model(_ metrics: [UsageMenuCardView.Model.Metric], email: String) -> UsageMenuCardView.Model {
            UsageMenuCardView.Model(
                provider: provider,
                providerName: "Claude",
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
        return CompactOverviewProviderCardModel(
            providerModel: model([], email: "provider"),
            accountModels: accounts.enumerated().map { index, metrics in
                (id: "account-\(index)", model: model(metrics, email: "account-\(index)@example.com"))
            })
    }
}
