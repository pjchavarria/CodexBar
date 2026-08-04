_Status: building · 2026-08-04_

# Reviewer Provider Accounts

## Resume here

Keep reviewer providers connected but unrouted until a later session defines which review jobs each provider owns and
how their output is evaluated. Cursor and Grok are native T3 provider instances. Google's current free path is the
standalone Antigravity CLI because T3 does not yet expose a Gemini driver; do not represent it as a native T3 account.

## Current reality

- T3 has enabled `Cursor Review` and `Grok Review` provider instances alongside every pre-existing provider instance.
  Neither connection changes a default, favorite, selected provider, or routing rule.
- The installed Cursor CLI is authenticated and T3 reports the instance ready.
- The installed Grok CLI is authenticated through grok.com and T3 reports the instance ready; T3's own authentication
  field remains unknown, so native CLI status is the authoritative login proof.
- The Google Antigravity CLI is installed as a standalone tool. Its browser OAuth must finish before it is callable.
- Fleet account inventory remains a user-only browser write; add or update these providers there without copying
  credentials, recovery values, or private identity into tracked files.

## Direction

- Preserve all existing T3 provider instances exactly.
- Connect accounts only; do not assign defaults, favorites, automatic reviewers, or routing yet.
- Treat native T3 readiness and standalone CLI readiness as different states.
- Verify readiness with allowlisted scalar fields only: instance ID, driver, status, installed/enabled flags,
  authentication status, version, and model count.
- Before routing, define a bounded reviewer job, evaluation corpus, failure behavior, and the decision that comparison
  will change.

## Options considered

- **Google Antigravity CLI — selected connection path.** Free with basic weekly limits and browser OAuth, but standalone
  from T3 today: <https://antigravity.google/pricing> and <https://antigravity.google/docs/cli/install>.
- **Google Jules — parked.** Its free tier is suitable for asynchronous GitHub tasks rather than a native T3 reviewer:
  <https://jules.google/docs/usage-limits>.
- **Gemini API through OpenCode — parked.** It is an API-key integration with model-specific project quotas, not the
  same consumer-account connection: <https://ai.google.dev/gemini-api/docs/rate-limits> and
  <https://opencode.ai/docs/providers>.
- **Legacy Gemini CLI consumer login — rejected.** Google ended that path on 2026-06-18:
  <https://developers.google.com/gemini-code-assist/docs/deprecations/code-assist-individuals>.

## Next checkpoint

Finish Google browser OAuth, verify all three reviewer paths without exposing identity payloads, then stop. Routing is a
separate product/workflow decision.

## Direction log

- **RA-001 · 2026-08-04:** Connected Cursor and Grok as native T3 reviewer instances without changing routing.
- **RA-002 · 2026-08-04:** Selected Antigravity as the current Google free-tier connection path, explicitly standalone
  until T3 exposes a supported Gemini driver.
- **RA-003 · 2026-08-04:** Deferred every reviewer assignment, default, favorite, and routing decision.
