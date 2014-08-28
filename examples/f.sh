#!/bin/bash
# example of Y = f(X)
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
#
# Note:
#
#   Must use single quote to prevent $X being expanded
#
# Examples:

# ./f.sh '2*sin[$X]' -pi pi -1 1
# ./f.sh 'sin[$X*pi/180]' 0 359 -1 1
# for i in {0..720..15}; do ./f.sh 'sin[$X*pi/180]' $i $i+359 -1 1; sleep 0.05; done
# ./f.sh 'tan[$X]' -pi pi -pi pi
# ./f.sh 'floor[$X]' -5 5 -5 5
# ./f.sh 'ceil[$X]' -5 5 -5 5
# ./f.sh '[$X^3+3*$X^2-6*$X-8]/4' -5 4 -4 6

PRINTF () {
  if [[ -z $NOPRINTF ]]; then
    F="$(tr '[]' '()' <<< "${f//$/}")"
    echo -ne "\e[1;1H\e[1;37mY=$F\e[0m"
  fi
}

while getopts CHPc: arg; do
  case $arg in
    C)
      NOCLEAR=1
      ;;
    H)
      NOHOLD=1
      ;;
    P)
      NOPRINTF=1
      ;;
    c)
      COLOR=$OPTARG
      ;;
  esac
done
shift $((OPTIND - 1))

COLS=$(tput cols)
ROWS=$(tput lines)

if ! enable -f $PWD/e.bash    e 2>/dev/null &&
   ! enable -f $PWD/../e.bash e 2>/dev/null
then
  echo cannot load e.bash loadable >&2
  exit 1
fi

f="$1"
e -v X_L -- "$2"
e -v X_H -- "$3"
e -v Y_L -- "$4"
e -v Y_H -- "$5"

e -v W -- [$X_H]-[$X_L]
e -v H -- [$Y_H]-[$Y_L]

[[ $NOCLEAR ]] || clear
PRINTF

for ((x = 0; x < COLS; x++)); do
  # terminal  -->  graph
  # x 0-base  -->  X
  e -v X -- [$x/$COLS]*[$W]+[$X_L]

  eval F="$f"
  e -v Y -- "$F"
  [[ $Y = *nan* ]] && continue

  # graph --> terminal
  # Y     --> y 0-base
  e -v y $ROWS-[$Y-[$Y_L]]/[$H]*$ROWS

  # 0-based to 1-based
  e -v x1 -- $x+1
  e -v y1 -- floor[$y+1]

  # out of range
  #((y1 <= 0 || ROWS < y1)) && continue
  ((y1 < 1)) && continue
  ((ROWS < y1)) && continue

  if [[ $COLOR ]]; then
    echo -ne "\e[${y1};${x1}H\e[${COLOR}m*\e[0m"
  else
    echo -ne "\e[${y1};${x1}H*"
  fi
done

PRINTF
[[ -z $NOHOLD ]] && read -s
