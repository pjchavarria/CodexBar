import AppKit
import CodexBarCore
import Foundation

extension StatusItemController {
    /// Fork status item: every monitored account, laid out as provider columns.
    ///
    /// Returns `nil` when the grid does not apply, so the caller falls through to the upstream
    /// single-provider rendering; otherwise returns whether this render was served from the cached
    /// signature, matching the other `applyIcon` paths.
    func applyMenuBarAccountGridIfNeeded(
        statusItem: NSStatusItem,
        warningFlash: Bool,
        now: Date = .init())
        -> Bool?
    {
        guard CodexBarPersonalization.menuBarAccountGridEnabled, let button = statusItem.button else {
            // Nothing of ours is on the item, so it must not keep arming the refresh timer.
            self.menuBarAccountGridResetDates = []
            return nil
        }
        let providerModels = self.compactOverviewProviderCardModels()
        let grid = MenuBarAccountGrid(providerModels: providerModels, now: now)
        guard !grid.isEmpty else {
            self.menuBarAccountGridResetDates = []
            return nil
        }
        // Hand the drawn countdowns to the refresh scheduler before the cache check, so a render served
        // from the cached signature still keeps its wake boundaries armed.
        self.menuBarAccountGridResetDates = grid.resetDates

        let options = MenuBarAccountGridRenderOptions(barHeight: self.statusBar.thickness)
        let signature = [
            "mode=accountGrid",
            grid.signature,
            "bar=\(Int(options.barHeight.rounded()))",
            "gap=\(self.settings.menuBarLayoutGap.rawValue)",
            "highContrast=\(self.shouldUseHighContrastStatusItemContent ? "1" : "0")",
            "warningFlash=\(warningFlash ? "1" : "0")",
        ].joined(separator: "|")
        let hasContent = button.image != nil || button.attributedTitle.length > 0
        if self.lastAppliedMergedIconRenderSignature == signature, hasContent {
            self.noteIconPerfRender(skipped: true)
            return true
        }

        guard let rendered = MenuBarAccountGridRenderer.render(grid: grid, options: options) else {
            // Nothing drawable: the upstream renderer takes the item, so its countdowns own the timer.
            self.menuBarAccountGridResetDates = []
            return nil
        }
        self.lastAppliedMergedIconRenderSignature = signature
        let image = warningFlash ? Self.quotaWarningFlashImage(base: rendered.image) : rendered.image
        self.setButtonContent(image: image, title: nil, for: button)
        if button.accessibilityTitle() != rendered.accessibilityLabel {
            button.setAccessibilityTitle(rendered.accessibilityLabel)
        }
        // AppKit only self-sizes a status item around its title; an image needs an explicit length.
        // `setButtonContent` appends the debug marker as a title, so leave room for it too.
        let horizontalPadding: CGFloat = self.settings.menuBarLayoutGap == .tight ? 3 : 10
        let titleWidth = button.title.isEmpty
            ? 0
            : ceil(NSAttributedString(
                string: button.title,
                attributes: [.font: NSFont.systemFont(ofSize: NSFont.systemFontSize)]).size().width)
        statusItem.length = max(18, ceil(image.size.width) + titleWidth + horizontalPadding)
        self.noteIconPerfRender(skipped: false)
        return false
    }
}
