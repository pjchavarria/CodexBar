# Roadmap

_Snapshot: 2026-08-09_

## Active

- Nothing scheduled. Since PD-019 the fork is a personal tool: plain CodexBar identity, keeping the shipped
  account-card overview. Work here is maintenance of that surface.
- [Reviewer provider evaluation](docs/reviewer-accounts.md) — score Codex 2, Claude 2, Cursor, Grok, and Antigravity on a
  frozen three-task corpus before promoting any new production route or changing Luna Medium to Luna Max.

## Shipped

- 2026-08-09 — [Plain CodexBar identity restored](docs/product-decisions.md) (PD-019): the installer targets
  `/Applications/CodexBar.app` (`com.pxl.codexbar`), retires the QuotaRoom bundle and login item, and migrates its
  settings once.
- 2026-08-04 — [Compact multi-account overview](docs/compact-overview.md) — Route B is the installed personal app's only
  menu and retains every configured Codex and Claude account at the fixed two-column width.

## Parked

- [TokenReserve standalone release](docs/standalone-release.md) — parked by PD-019; the repository is kept intact
  outside the active portfolio, and PD-015/PD-017/PD-018 record the naming and channel decisions for a revival.

## Later

- Revisit the menu-bar visualization only if the user asks; he confirmed on 2026-08-09 he likes the current merged
  status item.
