#!/bin/bash

DURATION=5
TEST='sin[pi/2]'
EXPECT=1

trap 'kill $tmpcount_pid ; rm "$tmpcount" ; exit 130' INT

test_command () {

  local RESULT

  echo -ne "\e[1;37mBenchmarking\e[0m "
  [[ ! -z "${SETUP[@]}" ]] && echo -ne "\e[1;32m${SETUP[@]/$PWD/\$PWD}\e[0m; "
  echo -e "\e[1;33m${TD[@]}\e[0m..."

  echo -n "Please wait for $DURATION seconds..."
  tmpcount="$(mktemp)"
  (
    trap exit TERM
    "${SETUP[@]}"
    while :; do
      if [[ -z $VARNAME ]]; then
        RESULT="$(${TD[@]})"
      else
        ${TD[@]}
        RESULT="${!VARNAME}"
      fi
      [[ $RESULT == $EXPECT ]] && echo >> "$tmpcount"
    done
  ) &>/dev/null &
  tmpcount_pid=$!
  sleep $DURATION
  kill $tmpcount_pid

  RUNS=$(($(wc -l < "$tmpcount") / $DURATION))
  printf "\e[3K\e[0G\e[1;34m%'7.0f\e[0m runs per second via %s\n" "$RUNS" "$VIA"
  rm "$tmpcount"

}

SETUP=()
VIA='original e program'
TD=(e-0.02718/e "$TEST")
VARNAME=

test_command

SETUP=()
VIA='e program'
TD=(./e "$TEST")
VARNAME=

test_command

SETUP=('enable' '-f' "$PWD/e.bash" 'e')
VIA='Bash loadable with Command Substitution'
TD=(e "$TEST")
VARNAME=

test_command

SETUP=('enable' '-f' "$PWD/e.bash" 'e')
VIA='Bash loadable with Variable Binding'
VARNAME=BLAH
TD=(e -v "$VARNAME" "$TEST")

test_command
