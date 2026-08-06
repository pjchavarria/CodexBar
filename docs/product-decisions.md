# Product Decisions

## PD-001 · Build on CodexBar upstream
- **Status:** locked
- **Locked:** 2026-08-03
- **Decision:** Use the open-source CodexBar repository as the product base, retain the canonical project as an upstream
  Git remote, and isolate personalization behind narrow fork-owned seams.
- **Why:** The fork should inherit provider, authentication, and maintenance work without recreating CodexBar.
- **Applies to:** Repository structure, upstream merges, provider behavior, and fork-owned implementation boundaries.

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
- **Status:** locked
- **Locked:** 2026-08-04
- **Decision:** Install the fork as CodexBar Personal beside upstream CodexBar, with its own bundle/settings identity,
  one-time settings migration, shared existing account stores, and no upstream Sparkle update feed.
- **Why:** The fork must be usable daily without being overwritten by upstream releases, while upstream remains an
  untouched rollback and merge source.
- **Applies to:** Packaging, signing, settings migration, installation, updates, and rollback.

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
- **Status:** locked
- **Locked:** 2026-08-05
- **Decision:** Route B is the complete enabled-provider census, not only a Codex/Claude view. Keep an enabled provider
  visible when usage is unavailable, show Google Antigravity usage from the authenticated `agy` CLI, and show Cursor's
  authenticated Cursor Agent identity when its web usage session is unavailable. Do not route code review or other
  work to Google, Cursor, or Grok until a later explicit decision.
- **Why:** Provider disappearance was being mistaken for missing configuration, while fabricating quota from an
  authentication-only CLI would be misleading.
- **Applies to:** Route B provider visibility, Cursor fallback behavior, Antigravity enablement, and reviewer routing.

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
- **Status:** locked
- **Locked:** 2026-08-05
- **Decision:** Replace the CodexBar product name and terminal-style icon with an independent, provider-neutral name and
  icon before selling the app. Keep the upstream MIT copyright and permission notice in distributed copies. The exact
  public name, icon construction, bundle identifier, and domain remain open until the user approves the rendered brand
  direction and collision checks are complete.
- **Why:** A multi-provider paid product should not present itself as a Codex-only derivative or reuse upstream's
  terminal-command identity.
- **Applies to:** Public naming, application icon, bundle/display name, packaging, release artifacts, storefront, and
  license notices.
