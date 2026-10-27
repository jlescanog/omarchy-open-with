#!/bin/bash
# Smoke tests. No browser is launched — every case uses --print.
set -euo pipefail
cd "$(dirname "$0")/.."

pass=0 fail=0
check() { # desc, expected-substr, actual
  if [[ "$3" == *"$2"* ]]; then echo "ok   - $1"; pass=$((pass + 1)); else
    echo "FAIL - $1"; echo "       want *$2*"; echo "       got  $3"; fail=$((fail + 1)); fi
}

jq -e . manifest.json >/dev/null && check "manifest is valid JSON" "" ""
check "omarchy validate passes" "OK" \
  "$(omarchy plugin validate . >/dev/null 2>&1 && echo OK || echo FAIL)"

# Stub the menu so a choice can be forced.
stub="$(mktemp -d)"
cat >"$stub/omarchy" <<'S'
#!/bin/bash
[ "$1 $2" = "menu ping" ] && { echo ok; exit 0; }
[ "$1 $2" = "menu select" ] && { cat "${OW_PICK:?}"; exit 0; }
exit 1
S
chmod +x "$stub/omarchy"
sel="$(mktemp)"
run() { OW_PICK="$sel" PATH="$stub:$PATH" bash bin/omarchy-open-with --print "$1" 2>&1; }

# Pick the first discovered browser label for the launch tests.
first="$(bash -c 'source <(sed -n "46,112p" bin/omarchy-open-with)
  mapfile -t o < <(for i in "${!labels[@]}"; do printf "%s\t%s\n" "${labels[$i]#*$'"'"'\t'"'"'}" "$i"; done | sort | cut -f2)
  echo "${labels[${o[0]}]#*$'"'"'\t'"'"'}"' 2>/dev/null)"

printf '%s' "$first" >"$sel"
check "a real choice resolves to a launch" "launch:" "$(run 'https://example.com/')"

printf 'Copy link' >"$sel"
check "Copy link resolves to copy" "copy: https://example.com/x" "$(run 'https://example.com/x')"

printf 'Copy link' >"$sel"
check "a bare path becomes file://" "copy: file:///tmp/p.html" "$(run '/tmp/p.html')"

# A profile name with shell metacharacters must survive as one argv element.
printf '%s' "$first" >"$sel"
out="$(run 'https://example.com/;rm -rf ~')"
# --print shows argv via `printf %q`; a split would put "rm" on its own,
# unescaped. One argument keeps the ';' and space backslash-escaped together.
check "url with ; stays one argument" 'example.com/\;rm\ -rf' "$out"

rm -rf "$stub" "$sel"

# open-with-ctl against a throwaway XDG tree shaped like Omarchy's: links routed
# through omarchy-browser.desktop by hyprland-mimeapps.list, the real browser
# in mimeapps.list.
xdg="$(mktemp -d)"
mkdir -p "$xdg/config" "$xdg/data/applications" "$xdg/state"
printf '[Desktop Entry]\nType=Application\nName=Browser\nExec=sh %%U\nMimeType=x-scheme-handler/http;x-scheme-handler/https;\n' \
  >"$xdg/data/applications/omarchy-browser.desktop"
printf '[Desktop Entry]\nType=Application\nName=Chromium\nExec=sh %%U\nMimeType=x-scheme-handler/http;x-scheme-handler/https;text/html;\n' \
  >"$xdg/data/applications/chromium.desktop"
printf '[Default Applications]\ntext/html=chromium.desktop\nx-scheme-handler/http=chromium.desktop\nx-scheme-handler/https=chromium.desktop\n' \
  >"$xdg/config/mimeapps.list"
printf '# keep me\n[Default Applications]\nx-scheme-handler/http=omarchy-browser.desktop\nx-scheme-handler/https=omarchy-browser.desktop\n' \
  >"$xdg/config/hyprland-mimeapps.list"
cp "$xdg/config/mimeapps.list" "$xdg/mimeapps.orig"
cp "$xdg/config/hyprland-mimeapps.list" "$xdg/hyprland.orig"
mkdir -p "$xdg/home"
printf '[[ $- != *i* ]] && return\nsource "$OMARCHY_PATH/default/bash/rc"\n\n# mine\nalias p=python\n' \
  >"$xdg/home/.bashrc"
cp "$xdg/home/.bashrc" "$xdg/bashrc.orig"

sandbox() {
  env XDG_CONFIG_HOME="$xdg/config" XDG_DATA_HOME="$xdg/data" XDG_STATE_HOME="$xdg/state" HOME="$xdg/home" \
    XDG_DATA_DIRS="$xdg/data" XDG_CURRENT_DESKTOP=Hyprland "$@"
}
ctl() { sandbox bash bin/open-with-ctl "$@" 2>&1; }
query() { sandbox xdg-mime query default "$@" 2>/dev/null; }

ctl install >/dev/null
check "install: status reports installed" "installed (" "$(ctl status)"
check "install: https goes to Open With" "io.github.jlescanog.open-with.desktop" "$(query x-scheme-handler/https)"
check "install: http left to Omarchy" "omarchy-browser.desktop" "$(query x-scheme-handler/http)"
check "install: mimeapps.list untouched" "same" \
  "$(cmp -s "$xdg/mimeapps.orig" "$xdg/config/mimeapps.list" && echo same || echo changed)"
ctl install >/dev/null
check "install: one BROWSER block, right after Omarchy's rc" 'bash/rc"|# >>> open-with >>>|1' \
  "$(grep -A1 'default/bash/rc' "$xdg/home/.bashrc" | paste -sd'|')|$(grep -c '^# >>> open-with' "$xdg/home/.bashrc")"
check "install: BROWSER points at the picker" "bin/omarchy-open-with" \
  "$(BROWSER=omarchy-launch-browser bash -c 'source <(sed -n "/^# >>> open-with/,/^# <<< open-with/p" "$1"); echo "$BROWSER"' _ "$xdg/home/.bashrc")"
ctl uninstall >/dev/null
check "uninstall: status reports not installed" "not installed" "$(ctl status)"
check "uninstall: hyprland list restored exactly" "same" \
  "$(cmp -s "$xdg/hyprland.orig" "$xdg/config/hyprland-mimeapps.list" && echo same || echo changed)"
check "uninstall: .bashrc restored exactly" "same" \
  "$(cmp -s "$xdg/bashrc.orig" "$xdg/home/.bashrc" && echo same || echo changed)"

rm -rf "$xdg"
echo
echo "$pass passed, $fail failed"
[[ $fail -eq 0 ]]
