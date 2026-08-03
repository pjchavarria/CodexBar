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
  menu stacks every Codex and Claude account snapshot, groups Claude Session and Fable beneath Weekly, renders one
  combined cost/token dashboard after every provider section, and stays at 310 points. Retain typed cost/token values
  through overview aggregation; formatting KPIs or accessibility text earlier can make them disagree with the chart.
- **Why:** A narrow seam minimizes upstream conflicts while preventing UI-only changes from widening credentials or network activity.
- **Evidence:** `Sources/CodexBar/CodexBarPersonalization.swift`,
  `Sources/CodexBar/CompactOverviewProviderCard.swift`, `Sources/CodexBar/UsageStore+CompactOverview.swift`,
  `Sources/CodexBar/CompactOverviewDashboard.swift`, `Tests/CodexBarTests/UsageMenuCardLayoutTests.swift`, and
  `docs/compact-overview.md`.
- **Revisit when:** Upstream exposes a typed provider-wide multi-account history model or changes merged-menu routing.

## KB-003 · Verify identity and suppress mutator output for claude-swap recovery
- **Status:** active
- **Last verified:** 2026-08-03
- **Use when:** Diagnosing or repairing claude-swap account slots.
- **Knowledge:** Before `add --slot`, compare Claude's native auth status with the intended identity; reauthentication can leave the same account active, and claude-swap then moves that existing account into the target slot. Never surface raw output from account mutations because it can print private identity labels. Suppress it and verify the result separately with allowlisted slot numbers, status enums, counts, and identity-equality booleans.
- **Why:** A visually assumed login can overwrite or move the wrong slot, while shallow or post-action-only redaction can expose private account data.
- **Evidence:** Installed claude-swap 0.24.1 `add_account` slot-migration behavior, `claude auth status --json`, and redacted `cswap list/status --json` recovery probes verified on 2026-08-03.
- **Revisit when:** claude-swap adds a machine-verifiable intended-identity guard and privacy-safe structured mutation results.
