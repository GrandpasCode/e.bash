#!/bin/bash
# example of plotting sine graph using loadable with variable binding
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

COLS=$(tput cols)
ROWS=$(tput lines)

if ! enable -f $PWD/e.bash    e 2>/dev/null &&
   ! enable -f $PWD/../e.bash e 2>/dev/null
then
  echo cannot load e.bash loadable >&2
  exit 1
fi

clear
for ((x = 0; x < COLS; x++)); do
  e -v Y floor[$ROWS - [sin[$x/$COLS*2*pi] + 1]/2*$ROWS]
  ((Y++))
  ((X = x + 1))
  echo -ne "\e[$Y;${X}H*"
done
