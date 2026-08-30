#!/bin/bash
# Smoke tests — no browser is ever launched (BROWSER_PICKER_PRINT=1).
set -euo pipefail
cd "$(dirname "$0")/.."

pass=0 fail=0
check() { # desc, expected-substr, actual
  if [[ "$3" == *"$2"* ]]; then echo "ok   - $1"; pass=$((pass + 1)); else
    echo "FAIL - $1"; echo "       want *$2*"; echo "       got  $3"; fail=$((fail + 1)); fi
}

export BROWSER_PICKER_PRINT=1

jq -e . manifest.json >/dev/null && check "manifest is valid JSON" "" ""
check "omarchy validate passes" "OK" "$(omarchy plugin validate . >/dev/null 2>&1 && echo OK || echo FAIL)"

conf_dir="$(mktemp -d)"
mkdir -p "$conf_dir/omarchy-browser-picker"

# A rule that resolves to an installed browser skips the menu.
picked="Firefox"; command -v firefox >/dev/null || picked="Chrome"
printf '[rules]\nexample.com = %s\n' "$picked" >"$conf_dir/omarchy-browser-picker/config"
out="$(XDG_CONFIG_HOME="$conf_dir" bash bin/omarchy-browser-picker https://example.com/ 2>&1 || true)"
check "domain rule routes without a menu" "launch:" "$out"

# bypass_menu opens the default directly.
printf 'default = %s\nbypass_menu = true\n' "$picked" >"$conf_dir/omarchy-browser-picker/config"
out="$(XDG_CONFIG_HOME="$conf_dir" bash bin/omarchy-browser-picker https://nowhere.test/ 2>&1 || true)"
check "bypass_menu opens default directly" "launch:" "$out"

# A bare path becomes a file:// URL.
printf '[rules]\n* = %s\n' "$picked" >"$conf_dir/omarchy-browser-picker/config"
out="$(XDG_CONFIG_HOME="$conf_dir" bash bin/omarchy-browser-picker /tmp/page.html 2>&1 || true)"
check "local path is turned into file://" "file:///tmp/page.html" "$out"

rm -rf "$conf_dir"
echo
echo "$pass passed, $fail failed"
[[ $fail -eq 0 ]]
