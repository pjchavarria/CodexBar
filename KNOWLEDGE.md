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
- **Last verified:** 2026-08-06
- **Use when:** Updating the compact multi-account overview or merging upstream menu/account changes.
- **Knowledge:** Keep fork-only composition behind `CodexBarPersonalization` and dedicated views/extensions, but do not
  make Route B conditional on merged-icon or provider-count settings. The 420-point menu lays every enabled provider
  account into two self-contained card columns without the upstream six-account cap, keeps ordinary email-length
  identities readable, and keeps failed or unavailable accounts visible with truthful status. It exposes no provider tabs,
  provider submenus, alternate layouts, or customization
  action. The same personal-overview provider context must own account identity projection, Refresh scope, retry scope,
  and revalidation; never let hidden upstream selection flags, multi-account-only switcher thresholds, or
  single-account presentation preferences narrow the only visible route. Retain typed cost/token values and provider
  identity through the one overview aggregation so
  KPIs, accessibility text, and the provider-stacked chart agree.
  Cards are paired in enabled-provider order and each pair uses the taller measured card height; an unpaired final card
  keeps its intrinsic height in the left column. Route B's Codex chart source is the ambient local session ledger rather
  than the selected managed quota account, because the bottom dashboard is provider-global while the Codex cards are
  account-scoped.
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
- **Knowledge:** Use CLI probes, parser tests, bundle/process checks, and hidden T3 preview tabs by default. Build,
  install, and relaunch completed app changes immediately with a nonactivating launch such as `open -g`; do not defer
  those background-safe steps as a separate approval checkpoint. After installation, verify the exact user-visible
  provider path with the installed helper: provider/account changes require the expected account census plus truthful
  usage or error state, and Codex multi-account work requires `--all-accounts`. A running signed process is installation
  proof, not behavior proof. Do not click menu extras, activate applications, open Settings, or launch foreground OAuth
  during unattended verification. Group only unavoidable visual interaction or authentication into one explicit
  user-controlled checkpoint. Live identity diagnostics emit only fixed allowlisted counts, status, and equality facts;
  never raw provider JSON, browser-profile registries, process command lines, or authentication payloads.
- **Why:** macOS UI automation changes the active application and interrupts typing even when the verification itself
  succeeds, while deferring a background-safe install forces an unnecessary extra user loop. Conversely, package-only
  verification can install a healthy binary whose real account census is still incomplete.
- **Evidence:** User corrections during CodexBar account recovery on 2026-08-05; background Cursor, Antigravity, and
  Fleet checks completed without activating a window. The installed personal app was later found to return one Codex
  account because its live and managed sources resolved to the same identity; the earlier signature/process check had
  not exercised `usage --provider codex --all-accounts`.
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

## KB-009 · Prove the final user-visible delivery path
- **Status:** active
- **Last verified:** 2026-08-05
- **Use when:** Handing off a CodexBar mock, screenshot, installed menu change, or provider-account repair.
- **Knowledge:** Match the last QA check to the outcome that changed. Visual work ends with one inspection of the final
  rendered artifact through the same delivery path the user receives; provider/account work ends with the installed
  helper and expected census. In T3 Code, neither an inline-visualization token nor a filesystem path proves that the
  user saw an image. Attach a real PNG and provide one terminal `open` command after an inline-render failure. Do not
  require visual inspection for changes whose observable contract is entirely nonvisual.
- **Why:** A valid source artifact can still render with the wrong appearance, broken text encoding, or no visible
  attachment, while an unrelated screenshot adds friction without proving a data or provider fix.
- **Evidence:** The QuotaRoom/CodexBar account-card mock first arrived as an unsupported inline token, then a Quick Look
  render exposed light-mode and mojibake defects before the corrected dark PNG was attached on 2026-08-05.
- **Revisit when:** T3 Code exposes a programmatic acknowledgement that a conversation image rendered successfully.

## KB-010 · Isolate signed forks from upstream Keychain cache ACLs
- **Status:** active
- **Last verified:** 2026-08-06
- **Use when:** Packaging a separately signed CodexBar fork or verifying a provider used by both cards and the aggregate
  cost dashboard.
- **Knowledge:** Give every separately signed bundle its own `CodexBarCacheService` value derived from its bundle
  identifier, and make bundled helpers read that value from the containing app. Reusing
  `com.steipete.codexbar.cache` lets an upstream-created trusted-application ACL reject the fork without UI. For a
  provider that contributes both account status and cost history, installed QA must exercise both `usage` and `cost`;
  identity-only fallback can make the first green while the dashboard remains broken.
- **Why:** QuotaRoom's Cursor usage passed through Cursor Agent while its cost refresh repeatedly failed after the
  browser-session cache write was refused by the upstream cache item's ACL.
- **Evidence:** `Sources/CodexBarCore/KeychainCacheStore.swift`,
  `Sources/CodexBarCore/KeychainCacheStore+ApplicationPaths.swift`, `Scripts/package_app.sh`, and installed Cursor
  usage/cost probes on 2026-08-06: after one user-controlled Chrome authorization, two usage reads and two cost reads
  returned valid non-error Cursor data and the fresh QuotaRoom process logged zero session-change failures.
- **Revisit when:** Keychain storage moves to access-group sharing or Cursor exposes one supported session source for
  both status and cost history.

## KB-011 · Retire the predecessor login item during a bundle rename
- **Status:** active
- **Last verified:** 2026-08-06
- **Use when:** Replacing an installed menu-bar app with a new bundle identifier without leaving a second launchable.
- **Knowledge:** Copying the old `launchAtLogin` preference to the new settings domain enables the new
  `SMAppService.mainApp` registration but does not unregister the old bundle's independent registration. Stop both
  apps, persist `launchAtLogin=false` in the old domain, launch the old bundle in the background so it unregisters
  itself, verify the background-task record when macOS responds, then remove the obsolete bundle. A replacement install
  may keep the prior app only inside a validated hidden transaction directory; restore it on failure and delete the
  transaction after the replacement stays running. Do not retain `.previous.app` bundles or rollback ZIPs.
- **Why:** Both CodexBar Personal and QuotaRoom were enabled login items after the rename, so the next login could
  resurrect two personal apps even though only QuotaRoom was currently running.
- **Evidence:** `Scripts/install_personal_app.sh`, `Scripts/test_personal_app_installer.sh`, and the 2026-08-06
  `sfltool dumpbtm` audit showing CodexBar Personal disabled and QuotaRoom enabled.
- **Revisit when:** Apple provides a supported API for one bundle to unregister another bundle's main-app login item.

## KB-012 · Use the fork as an oracle, not the replacement architecture
- **Status:** superseded — PD-019 (2026-08-09) parked the standalone; the fork is the personal surface again and there
  is no replacement to migrate into. The dependency-closure findings below stay valid if the standalone is revived.
- **Last verified:** 2026-08-06
- **Use when:** Migrating the approved account-card product into its standalone application.
- **Knowledge:** Start the replacement in a new repository and admit reused files only after their dependency closure is
  small, pure, licensed, and necessary. Preserve visible behavior and typed provider semantics, not the upstream app
  graph. Keep the installed fork available only while it provides parity evidence; do not merge new upstream features.
- **Why:** The current app target contains 419 Swift files, 65 immediate provider directories, and Sync. The five desired
  provider folders still depend on broad settings, OAuth/session, projection, browser, and process machinery, so an
  in-repo thin target would preserve the coupling the rewrite is meant to remove.
- **Evidence:** `docs/standalone-release.md`, `docs/product-decisions.md`, the 2026-08-06 deterministic source inventory,
  and the architecture adversary that upheld a new repository unless a compiled dependency-closure spike proves the
  provider core is already separable.
- **Revisit when:** A compiled thin-target spike satisfies that falsifier or the five-provider product promise changes.

## KB-013 · Codex rows have three sources; only identity proves two accounts
- **Status:** active
- **Last verified:** 2026-08-06
- **Use when:** Someone reports the overview showing one account twice, proposes keying accounts by configuration
  directory, or proposes collapsing rows that "must be" the same account.
- **Knowledge:** `CodexVisibleAccountProjection.make` builds visible rows from three sources: every managed store
  account, the live ambient home (`$CODEX_HOME`, else `~/.codex`), and every path configured in
  `codexProfileHomePaths`. The managed store deduplicates on email plus provider account id, and the live account is
  matched against existing drafts through `CodexIdentityMatcher` and merged. Profile homes were filtered on path
  alone until 2026-08-06, so a configured home holding the same credential as the live login or a managed account
  produced a second card for one account and counted its quota twice; they now pass the same identity check.
  Dropping a row is only half the change: the persisted selection can still point at the absorbed path, and a
  selection matching no rendered row leaves nothing active, so `UsageStore+TokenAccounts` never binds an account and
  the provider stops publishing a snapshot. `CodexActiveSourceResolver.resolvedProfileSource` therefore remaps an
  absorbed profile path onto whichever row survived — managed, live, or the first profile home for that identity —
  which also makes `persistResolvedCodexActiveSourceCorrectionIfNeeded()` heal the stored value. Any future row
  filter owes the same pairing: never drop a draft without remapping selections that could name it.
  Confirm any duplicate claim by decoding the `sub`, `chatgpt_account_id`, and plan claims from each home's
  `auth.json` locally — no network call, no keychain prompt, no provider quota spent. Two rows prove two accounts
  only once that decode agrees.
- **Why:** Agent tooling keeps its own `CODEX_HOME` directories (`~/.codex`, `~/.codex-t3/account-2`) that can be
  signed into a single account, and the dispatch wrapper reports that duplication. The app never discovers those
  homes on its own, but it does read the ambient home and any profile home a user configures, so the tooling's
  duplication and the app's rows are separate facts that look alike and get conflated. On 2026-08-06 the two rows on
  this machine were two managed accounts resolving to two different Google subjects and two different ChatGPT account
  ids, whose email addresses differ but share their first eleven characters — correct rows that read as duplicates at
  card width.
- **Evidence:** `Sources/CodexBarCore/Providers/Codex/CodexVisibleAccountProjection.swift` (`make`, profile-home
  identity guard), `Sources/CodexBarCore/CodexManagedAccounts.swift` (`sanitizedAccounts`),
  `Sources/CodexBarCore/Providers/Codex/CodexAccountReconciliation.swift` (`CodexIdentityMatcher`,
  `CodexActiveSourceResolver.absorbingSource`), and `Tests/CodexBarTests/CodexProfileHomeAccountTests.swift`, whose
  duplicate-identity case renders two cards without the guard and whose selected-duplicate cases leave no active
  account without the remap.
- **Revisit when:** A row source is added that cannot supply an identity, or a case appears where one subscription
  pool genuinely serves two distinct provider account ids — the Claude precedent in KB-001 is to withhold the suspect
  numbers rather than merge the rows.

## KB-014 · A hung test here is usually the app-group container, not the diff
- **Status:** active
- **Last verified:** 2026-08-06
- **Use when:** A `swift test` run stops producing output with tests started and never finished, especially
  in `CodexManagedRoutingTests` or anything that drives a full `UsageStore.refresh()` (a bare
  `refreshProvider` does not reach the snapshot).
- **Knowledge:** A full refresh ends in `persistWidgetSnapshot`, and `AppGroupSupport.snapshotURL` resolves
  to `~/Library/Group Containers/<group>/widget-snapshot.json` whenever a group container is available. macOS
  serves that directory through `containermanagerd`; when that daemon wedges, `open()` on any group container
  blocks forever and the test process sits at 0% CPU with no timeout. Diagnose without touching this
  repository: `sample <pid>` shows the stack ending in `open`, and `ls` on an unrelated group container such
  as `2DC432GLL2.com.openai.codex.notifications` hangs identically while `~/Library/Group Containers` itself
  lists instantly. Confirm a diff is innocent by stashing it and rerunning the same filter at the baseline
  commit; the same tests hang. Suites that never touch a refresh — `CodexProfileHomeAccountTests`,
  `CodexAccountReconciliationTests` — still run in well under a second, so verification is not blocked, only
  narrowed. Recovery needs a privileged `containermanagerd` restart or a reboot, which is the user's call.
- **Why:** The failure looks exactly like an infinite loop introduced by the change under review, so the
  reflex is to bisect the diff, and a reviewer that demands the hung suite's results blocks a correct change
  on a machine fault.
- **Evidence:** `Sources/CodexBarCore/AppGroupSupport.swift` (`snapshotURL`, `currentContainerURL`),
  `Sources/CodexBarCore/WidgetSnapshot.swift:188-203`, and the 2026-08-06 baseline comparison in which the
  identical ten `CodexManagedRoutingTests` tests hung with and without the working-tree changes.
- **Revisit when:** The widget snapshot store gains a bounded read, or tests inject a temporary snapshot
  directory instead of resolving the real container.

## KB-015 · Installer shell scripts must survive macOS's bash 3.2

- **What:** Anything under `Scripts/` that a user or installer runs directly executes on the system
  `/bin/bash`, which is bash 3.2. There, expanding a possibly-empty array with `"${arr[@]}"` under
  `set -u` aborts as an unbound variable — the exact failure that killed the first real
  `install_personal_app.sh` run in `remove_obsolete_install_artifacts` when `/Applications` held no
  leftover artifacts. Length expansion `${#arr[@]}` is safe, so every such expansion sits behind a
  `[[ ${#arr[@]} -gt 0 ]]` guard.
- **Why:** Development and CI shells are newer bash or zsh, so the suite can stay green for months
  while the one environment that matters — a stock Mac — fails on the empty path nobody fixtures.
- **Evidence:** `Scripts/install_personal_app.sh` (`remove_obsolete_install_artifacts`),
  the `/bin/bash` empty-artifacts regression in `Scripts/test_personal_app_installer.sh`,
  commit 205110bd (2026-08-09).
- **Revisit when:** Scripts pin a modern bash via Homebrew, or macOS ships bash 4+.

## KB-016 · Open root menus never rebuild; MenuCardRefreshMonitor is the only live channel

- **Status:** active
- **Last verified:** 2026-08-09
- **Use when:** Adding anything time- or refresh-sensitive to a menu surface (timestamps, "Refreshing…"
  states, live counters), or reviewing a claim that an open menu "updates on the next data tick".
- **Knowledge:** While a root menu is open, `refreshOpenMenuIfNeeded` defers the parent rebuild
  (`menuSession.deferParentRebuild(key)` and returns), so the store-observation → `invalidateMenus`
  → smart-update reconcile path never reaches the open menu — it applies on reopen. The only channel
  that updates an open menu live is `MenuCardRefreshMonitor` observed from inside the hosted SwiftUI
  view (`@Environment(\.menuCardRefreshMonitor)`). Any view that swaps in live data must also keep the
  cached NSMenu item height invariant: adopt a fresh model only when structurally compatible with the
  baked one (same cards/metrics), as `CompactOverviewAccountGridModel.preferringLive` does.
- **Why:** The refresh path looks complete when traced from the store side, so a reviewer finding of
  "stale while open" was wrongly declined in this session; the deferral branch is easy to miss.
- **Evidence:** `Sources/CodexBar/StatusItemController+MenuTracking.swift` (`refreshOpenMenuIfNeeded`),
  `Sources/CodexBar/MenuCardRefreshMonitor.swift`, `Sources/CodexBar/CompactOverviewProviderCard.swift`
  (`preferringLive`/`isStructurallyCompatible`), `Sources/CodexBar/MenuCardView.swift:353-357`.
- **Revisit when:** Menu hosting moves off NSMenu or open-menu rebuilds become supported.
