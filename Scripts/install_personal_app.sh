#!/usr/bin/env bash
# Package and install the personalized fork alongside upstream CodexBar.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${CODEXBAR_PERSONAL_ENV_FILE:-$ROOT/.codexbar-personal.env}"
SOURCE_DOMAIN="${CODEXBAR_PERSONAL_SOURCE_DOMAIN:-com.steipete.codexbar}"
BUNDLE_ID="${CODEXBAR_PERSONAL_BUNDLE_ID:-com.pxl.codexbar.personal}"
DISPLAY_NAME="${CODEXBAR_PERSONAL_DISPLAY_NAME:-CodexBar Personal}"
TARGET_APP="${CODEXBAR_PERSONAL_INSTALL_PATH:-/Applications/CodexBar Personal.app}"
MIGRATION_KEY="CodexBarPersonalSettingsMigrationVersion"
MIGRATION_VERSION=1
DEFAULTS_BIN="${DEFAULTS_BIN:-/usr/bin/defaults}"
PLUTIL_BIN="${PLUTIL_BIN:-/usr/bin/plutil}"
MIN_FREE_KB="${CODEXBAR_PERSONAL_MIN_FREE_KB:-6291456}"
UPSTREAM_APP="/Applications/CodexBar.app"
UPSTREAM_WAS_RUNNING=0
PERSONAL_WAS_RUNNING=0
INSTALLED_NEW_APP=0

log() { printf '%s\n' "$*"; }
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

open_app() {
  # A launcher such as T3 can scope this shell to one provider account. The menu app must
  # discover the user's ambient and managed accounts instead of inheriting that launcher identity.
  env -u CODEX_HOME -u CLAUDE_CONFIG_DIR open -n "$1"
}

load_local_environment() {
  if [[ -f "$ENV_FILE" ]]; then
    # The file is gitignored and contains local signing selection only.
    # shellcheck disable=SC1090
    source "$ENV_FILE"
  fi
}

resolve_identity_hash() {
  local team_id="$1"
  local line hash label subject matches=""
  while IFS= read -r line; do
    [[ "$line" == *'"Apple Development:'* ]] || continue
    hash="$(printf '%s\n' "$line" | awk '{print $2}')"
    label="${line#*\"}"
    label="${label%\"*}"
    subject="$(security find-certificate -c "$label" -p 2>/dev/null \
      | openssl x509 -noout -subject -nameopt RFC2253 2>/dev/null || true)"
    if [[ "$subject" == *",OU=${team_id},"* || "$subject" == subject=OU="${team_id},"* ]]; then
      matches="${matches}${hash}"$'\n'
    fi
  done < <(security find-identity -v -p codesigning 2>/dev/null)

  matches="$(printf '%s' "$matches" | sed '/^$/d' | sort -u)"
  if [[ -z "$matches" ]]; then
    return 1
  fi
  if [[ "$(printf '%s\n' "$matches" | wc -l | tr -d ' ')" -ne 1 ]]; then
    return 2
  fi
  printf '%s\n' "$matches"
}

check_disk_headroom() {
  local build_root available_kb
  build_root="${CODEXBAR_PERSONAL_BUILD_ROOT:-$ROOT}"
  mkdir -p "$build_root"
  available_kb="$(df -Pk "$build_root" | awk 'NR == 2 { print $4 }')"
  [[ "$available_kb" =~ ^[0-9]+$ ]] || fail "Could not determine free disk space"
  [[ "$MIN_FREE_KB" =~ ^[0-9]+$ ]] || fail "CODEXBAR_PERSONAL_MIN_FREE_KB must be an integer"
  if [[ "$available_kb" -lt "$MIN_FREE_KB" ]]; then
    fail "CodexBar Personal requires 6 GiB free before a release build; only $((available_kb / 1024)) MiB is available"
  fi
}

remove_nonportable_defaults() {
  local plist="$1"
  local key
  for key in \
    SUEnableAutomaticChecks \
    SUAutomaticallyUpdate \
    SUHasLaunchedBefore \
    SULastCheckTime \
    SUUpdateGroupIdentifier \
    "NSStatusItem VisibleCC codexbar-merged" \
    "NSStatusItem VisibleCC Item-0"
  do
    "$PLUTIL_BIN" -remove "$key" "$plist" >/dev/null 2>&1 || true
  done
}

migrate_settings_once() (
  local existing source_plist migrated_plist verify_plist
  existing="$(mktemp "${TMPDIR:-/tmp}/codexbar-personal-existing.XXXXXX")"
  source_plist="$(mktemp "${TMPDIR:-/tmp}/codexbar-personal-source.XXXXXX")"
  migrated_plist="$(mktemp "${TMPDIR:-/tmp}/codexbar-personal-migrated.XXXXXX")"
  verify_plist="$(mktemp "${TMPDIR:-/tmp}/codexbar-personal-verify.XXXXXX")"
  trap 'rm -f "$existing" "$source_plist" "$migrated_plist" "$verify_plist"' EXIT

  "$DEFAULTS_BIN" export "$BUNDLE_ID" "$existing" >/dev/null 2>&1 || true
  if "$PLUTIL_BIN" -extract "$MIGRATION_KEY" raw "$existing" >/dev/null 2>&1; then
    log "Personal settings already migrated."
    return 0
  fi
  if "$DEFAULTS_BIN" read "$BUNDLE_ID" >/dev/null 2>&1; then
    fail "The personal settings domain already contains unrecognized data; refusing to overwrite it"
  fi
  if ! "$DEFAULTS_BIN" read "$SOURCE_DOMAIN" >/dev/null 2>&1; then
    fail "The existing CodexBar settings domain is unavailable; no personal settings were written"
  fi
  if ! "$DEFAULTS_BIN" export "$SOURCE_DOMAIN" "$source_plist" >/dev/null 2>&1; then
    fail "Could not read the existing CodexBar settings; no personal settings were written"
  fi

  cp "$source_plist" "$migrated_plist"
  remove_nonportable_defaults "$migrated_plist"
  "$PLUTIL_BIN" -insert "$MIGRATION_KEY" -integer "$MIGRATION_VERSION" "$migrated_plist"

  if ! "$DEFAULTS_BIN" import "$BUNDLE_ID" "$migrated_plist" >/dev/null 2>&1; then
    "$DEFAULTS_BIN" delete "$BUNDLE_ID" >/dev/null 2>&1 || true
    fail "Could not import the personal settings; the partial destination was removed"
  fi
  if ! "$DEFAULTS_BIN" export "$BUNDLE_ID" "$verify_plist" >/dev/null 2>&1 \
    || [[ "$("$PLUTIL_BIN" -extract "$MIGRATION_KEY" raw "$verify_plist" 2>/dev/null || true)" != "$MIGRATION_VERSION" ]]
  then
    "$DEFAULTS_BIN" delete "$BUNDLE_ID" >/dev/null 2>&1 || true
    fail "Could not verify the personal settings; the destination was rolled back"
  fi
  log "Copied existing CodexBar settings into the personal app."
)

stop_installed_apps() {
  if pgrep -f '^/Applications/CodexBar\.app/Contents/MacOS/CodexBar$' >/dev/null 2>&1; then
    UPSTREAM_WAS_RUNNING=1
  fi
  if pgrep -f '^/Applications/CodexBar Personal\.app/Contents/MacOS/CodexBar$' >/dev/null 2>&1; then
    PERSONAL_WAS_RUNNING=1
  fi
  pkill -f '^/Applications/CodexBar\.app/Contents/MacOS/CodexBar$' >/dev/null 2>&1 || true
  pkill -f '^/Applications/CodexBar Personal\.app/Contents/MacOS/CodexBar$' >/dev/null 2>&1 || true
}

restore_running_app_on_failure() {
  local status="$?"
  trap - EXIT
  if [[ "$status" -ne 0 ]]; then
    local previous="$(dirname "$TARGET_APP")/CodexBar Personal.previous.app"
    if [[ "$INSTALLED_NEW_APP" == "1" && -e "$TARGET_APP" ]]; then
      mv "$TARGET_APP" "$(dirname "$TARGET_APP")/CodexBar Personal.failed-$$.app" || true
    fi
    if [[ "$INSTALLED_NEW_APP" == "1" && -e "$previous" && ! -e "$TARGET_APP" ]]; then
      mv "$previous" "$TARGET_APP" || true
    fi
    if [[ "$PERSONAL_WAS_RUNNING" == "1" && -e "$TARGET_APP" ]]; then
      open_app "$TARGET_APP" || true
    elif [[ "$UPSTREAM_WAS_RUNNING" == "1" && -e "$UPSTREAM_APP" ]]; then
      open_app "$UPSTREAM_APP" || true
    fi
  fi
  exit "$status"
}

install_packaged_app() {
  local packaged="$1"
  local target_dir staged previous
  target_dir="$(dirname "$TARGET_APP")"
  staged="$target_dir/.CodexBar Personal.installing.app"
  previous="$target_dir/CodexBar Personal.previous.app"

  [[ -d "$packaged" ]] || fail "Missing packaged app at $packaged"
  [[ "$TARGET_APP" == */"CodexBar Personal.app" ]] \
    || fail "Install target must end in CodexBar Personal.app"
  mkdir -p "$target_dir"
  rm -rf "$staged"
  ditto "$packaged" "$staged"
  codesign --verify --deep --strict --verbose=2 "$staged"

  if [[ -e "$previous" ]]; then
    if command -v trash >/dev/null 2>&1; then
      trash "$previous"
    else
      fail "A previous backup already exists at $previous; move it before updating"
    fi
  fi
  if [[ -e "$TARGET_APP" ]]; then
    mv "$TARGET_APP" "$previous"
  fi
  if ! mv "$staged" "$TARGET_APP"; then
    [[ -e "$previous" && ! -e "$TARGET_APP" ]] && mv "$previous" "$TARGET_APP"
    fail "Could not install the personal app; the previous app was restored"
  fi
  INSTALLED_NEW_APP=1
}

launch_and_verify() {
  open_app "$TARGET_APP"
  local expected="$TARGET_APP/Contents/MacOS/CodexBar"
  local attempt
  for attempt in 1 2 3 4 5 6 7 8 9 10; do
    if pgrep -f "^${expected}$" >/dev/null 2>&1; then
      log "CodexBar Personal is running."
      return 0
    fi
    sleep 1
  done
  fail "CodexBar Personal did not stay running"
}

main() {
  load_local_environment
  if [[ "${1:-}" == "--migrate-settings-only" ]]; then
    migrate_settings_once
    return 0
  fi
  if [[ "${1:-}" == "--check-headroom-only" ]]; then
    check_disk_headroom
    return 0
  fi

  check_disk_headroom

  local team_id="${CODEXBAR_PERSONAL_TEAM_ID:-}"
  local identity="${APP_IDENTITY:-}"
  local build_root="${CODEXBAR_PERSONAL_BUILD_ROOT:-$ROOT/.build}"
  [[ -n "$team_id" ]] || fail "Set CODEXBAR_PERSONAL_TEAM_ID in $ENV_FILE"
  if [[ -z "$identity" ]]; then
    identity="$(resolve_identity_hash "$team_id")" \
      || fail "Could not resolve one Apple Development identity for the configured team"
  fi

  stop_installed_apps
  trap restore_running_app_on_failure EXIT
  migrate_settings_once

  env \
    APP_IDENTITY="$identity" \
    APP_TEAM_ID="$team_id" \
    CODEXBAR_SIGNING=identity \
    CODEXBAR_BUILD_ROOT="$build_root" \
    CODEXBAR_APP_BUNDLE_NAME="CodexBar Personal.app" \
    CODEXBAR_BUNDLE_ID="$BUNDLE_ID" \
    CODEXBAR_DISPLAY_NAME="$DISPLAY_NAME" \
    CODEXBAR_FEED_URL="" \
    CODEXBAR_AUTO_CHECKS=false \
    CODEXBAR_INCLUDE_WIDGET=0 \
    CODEXBAR_INCLUDE_APP_GROUP=0 \
    "$ROOT/Scripts/package_app.sh" release

  local packaged="$ROOT/CodexBar Personal.app"
  [[ "$(defaults read "$packaged/Contents/Info.plist" CFBundleIdentifier)" == "$BUNDLE_ID" ]] \
    || fail "Packaged bundle identifier does not match the personal app"
  [[ "$(defaults read "$packaged/Contents/Info.plist" SUEnableAutomaticChecks)" == "0" ]] \
    || fail "Personal app update checks are not disabled"
  install_packaged_app "$packaged"
  launch_and_verify
  trap - EXIT
}

main "$@"
