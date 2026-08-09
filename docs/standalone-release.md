_Status: parked by PD-019 · 2026-08-09_

# TokenReserve — the standalone release

## Resume here

**Parked (PD-019, 2026-08-09):** the user uninstalled the TokenReserve stand-in, returned the installed app to plain
CodexBar, and stopped the standalone push; the repository is kept intact outside the active portfolio. Everything
below is the state of the initiative at the moment it was parked, preserved for a future revival.

The name is locked (PD-017) and the channel is locked (PD-018). The next step was: scaffold the TokenReserve
repository as an unsandboxed direct-download Mac app and land one vertical slice — menu-bar shell, fixture-backed
account cards, and the provider-colored aggregate chart — before any live credential is read.

## What this is

**The lived end state:** before starting anything expensive, you already know which of your accounts can carry it. You
glance up, you see where every one of them stands, and you pick. You never discover mid-task that you are out.

**What you do instead today:** you find out by hitting the wall — a refusal in the middle of work — or you keep several
provider pages open and reconcile them by hand. Both cost the task you were in.

**The success signal:** a stranger pays for it and keeps it running past the first month. The counter-signal is people
installing it, looking once, and quitting it — that means it answered a curiosity, not a recurring need.

**Durable non-goals:** it is not an agent runner, not a cost optimizer, not a dashboard you visit, and not a tool that
asks you to paste credentials. It reads the logins you already have.

**The bet:** that "how much is left, across every account, without setup" is worth paying for even though each provider
shows its own number for free. If people are content checking one provider at a time, the bet is wrong.

## Locked outcome

- Direct download, notarized, Sparkle-updated. The Mac App Store is a non-goal (PD-018).
- The sellable product is the 420-point, two-column complete-provider account grid described by
  [PD-009 and PD-012](product-decisions.md).
- The rewrite may replace provider acquisition mechanisms, but it does not silently remove Codex, Claude, Cursor,
  Grok, Antigravity, configured accounts, truthful errors, or the provider-colored aggregate chart.
- Distributed copies retain the upstream MIT license and copyright notice.
- The new repository does not import upstream application architecture. Reuse is admitted file by file only after its
  dependency closure, license notice, and product need are explicit.

## Why not the App Store

App Sandbox is mandatory for Mac App Store distribution. Inside it an app cannot read another application's files in
the user's home, cannot read another application's Keychain items, cannot read browser cookie databases, and cannot
launch a command-line tool outside its own bundle. That is the whole acquisition layer, not an edge of it: sandboxed,
Cursor and Grok have no known path to their numbers, and the rest degrade to hand-pasted credentials. The zero-setup
promise is the product, so the store costs more than it returns. Full reasoning and residual risk: PD-018.

This inverts the previous plan. Earlier revisions of this brief treated sandbox eligibility as the release gate and
listed the updater as a thing that must not migrate. Under direct distribution the updater is required and the sandbox
constraint is gone; what remains is the same simplification boundary.

## Standalone architecture boundary

The repository audit counted 419 Swift app files, 714 Swift test files, 65 immediate provider directories excluding
`Shared`, and an active `Sources/CodexBar/Sync` subsystem. The replacement therefore starts in a new repository instead
of adding a thin target here.

### May migrate after dependency review

- The approved account-card and aggregate-chart composition, rewritten against a small replacement domain model.
- Provider response models, parsers, reset calculations, identity resolution, and fixtures that compile without the
  upstream settings, sync, updater, or menu-controller graph.
- The acquisition paths themselves — credential file reads, Keychain reads, browser cookie import, and CLI probes —
  which stay legal under direct distribution and are the most expensive part of the fork to re-derive.
- Provider colors, accessibility labels, and formatting rules that are part of the approved visible behavior.
- Sparkle and the update channel, which direct distribution requires.
- The upstream MIT copyright and permission notice with every copied substantial portion.

### Must not migrate

- Widgets, iCloud/app-group sync, Claude Sync, hooks, agent-session UI, telemetry, status pages, provider tabs,
  provider submenus, alternate layouts, or the upstream settings/controller graph.
- The app-group widget snapshot store, whose unbounded reads are the hazard recorded in KB-014.
- Providers outside Codex, Claude, Cursor, Grok, and Antigravity until the five-provider release promise is complete.
- The `codexbar` CLI, `serve`, and every surface that is not the one menu.

## Build sequence

1. Scaffold a new Swift 6 / macOS 15+ repository: menu-bar shell, minimal settings window, login item that does not
   activate other applications, no sandbox entitlement, hardened runtime on for notarization.
2. Implement the approved account-card grid and aggregate chart against deterministic fixtures. This is the visual and
   accessibility contract, fixed before any live credential is read.
3. Define one small provider adapter protocol around typed account identity, quota rows, errors, and chart
   contributions.
4. Port providers in ascending order of acquisition complexity: Antigravity (in-process OAuth), Codex (credential file
   plus profile homes), Claude (OAuth, then cookie, then CLI), Cursor, Grok. Each lands with its own fixtures and its
   truthful-error path before the next starts.
5. Wire Sentry crash reporting before the first build leaves this machine, with the outbound payload inspected at the
   transport boundary and identity, paths, and user content excluded.
6. Wire Sparkle against a real appcast, then notarize and staple. Prove an update installs over a previous build.
7. Payment and licensing last, and only when there is something to sell.

### Provider acquisition matrix

Direct distribution removes the sandbox question, so the work is porting a known-working path rather than obtaining a
new one. Status is now about porting cost, not permission.

| Provider | Working input to port | Porting note | Status |
| --- | --- | --- | --- |
| Antigravity | In-process remote OAuth fetch | Drop the external `agy` process path; the OAuth fetch is already self-contained | Port first |
| Codex | Managed OAuth/web credentials, `~/.codex` and configured profile homes, session logs for the chart | Carry the identity model with it — rows key on account identity, never on directory (KB-013) | Straightforward |
| Claude | OAuth token, browser cookie import, CLI pseudo-terminal probe, optional `claude-swap` list | Three fallbacks with an ordering that already has known inconsistencies; simplify to one order and delete the rest | Most work |
| Cursor | Browser cookie database, or the external `cursor-agent` | Keep the cookie path; drop the external agent | Straightforward |
| Grok | Browser cookie import and the local web-billing path | Renders Credits, not tokens — the aggregate must not silently add credits to token totals | Straightforward |

## Distribution mechanics

- **Notarization** is free and automated; it is what stops Gatekeeper warning users on first launch.
- **Sparkle** is already wired in the fork and migrates. It needs a hosted appcast and a signing key held outside the
  repository.
- **Payment** is undecided and deliberately deferred. Merchant-of-record services (Paddle, Lemon Squeezy) take EU VAT
  off the owner's desk at a higher rate; Stripe is cheaper and leaves tax handling to him.
- **Crash reporting** is required in the first public release per the fleet rule, wired and payload-inspected, not
  merely linked.

## Evidence

- [Configuring the macOS App Sandbox](https://developer.apple.com/documentation/xcode/configuring-the-macos-app-sandbox)
  — sandboxing is required for Mac App Store distribution.
- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) — 5.2.2 third-party service access,
  2.5.1 public APIs.
- [App Store Small Business Program](https://developer.apple.com/app-store/small-business-program/) — the 15% rate the
  direct channel trades away.

## Exit criteria

- The application launches without taking focus and shows every configured account.
- Codex, Claude, Cursor, Grok, and Antigravity return truthful quota or explicit provider-scoped errors.
- The aggregate dashboard includes every available typed provider series, including Codex, and never mixes units.
- A notarized build installs on a machine that has never run it, and a Sparkle update installs over it.
- A deliberately triggered crash in a production-configuration build resolves to real source locations, and the
  outbound payload was inspected before any upload path existed.

## Direction log

- 2026-08-06: The user rejected QuotaRoom, ended the upstream-fork product strategy, and locked a new minimal standalone
  app that preserves the approved grid, chart, and complete five-provider promise.
- 2026-08-06: A repository inventory and adversarial architecture pass upheld a new-repository boundary. The existing
  fork remains only a temporary behavior/code oracle; a compiled thin-target dependency proof is the sole evidence that
  would reopen that boundary.
- 2026-08-06: The user chose the Mac App Store as the public release target, and inspection showed the current build is
  unsandboxed and depends on cross-container provider data, so a sandbox compatibility spike was made to precede
  submission. **Superseded the same day.**
- 2026-08-06: The name locked as TokenReserve (PD-017) after a full naming round; TokenStorage was recorded and
  withdrawn before it reached the decider intact.
- 2026-08-06: The user locked direct distribution and dropped the Mac App Store (PD-018) once the sandbox cost was laid
  out provider by provider. The sandbox spike, the temporary-exception analysis, and the storefront checklist are
  retired; the updater moves from a forbidden dependency to a required one.
