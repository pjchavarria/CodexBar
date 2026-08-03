# CodexBar Knowledge

## KB-001 · Treat claude-swap duplicate usage as untrusted
- **Status:** active
- **Last verified:** 2026-08-03
- **Use when:** Changing Claude multi-account parsing, projection, or card actions.
- **Knowledge:** `cswap --list --json` can report duplicate-credential or identical-usage warnings when one slot may be serving another account's quota. Preserve only the warned numeric slots, keep the active account's live usage, and withhold suspect inactive metrics and activation instead of guessing ownership.
- **Why:** A poisoned or duplicated slot otherwise renders another account's quota under the wrong email and makes the wrong credential actionable.
- **Evidence:** `Sources/CodexBarCore/Providers/Claude/ClaudeSwap/ClaudeSwapAccountList.swift`, `Sources/CodexBarCore/Providers/Claude/ClaudeSwap/ClaudeSwapAccountProjection.swift`, and `Tests/CodexBarTests/ClaudeSwapAccountProjectionTests.swift`.
- **Revisit when:** claude-swap replaces human-readable warning arrays with a structured, identity-verified diagnostic contract.

## KB-002 · Keep compact-overview personalization at the presentation boundary
- **Status:** active
- **Last verified:** 2026-08-03
- **Use when:** Updating the compact multi-account overview or merging upstream menu/account changes.
- **Knowledge:** Keep fork-only composition behind `CodexBarPersonalization` and dedicated views/extensions. The compact
  menu stacks Codex and Claude account snapshots, filters quota rows, renders one authoritative provider dashboard
  after the accounts, and stays at 310 points. Never sum already-formatted dashboard points because the KPIs,
  currency, accessibility text, and chart can disagree; any true account aggregation belongs in typed usage data
  before formatting.
- **Why:** A narrow seam minimizes upstream conflicts while preventing UI-only changes from widening credentials or network activity.
- **Evidence:** `Sources/CodexBar/CodexBarPersonalization.swift`,
  `Sources/CodexBar/CompactOverviewProviderCard.swift`, `Sources/CodexBar/UsageStore+CompactOverview.swift`,
  `Tests/CodexBarTests/UsageMenuCardLayoutTests.swift`, and `docs/compact-overview.md`.
- **Revisit when:** Upstream exposes a typed provider-wide multi-account history model or changes merged-menu routing.
