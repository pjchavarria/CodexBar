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
  release architecture.
- **Superseded in part by:** PD-018 — the release channel is a direct download, not the Mac App Store. Every other
  decision in this entry remains locked.

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
- **Status:** locked
- **Locked:** 2026-08-06
- **Decision:** Do not release the standalone product as QuotaRoom. Keep the approved icon and menu-bar visualization
  direction provisional until the final name is chosen; do not reserve a bundle identifier, App Store record, or domain
  under a brainstorm candidate.
- **Why:** The user rejected the assembled “quota + room” mechanism metaphor before storefront work began.
- **Applies to:** Product naming, bundle identity, repository naming, domains, storefront metadata, and public assets.

## PD-016 · Name the standalone product TokenStorage
- **Status:** withdrawn — never in force
- **Recorded and withdrawn:** 2026-08-06
- **What it recorded:** TokenStorage as the locked product name.
- **Why it is withdrawn:** The name was relayed as decided, but the candidate set it was chosen against had been
  compressed to a single sentence before it reached the decider. The choice was made without the alternatives, their
  risks, or the category finding in view — that CodexBar, ClaudeBar, ClaudeUsageBar, Usage4Claude, and Quotio are all
  free and all named after the mechanism, so a mechanism-shaped name cannot separate a paid product from them. It was
  therefore not a decision on the merits. Naming is open again and PD-015 remains the live constraint.
- **Retained for:** The residual risk noted at the time, which still applies if TokenStorage returns as a candidate:
  it is the conventional identifier for a credential store in auth SDKs, while the product's most review-sensitive
  mechanism is reading credentials belonging to other applications; it is also a generic engineering term, which
  weakens search and trademark distinctiveness.
## PD-017 · Name the standalone product TokenReserve
- **Status:** locked
- **Locked:** 2026-08-06
- **Decision:** The standalone product is named TokenReserve. Bundle identity, repository naming, domain, storefront
  metadata, icon, and public copy may now be produced under that name, which closes the provisional hold PD-015 placed
  on storefront work. The withdrawn PD-016 is not revived; TokenStorage remains rejected.
- **Why:** The user locked it after a full naming round. "Reserve" names remaining capacity, which is what the product
  is opened to find out, and it drops the credential-vault reading that made TokenStorage misdescribe the app's most
  review-sensitive behaviour. Two objections raised against it did not survive scrutiny: the DeFi phrase collision does
  not reach a buyer who arrives from a screenshot or a qualified query, and a name points at the domain rather than at
  the dominant on-screen formatter.
- **Residual risk:** "Token" is not the displayed unit for every provider — Grok renders Credits, Cursor and
  Antigravity render window percentages, and tokens appear only in the bottom summary strip. Copy and screenshots
  should lead with remaining capacity rather than token counts so the name is not read as a promise about units.
- **Applies to:** Product naming, bundle identity, repository naming, domains, storefront metadata, public assets, and
  marketing copy.

## PD-018 · Ship TokenReserve as a direct download, not on the Mac App Store
- **Status:** locked
- **Locked:** 2026-08-06
- **Decision:** TokenReserve is distributed as a notarized direct download from its own site, updated in place by
  Sparkle. The Mac App Store is a durable non-goal for launch: no architecture, entitlement, or provider decision may
  be bent toward sandbox eligibility, and no App Store Connect record is created. Revisiting it later means an
  additional cut-down store build alongside the direct one, never a redesign of the direct product.
- **Why:** App Sandbox is mandatory for Mac App Store distribution, and the product's entire acquisition layer depends
  on exactly what the sandbox forbids — reading other applications' credential files and account homes, other
  applications' Keychain items, browser cookie databases, and launching their command-line tools. Sandboxed, Cursor and
  Grok have no known path to their numbers at all, and the rest degrade to the user pasting credentials by hand, which
  deletes the zero-setup promise that is the product. Review Guideline 5.2.2 additionally places a human reviewer in
  front of every update to a mechanism built on undocumented provider endpoints, so a mid-life rejection could strand
  paying customers.
- **Supersedes:** PD-011's App Store channel and PD-012's App Store release-architecture scope. Both entries keep every
  other decision they carry.
- **Residual risk:** Choosing direct distribution removes the reviewer, not the provider terms. Reading another
  application's stored credentials may violate a provider's terms of use on any channel; that question is open and is
  not resolved by this decision.
- **Applies to:** Distribution, packaging, entitlements, provider acquisition architecture, the updater, payment and
  licensing, and all storefront work.


## PD-019 · Return the personal app to plain CodexBar and park the standalone
- **Status:** locked
- **Locked:** 2026-08-09
- **Decision:** The installed personal app is plain CodexBar again: `/Applications/CodexBar.app`, bundle identifier
  `com.pxl.codexbar`, display name CodexBar. The installer retires the QuotaRoom bundle and its login item and
  migrates its settings domain once. The TokenReserve standalone application is parked, not revived: its installed
  stand-in is uninstalled, its repository is kept intact outside the active portfolio, and no standalone work is
  scheduled. This fork stops being a sellable product and leaves the Side Projects portfolio; it continues as the
  user's personal tool whose one deliberate UI divergence from upstream is the 420-point account-card overview
  (PD-009) and the merged status item, both kept exactly as shipped.
- **Why:** The user chose the working tool over the productization arc. The overview already shows every account at a
  glance — the view he asked to keep — and the standalone rewrite was a second codebase that added no daily value
  while the fork stayed installed. A personalized fork of an MIT upstream is a tool, not a product, so it does not
  belong in the sellable portfolio.
- **Applies to:** App identity, packaging and installation, distribution ambitions, repository location, portfolio
  membership, and the scope of future UI work.
- **Supersedes:** PD-010's QuotaRoom install identity (the separate-app boundary and license-notice duties carry
  over to the CodexBar identity). Parks PD-012's standalone replacement and PD-017/PD-018's TokenReserve storefront
  and channel work — those decisions stay recorded and become binding again only if the standalone is revived.


## PD-020 · The status item shows every account as a provider grid
- **Status:** locked
- **Locked:** 2026-08-09
- **Decision:** The merged status item renders every enabled provider's monitored accounts instead of one provider's
  single number. Layout is a grid drawn into one template image: one column per provider, one row per account, one
  provider mark per column at the single-line icon size (16 pt) vertically centered on its rows, and one
  right-aligned lane per value so the numbers and the reset countdown line up down the rows. Codex contributes its
  weekly lane; Claude contributes session and weekly as two separate lanes, never joined by a slash. Each row ends
  with a compact largest-unit countdown derived from that row's own weekly reset instant. The grid stays capped at
  two rows per provider — the menu bar has two text lines — while the overview menu remains the complete census.
- **Why:** The old item answered "how much is left on one account" while the fork monitors four. Route B already
  resolves every account; spending menu-bar width on that census removes the click that the overview existed to
  serve. Drawing it as an image rather than an attributed title is what makes column alignment possible at all:
  attributed text has no column concept, so values would drift with the width of whatever precedes them.
- **Residual risk:** The item is roughly two to three times its previous width and grows with each enabled provider,
  which is real estate the menu bar contests on a notched display; macOS drops overflowing extras silently. Reset
  countdowns still change the item's width as they tick down.
- **Supersedes:** The "leave the status-item visualization unchanged" hold in `docs/compact-overview.md`, and the
  "merged status item kept exactly as shipped" clause of PD-019. PD-019 keeps every other decision it carries.
- **Applies to:** Status-item rendering, menu-bar layout presets, and any future per-account bar surface.
