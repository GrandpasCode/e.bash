#! make -f
# Copyright (C) 2014  Yu-Jie Lin
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

SHELL = bash

INSTALL = install
INSTALL_PROGRAM = $(INSTALL) -D -m 755

prefix  = /usr/local

bindir  = $(prefix)/bin

TARGETS = e e.bash

E2718 = e-0.02718

CFLAGS  = -std=c99 -g -O2 -Wall -Wextra
LDFLAGS = -lm

# when with check target:
# - treat warnings as error for e and e.bash
# - set benchmark DURATION = .1
BENCHMARK_DURATION = 5
ifneq ($(filter check,$(MAKECMDGOALS)),)
CFLAGS += -Werror
BENCHMARK_DURATION = .1
endif

.PHONY: all
all: $(TARGETS)

e: version.h e.c

e.bash: LDFLAGS += -shared -Wl,-soname,$@

e.bash.o: CFLAGS   := $(subst c99,gnu99,$(CFLAGS)) -fPIC -I$(BASH_INC)
e.bash.o: CPPFLAGS += -DBASH_LOADABLE
e.bash.o: version.h e.c
	@if [[ ! -f '$(BASH_INC)'/builtins.h ]]; then \
	  echo Cannot file Bash header files at $(BASH_INC) >&2; \
	  echo Please set BASH_INC correctly >&2; \
	  exit 1; \
	fi
	$(CC) -c $(CFLAGS) $(CPPFLAGS) -o $@ e.c

.PHONY: e2718
e2718: $(E2718)/e

$(E2718)/e: $(E2718)
	make -C $(E2718)

$(E2718):
	tar xf $(E2718).tar.gz
	rm -f $(E2718)/e

.PHONY: benchmark
benchmark: clean check-style e2718 e e.bash
	DURATION=$(BENCHMARK_DURATION) $(SHELL) $@.sh

.PHONY: check
check: benchmark
	$(SHELL) $@.sh

.PHONY: check-style
check-style:
	@doc8 *.rst
	@egrep -rnI \
	       --exclude=*.rst \
	       --exclude=COPYING \
	       --exclude=README.e2718 \
	       --exclude-dir=$(E2718) \
	       '\s+$$' * \
	&& exit 1 \
	|| exit 0

.PHONY: install
install: $(TARGETS)
	for bin in $^; do \
	  $(INSTALL_PROGRAM) $$bin $(DESTDIR)$(bindir)/$$bin; \
	done

.PHONY: install-strip
install-strip:
	$(MAKE) INSTALL_PROGRAM='$(INSTALL_PROGRAM) -s' install

.PHONY: uninstall
uninstall: $(TARGETS)
	for bin in $^; do \
	  $(RM) -f $(DESTDIR)$(bindir)/$$bin; \
	done

.PHONY: clean
clean:
	rm -rf $(E2718)
	rm -f $(TARGETS)
	rm -f *.o
