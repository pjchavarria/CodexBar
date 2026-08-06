#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FILES=(
  "$ROOT/AGENTS.md"
  "$ROOT/Makefile"
  "$ROOT/Scripts/compile_and_run.sh"
  "$ROOT/Scripts/install_personal_app.sh"
  "$ROOT/Scripts/launch.sh"
  "$ROOT/Scripts/test_live_update.sh"
  "$ROOT/.agents/skills/qa-test/SKILL.md"
  "$ROOT/.agents/skills/release-codexbar/SKILL.md"
  "$ROOT/docs/DEVELOPMENT_SETUP.md"
  "$ROOT/docs/FORK_QUICK_START.md"
  "$ROOT/docs/RELEASING.md"
  "$ROOT/docs/releasing-homebrew.md"
)

unsafe_pattern='(?<![[:alnum:]_])open[[:space:]]+(?!-g(?:[[:space:]]|$))(?=-|["$/.~]|CodexBar)'

line_is_unsafe() {
  printf '%s\n' "$1" | rg --pcre2 -q "$unsafe_pattern"
}

UNSAFE_SAMPLES=(
  'open "$APP_PATH"'
  'open "$PWD/CodexBar.app"'
  'open -F CodexBar.app'
  'open /Applications/CodexBar.app'
  'open CodexBar.app'
)
SAFE_SAMPLES=(
  'open -g "$APP_PATH"'
  'open -g -n "$PWD/CodexBar.app"'
  'open -g -F CodexBar.app'
  'open -g /Applications/CodexBar.app'
  'open -g -a CodexBar'
)

for sample in "${UNSAFE_SAMPLES[@]}"; do
  line_is_unsafe "$sample" || {
    echo "Background launch policy failed to reject: $sample" >&2
    exit 1
  }
done
for sample in "${SAFE_SAMPLES[@]}"; do
  if line_is_unsafe "$sample"; then
    echo "Background launch policy rejected a nonactivating launch: $sample" >&2
    exit 1
  fi
done

if rg --pcre2 -n "$unsafe_pattern" "${FILES[@]}"; then
  echo "Foreground app launch found; use open -g for background-safe relaunches." >&2
  exit 1
fi

for file in "${FILES[@]}"; do
  [[ -f "$file" ]] || {
    echo "Missing background-launch policy input: $file" >&2
    exit 1
  }
done

echo "Background launch policy tests passed."
