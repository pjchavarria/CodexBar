#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_DOMAIN="CodexBarPersonalMigrationSourceTests-$RANDOM-$$"
TARGET_DOMAIN="CodexBarPersonalMigrationTargetTests-$RANDOM-$$"
FIXTURE="$(mktemp "${TMPDIR:-/tmp}/codexbar-personal-settings-fixture.XXXXXX")"
LEGACY_TEST_ROOT=""
trap 'defaults delete "$SOURCE_DOMAIN" >/dev/null 2>&1 || true; defaults delete "$TARGET_DOMAIN" >/dev/null 2>&1 || true; rm -f "$FIXTURE"; [[ -z "$LEGACY_TEST_ROOT" ]] || rm -rf "$LEGACY_TEST_ROOT"' EXIT

cat > "$FIXTURE" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>multiAccountMenuLayout</key><string>merged</string>
  <key>claudeSwapEnabled</key><true/>
  <key>SUEnableAutomaticChecks</key><true/>
  <key>CodexBarPersonalSettingsMigrationVersion</key><integer>1</integer>
</dict></plist>
PLIST

defaults import "$SOURCE_DOMAIN" "$FIXTURE" >/dev/null
CODEXBAR_PERSONAL_MIN_FREE_KB=1 "$ROOT/Scripts/install_personal_app.sh" --check-headroom-only
if CODEXBAR_PERSONAL_MIN_FREE_KB=999999999999 \
  "$ROOT/Scripts/install_personal_app.sh" --check-headroom-only >/dev/null 2>&1
then
  echo "Insufficient disk headroom unexpectedly passed" >&2
  exit 1
fi

CODEXBAR_PERSONAL_SOURCE_DOMAIN="$SOURCE_DOMAIN" \
CODEXBAR_PERSONAL_BUNDLE_ID="$TARGET_DOMAIN" \
  "$ROOT/Scripts/install_personal_app.sh" --migrate-settings-only >/dev/null

[[ "$(defaults read "$TARGET_DOMAIN" multiAccountMenuLayout)" == "merged" ]]
[[ "$(defaults read "$TARGET_DOMAIN" claudeSwapEnabled)" == "1" ]]
[[ "$(defaults read "$TARGET_DOMAIN" CodexBarPersonalSettingsMigrationVersion)" == "1" ]]
if defaults read "$TARGET_DOMAIN" SUEnableAutomaticChecks >/dev/null 2>&1; then
  echo "Sparkle settings unexpectedly migrated" >&2
  exit 1
fi

defaults write "$TARGET_DOMAIN" personalOnlyValue -string preserved
defaults write "$SOURCE_DOMAIN" multiAccountMenuLayout -string changed
CODEXBAR_PERSONAL_SOURCE_DOMAIN="$SOURCE_DOMAIN" \
CODEXBAR_PERSONAL_BUNDLE_ID="$TARGET_DOMAIN" \
  "$ROOT/Scripts/install_personal_app.sh" --migrate-settings-only >/dev/null
[[ "$(defaults read "$TARGET_DOMAIN" multiAccountMenuLayout)" == "merged" ]]
[[ "$(defaults read "$TARGET_DOMAIN" personalOnlyValue)" == "preserved" ]]

defaults delete "$TARGET_DOMAIN"
defaults write "$TARGET_DOMAIN" unrecognizedValue -bool true
if CODEXBAR_PERSONAL_SOURCE_DOMAIN="$SOURCE_DOMAIN" \
  CODEXBAR_PERSONAL_BUNDLE_ID="$TARGET_DOMAIN" \
  "$ROOT/Scripts/install_personal_app.sh" --migrate-settings-only >/dev/null 2>&1
then
  echo "Unrecognized destination settings unexpectedly overwritten" >&2
  exit 1
fi
[[ "$(defaults read "$TARGET_DOMAIN" unrecognizedValue)" == "1" ]]

if ! rg -q 'env -u CODEX_HOME -u CLAUDE_CONFIG_DIR "\$OPEN_BIN" -g -n' \
  "$ROOT/Scripts/install_personal_app.sh"
then
  echo "Personal app launcher does not clear account-scoped environments and preserve focus" >&2
  exit 1
fi

if ! rg -q 'BUNDLE_ID="\$\{CODEXBAR_PERSONAL_BUNDLE_ID:-com\.pxl\.quotaroom\}"' \
  "$ROOT/Scripts/install_personal_app.sh" \
  || ! rg -q 'TARGET_APP="\$\{CODEXBAR_PERSONAL_INSTALL_PATH:-/Applications/QuotaRoom\.app\}"' \
    "$ROOT/Scripts/install_personal_app.sh"
then
  echo "Personal app installer does not default to the locked QuotaRoom identity" >&2
  exit 1
fi

LEGACY_TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/codexbar-personal-login-item.XXXXXX")"
LEGACY_APP="$LEGACY_TEST_ROOT/CodexBar Personal.app"
STATE_FILE="$LEGACY_TEST_ROOT/state"
ACTION_LOG="$LEGACY_TEST_ROOT/actions.log"
mkdir -p "$LEGACY_APP/Contents/MacOS"
printf 'enabled\n' >"$STATE_FILE"

cat >"$LEGACY_TEST_ROOT/defaults" <<'SH'
#!/usr/bin/env bash
printf 'defaults %s\n' "$*" >>"$ACTION_LOG"
SH
cat >"$LEGACY_TEST_ROOT/open" <<'SH'
#!/usr/bin/env bash
printf 'open %s\n' "$*" >>"$ACTION_LOG"
printf 'disabled\n' >"$STATE_FILE"
SH
cat >"$LEGACY_TEST_ROOT/pkill" <<'SH'
#!/usr/bin/env bash
printf 'pkill %s\n' "$*" >>"$ACTION_LOG"
SH
cat >"$LEGACY_TEST_ROOT/pgrep" <<'SH'
#!/usr/bin/env bash
exit 1
SH
cat >"$LEGACY_TEST_ROOT/sfltool" <<'SH'
#!/usr/bin/env bash
if [[ "$(cat "$STATE_FILE")" == "enabled" ]]; then
  cat <<'DUMP'
#1:
  Name: CodexBar Personal
  Disposition: [enabled, allowed, notified] (0xb)
  Bundle Identifier: com.pxl.codexbar.personal
DUMP
else
  printf 'Items:\n'
fi
SH
chmod +x "$LEGACY_TEST_ROOT/defaults" "$LEGACY_TEST_ROOT/open" "$LEGACY_TEST_ROOT/pgrep" \
  "$LEGACY_TEST_ROOT/pkill" "$LEGACY_TEST_ROOT/sfltool"

ACTION_LOG="$ACTION_LOG" STATE_FILE="$STATE_FILE" \
DEFAULTS_BIN="$LEGACY_TEST_ROOT/defaults" OPEN_BIN="$LEGACY_TEST_ROOT/open" \
PGREP_BIN="$LEGACY_TEST_ROOT/pgrep" PKILL_BIN="$LEGACY_TEST_ROOT/pkill" \
SFLTOOL_BIN="$LEGACY_TEST_ROOT/sfltool" \
CODEXBAR_PERSONAL_LEGACY_APP_PATH="$LEGACY_APP" \
  "$ROOT/Scripts/install_personal_app.sh" --disable-legacy-login-only >/dev/null

[[ "$(cat "$STATE_FILE")" == "disabled" ]]
[[ -d "$LEGACY_APP" ]]
rg -q '^defaults write com\.pxl\.codexbar\.personal launchAtLogin -bool false$' "$ACTION_LOG"
rg -Fq "open -g -n $LEGACY_APP" "$ACTION_LOG"

echo "Personal app installer tests passed."
