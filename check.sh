#!/bin/bash

E2718="$PWD/e-0.02718/e"
EPROG="$PWD/e"
EBASH="$PWD/e.bash"

PASS=0
TOTAL=0

TEST () {
  ((TOTAL++))
  _TEST "$@" && ((PASS++))
}

_TEST () {
  local T E RE2718 REPROG REBASH

  T="$1"  # test input
  E="$2"  # expected result

  RE2718="$("$E2718" "$T")"
  REPROG="$("$EPROG" "$T")"
  REBASH="$( (enable -f "$EBASH" e && e -- "$T") )"

  [[ "$E$E$E" == "$RE2718$REPROG$REBASH" ]] && return 0

  echo -e "INPUT: $T\nEXPCT: $E"
  [[ $E != $RE2718 ]] && echo "E2718: $RE2718"
  [[ $E != $REPROG ]] && echo "EPROG: $REPROG"
  [[ $E != $REBASH ]] && echo "EBASH: $REBASH"
  echo
  return 1
}


TEST 0 0
TEST 1 1
TEST -1 -1
TEST pi 3.14159265358979
TEST sin[pi/2] 1
echo

echo "PASS: $PASS of $TOTAL"
exit $((PASS < TOTAL))
