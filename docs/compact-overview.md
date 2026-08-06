_Status: shipped · 2026-08-05_

# Compact Multi-Account Overview

## Resume here

Keep the approved Route B compact overview working at 420 points in the separately installed QuotaRoom app,
validate it with synthetic rendering and packaged-app runtime geometry, then merge future upstream releases into the
fork without spreading personalization into provider code.

## Current reality

- The repository is a fork of `steipete/CodexBar` with `origin` pointing to the fork and `upstream` pointing to the
  canonical project in the working checkout.
- CodexBar already owns account discovery, account-scoped quota snapshots, inline usage dashboards, refresh actions,
  settings, and provider submenus.
- The fork adds a presentation seam, a compact account-card grid, and account-to-card projection. It does not add another
  credential store, fetcher, parser, or chart data source.
- `Scripts/install_personal_app.sh` packages and installs `/Applications/QuotaRoom.app` with separate bundle and
  Keychain-cache identities, imports upstream settings once, uses the existing shared account stores, and leaves
  upstream CodexBar intact.
  The personal package disables Sparkle updates, the widget, and iCloud app-group sync until matching personal
  provisioning is deliberately configured. It also unregisters the legacy CodexBar Personal login item before
  launching QuotaRoom, while leaving the stopped legacy bundle available as a manual rollback.

## Direction

- Keep the merged menu fixed at `CodexBarPersonalization.compactOverviewMenuWidth` (420 points) so complete account
  cards and ordinary identities remain readable in both columns.
- Always open the merged multi-provider menu on Overview and omit the provider switcher.
- Lay every available account into one two-column grid. Each card repeats the provider icon/name, account identity,
  truthful error state, and that provider's quota rows; keep same-provider accounts adjacent. Measure each pair as one
  row and give both cards the taller sibling's height so Cursor/Grok and future mixed-provider pairs stay aligned.
- Do not cap the account grid or drop an account when usage is missing, stale, or failed; render its identity and
  truthful status while retaining the same two-column flow.
- Keep every enabled provider in Route B even when its current fetch is error-only. Google Antigravity reads real usage
  from the authenticated `agy` CLI. Cursor first attempts its web/app usage session, then falls back to a truthful
  Cursor Agent connected identity without inventing quota values.
- Clear launcher-scoped `CODEX_HOME` and `CLAUDE_CONFIG_DIR` before app initialization so T3, shell, Finder, and Login
  Item launches all discover the same account census; targeted account fetches still supply their explicit homes.
- Keep the live Codex app login separate from CodexBar's managed account census. Both monitored accounts may be used by
  one Codex app through manual logout/login; Chrome profiles are authentication checkpoints, not persistent app routes.
- Show Codex Weekly only. Show Claude Session, Weekly, and Fable only as equally compact peer bars in Claude's provider
  color, preserving the existing red pacing and threshold markers.
- Do not render usage dashboards inside account or provider sections. Render one combined cost/token KPI and chart
  model at the bottom of the entire overview, without dashboard detail lines. Keep the four KPIs global while stacking
  each chart day by provider color with a text legend. Aggregate retained typed usage values and provider identity
  before currency, token totals, chart points, and accessibility text are formatted.
- Route B's Codex chart contribution is the ambient local Codex session ledger, independent of which managed account is
  selected for quota monitoring. Account cards remain account-scoped; the bottom chart remains provider-global.
- Route B is the only runtime menu: do not attach provider tabs, submenus, alternate layouts, or agent-session rows.
  Keep bottom Refresh, Settings, and Quit actions.
- Leave the status-item visualization unchanged until a later design decision.

## Upstream compatibility boundary

Fork-owned presentation behavior starts at `CodexBarPersonalization`,
`CompactOverviewProviderCard`, and `StatusItemController+CompactOverview`. Small call-site guards in menu/account refresh
code route into that boundary. Upstream provider/auth models stay authoritative and unchanged.

When updating from upstream, fetch and merge `upstream/main`, resolve only genuine overlaps, run the compact overview
layout proof plus the repository test/check commands, then inspect the synthetic dark-mode render before pushing.

## Next checkpoint

Keep the installed personal app current by merging `upstream/main`, rerunning the personal installer, and confirming
that every known account identity from every enabled provider appears in the two-column card grid, every enabled
provider has a visible truthful state, and the bottom chart separates every available typed cost source without
duplicating account cards. Public distribution now continues through the
[Mac App Store release readiness brief](app-store-release.md); do not weaken the complete-provider promise merely to
produce an uploadable sandbox build.

## Locked product identity

The account-card mock is approved and implemented. The sellable product identity is QuotaRoom. The application uses
the full-color open-frame quota icon and `com.pxl.quotaroom` bundle/settings identity; the existing dynamic status-item
visualization remains unchanged. Domain registry availability is not trademark clearance or registrar purchase proof.

The installed QuotaRoom audit confirms two healthy managed Codex accounts, two fresh claude-swap accounts, healthy
Grok and Antigravity usage, and healthy Cursor quota and cost/history paths. The installed QuotaRoom helper returned
valid non-error Cursor usage and cost data twice after the bundle-specific Keychain cache repair.

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
- 2026-08-04: The live two-column menu proved 310 points too narrow for ordinary email-length identities, and the first
  360-point correction still clipped a Claude identity beside `-swap`; Route B now uses 380 points.
- 2026-08-05: The user separated the one live Codex app login from CodexBar's monitored account census; browser profiles
  are login helpers only, and the live app is switched manually.
- 2026-08-05: The user required Google, Cursor, and other enabled providers to remain visible in Route B while explicitly
  deferring reviewer routing.
- 2026-08-05: The user opened a new account-card mock iteration: one consistent self-contained card per account in two
  columns, with same-provider accounts adjacent and Antigravity as the final unpaired card.
- 2026-08-05: The user approved the account-card mock, widened the live layout to the mock's 420 points, and replaced
  About with Settings in the only bottom action set.
- 2026-08-05: The user locked the intent to sell the fork under a new provider-neutral product name and icon; exact
  branding remains open pending approval of the researched render.
- 2026-08-05: Rebrand research kept QuotaRoom over the more natural Spare because Spare has a direct AI-brand
  collision, and sharpened icon A into separate full-color app/storefront artwork and a monochrome menu-bar template.
- 2026-08-06: The user locked QuotaRoom and the open-frame application icon. The menu-bar visualization remains
  provider/usage-driven and deferred.
- 2026-08-06: Cursor completion now requires both installed usage and cost/history probes; a passing identity-only
  Cursor Agent fallback cannot prove the aggregate dashboard path.
- 2026-08-06: The installed QuotaRoom census verified two Codex accounts, two Claude accounts, Grok, Antigravity, and
  Cursor Agent identity. Cursor's remaining browser authorization was a visible user checkpoint, not a background
  session-mutation failure.
- 2026-08-06: The user completed Cursor authorization; two installed usage and cost/history probes now verify its full
  card and aggregate-dashboard paths.
- 2026-08-06: The user required paired cards to share a row height and the global chart to retain Codex alongside
  Claude and Cursor.
- 2026-08-06: The user chose the Mac App Store as QuotaRoom's public release target. The first release checkpoint is a
  sandbox compatibility proof for the complete provider set, not a reduced-provider upload.
