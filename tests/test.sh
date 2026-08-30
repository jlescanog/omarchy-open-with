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
echo
echo "$pass passed, $fail failed"
[[ $fail -eq 0 ]]
