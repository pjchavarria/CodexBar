_Status: shipped · 2026-08-04_

# Compact Multi-Account Overview

## Resume here

Keep the approved Route B compact overview working at 360 points in the separately installed CodexBar Personal app,
validate it with synthetic rendering and packaged-app runtime geometry, then merge future upstream releases into the
fork without spreading personalization into provider code.

## Current reality

- The repository is a fork of `steipete/CodexBar` with `origin` pointing to the fork and `upstream` pointing to the
  canonical project in the working checkout.
- CodexBar already owns account discovery, account-scoped quota snapshots, inline usage dashboards, refresh actions,
  settings, and provider submenus.
- The fork adds a presentation seam, a compact provider card, and account-to-card projection. It does not add another
  credential store, fetcher, parser, or chart data source.
- `Scripts/install_personal_app.sh` packages and installs `/Applications/CodexBar Personal.app` with a separate bundle
  identity, imports upstream settings once, uses the existing shared account stores, and leaves upstream CodexBar intact.
  The personal package disables Sparkle updates, the widget, and iCloud app-group sync until matching personal
  provisioning is deliberately configured.

## Direction

- Keep the merged menu fixed at `CodexBarPersonalization.compactOverviewMenuWidth` (360 points) so ordinary account
  identities remain readable in both columns.
- Always open the merged multi-provider menu on Overview and omit the provider switcher.
- Lay every available Codex or Claude account into two equal columns within its provider section.
- Do not cap the account grid or drop an account when usage is missing, stale, or failed; render its identity and
  truthful status while retaining the same two-column flow.
- Clear launcher-scoped `CODEX_HOME` and `CLAUDE_CONFIG_DIR` before app initialization so T3, shell, Finder, and Login
  Item launches all discover the same account census; targeted account fetches still supply their explicit homes.
- Show Codex Weekly only. Show Claude Session, Weekly, and Fable only as equally compact peer bars in Claude's provider
  color, preserving the existing red pacing and threshold markers.
- Do not render usage dashboards inside account or provider sections. Render one combined cost/token KPI and chart
  model at the bottom of the entire overview, without dashboard detail lines. Keep the four KPIs global while stacking
  each chart day by provider color with a text legend. Aggregate retained typed usage values and provider identity
  before currency, token totals, chart points, and accessibility text are formatted.
- Route B is the only runtime menu: do not attach provider tabs, submenus, alternate layouts, agent-session rows, or a
  Settings action. Keep bottom Refresh, About, and Quit actions.
- Leave the status-item visualization unchanged until a later design decision.

## Upstream compatibility boundary

Fork-owned presentation behavior starts at `CodexBarPersonalization`,
`CompactOverviewProviderCard`, and `StatusItemController+CompactOverview`. Small call-site guards in menu/account refresh
code route into that boundary. Upstream provider/auth models stay authoritative and unchanged.

When updating from upstream, fetch and merge `upstream/main`, resolve only genuine overlaps, run the compact overview
layout proof plus the repository test/check commands, then inspect the synthetic dark-mode render before pushing.

## Next checkpoint

Keep the installed personal app current by merging `upstream/main`, rerunning the personal installer, and confirming
that every known Codex and Claude account identity appears in its two-column provider grid and that the bottom chart
separates every available typed cost source without duplicating provider sections.

## Direction log

- 2026-08-03: User approved the compact multi-account mockup but required the implementation to retain the current
  menu width.
- 2026-08-03: Menu-bar visualization changes were explicitly deferred.
- 2026-08-03: User replaced per-provider dashboards with one aggregate at the bottom and nested Claude Session inside
  Weekly as a yellow sub-bar.
- 2026-08-03: User approved Route B, superseding vertical accounts and nested-yellow Claude bars with two account
  columns, three compact Claude peer bars, and a provider-colored stacked aggregate chart.
- 2026-08-04: User chose to start using Route B as a separately installed personal app and authorized validation with
  every configured Codex and Claude account.
- 2026-08-04: User removed every non-Route-B surface and required the overview to retain every configured account,
  including accounts whose usage cannot be fetched.
- 2026-08-04: The live two-column menu proved 310 points too narrow for ordinary email-length identities; the user
  locked Route B to a wider 360-point menu.
