#!/usr/bin/env bash
# ctxc test suite: exit codes, filters, budget behavior, --json shape.
set -u
cd "$(dirname "$0")/.."
CTXC=./ctxc
FX=test/fixtures/tiny
fails=0

check() { # name expected actual
  if [ "$2" = "$3" ]; then
    printf 'ok   %s\n' "$1"
  else
    printf 'FAIL %s: want %s, got %s\n' "$1" "$2" "$3"
    fails=$((fails + 1))
  fi
}

t() { # desc expect_rc cmd...
  local desc=$1 want=$2; shift 2
  "$@" >/dev/null 2>&1
  check "$desc (exit)" "$want" "$?"
}

# exit codes
t "no args packs cwd"        0 $CTXC $FX
t "missing dir dies"         2 $CTXC /nonexistent-ctxc-xyz
t "unknown flag dies"        2 $CTXC $FX --nope
t "help exits clean"         0 $CTXC --help

# --list
$CTXC $FX --list | grep -q . && check "--list non-empty" 1 1 || check "--list non-empty" 0 1

# include/exclude
c=$($CTXC $FX --include '*.md' --list | wc -l | tr -d ' ')
check "--include narrows to md" 1 "$c"
c=$($CTXC $FX --exclude '*.md' --list | wc -l | tr -d ' ')
check "--exclude drops md" 1 "$c"

# budget: tiny fixture at budget 10 must skip everything but stay alive enough to pack one
$CTXC $FX --budget 10 --json >/dev/null 2>"$FX.out"
grep -q "budget reached" "$FX.out" && check "budget note emitted" 1 1 || check "budget note emitted" 0 1
j=$($CTXC $FX --json)
printf '%s' "$j" | grep -q '"binaries":"excluded"' && check "json binaries excluded" 1 1 || check "json binaries excluded" 0 1

# binary skip: fixture PNG is skipped by default, kept with --include-binaries
mkdir -p "$FX/assets"
printf '\x89PNG\r\n\x00\x1a\n rest' > "$FX/assets/logo.png"
$CTXC $FX --list | grep -q "logo.png" && check "binary skipped by default" 0 1 || check "binary skipped by default" 1 1
$CTXC $FX --include-binaries --list | grep -q "logo.png" && check "--include-binaries keeps png" 1 1 || check "--include-binaries keeps png" 0 1
rm -rf "$FX/assets"
printf '%s' "$j" | grep -q '"files":'          && check "json has files"   1 1 || check "json has files" 0 1
printf '%s' "$j" | grep -q '"est_tokens":[0-9]' && check "json has tokens" 1 1 || check "json has tokens" 0 1

rm -f "$FX.out"
echo
if [ "$fails" -eq 0 ]; then echo "all tests passed"; exit 0; fi
echo "$fails test(s) failed"; exit 1
