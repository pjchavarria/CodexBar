# Compact Multi-Account Overview

> Status: active — updated 2026-08-03

## Resume here

Keep the approved Route B compact overview working at 310 points, validate it with synthetic rendering and packaged-app
runtime geometry, then merge future upstream releases into the fork without spreading personalization into provider code.

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
- Lay every available Codex or Claude account into two equal columns within its provider section.
- Show Codex Weekly only. Show Claude Session, Weekly, and Fable only as equally compact peer bars in Claude's provider
  color, preserving the existing red pacing and threshold markers.
- Do not render usage dashboards inside account or provider sections. Render one combined cost/token KPI and chart
  model at the bottom of the entire overview, without dashboard detail lines. Keep the four KPIs global while stacking
  each chart day by provider color with a text legend. Aggregate retained typed usage values and provider identity
  before currency, token totals, chart points, and accessibility text are formatted.
- Keep provider actions in the existing submenus and keep bottom Refresh, Settings, About, and Quit actions.
- Leave the status-item visualization unchanged until a later design decision.

## Upstream compatibility boundary

Fork-owned presentation behavior starts at `CodexBarPersonalization`,
`CompactOverviewProviderCard`, and `StatusItemController+CompactOverview`. Small call-site guards in menu/account refresh
code route into that boundary. Upstream provider/auth models stay authoritative and unchanged.

When updating from upstream, fetch and merge `upstream/main`, resolve only genuine overlaps, run the compact overview
layout proof plus the repository test/check commands, then inspect the synthetic dark-mode render before pushing.

## Next checkpoint

Run the freshly built fork after local tests and synthetic rendering are clean; confirm that every known Codex and
Claude account identity appears in its two-column provider grid and that the bottom chart separates every available
typed cost source without duplicating provider sections.

## Direction log

- 2026-08-03: User approved the compact multi-account mockup but required the implementation to retain the current
  menu width.
- 2026-08-03: Menu-bar visualization changes were explicitly deferred.
- 2026-08-03: User replaced per-provider dashboards with one aggregate at the bottom and nested Claude Session inside
  Weekly as a yellow sub-bar.
- 2026-08-03: User approved Route B, superseding vertical accounts and nested-yellow Claude bars with two account
  columns, three compact Claude peer bars, and a provider-colored stacked aggregate chart.
