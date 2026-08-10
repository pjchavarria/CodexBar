import AppKit
import CodexBarCore
import Foundation

struct MenuBarAccountGridRenderOptions: Hashable {
    let barHeight: CGFloat
}

struct MenuBarAccountGridRenderedItem {
    let image: NSImage
    let accessibilityLabel: String
}

/// Draws `MenuBarAccountGrid` into a single template image.
///
/// An `NSAttributedString` title can stack two lines but has no column concept, so percentages and
/// countdowns would drift with the width of whatever precedes them. Measuring each lane here and
/// drawing its values right-aligned in a shared column is what makes the rows line up, and it keeps
/// status-item drawing in the same place `IconRenderer` already does it.
@MainActor
enum MenuBarAccountGridRenderer {
    /// Provider mark at the single-line item's icon size rather than the 9pt stacked type: one mark
    /// per provider can afford to stay recognizable.
    static let iconSize: CGFloat = 16
    static let fontSize: CGFloat = 9
    static let lineHeight: CGFloat = 10
    static let iconGap: CGFloat = 3
    static let laneGap: CGFloat = 5
    static let resetGap: CGFloat = 5
    static let providerGap: CGFloat = 9

    struct MeasuredColumn {
        let column: MenuBarAccountGrid.Column
        let laneWidths: [CGFloat]
        let resetWidth: CGFloat
        let width: CGFloat
    }

    static func font() -> NSFont {
        // Monospaced digits keep a column's width constant as its value changes, so a percentage
        // ticking 9% → 10% cannot nudge everything to its right.
        NSFont.monospacedDigitSystemFont(ofSize: self.fontSize, weight: .medium)
    }

    static func measure(column: MenuBarAccountGrid.Column, font: NSFont) -> MeasuredColumn {
        let laneWidths = (0..<column.laneCount).map { lane in
            column.rows.map { self.textWidth(self.laneText(row: $0, lane: lane), font: font) }.max() ?? 0
        }
        let resetWidth = column.rows.map { self.textWidth($0.reset ?? "", font: font) }.max() ?? 0
        var width = self.iconSize + self.iconGap
        width += laneWidths.reduce(0, +)
        width += self.laneGap * CGFloat(max(0, laneWidths.count - 1))
        if resetWidth > 0 {
            width += self.resetGap + resetWidth
        }
        return MeasuredColumn(
            column: column,
            laneWidths: laneWidths,
            resetWidth: resetWidth,
            width: width)
    }

    static func totalWidth(_ columns: [MeasuredColumn]) -> CGFloat {
        columns.reduce(0) { $0 + $1.width } + self.providerGap * CGFloat(max(0, columns.count - 1))
    }

    static func render(
        grid: MenuBarAccountGrid,
        options: MenuBarAccountGridRenderOptions)
        -> MenuBarAccountGridRenderedItem?
    {
        guard !grid.isEmpty else { return nil }
        let font = self.font()
        let columns = grid.columns.map { self.measure(column: $0, font: font) }
        guard !columns.isEmpty else { return nil }
        let size = NSSize(width: ceil(self.totalWidth(columns)), height: options.barHeight)

        let image = NSImage(size: size)
        image.lockFocus()
        var x: CGFloat = 0
        for column in columns {
            self.draw(column: column, originX: x, size: size, font: font)
            x += column.width + self.providerGap
        }
        image.unlockFocus()
        image.isTemplate = true
        return MenuBarAccountGridRenderedItem(
            image: image,
            accessibilityLabel: grid.accessibilityLabel)
    }

    static func laneText(row: MenuBarAccountGrid.Row, lane: Int) -> String {
        guard lane < row.values.count else { return "" }
        return row.values[lane] ?? MenuBarAccountGrid.missingValue
    }

    static func textWidth(_ text: String, font: NSFont) -> CGFloat {
        guard !text.isEmpty else { return 0 }
        return ceil(NSAttributedString(string: text, attributes: [.font: font]).size().width)
    }

    // MARK: - Drawing

    private static func draw(
        column measured: MeasuredColumn,
        originX: CGFloat,
        size: NSSize,
        font: NSFont)
    {
        let column = measured.column
        let blockHeight = self.lineHeight * CGFloat(max(1, column.rows.count))
        let top = (size.height + blockHeight) / 2

        if let icon = ProviderBrandIcon.image(for: column.provider) {
            let width = icon.size.height > 0
                ? icon.size.width * self.iconSize / icon.size.height
                : self.iconSize
            // One mark per provider, centered on the whole account block instead of repeated per row.
            self.drawIcon(icon, rect: NSRect(
                x: originX,
                y: (size.height - self.iconSize) / 2,
                width: width,
                height: self.iconSize))
        }

        for (index, row) in column.rows.enumerated() {
            let y = top - self.lineHeight * CGFloat(index + 1)
            var x = originX + self.iconSize + self.iconGap
            for (lane, laneWidth) in measured.laneWidths.enumerated() {
                self.draw(
                    self.laneText(row: row, lane: lane),
                    font: font,
                    rect: NSRect(x: x, y: y, width: laneWidth, height: self.lineHeight),
                    alignment: .right)
                x += laneWidth + self.laneGap
            }
            guard measured.resetWidth > 0 else { continue }
            // The lane loop leaves `x` one lane gap past the last value; the reset column owns its own.
            x += self.resetGap - self.laneGap
            self.draw(
                row.reset ?? "",
                font: font,
                rect: NSRect(x: x, y: y, width: measured.resetWidth, height: self.lineHeight),
                alignment: .right)
        }
    }

    private static func drawIcon(_ icon: NSImage, rect: NSRect) {
        guard icon.isTemplate else {
            icon.draw(in: rect)
            return
        }
        // A template image drawn into another image does not receive AppKit's tint. Draw its mask in
        // black so the status item's own template treatment can invert it with the rest of the grid.
        let mask = NSImage(size: rect.size)
        mask.lockFocus()
        let bounds = NSRect(origin: .zero, size: rect.size)
        icon.draw(in: bounds)
        NSColor.black.setFill()
        bounds.fill(using: .sourceAtop)
        mask.unlockFocus()
        mask.draw(in: rect)
    }

    private static func draw(
        _ text: String,
        font: NSFont,
        rect: NSRect,
        alignment: NSTextAlignment)
    {
        guard !text.isEmpty else { return }
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment
        let attributed = NSAttributedString(string: text, attributes: [
            .font: font,
            .foregroundColor: NSColor.black,
            .paragraphStyle: paragraph,
        ])
        let textHeight = attributed.size().height
        attributed.draw(in: NSRect(
            x: rect.minX,
            y: rect.minY + ((rect.height - textHeight) / 2).rounded(),
            width: rect.width,
            height: textHeight))
    }
}
