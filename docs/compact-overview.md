_Status: shipped reference · 2026-08-06_

# Compact Multi-Account Overview

## Resume here

Keep the approved Route B compact overview working at 420 points in the currently installed fork while the standalone
replacement is built. Use this surface as the behavior and visual oracle; do not add upstream features or turn the fork
into the replacement architecture.

## Current reality

- The repository is the temporary implementation reference for the standalone replacement; upstream merges are no
  longer the product strategy.
- CodexBar already owns account discovery, account-scoped quota snapshots, inline usage dashboards, refresh actions,
  settings, and provider submenus.
- The fork adds a presentation seam, a compact account-card grid, and account-to-card projection. It does not add another
  credential store, fetcher, parser, or chart data source.
- `Scripts/install_personal_app.sh` packages and installs `/Applications/QuotaRoom.app` with separate bundle and
  Keychain-cache identities, imports upstream settings once, uses the existing shared account stores, and leaves
  upstream CodexBar intact.
  The personal package disables Sparkle updates, the widget, and iCloud app-group sync. It unregisters and removes the
  legacy CodexBar Personal app, and retains a replaced bundle only inside the active install transaction.

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

## Replacement transfer boundary

Use `CodexBarPersonalization`, `CompactOverviewProviderCard`, and `StatusItemController+CompactOverview` to recover the
approved behavior, not as a module boundary to copy wholesale. The standalone app may migrate only dependency-light
typed models, parsers, fixtures, provider colors, formatting rules, and view behavior after an explicit dependency and
license audit. It must not inherit the upstream controller, settings, Sync, widget, hook, telemetry, provider
submenu, alternate-layout, or external-process graph. Two earlier exclusions are lifted by the direct-download lock
(PD-018): Sparkle and the update channel are now required, and the browser-cookie and credential-file acquisition paths
stay legal and migrate.

## Next checkpoint

Reproduce the fixture-backed card grid and chart in the scaffolded TokenReserve repository. Public distribution
continues through the [TokenReserve standalone release brief](standalone-release.md); do not weaken the
complete-provider promise for any packaging convenience.

## Product identity

The account-card mock is approved and implemented. QuotaRoom is retired and the sellable name is TokenReserve
(PD-017), distributed as a direct download (PD-018). The full-color open-frame icon and existing dynamic status-item
visualization are provisional until that name is applied. Domain registry availability is not trademark clearance or
registrar purchase proof.

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
  sandbox compatibility proof for the complete provider set, not a reduced-provider upload. **Superseded the same day
  by PD-018:** the channel is a direct download and the sandbox proof is retired.
- 2026-08-06: The user rejected QuotaRoom, replaced the fork strategy with a minimal standalone app in a new repository,
  and removed persistent rollback launchables. This document is now the behavior oracle for that replacement.
