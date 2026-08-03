# CodexBar Knowledge

## KB-001 · Treat claude-swap duplicate usage as untrusted
- **Status:** active
- **Last verified:** 2026-08-03
- **Use when:** Changing Claude multi-account parsing, projection, or card actions.
- **Knowledge:** `cswap --list --json` can report duplicate-credential or identical-usage warnings when one slot may be serving another account's quota. Preserve only the warned numeric slots, keep the active account's live usage, and withhold suspect inactive metrics and activation instead of guessing ownership.
- **Why:** A poisoned or duplicated slot otherwise renders another account's quota under the wrong email and makes the wrong credential actionable.
- **Evidence:** `Sources/CodexBarCore/Providers/Claude/ClaudeSwap/ClaudeSwapAccountList.swift`, `Sources/CodexBarCore/Providers/Claude/ClaudeSwap/ClaudeSwapAccountProjection.swift`, and `Tests/CodexBarTests/ClaudeSwapAccountProjectionTests.swift`.
- **Revisit when:** claude-swap replaces human-readable warning arrays with a structured, identity-verified diagnostic contract.
