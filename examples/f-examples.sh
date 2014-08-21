#!/bin/bash
# examples of f.sh
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

./f.sh '2*sin[$X]' -pi pi -1 1

./f.sh 'sin[$X*pi/180]' 0 359 -1 1

for i in {0..720..15}; do
  ./f.sh -H 'sin[$X*pi/180]' $i $i+359 -1 1
  sleep 0.05
done
read

./f.sh 'tan[$X]' -pi pi -pi pi

clear
./f.sh -CP -c '1;31' 'sin[$X]' -pi pi -1 1
./f.sh -CP -c '1;32' 'cos[$X]' -pi pi -1 1
./f.sh -CP -c '1;33' 'tan[$X]' -pi pi -1 1

./f.sh 'floor[$X]' -5 5 -5 5

./f.sh 'ceil[$X]' -5 5 -5 5

./f.sh '[$X^3+3*$X^2-6*$X-8]/4' -5 4 -4 6

clear
