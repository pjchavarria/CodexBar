---
name: qa-test
description: "CodexBar live QA/e2e testing: run provider usage matrix checks, validate real app config, use Peekaboo for menu proof, use Browser Use/official docs for API spec or logged-in dashboard checks, and handle 1Password credentials safely."
---

# CodexBar Live QA

Use for live provider testing, release smoke tests, menu verification, or debugging “provider works/fails” reports.

## Rules

- Work from the CodexBar repo checkout.
- Use `CodexBar.app/Contents/Helpers/CodexBarCLI` for pre-install development checks. For completion claims about the
  installed personal fork, use `/Applications/QuotaRoom.app/Contents/Helpers/CodexBarCLI` or an explicit
  `CODEXBAR_CLI` override pointing to the installed application under test.
- Do not use `CodexBar.app/Contents/MacOS/codexbar`; that is the app binary and may appear to hang as a CLI.
- Never run broad `env`, `set`, or secret regex dumps.
- Use `$one-password` for secrets: all `op` commands inside one persistent tmux session, service account first, no raw secret output.
- Treat browser-cookie/keychain flows as prompt-risky. Prefer CLI/API-token checks and `KeychainNoUIQuery`-safe tests unless the user explicitly requested live UI.
- For current API behavior, browse official provider docs only.
- Make the last check match the changed outcome. A visual artifact or interface change ends with one inspection of the
  final rendered artifact through the same path the user will receive; a data/provider change ends with the installed
  helper and expected account census. Do not add screenshot work to nonvisual changes merely as ceremony.
- In T3 Code, a source path or inline-visualization token is not delivery proof. Attach the final PNG with Image View
  and provide one `open` command when the client path has already failed. If the attachment was not actually rendered,
  say so instead of claiming that the image appeared.

## CLI Matrix

Run the bundled script:

```bash
.agents/skills/qa-test/scripts/live_provider_matrix.sh --enabled
```

Useful modes:

```bash
.agents/skills/qa-test/scripts/live_provider_matrix.sh --provider all
.agents/skills/qa-test/scripts/live_provider_matrix.sh --providers openai,zai,deepseek
.agents/skills/qa-test/scripts/live_provider_matrix.sh --default
```

Interpretation:

- `--enabled` asks `CodexBarCLI config providers` for enabled providers, honoring `CODEXBAR_CONFIG` and default toggles.
- `--default` runs the app-facing default command with no provider override.
- `--provider all` forces every registered provider and is expected to fail for providers without sessions/keys.
- A green app config needs `--enabled` and `--default` clean; `--provider all` is a discovery/triage tool.

## Installed-app completion gate

- Bundle presence, code signature, process health, and matching binary hashes prove only that the intended build is
  installed. They do not prove the provider behavior the user asked to change.
- After installation, set
  `CODEXBAR_CLI="${CODEXBAR_CLI:-/Applications/QuotaRoom.app/Contents/Helpers/CodexBarCLI}"` and run that exact
  helper against every provider or account path changed in the task. For Codex account work, include
  `"$CODEXBAR_CLI" usage --provider codex --all-accounts --format json` and compare the returned account count, source,
  usage/error state, and identity-equality relationships with the expected account census. Do not mark the app verified
  while a required account is missing, duplicated, or represented only by packaging evidence.
- If the installed surface consumes a provider's cost or token history, run
  `"$CODEXBAR_CLI" cost --provider <provider> --format json` as a separate completion gate. A passing
  `usage --provider <provider>` result does not prove the cost/history path: identity-only fallbacks can make usage
  green while the aggregate dashboard still fails. Exercise both paths twice when the fix changes session persistence.
- For the aggregate dashboard, compare every provider with positive installed cost/history data against the rendered
  legend and stack. Synthetic chart fixtures prove rendering only; they do not prove the installed app selected the
  same provider data sources. For paired-card layout changes, visually inspect the final render and confirm both card
  borders in each row share the same top and bottom coordinates even when their metric counts differ.
- Keep live output private: capture stdout and stderr in a task-owned mode-700 temporary directory, set captured files
  to mode 600, and emit only a fixed allowlist of booleans, counts, source names, status enums, timestamps, and quota
  values. Never print raw usage JSON, browser-profile registries, broad process command lines, or authentication payloads
  while diagnosing identity.
- When a missing credential makes the requested state impossible to prove, identify the exact absent account slot and
  leave verification incomplete until its one user-controlled authentication checkpoint succeeds.

## Config QA

Validate config:

```bash
CodexBar.app/Contents/Helpers/CodexBarCLI config validate
stat -f '%Lp %N' "$HOME/.codexbar/config.json"
```

Redact config shape:

```bash
jq '(.providers // []) |= map(.apiKey = (if .apiKey then "<redacted>" else .apiKey end) |
  .secretKey = (if .secretKey then "<redacted>" else .secretKey end) |
  .cookieHeader = (if .cookieHeader then "<redacted>" else .cookieHeader end) |
  (if .id == "stepfun" and has("region") then .region = "<redacted>" else . end) |
  .tokenAccounts = (if .tokenAccounts then (.tokenAccounts | .accounts = (.accounts | map(.token = "<redacted>"))) else .tokenAccounts end))' \
  "$HOME/.codexbar/config.json"
```

Before editing config, make a backup:

```bash
cp "$HOME/.codexbar/config.json" "$HOME/.codexbar/config.pre-qa-$(date +%Y%m%d%H%M%S).json"
chmod 600 "$HOME/.codexbar"/config.pre-qa-*.json
```

## Live Menu QA

Install and relaunch in the background after CLI checks. Do not make installation a separate approval checkpoint:

```bash
pkill -x CodexBar || pkill -f 'CodexBar.app/Contents/MacOS/CodexBar' || true
open -g -n "$PWD/CodexBar.app"
pgrep -f "$PWD/CodexBar.app/Contents/MacOS/CodexBar"
```

Only when the user explicitly starts a visible verification checkpoint, use Peekaboo to open the menu:

```bash
peekaboo menu list-all --json | rg -i 'codexbar'
peekaboo menu click-extra --title codexbar-merged --json
screencapture -x /tmp/codexbar-live-menu.png
```

If Peekaboo is unavailable or `screencapture` returns a black frame, keep the user's current app frontmost, open the
QuotaRoom status item through `System Events`, and capture only its live layer-101 window:

```bash
osascript -e 'tell application "System Events" to tell process "CodexBar" to click menu bar item 1 of menu bar 2'
swift .agents/skills/qa-test/scripts/capture_quotaroom_menu.swift /tmp/quotaroom-live-menu.png
osascript -e 'tell application "System Events" to key code 53'
```

Record the frontmost process before and after; both values must match. This exact-window fallback can capture the
installed NSMenu when full-display capture returns a black frame and must not be replaced by a synthetic SwiftUI fixture.

Crop top-right menu if needed:

```bash
sips --cropToHeightWidth 900 340 --cropOffset 20 2650 /tmp/codexbar-live-menu.png \
  --out /tmp/codexbar-live-menu-crop.png >/dev/null
```

Verify visually with `view_image`. Confirm provider tabs/rows match enabled config and no failing provider dominates the first screen. This is the final check for a visual change; rerun it after any subsequent UI edit.

## Browser Use

Use `$browser-use` only when a logged-in dashboard, API key page, or provider docs need browser/profile state.

Existing Chrome path:

```bash
mcporter call chrome-devtools.list_pages --args '{}' --output text
mcporter call chrome-devtools.navigate_page --args '{"url":"https://provider.example"}' --output text
mcporter call chrome-devtools.take_snapshot --args '{}' --output text
```

If Browser Use is unavailable, say so and use web search for public official docs; do not substitute isolated Playwright for login/profile-dependent pages.

## Fix Triage

- Missing auth/session: configure key/session if available; otherwise leave provider disabled or report blocked auth.
- Wrong provider API/spec: inspect official docs, then patch fetcher/settings/tests.
- Provider key exists but live API rejects it: keep key stored if useful, disable provider if the menu would show a persistent error.
- User-facing behavior changes need `CHANGELOG.md`.
- Code fixes need focused tests, `make check`, `$autoreview`, and live CLI proof before landing.

## Known CodexBar QA Notes

- OpenAI Admin API key is the useful usage provider key. Project `OPENAI_API_KEY` values can fail legacy credit-balance fallback with 403.
- Deepgram usage requires a key/project with Management API permissions; transcription-only keys can return 403.
- Groq usage uses the Prometheus metrics API, not ordinary inference endpoints.
- MiniMax pay-as-you-go API keys and Token Plan/Coding Plan keys are different; wrong key kind can leave usage unavailable.
