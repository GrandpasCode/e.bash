#!/bin/bash

E2718="$PWD/e-0.02718/e"
EPROG="$PWD/e"
EBASH="$PWD/e.bash"

SKIP=0
PASS=0
TOTAL=0

TEST () {
  ((TOTAL++))
  _TEST "$@" && ((PASS++))
  SKIP_E2718=
}

FMT () {
  echo "$@" | sed '2,$ s/^/       /'
}

_TEST () {
  local T E RE2718 REPROG REBASH

  E="$1"    # expected result
  shift
  T=("$@")  # test input

  RE2718="$("$E2718" "${T[@]}")"
  REPROG="$("$EPROG" "${T[@]}")"
  REBASH="$( (enable -f "$EBASH" e && e -- "${T[@]}") )"

  [[ "$E$E$E" == "$RE2718$REPROG$REBASH" ]] && return 0

  FMT "INPUT: ${T[@]}"
  FMT "EXPCT: $E"
  [[ $E != $RE2718 ]] && FMT "E2718: $RE2718"
  [[ $E != $REPROG ]] && FMT "EPROG: $REPROG"
  [[ $E != $REBASH ]] && FMT "EBASH: $REBASH"
  echo

  if [[ $SKIP_E2718 ]]; then
    ((SKIP++))
    return 0
  fi
  return 1
}


TEST 0 0
TEST 1 1
TEST -1 -1
TEST 3.14159265358979 pi
TEST 1 sin[pi/2]

###################
# space-separated #
###################

TEST 3 '1+2'
TEST 3 1 + 2
TEST 3 1+ 2
TEST 3 1 +2
TEST 6 1 +2 + 3

################
# syntax error #
################

TEST $'123456789012345pi\n               ^--- syntax error' 123456789012345pi
SKIP_E2718=1
TEST $'1234567890123456pi\nsyntax error ---^' 1234567890123456pi
TEST $'12345678901234567pi\n syntax error ---^' 12345678901234567pi

echo

echo "PASS: $PASS of $TOTAL (SKIP = $SKIP)"
exit $((PASS < TOTAL))
