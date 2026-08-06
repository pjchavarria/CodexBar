#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_DOMAIN="CodexBarPersonalMigrationSourceTests-$RANDOM-$$"
TARGET_DOMAIN="CodexBarPersonalMigrationTargetTests-$RANDOM-$$"
FIXTURE="$(mktemp "${TMPDIR:-/tmp}/codexbar-personal-settings-fixture.XXXXXX")"
trap 'defaults delete "$SOURCE_DOMAIN" >/dev/null 2>&1 || true; defaults delete "$TARGET_DOMAIN" >/dev/null 2>&1 || true; rm -f "$FIXTURE"' EXIT

cat > "$FIXTURE" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>multiAccountMenuLayout</key><string>merged</string>
  <key>claudeSwapEnabled</key><true/>
  <key>SUEnableAutomaticChecks</key><true/>
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

if ! rg -q 'env -u CODEX_HOME -u CLAUDE_CONFIG_DIR open -g -n' \
  "$ROOT/Scripts/install_personal_app.sh"
then
  echo "Personal app launcher does not clear account-scoped environments and preserve focus" >&2
  exit 1
fi

echo "Personal app installer tests passed."
