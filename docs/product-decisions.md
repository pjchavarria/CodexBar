# Product Decisions

## 2026-08-03 — Build on CodexBar upstream

**Status:** Active

Use the open-source CodexBar repository as the product base instead of recreating it. Keep the canonical upstream as a
Git remote, isolate personalization behind narrow fork-owned seams, and preserve upstream provider/auth behavior so
future upstream changes can be merged with minimal conflict.

## 2026-08-03 — Make the merged menu a compact overview

**Status:** Active

The merged menu is an overview-only surface at the existing 310-point width. It has no provider tab strip. Codex and
Claude accounts stack vertically within their provider section. No account or provider owns a usage dashboard; one
combined cost/token dashboard appears after every provider section. Combine typed usage values before display
formatting so KPIs, currency, chart points, and accessibility text remain one consistent aggregate.

Codex accounts show Weekly only. Each Claude account has one Weekly group: Weekly is the main bar, with Session and
Fable nested beneath it; Session and Fable use yellow treatments. The bottom dashboard keeps the four cost/token KPIs
and graph but omits explanatory detail lines such as top-model and estimated-bill copy. Compact account fan-out is
limited to Codex and Claude; provider-specific credentials, actions, and the menu-bar visualization remain outside
this personalization.
