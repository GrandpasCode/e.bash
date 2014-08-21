#!/bin/bash
# Copyright (C) 2001  Dimitromanolakis Apostolos
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
