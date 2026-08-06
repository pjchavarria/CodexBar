_Status: evaluating · 2026-08-06_

# Reviewer Provider Accounts

## Resume here

Keep reviewer providers connected but unrouted while a frozen evaluation corpus determines whether Cursor, Grok, or
Google Antigravity can match the existing Codex 2 and Claude 2 routes. Cursor and Grok are native T3 provider instances;
Antigravity remains a standalone CLI rather than a T3 account.

## Current reality

- T3 has enabled `Cursor Review` and `Grok Review` provider instances alongside every pre-existing provider instance.
  Neither connection changes a default, favorite, selected provider, or routing rule.
- The installed Cursor CLI is authenticated and T3 reports the instance ready.
- The installed Grok CLI is authenticated through grok.com and T3 reports the instance ready; T3's own authentication
  field remains unknown, so native CLI status is the authoritative login proof.
- The Google Antigravity CLI is installed and authenticated as a standalone tool.
- Fleet account inventory remains a user-only browser write; add or update these providers there without copying
  credentials, recovery values, or private identity into tracked files.

## Direction

- Preserve all existing T3 provider instances exactly.
- Evaluate all five lanes, but do not assign defaults, favorites, automatic reviewers, or production routing until a
  lane passes the full corpus.
- Treat native T3 readiness and standalone CLI readiness as different states.
- Verify readiness with allowlisted scalar fields only: instance ID, driver, status, installed/enabled flags,
  authentication status, version, and model count.
- Before routing, define a bounded reviewer job, evaluation corpus, failure behavior, and the decision that comparison
  will change.
- Mechanical extraction remains routed to Codex 2 with `gpt-5.6-luna` at medium reasoning. Luna Max is available in
  Cursor's model catalog but is not the locked route; changing that requires a matched Medium-versus-Max evaluation.
- Architecture, implementation, safety, review judgment, and final acceptance remain Sol work rather than Luna work.

## Preliminary equal-prompt probe · 2026-08-06

One isolated repository fixture contained a known unsafe configurable deletion path. Every lane received the same
read-only review request. The fixture also contained other arguable installer defects, so this probe measures
orchestration readiness and candidate-finding behavior; it is not a clean quality ranking.

| Lane | Result | Routing verdict |
| --- | --- | --- |
| Codex 2 / Sol | Completed; found a different plausible process-restoration defect, not the seeded deletion defect | Not a parity oracle |
| Claude 2 / Opus | Reached the eight-turn limit without a verdict | Not ready under this harness |
| Cursor / Composer 2.5 | Completed; found a different plausible login-item defect, not the seeded deletion defect | Not proven on par |
| Grok / Grok 4.5 | Reached the eight-turn limit without a verdict | Not ready under this harness |
| Antigravity / Gemini 3.1 Pro High | Headless tool permission was denied before a verdict | Harness blocker; no quality result |

No lane is promoted from this probe. The next corpus removes competing defects and scores three independent task classes:

1. Bounded extraction with an exact count/schema oracle.
2. Defect review with one isolated seeded bug, explicit false-positive scoring, and a deterministic verdict deadline.
3. A small throwaway implementation scored by tests, diff scope, latency, and unsafe tool use.

Promotion requires repeatable completion and comparable correctness across all three classes, not a single win.

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

Build the three-task frozen corpus, run matched repetitions across all five lanes, and publish a scorecard that can
change routing. Test Luna Medium versus Luna Max separately on the mechanical task only.

## Direction log

- **RA-001 · 2026-08-04:** Connected Cursor and Grok as native T3 reviewer instances without changing routing.
- **RA-002 · 2026-08-04:** Selected Antigravity as the current Google free-tier connection path, explicitly standalone
  until T3 exposes a supported Gemini driver.
- **RA-003 · 2026-08-04:** Deferred every reviewer assignment, default, favorite, and routing decision.
- **RA-004 · 2026-08-06:** The user opened routing evaluation for Cursor, Grok, and Antigravity; the first equal-prompt
  probe promoted no lane because it exposed orchestration failures and lacked one unambiguous quality oracle.
- **RA-005 · 2026-08-06:** Confirmed that the current mechanical route is Luna Medium through Codex 2, not Luna Max; a
  matched mechanical benchmark is required before changing it.
