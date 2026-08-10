import AppKit
import CodexBarCore
import Foundation
import XCTest
@testable import CodexBar

/// Writes the real renderer's output onto a menu-bar-like backdrop so the drawing can be inspected
/// without installing the app. Skipped unless `CODEXBAR_GRID_SNAPSHOT_DIR` names a directory, so it
/// stays a development aid rather than a CI artifact producer.
@MainActor
final class MenuBarAccountGridSnapshotTests: XCTestCase {
    func test_writesGridSnapshotWhenRequested() throws {
        guard let directory = ProcessInfo.processInfo.environment["CODEXBAR_GRID_SNAPSHOT_DIR"] else {
            throw XCTSkip("Set CODEXBAR_GRID_SNAPSHOT_DIR to write a menu-bar grid snapshot.")
        }
        let grid = MenuBarAccountGrid(
            providerModels: [
                self.card(provider: .codex, rows: [[("secondary", 100.0)], [("secondary", 30.0)]]),
                self.card(
                    provider: .claude,
                    rows: [
                        [("primary", 51.0), ("secondary", 18.0)],
                        [("primary", 0.0), ("secondary", 80.0)],
                    ]),
            ],
            now: self.now)
        let rendered = try XCTUnwrap(MenuBarAccountGridRenderer.render(
            grid: grid,
            options: MenuBarAccountGridRenderOptions(barHeight: 24)))

        for (name, background) in [
            ("dark", NSColor(calibratedRed: 0.18, green: 0.44, blue: 0.66, alpha: 1)),
            ("light", NSColor(calibratedWhite: 0.90, alpha: 1)),
        ] {
            let tint: NSColor = name == "dark" ? .white : .black
            let url = URL(fileURLWithPath: directory)
                .appendingPathComponent("menubar-grid-\(name).png")
            try self.write(
                image: self.composite(rendered.image, background: background, tint: tint),
                to: url)
        }
        print("grid accessibility label: \(rendered.accessibilityLabel)")
    }

    // MARK: - Helpers

    private let now = Date(timeIntervalSince1970: 1_770_000_000)

    private func card(
        provider: UsageProvider,
        rows: [[(id: String, percent: Double)]]) -> CompactOverviewProviderCardModel
    {
        let reset = self.now.addingTimeInterval(7 * 24 * 3600)
        func model(_ metrics: [UsageMenuCardView.Model.Metric], email: String) -> UsageMenuCardView.Model {
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
        return CompactOverviewProviderCardModel(
            providerModel: model([], email: "provider"),
            accountModels: rows.enumerated().map { index, lanes in
                (
                    id: "account-\(index)",
                    model: model(
                        lanes.map { lane in
                            UsageMenuCardView.Model.Metric(
                                id: lane.id,
                                title: lane.id == "primary" ? "Session" : "Weekly",
                                percent: lane.percent,
                                percentStyle: .used,
                                resetText: nil,
                                resetsAt: lane.id == "secondary" ? reset : nil,
                                detailText: nil,
                                detailLeftText: nil,
                                detailRightText: nil,
                                pacePercent: nil,
                                paceOnTop: true)
                        },
                        email: "\(provider.rawValue)-\(index)@example.com"))
            })
    }

    /// Approximates how AppKit presents a template status-item image: the mask tinted for the bar's
    /// appearance, drawn over a desktop-colored strip.
    private func composite(_ image: NSImage, background: NSColor, tint: NSColor) -> NSImage {
        let padding: CGFloat = 12
        let size = NSSize(width: image.size.width + padding * 2, height: image.size.height)
        let output = NSImage(size: size)
        output.lockFocus()
        background.setFill()
        NSRect(origin: .zero, size: size).fill()
        let tinted = NSImage(size: image.size)
        tinted.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: image.size))
        tint.setFill()
        NSRect(origin: .zero, size: image.size).fill(using: .sourceAtop)
        tinted.unlockFocus()
        tinted.draw(in: NSRect(origin: NSPoint(x: padding, y: 0), size: image.size))
        output.unlockFocus()
        return output
    }

    private func write(image: NSImage, to url: URL) throws {
        let scale: CGFloat = 6 // Menu-bar type is tiny; upscale so the drawing can be inspected.
        let pixelSize = NSSize(width: image.size.width * scale, height: image.size.height * scale)
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(pixelSize.width),
            pixelsHigh: Int(pixelSize.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0)
        else {
            throw XCTSkip("Could not allocate a bitmap for the grid snapshot.")
        }
        rep.size = pixelSize
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        NSGraphicsContext.current?.imageInterpolation = .none
        image.draw(in: NSRect(origin: .zero, size: pixelSize))
        NSGraphicsContext.restoreGraphicsState()
        let data = try XCTUnwrap(rep.representation(using: .png, properties: [:]))
        try data.write(to: url)
    }
}
