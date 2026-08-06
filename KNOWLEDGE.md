# CodexBar Knowledge

## KB-001 · Treat claude-swap duplicate usage as untrusted
- **Status:** active
- **Last verified:** 2026-08-03
- **Use when:** Changing Claude multi-account parsing, projection, or card actions.
- **Knowledge:** `cswap --list --json` can report duplicate-credential or identical-usage warnings when one slot may be serving another account's quota. Preserve only the warned numeric slots, keep the active account's live usage, and withhold suspect inactive metrics and activation instead of guessing ownership.
- **Why:** A poisoned or duplicated slot otherwise renders another account's quota under the wrong email and makes the wrong credential actionable.
- **Evidence:** `Sources/CodexBarCore/Providers/Claude/ClaudeSwap/ClaudeSwapAccountList.swift`, `Sources/CodexBarCore/Providers/Claude/ClaudeSwap/ClaudeSwapAccountProjection.swift`, and `Tests/CodexBarTests/ClaudeSwapAccountProjectionTests.swift`.
- **Revisit when:** claude-swap replaces human-readable warning arrays with a structured, identity-verified diagnostic contract.

## KB-002 · Make Route B the only runtime surface and preserve every account
- **Status:** active
- **Last verified:** 2026-08-04
- **Use when:** Updating the compact multi-account overview or merging upstream menu/account changes.
- **Knowledge:** Keep fork-only composition behind `CodexBarPersonalization` and dedicated views/extensions, but do not
  make Route B conditional on merged-icon or provider-count settings. The 380-point menu lays every configured Codex
  and Claude account into two columns without the upstream six-account cap, keeps ordinary email-length identities
  readable, and keeps failed or unavailable accounts visible with truthful status. It exposes no provider tabs,
  provider submenus, alternate layouts, or customization
  action. The same personal-overview provider context must own account identity projection, Refresh scope, retry scope,
  and revalidation; never let hidden upstream selection flags, multi-account-only switcher thresholds, or
  single-account presentation preferences narrow the only visible route. Retain typed cost/token values and provider
  identity through the one overview aggregation so
  KPIs, accessibility text, and the provider-stacked chart agree.
  When a selected single account has no per-account snapshot, project the provider-level snapshot or error through a
  model that still carries the configured account label; regression fixtures must leave the per-account snapshot
  collection empty to exercise that production path.
- **Why:** Conditional routing and bounded snapshot projections can silently return the user to upstream UI or omit an
  account even though the fork's only promised surface is the complete multi-account overview.
- **Evidence:** `Sources/CodexBar/CodexbarApp.swift`, `Sources/CodexBar/CodexBarPersonalization.swift`,
  `Sources/CodexBar/CompactOverviewProviderCard.swift`, `Sources/CodexBar/UsageStore+CompactOverview.swift`,
  `Sources/CodexBar/CompactOverviewDashboard.swift`, `Tests/CodexBarTests/UsageMenuCardLayoutTests.swift`, and
  `Tests/CodexBarTests/StatusMenuPersistentRefreshTests.swift`,
  `Tests/CodexBarTests/StatusMenuTokenAccountSwitcherTests.swift`,
  `Tests/CodexBarTests/CodexAccountMenuDisplaySnapshotTests.swift`, and `docs/compact-overview.md`.
- **Revisit when:** Upstream exposes a typed provider-wide multi-account history model or changes account projection.

## KB-003 · Verify identity and suppress auth output for claude-swap recovery
- **Status:** active
- **Last verified:** 2026-08-03
- **Use when:** Diagnosing or repairing claude-swap account slots.
- **Knowledge:** The stable local layout uses `~/.claude` for the Main Chrome identity and `~/.claude-2` for the Purple
  Chrome identity; the browser mapping is only for reauthentication. Before `add --slot`, compare Claude's native auth
  status with the intended identity; reauthentication can leave the same account active, and claude-swap then moves
  that existing account into the target slot. Never use a global `cswap switch` as account repair when independent
  config homes are available. Never surface raw output from account mutations or interactive OAuth launch commands:
  mutations can print private identity labels, while login can print an authorization URL containing a private login
  hint and credential-adjacent state. Suppress both streams when the browser opens automatically, then verify
  separately with allowlisted slot numbers, status enums, counts, and identity-equality booleans.
- **Why:** A visually assumed login can overwrite or move the wrong slot, while shallow or post-action-only redaction can expose private account data or OAuth state.
- **Evidence:** Installed claude-swap 0.24.1 `add_account` slot-migration behavior, `claude auth status --json`, and redacted `cswap list/status --json` recovery probes verified on 2026-08-03.
- **Revisit when:** claude-swap adds a machine-verifiable intended-identity guard and privacy-safe structured mutation results.

## KB-004 · Verify provider readiness with allowlisted fields only
- **Status:** active
- **Last verified:** 2026-08-04
- **Use when:** Connecting or checking external reviewer accounts in T3 or CodexBar.
- **Knowledge:** Query only the provider instance ID, driver, readiness, installation/enabled flags, authentication
  status, version, and model count. Never inspect or print an entire authentication object or broad provider log when
  those scalar fields can prove readiness.
- **Why:** Full authentication payloads and provider logs can contain private account identity or credential-adjacent
  data that is irrelevant to the readiness decision.
- **Evidence:** Privacy-safe Cursor and Grok readiness probes against T3's live provider-instance cache on 2026-08-04.
- **Revisit when:** T3 exposes a dedicated privacy-safe provider readiness command.

## KB-005 · Use the repository-pinned lint tools
- **Status:** active
- **Last verified:** 2026-08-04
- **Use when:** Formatting or linting Swift in this repository.
- **Knowledge:** Resolve SwiftFormat and SwiftLint through `Scripts/lint.sh` or `.build/lint-tools/bin`; do not invoke a
  global binary directly.
- **Why:** A globally installed older formatter can reject repository rules such as `redundantSendable` before it
  formats any source.
- **Evidence:** `Scripts/lint.sh`, `Scripts/install_lint_tools.sh`, and the pinned binaries under `.build/lint-tools/bin`.
- **Revisit when:** The project removes its pinned lint-tool installer.

## KB-006 · Keep the live Codex login independent from monitored accounts
- **Status:** active
- **Last verified:** 2026-08-05
- **Use when:** Discovering, authenticating, or repairing multiple Codex accounts.
- **Knowledge:** `~/.codex` is the one live Codex app and CLI login. CodexBar's existing managed-account store retains
  separately authenticated monitoring credentials. Never infer another Codex credential from a Chrome profile, T3
  provider instance, similarly named directory, or cached label. Before changing either side, compare privacy-safe
  identity fingerprints; if every discovered auth file matches one identity, the other account is genuinely absent and
  requires a user-controlled managed-account login.
- **Why:** Copying or aliasing the active credential makes two rows represent one account and breaks intentional manual
  logout/login switching in the Codex app.
- **Evidence:** Privacy-safe fingerprint comparison of the live Codex home, T3 profile home, managed account store, and
  available backups on 2026-08-05; `docs/product-decisions.md` PD-007.
- **Revisit when:** Codex ships a native multi-login account switcher with identity-scoped quota storage.

## KB-007 · Keep desktop verification in the background by default
- **Status:** active
- **Last verified:** 2026-08-05
- **Use when:** Testing CodexBar while the user is working in other applications.
- **Knowledge:** Use CLI probes, parser tests, bundle/process checks, and hidden T3 preview tabs by default. Do not click
  menu extras, activate applications, open Settings, or launch foreground OAuth during unattended verification. Group
  all unavoidable visual or authentication work into one explicit user-controlled checkpoint.
- **Why:** macOS UI automation changes the active application and interrupts typing even when the verification itself
  succeeds.
- **Evidence:** User-caught focus interruption during CodexBar account recovery on 2026-08-05; background Cursor,
  Antigravity, and Fleet checks then completed without activating a window.
- **Revisit when:** macOS exposes a reliable offscreen menu-bar automation session isolated from the user's desktop.

## KB-008 · Preserve provider visibility without fabricating usage
- **Status:** active
- **Last verified:** 2026-08-05
- **Use when:** Adding providers to Route B or handling missing provider sessions.
- **Knowledge:** Route B keeps every enabled provider visible even when its model is error-only. Cursor auto mode may
  fall back from a missing web session to `cursor-agent status --format json`, but that fallback supplies connected
  identity only; it must not invent quota or rate windows. Google Antigravity usage comes from the authenticated `agy`
  CLI. Provider presence is independent of whether T3 routes work to it.
- **Why:** Filtering error-only cards hides configured services, while treating authentication as quota data creates a
  false healthy state.
- **Evidence:** `Sources/CodexBar/CodexBarPersonalization.swift`,
  `Sources/CodexBarCore/Providers/Cursor/CursorAgentStatusProbe.swift`,
  `Tests/CodexBarTests/CursorStatusProbeTests.swift`, and privacy-safe live CLI probes on 2026-08-05.
- **Revisit when:** Cursor exposes a supported personal usage endpoint through Cursor Agent.
