# Product Decisions

## 2026-08-03 — Build on CodexBar upstream

**Status:** Active

Use the open-source CodexBar repository as the product base instead of recreating it. Keep the canonical upstream as a
Git remote, isolate personalization behind narrow fork-owned seams, and preserve upstream provider/auth behavior so
future upstream changes can be merged with minimal conflict.

## 2026-08-03 — Make the merged menu a compact overview

**Status:** Active

The merged menu is an overview-only surface at the existing 310-point width. It has no provider tab strip. Codex and
Claude accounts stack vertically within their provider section, followed by one shared history chart representing the
provider's accounts. Use the authoritative provider dashboard when it already has that scope; otherwise combine typed
account history before display formatting. Never sum rendered chart values independently of KPIs, currency, or
accessibility text.

Codex accounts show Weekly only. Claude accounts show Session, Weekly, and Fable only; Fable uses a yellow treatment.
The dashboard keeps its KPI values and graph but omits explanatory detail lines such as top-model and estimated-bill
copy. Compact account fan-out is limited to Codex and Claude; provider-specific credentials, actions, and the menu-bar
visualization remain outside this personalization.
