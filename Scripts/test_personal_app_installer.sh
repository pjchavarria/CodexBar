#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_DOMAIN="CodexBarPersonalMigrationSourceTests-$RANDOM-$$"
TARGET_DOMAIN="CodexBarPersonalMigrationTargetTests-$RANDOM-$$"
FIXTURE="$(mktemp "${TMPDIR:-/tmp}/codexbar-personal-settings-fixture.XXXXXX")"
LEGACY_TEST_ROOT=""
RECOVERY_TEST_ROOT=""
TIMEOUT_LOG=""
SFLTOOL_PID_FILE=""
trap 'defaults delete "$SOURCE_DOMAIN" >/dev/null 2>&1 || true; defaults delete "$TARGET_DOMAIN" >/dev/null 2>&1 || true; rm -f "$FIXTURE" "$TIMEOUT_LOG" "$SFLTOOL_PID_FILE"; [[ -z "$LEGACY_TEST_ROOT" ]] || rm -rf "$LEGACY_TEST_ROOT"; [[ -z "$RECOVERY_TEST_ROOT" ]] || rm -rf "$RECOVERY_TEST_ROOT"' EXIT

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
mkdir -p "$LEGACY_TEST_ROOT/not-the-legacy-app/Contents"
if CODEXBAR_PERSONAL_LEGACY_APP_PATH="$LEGACY_TEST_ROOT/not-the-legacy-app" \
  "$ROOT/Scripts/install_personal_app.sh" --disable-legacy-login-only >/dev/null 2>&1
then
  echo "Unsafe legacy app path unexpectedly accepted" >&2
  exit 1
fi
[[ -d "$LEGACY_TEST_ROOT/not-the-legacy-app" ]]

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
if [[ "${HANG_SFLTOOL:-0}" == "1" ]]; then
  printf '%s\n' "$$" >"$SFLTOOL_PID_FILE"
  trap '' TERM
  exec sleep 10
fi
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
CODEXBAR_PERSONAL_LEGACY_UNREGISTER_DELAY=0.01 \
CODEXBAR_PERSONAL_LEGACY_APP_PATH="$LEGACY_APP" \
  "$ROOT/Scripts/install_personal_app.sh" --disable-legacy-login-only >/dev/null

[[ "$(cat "$STATE_FILE")" == "disabled" ]]
[[ ! -e "$LEGACY_APP" ]]
rg -q '^defaults write com\.pxl\.codexbar\.personal launchAtLogin -bool false$' "$ACTION_LOG"
rg -Fq "open -g -n $LEGACY_APP" "$ACTION_LOG"

mkdir -p "$LEGACY_APP/Contents/MacOS"
printf 'enabled\n' >"$STATE_FILE"
TIMEOUT_LOG="$(mktemp "${TMPDIR:-/tmp}/codexbar-personal-login-timeout.XXXXXX")"
SFLTOOL_PID_FILE="$(mktemp "${TMPDIR:-/tmp}/codexbar-personal-login-pid.XXXXXX")"
timeout_started=$SECONDS
ACTION_LOG="$ACTION_LOG" STATE_FILE="$STATE_FILE" HANG_SFLTOOL=1 SFLTOOL_PID_FILE="$SFLTOOL_PID_FILE" \
  DEFAULTS_BIN="$LEGACY_TEST_ROOT/defaults" OPEN_BIN="$LEGACY_TEST_ROOT/open" \
  PGREP_BIN="$LEGACY_TEST_ROOT/pgrep" PKILL_BIN="$LEGACY_TEST_ROOT/pkill" \
  SFLTOOL_BIN="$LEGACY_TEST_ROOT/sfltool" SFLTOOL_TIMEOUT_TICKS=2 SFLTOOL_TIMEOUT_DELAY=0.01 \
  SFLTOOL_KILL_GRACE_DELAY=0.01 \
  CODEXBAR_PERSONAL_LEGACY_UNREGISTER_DELAY=0.01 \
  CODEXBAR_PERSONAL_LEGACY_APP_PATH="$LEGACY_APP" \
    "$ROOT/Scripts/install_personal_app.sh" --disable-legacy-login-only >"$TIMEOUT_LOG" 2>&1
[[ "$((SECONDS - timeout_started))" -lt 3 ]]
rg -Fq "WARNING: macOS timed out verifying the old login item; removing the obsolete app so it cannot relaunch" \
  "$TIMEOUT_LOG"
[[ "$(cat "$STATE_FILE")" == "disabled" ]]
[[ ! -e "$LEGACY_APP" ]]
if kill -0 "$(cat "$SFLTOOL_PID_FILE")" >/dev/null 2>&1; then
  echo "Timed-out login-item inspector survived cleanup" >&2
  exit 1
fi

if rg -Fq 'LEGACY_PERSONAL_ROLLBACK_ARCHIVE' "$ROOT/Scripts/install_personal_app.sh" \
  || rg -Fq '${TARGET_APP%.app}.previous.app' "$ROOT/Scripts/install_personal_app.sh" \
  || rg -Fq '${TARGET_APP%.app}.failed-' "$ROOT/Scripts/install_personal_app.sh" \
  || rg -Fq '.QuotaRoom.installing.app' "$ROOT/Scripts/install_personal_app.sh"
then
  echo "Personal app installer still creates a persistent rollback launchable" >&2
  exit 1
fi

RECOVERY_TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/codexbar-personal-recovery.XXXXXX")"
RECOVERY_TARGET="$RECOVERY_TEST_ROOT/QuotaRoom.app"
RECOVERY_TRANSACTION="$(mktemp -d "$RECOVERY_TEST_ROOT/.QuotaRoom.install.XXXXXX")"
mkdir -p "$RECOVERY_TARGET/Contents/MacOS"
if CODEXBAR_PERSONAL_SOURCE_ONLY=1 CODEXBAR_PERSONAL_INSTALL_PATH="$RECOVERY_TARGET" \
  bash -c 'source "$1"; INSTALL_TRANSACTION_DIR="$2"; trap restore_running_app_on_failure EXIT; false' \
    installer-test "$ROOT/Scripts/install_personal_app.sh" "$RECOVERY_TRANSACTION"
then
  echo "Failed first install unexpectedly reported success" >&2
  exit 1
fi
[[ ! -e "$RECOVERY_TARGET" ]]
[[ ! -e "$RECOVERY_TRANSACTION" ]]

RECOVERY_TRANSACTION="$(mktemp -d "$RECOVERY_TEST_ROOT/.QuotaRoom.install.XXXXXX")"
mkdir -p "$RECOVERY_TARGET/Contents/MacOS" "$RECOVERY_TRANSACTION/previous.app/Contents/MacOS"
printf 'new\n' >"$RECOVERY_TARGET/version"
printf 'old\n' >"$RECOVERY_TRANSACTION/previous.app/version"
if CODEXBAR_PERSONAL_SOURCE_ONLY=1 CODEXBAR_PERSONAL_INSTALL_PATH="$RECOVERY_TARGET" \
  bash -c 'source "$1"; INSTALL_TRANSACTION_DIR="$2"; trap restore_running_app_on_failure EXIT; false' \
    installer-test "$ROOT/Scripts/install_personal_app.sh" "$RECOVERY_TRANSACTION"
then
  echo "Failed replacement unexpectedly reported success" >&2
  exit 1
fi
[[ "$(cat "$RECOVERY_TARGET/version")" == "old" ]]
[[ ! -e "$RECOVERY_TRANSACTION" ]]

mkdir -p \
  "$RECOVERY_TEST_ROOT/QuotaRoom.previous.app" \
  "$RECOVERY_TEST_ROOT/.QuotaRoom.installing.app" \
  "$RECOVERY_TEST_ROOT/QuotaRoom.failed-123.app" \
  "$RECOVERY_TEST_ROOT/.QuotaRoom.install.STALE"
CODEXBAR_PERSONAL_SOURCE_ONLY=1 CODEXBAR_PERSONAL_INSTALL_PATH="$RECOVERY_TARGET" \
  bash -c 'source "$1"; remove_obsolete_install_artifacts' \
    installer-test "$ROOT/Scripts/install_personal_app.sh"
[[ -e "$RECOVERY_TARGET" ]]
[[ ! -e "$RECOVERY_TEST_ROOT/QuotaRoom.previous.app" ]]
[[ ! -e "$RECOVERY_TEST_ROOT/.QuotaRoom.installing.app" ]]
[[ ! -e "$RECOVERY_TEST_ROOT/QuotaRoom.failed-123.app" ]]
[[ ! -e "$RECOVERY_TEST_ROOT/.QuotaRoom.install.STALE" ]]

echo "Personal app installer tests passed."
