#!/bin/bash
# example of plotting sine graph using bc
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

clear
for ((x = 0; x < COLS; x++)); do
  Y=$(bc -l <<< "$ROWS - (  s($x/$COLS*2*3.14) + 1)/2*$ROWS")
  ((Y = ${Y%.*} + 1))
  ((X = x + 1))
  echo -ne "\e[$Y;${X}H*"
done
