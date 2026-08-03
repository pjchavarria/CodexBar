# Compact Multi-Account Overview

> Status: active — updated 2026-08-03

## Resume here

Finish the compact overview implementation, validate it at 310 points with synthetic account data, then merge future
upstream releases into the fork without spreading personalization into provider code.

## Current reality

- The repository is a fork of `steipete/CodexBar` with `origin` pointing to the fork and `upstream` pointing to the
  canonical project in the working checkout.
- CodexBar already owns account discovery, account-scoped quota snapshots, inline usage dashboards, refresh actions,
  settings, and provider submenus.
- The fork adds a presentation seam, a compact provider card, and account-to-card projection. It does not add another
  credential store, fetcher, parser, or chart data source.

## Direction

- Keep the merged menu fixed at `StatusItemController.menuCardBaseWidth` (310 points).
- Always open the merged multi-provider menu on Overview and omit the provider switcher.
- Stack every available Codex or Claude account within its provider section.
- Show Codex Weekly only; show Claude Session, Weekly, and Fable only, with Fable in yellow.
- Render one authoritative provider KPI/chart model after that provider's accounts, without dashboard detail lines.
  Never sum already-formatted account dashboards; true account aggregation must happen in typed usage data before
  currency, token totals, and accessibility text are formatted.
- Keep provider actions in the existing submenus and keep bottom Refresh, Settings, About, and Quit actions.
- Leave the status-item visualization unchanged until a later design decision.

## Upstream compatibility boundary

Fork-owned presentation behavior starts at `CodexBarPersonalization`,
`CompactOverviewProviderCard`, and `StatusItemController+CompactOverview`. Small call-site guards in menu/account refresh
code route into that boundary. Upstream provider/auth models stay authoritative and unchanged.

When updating from upstream, fetch and merge `upstream/main`, resolve only genuine overlaps, run the compact overview
layout proof plus the repository test/check commands, then inspect the synthetic dark-mode render before pushing.

## Next checkpoint

Run the freshly built fork with the user's real Codex and Claude accounts only after local tests and synthetic rendering
are clean; confirm account naming and whether the authoritative provider chart covers both accounts. If not, add typed
account-history aggregation rather than combining display values.

## Direction log

- 2026-08-03: User approved the compact multi-account mockup but required the implementation to retain the current
  menu width.
- 2026-08-03: Menu-bar visualization changes were explicitly deferred.
