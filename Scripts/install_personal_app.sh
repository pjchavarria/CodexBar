#!/usr/bin/env bash
# Package and install the personal CodexBar app, replacing the retired QuotaRoom bundle.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${CODEXBAR_PERSONAL_ENV_FILE:-$ROOT/.codexbar-personal.env}"
SOURCE_DOMAIN="${CODEXBAR_PERSONAL_SOURCE_DOMAIN:-}"
BUNDLE_ID="${CODEXBAR_PERSONAL_BUNDLE_ID:-com.pxl.codexbar}"
DISPLAY_NAME="${CODEXBAR_PERSONAL_DISPLAY_NAME:-CodexBar}"
APP_BUNDLE_NAME="${CODEXBAR_PERSONAL_APP_BUNDLE_NAME:-CodexBar.app}"
TARGET_APP="${CODEXBAR_PERSONAL_INSTALL_PATH:-/Applications/CodexBar.app}"
MIGRATION_KEY="CodexBarPersonalSettingsMigrationVersion"
MIGRATION_VERSION=1
DEFAULTS_BIN="${DEFAULTS_BIN:-/usr/bin/defaults}"
PLUTIL_BIN="${PLUTIL_BIN:-/usr/bin/plutil}"
OPEN_BIN="${OPEN_BIN:-/usr/bin/open}"
PGREP_BIN="${PGREP_BIN:-/usr/bin/pgrep}"
PKILL_BIN="${PKILL_BIN:-/usr/bin/pkill}"
SFLTOOL_BIN="${SFLTOOL_BIN:-/usr/bin/sfltool}"
SFLTOOL_TIMEOUT_TICKS="${SFLTOOL_TIMEOUT_TICKS:-50}"
SFLTOOL_TIMEOUT_DELAY="${SFLTOOL_TIMEOUT_DELAY:-0.1}"
SFLTOOL_KILL_GRACE_DELAY="${SFLTOOL_KILL_GRACE_DELAY:-0.2}"
LEGACY_UNREGISTER_DELAY="${CODEXBAR_PERSONAL_LEGACY_UNREGISTER_DELAY:-3}"
LAUNCH_STABILITY_DELAY="${CODEXBAR_PERSONAL_LAUNCH_STABILITY_DELAY:-1}"
MIN_FREE_KB="${CODEXBAR_PERSONAL_MIN_FREE_KB:-6291456}"
LEGACY_PERSONAL_DOMAIN="com.pxl.quotaroom"
LEGACY_PERSONAL_APP="${CODEXBAR_PERSONAL_LEGACY_APP_PATH:-/Applications/QuotaRoom.app}"
PERSONAL_WAS_RUNNING=0
INSTALL_TRANSACTION_DIR=""

log() { printf '%s\n' "$*"; }
warn() { printf 'WARNING: %s\n' "$*" >&2; }
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

open_app() {
  # A launcher such as T3 can scope this shell to one provider account. The menu app must
  # discover the user's ambient and managed accounts instead of inheriting that launcher identity.
  # `-g` lets installs and relaunches finish without stealing focus from the user's current app.
  env -u CODEX_HOME -u CLAUDE_CONFIG_DIR "$OPEN_BIN" -g -n "$1"
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
    fail "CodexBar requires 6 GiB free before a release build; only $((available_kb / 1024)) MiB is available"
  fi
}

resolve_source_domain() {
  if [[ -n "$SOURCE_DOMAIN" ]]; then
    return 0
  fi
  if "$DEFAULTS_BIN" read "$LEGACY_PERSONAL_DOMAIN" >/dev/null 2>&1; then
    SOURCE_DOMAIN="$LEGACY_PERSONAL_DOMAIN"
  else
    SOURCE_DOMAIN=com.steipete.codexbar
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
  resolve_source_domain
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
  "$PLUTIL_BIN" -remove "$MIGRATION_KEY" "$migrated_plist" >/dev/null 2>&1 || true
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
  if "$PGREP_BIN" -f '^/Applications/CodexBar\.app/Contents/MacOS/CodexBar$' >/dev/null 2>&1 \
    || "$PGREP_BIN" -f '^/Applications/QuotaRoom\.app/Contents/MacOS/CodexBar$' >/dev/null 2>&1
  then
    PERSONAL_WAS_RUNNING=1
  fi
  "$PKILL_BIN" -f '^/Applications/CodexBar\.app/Contents/MacOS/CodexBar$' >/dev/null 2>&1 || true
  "$PKILL_BIN" -f '^/Applications/QuotaRoom\.app/Contents/MacOS/CodexBar$' >/dev/null 2>&1 || true
}

run_bounded_sfltool_dump() {
  local output="$1"
  local pid attempt

  "$SFLTOOL_BIN" dumpbtm >"$output" 2>/dev/null &
  pid=$!
  for ((attempt = 1; attempt <= SFLTOOL_TIMEOUT_TICKS; attempt++)); do
    if ! kill -0 "$pid" >/dev/null 2>&1; then
      wait "$pid"
      return $?
    fi
    sleep "$SFLTOOL_TIMEOUT_DELAY"
  done
  kill -TERM "$pid" >/dev/null 2>&1 || true
  sleep "$SFLTOOL_KILL_GRACE_DELAY"
  if kill -0 "$pid" >/dev/null 2>&1; then
    kill -KILL "$pid" >/dev/null 2>&1 || true
  fi
  wait "$pid" >/dev/null 2>&1 || true
  return 124
}

legacy_personal_login_item_is_enabled() {
  local dump
  dump="$(mktemp "${TMPDIR:-/tmp}/codexbar-personal-login-items.XXXXXX")"
  local status=0
  run_bounded_sfltool_dump "$dump" || status=$?
  if [[ "$status" -eq 124 ]]; then
    rm -f "$dump"
    return 2
  fi
  if [[ "$status" -ne 0 || ! -s "$dump" ]]; then
    rm -f "$dump"
    return 3
  fi
  if awk 'BEGIN { RS = "" }
    /Bundle Identifier: com\.pxl\.quotaroom/ && /Disposition: \[enabled/ { found = 1 }
    END { exit found ? 0 : 1 }' "$dump"
  then
    rm -f "$dump"
    return 0
  fi
  rm -f "$dump"
  return 1
}

disable_legacy_personal_login_item() {
  [[ -d "$LEGACY_PERSONAL_APP" ]] || return 0
  validate_legacy_personal_app_path

  "$DEFAULTS_BIN" write "$LEGACY_PERSONAL_DOMAIN" launchAtLogin -bool false
  # The legacy bundle must call SMAppService.mainApp.unregister() as itself. Launch it in the
  # background with its persisted setting off, wait for that startup path, then stop it.
  open_app "$LEGACY_PERSONAL_APP"
  sleep "$LEGACY_UNREGISTER_DELAY"
  "$PKILL_BIN" -f '^/Applications/QuotaRoom\.app/Contents/MacOS/CodexBar$' >/dev/null 2>&1 || true

  local inspection_status=0
  legacy_personal_login_item_is_enabled || inspection_status=$?
  case "$inspection_status" in
    0)
      warn "QuotaRoom remained enabled after unregister; removing the obsolete app so it cannot relaunch"
      ;;
    1)
      log "Disabled the QuotaRoom login item."
      ;;
    2)
      warn "macOS timed out verifying the old login item; removing the obsolete app so it cannot relaunch"
      ;;
    *)
      warn "macOS could not verify the old login item; removing the obsolete app so it cannot relaunch"
      ;;
  esac
  remove_legacy_personal_app
}

validate_legacy_personal_app_path() {
  local parent resolved_parent
  [[ "$LEGACY_PERSONAL_APP" == /* ]] \
    || fail "Legacy app path must be absolute"
  [[ "$(basename "$LEGACY_PERSONAL_APP")" == "QuotaRoom.app" ]] \
    || fail "Legacy app path must end in QuotaRoom.app"
  parent="$(dirname "$LEGACY_PERSONAL_APP")"
  resolved_parent="$(cd "$parent" && pwd -P)" \
    || fail "Could not resolve the legacy app parent directory"
  [[ "$resolved_parent" != "/" ]] \
    || fail "Refusing to operate on a legacy app directly under the filesystem root"
  [[ -d "$LEGACY_PERSONAL_APP/Contents" ]] \
    || fail "Legacy app path is not an application bundle"
}

remove_legacy_personal_app() {
  validate_legacy_personal_app_path
  rm -rf "$LEGACY_PERSONAL_APP"
  [[ ! -e "$LEGACY_PERSONAL_APP" ]] \
    || fail "Could not remove the obsolete QuotaRoom bundle"
  log "Removed the obsolete QuotaRoom app."
}

validate_install_transaction_dir() {
  local transaction_dir="$1"
  local target_dir target_stem resolved_target_dir resolved_transaction_parent
  [[ -n "$transaction_dir" && "$transaction_dir" == /* ]] \
    || fail "Install transaction directory must be absolute"
  target_stem="${APP_BUNDLE_NAME%.app}"
  [[ "$(basename "$transaction_dir")" == ".$target_stem.install."* ]] \
    || fail "Unexpected install transaction directory"
  target_dir="$(dirname "$TARGET_APP")"
  resolved_target_dir="$(cd "$target_dir" && pwd -P)" \
    || fail "Could not resolve the install target directory"
  resolved_transaction_parent="$(cd "$(dirname "$transaction_dir")" && pwd -P)" \
    || fail "Could not resolve the install transaction parent"
  [[ "$resolved_transaction_parent" == "$resolved_target_dir" ]] \
    || fail "Install transaction escaped the target directory"
}

discard_install_transaction() {
  [[ -n "$INSTALL_TRANSACTION_DIR" ]] || return 0
  validate_install_transaction_dir "$INSTALL_TRANSACTION_DIR"
  rm -rf "$INSTALL_TRANSACTION_DIR"
  [[ ! -e "$INSTALL_TRANSACTION_DIR" ]] \
    || fail "Could not remove the replaced app transaction"
  INSTALL_TRANSACTION_DIR=""
}

remove_obsolete_install_artifacts() {
  local target_dir target_stem resolved_target_dir artifact transaction
  local -a transactions=()
  target_dir="$(dirname "$TARGET_APP")"
  target_stem="${APP_BUNDLE_NAME%.app}"
  [[ "$(basename "$TARGET_APP")" == "$APP_BUNDLE_NAME" ]] \
    || fail "Install target must end in $APP_BUNDLE_NAME"
  mkdir -p "$target_dir"
  resolved_target_dir="$(cd "$target_dir" && pwd -P)" \
    || fail "Could not resolve the install target directory"
  [[ "$resolved_target_dir" != "/" ]] \
    || fail "Refusing to clean install artifacts at the filesystem root"

  for artifact in \
    "$target_dir/$target_stem.previous.app" \
    "$target_dir/.$target_stem.installing.app"
  do
    [[ ! -e "$artifact" ]] || rm -rf "$artifact"
  done
  while IFS= read -r -d '' artifact; do
    [[ "$(dirname "$artifact")" == "$target_dir" ]] \
      || fail "Obsolete install artifact escaped the target directory"
    [[ "$(basename "$artifact")" == "$target_stem.failed-"*.app ]] \
      || fail "Unexpected failed install artifact"
    rm -rf "$artifact"
  done < <(find "$target_dir" -mindepth 1 -maxdepth 1 -name "$target_stem.failed-*.app" -print0)

  while IFS= read -r -d '' transaction; do
    validate_install_transaction_dir "$transaction"
    transactions+=("$transaction")
  done < <(find "$target_dir" -mindepth 1 -maxdepth 1 -type d -name ".$target_stem.install.*" -print0)
  if [[ ! -e "$TARGET_APP" ]]; then
    local -a restorable=()
    for transaction in "${transactions[@]}"; do
      [[ ! -e "$transaction/previous.app" ]] || restorable+=("$transaction/previous.app")
    done
    [[ "${#restorable[@]}" -le 1 ]] \
      || fail "Multiple interrupted installs contain a previous app; refusing to guess"
    if [[ "${#restorable[@]}" -eq 1 ]]; then
      mv "${restorable[0]}" "$TARGET_APP" \
        || fail "Could not restore the app from an interrupted install"
    fi
  fi
  for transaction in "${transactions[@]}"; do
    rm -rf "$transaction"
  done
}

restore_running_app_on_failure() {
  local status="$?"
  trap - EXIT
  if [[ "$status" -ne 0 ]]; then
    if [[ -n "$INSTALL_TRANSACTION_DIR" && -d "$INSTALL_TRANSACTION_DIR" ]]; then
      local previous="$INSTALL_TRANSACTION_DIR/previous.app"
      local failed="$INSTALL_TRANSACTION_DIR/failed.app"
      if [[ -e "$TARGET_APP" ]]; then
        mv "$TARGET_APP" "$failed" || true
      fi
      if [[ -e "$previous" && ! -e "$TARGET_APP" ]]; then
        mv "$previous" "$TARGET_APP" || true
      fi
      validate_install_transaction_dir "$INSTALL_TRANSACTION_DIR"
      rm -rf "$INSTALL_TRANSACTION_DIR" || true
      INSTALL_TRANSACTION_DIR=""
    fi
    if [[ "$PERSONAL_WAS_RUNNING" == "1" ]]; then
      if [[ -e "$TARGET_APP" ]]; then
        open_app "$TARGET_APP" || true
      elif [[ -e "$LEGACY_PERSONAL_APP" ]]; then
        open_app "$LEGACY_PERSONAL_APP" || true
      fi
    fi
  fi
  exit "$status"
}

install_packaged_app() {
  local packaged="$1"
  local target_dir target_stem staged previous
  target_dir="$(dirname "$TARGET_APP")"
  target_stem="${APP_BUNDLE_NAME%.app}"

  [[ -d "$packaged" ]] || fail "Missing packaged app at $packaged"
  [[ "$(basename "$TARGET_APP")" == "$APP_BUNDLE_NAME" ]] \
    || fail "Install target must end in $APP_BUNDLE_NAME"
  mkdir -p "$target_dir"
  INSTALL_TRANSACTION_DIR="$(mktemp -d "$target_dir/.$target_stem.install.XXXXXX")"
  validate_install_transaction_dir "$INSTALL_TRANSACTION_DIR"
  staged="$INSTALL_TRANSACTION_DIR/staged.app"
  previous="$INSTALL_TRANSACTION_DIR/previous.app"
  ditto "$packaged" "$staged"
  codesign --verify --deep --strict --verbose=2 "$staged"

  if [[ -e "$TARGET_APP" ]]; then
    mv "$TARGET_APP" "$previous"
  fi
  if ! mv "$staged" "$TARGET_APP"; then
    [[ -e "$previous" && ! -e "$TARGET_APP" ]] && mv "$previous" "$TARGET_APP"
    fail "Could not install the personal app; the previous app was restored"
  fi
}

launch_and_verify() {
  open_app "$TARGET_APP"
  local expected="$TARGET_APP/Contents/MacOS/CodexBar"
  local attempt stable
  for attempt in 1 2 3 4 5 6 7 8 9 10; do
    if "$PGREP_BIN" -f "^${expected}$" >/dev/null 2>&1; then
      # One sighting is not proof it stays running: the legacy bundle is deleted after this
      # returns, so require the process to survive several consecutive polls first.
      for stable in 1 2 3; do
        sleep "$LAUNCH_STABILITY_DELAY"
        "$PGREP_BIN" -f "^${expected}$" >/dev/null 2>&1 \
          || fail "CodexBar exited right after launch"
      done
      log "CodexBar is running."
      return 0
    fi
    sleep 1
  done
  fail "CodexBar did not stay running"
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
  if [[ "${1:-}" == "--disable-legacy-login-only" ]]; then
    stop_installed_apps
    disable_legacy_personal_login_item
    if [[ "$PERSONAL_WAS_RUNNING" == "1" && -d "$TARGET_APP" ]]; then
      open_app "$TARGET_APP"
    fi
    return 0
  fi

  check_disk_headroom
  remove_obsolete_install_artifacts

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
    CODEXBAR_APP_BUNDLE_NAME="$APP_BUNDLE_NAME" \
    CODEXBAR_BUNDLE_ID="$BUNDLE_ID" \
    CODEXBAR_DISPLAY_NAME="$DISPLAY_NAME" \
    CODEXBAR_FEED_URL="" \
    CODEXBAR_AUTO_CHECKS=false \
    CODEXBAR_INCLUDE_WIDGET=0 \
    CODEXBAR_INCLUDE_APP_GROUP=0 \
    "$ROOT/Scripts/package_app.sh" release

  local packaged="$ROOT/$APP_BUNDLE_NAME"
  [[ "$(defaults read "$packaged/Contents/Info.plist" CFBundleIdentifier)" == "$BUNDLE_ID" ]] \
    || fail "Packaged bundle identifier does not match the personal app"
  [[ "$(defaults read "$packaged/Contents/Info.plist" SUEnableAutomaticChecks)" == "0" ]] \
    || fail "Personal app update checks are not disabled"
  install_packaged_app "$packaged"
  # The legacy QuotaRoom bundle stays untouched until the replacement has proven it stays running:
  # a launch failure must leave the user with the app they had, and the failure trap relaunches it.
  launch_and_verify
  discard_install_transaction
  trap - EXIT
  # Only a verified, running CodexBar retires the QuotaRoom login item and bundle. A failure past
  # this point exits loudly but never tears down the healthy install above.
  disable_legacy_personal_login_item
}

if [[ "${CODEXBAR_PERSONAL_SOURCE_ONLY:-0}" != "1" ]]; then
  main "$@"
fi
