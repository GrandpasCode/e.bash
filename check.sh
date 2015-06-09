#!/bin/bash

E2718="$PWD/e-0.02718/e"
EPROG="$PWD/e"
EBASH="$PWD/e.bash"

SKIP=0
PASS=0
TOTAL=0

FMT () {
  echo "$@" | sed '2,$ s/^/       /'
}

TEST () {
  TEST_F _TEST_EQ "$@"
}

TEST_F() {
  ((TOTAL++))
  _TEST "$@" && ((PASS++))
  SKIP_E2718=
}

_TEST () {
  local F T E RE2718 REPROG REBASH ERRORS

  F="$1"
  shift
  E="$1"    # expected result
  shift
  T=("$@")  # test input

  RE2718="$("$E2718" "${T[@]}")"
  REPROG="$("$EPROG" "${T[@]}")"
  REBASH="$( (enable -f "$EBASH" e && e "${T[@]}") )"

  ERRORS=0
  if [[ $SKIP_E2718 ]]; then
    ((SKIP++))
  else
    "$F" "$E" "$RE2718" || ((ERRORS++))
  fi
  "$F" "$E" "$REPROG" || ((ERRORS++))
  "$F" "$E" "$REBASH" || ((ERRORS++))

  ((ERRORS == 0)) && return 0

  FMT "INPUT: ${T[@]}"
  FMT "EXPCT: $E"
  [[ $SKIP_E2718 ]]   ||
  "$F" "$E" "$RE2718" || FMT "E2718: $RE2718"
  "$F" "$E" "$REPROG" || FMT "EPROG: $REPROG"
  "$F" "$E" "$REBASH" || FMT "EBASH: $REBASH"
  echo

  return 1
}

_TEST_EQ () {
  [[ $1 == $2 ]]
}

_TEST_RAND_10 () {
  ((0 <= $2)) && (($2 < 10))
}

# check Unix timestamp within range of 1 second
# 1 second should be enough when seconds crossing between calls of time from e
# and test function
_TEST_TIME () {
  local t

  printf -v t '%(%s)T' -1
  ((t == $2)) || (($2 <= t - 1))
}

_TEST_VERSION () {
  local VERSION D

  VERSION="e $(<version.h egrep -o '[0-9]+\.[0-9]+\.[0-9]+')"
  D=$(head -1 <<< "$2")

  [[ $VERSION == $D ]]
}

#########
# basic #
#########

TEST 0 0
TEST 1 1
TEST -1 -- -1
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

###########
# min/max #
###########

SKIP_E2718=1
TEST "\
0.000000000000000000000000000000000000000000000000000000000000000000000000000\
00000000000000000000000000000000000000000000000000000000000000000000000000000\
00000000000000000000000000000000000000000000000000000000000000000000000000000\
00000000000000000000000000000000000000000000000000000000000000000000000000000\
022250738585072"\
     dblmin
SKIP_E2718=1
TEST "\
17976931348623157081452742373170435679807056752584499659891747680315726078002\
85387605895586327668781715404589535143824642343213268894641827684675467035375\
16986049910576551282076245490090389328944075868508455133942304583236903222948\
16580855933212334827479782620414472316873817718091929988125040402618412485836\
8"\
     dblmax

#############
# functions #
#############

# round
#######

SKIP_E2718=1
TEST  1 round[ 0.5]
SKIP_E2718=1
TEST -1 round[-0.5]

# sign
######

SKIP_E2718=1
TEST  0 sign[ 0]
SKIP_E2718=1
TEST  1 sign[ 1]
SKIP_E2718=1
TEST -1 sign[-1]

# trunc
#######

SKIP_E2718=1
TEST  1    trunc[ 1.5]
SKIP_E2718=1
TEST -1 -- trunc[-1.5]
SKIP_E2718=1
TEST  1    trunc[ 1  ]
SKIP_E2718=1
TEST -1 -- trunc[-1  ]

# time
######

SKIP_E2718=1
TEST_F _TEST_TIME ? time

################
# syntax error #
################

TEST $'123456789012345pi\n               ^--- syntax error' 123456789012345pi
SKIP_E2718=1
TEST $'1234567890123456pi\nsyntax error ---^' 1234567890123456pi
TEST $'12345678901234567pi\n syntax error ---^' 12345678901234567pi

##########
# random #
##########

SKIP_E2718=1
TEST 2147483647 randmax
SKIP_E2718=1
TEST 0 floor[randf*1]
SKIP_E2718=1
TEST_F _TEST_RAND_10 '?' floor[randf*10]

# srand
#######

SKIP_E2718=1
TEST 1205554746 srand[3] +rand
SKIP_E2718=1
TEST 1205554746 srand[pi]+rand
SKIP_E2718=1
TEST 2411109492 srand[pi]+rand+srand[pi]+rand
SKIP_E2718=1
TEST 1688702731 srand[pi]+rand+rand

##################
# version string #
##################

SKIP_E2718=1
TEST_F _TEST_VERSION '?' -V

echo

echo "PASS: $PASS of $TOTAL (SKIP = $SKIP)"
exit $((PASS < TOTAL))
