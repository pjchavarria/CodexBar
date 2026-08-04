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
- **Status:** locked
- **Locked:** 2026-08-03
- **Decision:** Place Codex and Claude accounts in two equal columns at 310 points. Codex shows Weekly only; Claude shows
  Session, Weekly, and Fable as compact peer bars in the provider color with existing red pacing markers. Keep one
  globally aggregated dashboard whose daily bars stack provider-colored segments and whose four totals remain global.
- **Why:** This keeps multiple accounts scannable without widening the menu or repeating dashboards.
- **Applies to:** Codex/Claude account cards and the bottom cost/token chart.
- **Supersedes:** PD-002's vertical accounts and nested-yellow Claude bars.

## PD-004 · Use a separate personal application identity
- **Status:** locked
- **Locked:** 2026-08-04
- **Decision:** Install the fork as CodexBar Personal beside upstream CodexBar, with its own bundle/settings identity,
  one-time settings migration, shared existing account stores, and no upstream Sparkle update feed.
- **Why:** The fork must be usable daily without being overwritten by upstream releases, while upstream remains an
  untouched rollback and merge source.
- **Applies to:** Packaging, signing, settings migration, installation, updates, and rollback.

## PD-005 · Make Route B the complete personal-app surface
- **Status:** locked
- **Locked:** 2026-08-04
- **Decision:** Always use one merged Route B menu, regardless of provider count or previous display settings. Show every
  configured Codex and Claude account without a cap, including truthful unavailable/error rows. Expose no tabs,
  separate provider status items, provider submenus, alternate layouts, agent-session rows, or Settings action; retain
  only Refresh, About, and Quit below the overview.
- **Why:** The personal app exists solely for the compact, complete account overview; conditional upstream surfaces and
  bounded projections made the UI inconsistent and hid configured accounts.
- **Applies to:** Personal-app runtime routing, account projection, menu actions, and unavailable-account behavior.
- **Supersedes:** PD-002's conditional/provider-action boundaries and any PD-003 implementation that caps account rows.

## PD-006 · Widen Route B for readable account identities
- **Status:** locked
- **Locked:** 2026-08-04
- **Decision:** Keep the two-column Route B menu fixed at 360 points instead of 310 points so ordinary email-length
  Codex and Claude account identities remain readable without changing the approved layout or adding disclosure UI.
- **Why:** The installed 310-point menu clipped both Codex identities and the unavailable Claude identity, making the
  complete account census visually ambiguous.
- **Applies to:** Personal-app menu width and two-column account identity labels.
- **Supersedes:** PD-003's 310-point width; its two-column layout and quota composition remain locked.
