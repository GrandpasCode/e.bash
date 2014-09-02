#!/bin/bash
# Copyright (C) 2014  Yu-Jie Lin
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 2 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

: ${DURATION:=5}
: ${TEST:=sin[pi/2]}
: ${EXPECT:=1}
: ${VARNAME=RESULT}

trap 'kill $tmpcount_pid ; rm "$tmpcount" ; exit 130' INT

test_command () {

  local RESULT
  local VIA="$1"
  local TD="$2"
  local SETUP="$3"

  echo -ne "\e[1;37mBenchmarking\e[0m "
  [[ ! -z "${SETUP[@]}" ]] && echo -ne "\e[1;32m${SETUP[@]/$PWD/\$PWD}\e[0m; "
  echo -e "\e[1;33m${TD[@]}\e[0m..."

  echo -n "Please wait for $DURATION seconds..."
  tmpcount="$(mktemp)"
  (
    trap exit TERM
    eval "$SETUP"
    while RESULT=; do
      "$TD"
      [[ $RESULT == $EXPECT ]] && echo >> "$tmpcount"
    done
  ) &>/dev/null &
  tmpcount_pid=$!
  sleep $DURATION
  if ! kill $tmpcount_pid; then
    echo -e "\e[1;31msubprocess ($tmpcount_pid) already gone," \
            "something went wrong\e[0m" >&2
    exit 1
  fi

  RUNS=$(bc <<< "$(wc -l < "$tmpcount") / $DURATION")
  printf "\e[3K\e[0G\e[1;34m%'7.0f\e[0m runs per second via %s\n" "$RUNS" "$VIA"
  rm "$tmpcount"

  if ((RUNS == 0)); then
    echo -e "\e[1;31m0 runs, something went wrong\e[0m" >&2
    exit 1
  fi
}

test_e2718 () {
  RESULT="$(e-0.02718/e $TEST)"
}

test_command 'original e program' test_e2718

test_e_command () {
  RESULT="$(./e $TEST)"
}

test_command 'e program' test_e_command

test_e_loadable () {
  RESULT="$(e $TEST)"
}

test_command 'Bash loadable with Command Substitution' \
             test_e_loadable \
             'enable -f $PWD/e.bash e'

test_e_loadable_v () {
  e -v RESULT $TEST
}

test_command 'Bash loadable with Variable Binding' \
             test_e_loadable_v \
             'enable -f $PWD/e.bash e'
