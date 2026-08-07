# Product Decisions

## PD-001 · Build on CodexBar upstream
- **Status:** superseded
- **Locked:** 2026-08-03
- **Decision:** Use the open-source CodexBar repository as the product base, retain the canonical project as an upstream
  Git remote, and isolate personalization behind narrow fork-owned seams.
- **Why:** The fork should inherit provider, authentication, and maintenance work without recreating CodexBar.
- **Applies to:** Repository structure, upstream merges, provider behavior, and fork-owned implementation boundaries.
- **Superseded by:** PD-012 replaces upstream merges with a standalone minimal application; the fork remains a temporary
  behavior and code-reference oracle only.

## PD-002 · Make the merged menu a compact overview
- **Status:** superseded
- **Locked:** 2026-08-03
- **Decision:** Use a 310-point overview-only merged menu, with Codex Weekly, Claude Session/Weekly/Fable, and one global
  cost/token dashboard; the original account layout was vertical and the Claude secondary bars were nested yellow.
- **Why:** The upstream overview repeated information and consumed too much vertical space.
- **Applies to:** The merged menu's content hierarchy, quota metrics, and aggregated dashboard.
- **Superseded by:** PD-003 replaces the account/bar layout; PD-005 replaces the conditional/action boundaries while
  preserving the compact metrics and global dashboard.

## PD-003 · Use the two-column Route B account layout
- **Status:** superseded
- **Locked:** 2026-08-03
- **Decision:** Place Codex and Claude accounts in two equal columns at 310 points. Codex shows Weekly only; Claude shows
  Session, Weekly, and Fable as compact peer bars in the provider color with existing red pacing markers. Keep one
  globally aggregated dashboard whose daily bars stack provider-colored segments and whose four totals remain global.
- **Why:** This keeps multiple accounts scannable without widening the menu or repeating dashboards.
- **Applies to:** Codex/Claude account cards and the bottom cost/token chart.
- **Supersedes:** PD-002's vertical accounts and nested-yellow Claude bars.
- **Superseded by:** PD-009 keeps the two-column structure but makes every account its own provider-labeled card.

## PD-004 · Use a separate personal application identity
- **Status:** superseded
- **Locked:** 2026-08-04
- **Decision:** Install the fork as CodexBar Personal beside upstream CodexBar, with its own bundle/settings identity,
  one-time settings migration, shared existing account stores, and no upstream Sparkle update feed.
- **Why:** The fork must be usable daily without being overwritten by upstream releases, while upstream remains an
  untouched rollback and merge source.
- **Applies to:** Packaging, signing, settings migration, installation, updates, and rollback.
- **Superseded by:** PD-010 keeps the separate-app boundary and replaces the provisional CodexBar Personal identity
  with QuotaRoom.

## PD-005 · Make Route B the complete personal-app surface
- **Status:** superseded
- **Locked:** 2026-08-04
- **Decision:** Always use one merged Route B menu, regardless of provider count or previous display settings. Show every
  configured Codex and Claude account without a cap, including truthful unavailable/error rows. Expose no tabs,
  separate provider status items, provider submenus, alternate layouts, agent-session rows, or Settings action; retain
  only Refresh, About, and Quit below the overview.
- **Why:** The personal app exists solely for the compact, complete account overview; conditional upstream surfaces and
  bounded projections made the UI inconsistent and hid configured accounts.
- **Applies to:** Personal-app runtime routing, account projection, menu actions, and unavailable-account behavior.
- **Supersedes:** PD-002's conditional/provider-action boundaries and any PD-003 implementation that caps account rows.
- **Superseded by:** PD-009 preserves the one-surface/no-cap rule while replacing provider sections and About with
  account cards and Settings.

## PD-006 · Widen Route B for readable account identities
- **Status:** superseded
- **Locked:** 2026-08-04
- **Decision:** Keep the two-column Route B menu fixed at 380 points instead of 310 points so ordinary email-length
  Codex and Claude account identities plus required inline suffixes remain readable without changing the approved
  layout or adding disclosure UI.
- **Why:** The installed 310-point menu clipped both Codex identities and the unavailable Claude identity; a 360-point
  correction still clipped the longer Claude identity beside `-swap`, so the complete account census remained
  visually ambiguous.
- **Applies to:** Personal-app menu width and two-column account identity labels.
- **Supersedes:** PD-003's 310-point width; its two-column layout and quota composition remain locked.
- **Superseded by:** PD-009 widens the approved account-card grid to 420 points.

## PD-007 · Separate monitored Codex accounts from the live Codex login
- **Status:** locked
- **Locked:** 2026-08-05
- **Decision:** Treat the Codex app and CLI as one manually switched live login. Keep CodexBar's monitored account
  census in its existing managed account store, independent of the currently active Codex login and independent of
  Chrome profiles. A browser profile is only a user-controlled authentication helper, never a permanent route from an
  account row to the Codex app.
- **Why:** The user intentionally logs out and back in when one Codex account runs out; tying browser profiles or T3
  provider instances to the live app corrupts that operating model and makes account rows disappear when the active
  login changes.
- **Applies to:** Codex account discovery, managed account authentication, active-login switching, and account labels.

## PD-008 · Show enabled providers without routing work to them
- **Status:** superseded
- **Locked:** 2026-08-05
- **Decision:** Route B is the complete enabled-provider census, not only a Codex/Claude view. Keep an enabled provider
  visible when usage is unavailable, show Google Antigravity usage from the authenticated `agy` CLI, and show Cursor's
  authenticated Cursor Agent identity when its web usage session is unavailable. Do not route code review or other
  work to Google, Cursor, or Grok until a later explicit decision.
- **Why:** Provider disappearance was being mistaken for missing configuration, while fabricating quota from an
  authentication-only CLI would be misleading.
- **Applies to:** Route B provider visibility, Cursor fallback behavior, Antigravity enablement, and reviewer routing.
- **Superseded by:** PD-013 keeps provider visibility and authorizes a measured routing evaluation without promoting any
  new provider by default.

## PD-009 · Make every account a self-contained card
- **Status:** locked
- **Locked:** 2026-08-05
- **Decision:** Route B is one 420-point, two-column grid of self-contained account cards. Keep accounts from the same
  provider adjacent, then continue in enabled-provider order; an unpaired final account occupies the left column. Every
  card owns its provider icon/name, full account identity, truthful error state, and provider-specific quota rows.
  Codex keeps Weekly; Claude keeps Session, Weekly, and Fable as compact peer bars; other providers keep their available
  quota rows. Keep the single provider-colored aggregate dashboard below the grid. Keep only Refresh, Settings, and Quit
  below the dashboard.
- **Why:** Provider-sized sections made the five enabled services feel unrelated and prevented Cursor and Grok from
  sharing one scan row. Repeating one complete card grammar makes additional accounts and services predictable.
- **Applies to:** Personal-app menu width, account/provider composition, quota/error presentation, dashboard placement,
  and bottom actions.
- **Supersedes:** PD-003's provider-section grid, PD-005's About action, and PD-006's 380-point width.

## PD-010 · Give the sellable fork an independent identity
- **Status:** superseded
- **Locked:** 2026-08-05
- **Decision:** Ship the personal fork as QuotaRoom at `/Applications/QuotaRoom.app`, using bundle identifier
  `com.pxl.quotaroom` and the approved full-color open-frame quota icon for the application, Dock, and future storefront.
  Keep the dynamic provider/usage menu-bar visualization unchanged for now. Keep the upstream MIT copyright and
  permission notice in distributed copies. Keep CodexBar Personal only as a stopped manual rollback, with its launch
  item unregistered so it cannot start beside QuotaRoom after login.
- **Why:** A multi-provider paid product should not present itself as a Codex-only derivative or reuse upstream's
  terminal-command identity.
- **Applies to:** Public naming, application icon, bundle/display name, packaging, release artifacts, storefront, and
  license notices. A public domain and storefront listing remain separate future decisions.
- **Superseded by:** PD-012 replaces the fork with a standalone app, PD-014 removes rollback launchables, and PD-015
  records that QuotaRoom is rejected while the final name remains open.

## PD-011 · Prepare QuotaRoom for the Mac App Store without hiding providers
- **Status:** superseded
- **Locked:** 2026-08-06
- **Decision:** Make the Mac App Store QuotaRoom's intended public release channel. Keep the current notarizable direct
  bundle as the working baseline while building and validating a separate sandboxed distribution path. The App Store
  build must preserve the truthful complete-provider census; it may replace unsupported credential and data-access
  mechanisms, but it must not silently omit providers or claim account usage it cannot fetch.
- **Why:** The current unsandboxed bundle reads provider data from browser stores, local account homes, and installed
  command-line tools, while the Mac App Store requires an appropriately sandboxed, self-contained application.
- **Applies to:** Distribution architecture, entitlements, provider acquisition, App Store Connect metadata, privacy
  disclosure, review evidence, and TestFlight release gates.
- **Superseded by:** PD-012 keeps the complete-provider App Store promise but makes sandboxing a first-class property of
  the new standalone app rather than a second target inside the fork.

## PD-012 · Replace the fork with a minimal standalone app
- **Status:** locked
- **Locked:** 2026-08-06
- **Decision:** Build a new native macOS application in a new repository. Preserve only the approved 420-point,
  two-column account-card menu, provider-specific quota rows, truthful unavailable states, typed provider-colored
  aggregate chart, background refresh, account authentication/settings, and login item for Codex, Claude, Cursor,
  Grok, and Antigravity. The current fork remains a read-only behavior and implementation oracle until the replacement
  reaches complete-provider parity; it is not the product base and receives no further upstream feature merges.
- **Why:** The current app target contains 419 Swift files, 65 provider directories, and a Sync subsystem, while the
  approved product is one menu surface over five providers. A new repository makes excluded systems a structural
  boundary instead of a convention inside a coupled upstream tree.
- **Applies to:** Repository ownership, migration sequencing, source reuse, provider adapters, testing, packaging, and
  App Store release architecture.

## PD-013 · Evaluate additional agent providers before routing
- **Status:** locked
- **Locked:** 2026-08-06
- **Decision:** Evaluate Cursor, Grok, and Google Antigravity against the existing Codex 2 and Claude 2 routes using a
  frozen, scored corpus covering bounded extraction, defect review, and small implementation. Do not promote a provider
  from connection status or one benchmark. Keep mechanical Luna work on Codex 2 at medium reasoning until a separate
  Luna Medium-versus-Max evaluation proves a better route; keep architecture, coding, safety, review judgment, and
  final acceptance on Sol.
- **Why:** The first equal-prompt probe produced alternative findings from Codex and Cursor, turn-limit exhaustion from
  Claude and Grok, and a headless permission denial from Antigravity. That tests orchestration readiness but does not
  establish quality parity.
- **Applies to:** T3 provider routing, reviewer automation, model selection, evaluation evidence, and failure behavior.

## PD-014 · Keep only the latest installed app
- **Status:** locked
- **Locked:** 2026-08-06
- **Decision:** Do not retain stopped predecessor apps, `.previous.app` bundles, or rollback ZIP archives. During an
  install, keep the prior bundle only inside a hidden transaction directory long enough to restore an interrupted
  replacement; delete that transaction after the new app launches successfully. Git history and reproducible builds
  are the rollback mechanism after installation.
- **Why:** Persistent rollback launchables add login-item and identity ambiguity without protecting source or release
  history.
- **Applies to:** Local installation, bundle replacement, predecessor cleanup, packaging tests, and handoff language.

## PD-015 · Retire the QuotaRoom name
- **Status:** superseded
- **Locked:** 2026-08-06
- **Decision:** Do not release the standalone product as QuotaRoom. Keep the approved icon and menu-bar visualization
  direction provisional until the final name is chosen; do not reserve a bundle identifier, App Store record, or domain
  under a brainstorm candidate.
- **Why:** The user rejected the assembled “quota + room” mechanism metaphor before storefront work began.
- **Applies to:** Product naming, bundle identity, repository naming, domains, storefront metadata, and public assets.
- **Superseded by:** PD-016 closes the open naming question.

## PD-016 · Name the standalone product TokenStorage
- **Status:** locked
- **Locked:** 2026-08-06
- **Decision:** Release the standalone product as TokenStorage. Use that name for the repository, application display
  name, bundle identity, and storefront listing. Reserving a bundle identifier, App Store Connect record, or domain
  still waits on the distribution-channel decision.
- **Why:** Paul chose the name directly, after rejecting QuotaRoom and the alternative shortlist.
- **Residual risk, accepted:** `TokenStorage` is the conventional identifier for a credential store in auth SDKs, and
  the product's most review-sensitive mechanism is reading credentials that belong to other applications, so the name
  names that surface rather than the user promise. It is also a generic engineering term, which weakens search and
  trademark distinctiveness. Recorded once here; the decision stands.
- **Applies to:** Product naming, repository naming, bundle identity, domains, storefront metadata, and public assets.
