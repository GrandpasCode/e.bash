#! make -f

SHELL = bash

TARGETS = e e.bash

E2718 = e-0.02718

CFLAGS  = -std=c99 -g -O2 -Wall -Wextra
LDFLAGS = -lm

VERSION = 0.02718
DISTFILES = ChangeLog AUTHORS COPYING EXAMPLES GRAMMAR Makefile README e e.c

.PHONY: all
all: $(TARGETS)

e: e.c

e.bash: LDFLAGS += -shared -Wl,-soname,$@

e.bash.o: CFLAGS   := $(subst c99,gnu99,$(CFLAGS)) -fPIC -I$(BASH_INC)
e.bash.o: CPPFLAGS += -DBASH_LOADABLE
e.bash.o: e.c
	@if [[ ! -f '$(BASH_INC)'/builtins.h ]]; then \
	  echo Cannot file Bash header files at $(BASH_INC) >&2; \
	  echo Please set BASH_INC correctly >&2; \
	  exit 1; \
	fi
	$(CC) -c $(CFLAGS) $(CPPFLAGS) -o $@ $<

.PHONY: e2718
e2718: $(E2718)/e

$(E2718)/e: $(E2718)
	make -C $(E2718)

$(E2718):
	tar xf $(E2718).tar.gz
	rm -f $(E2718)/e

.PHONY: benchmark check
benchmark check: e2718 e e.bash
	$(SHELL) $@.sh

.PHONY: clean
clean:
	rm -rf $(E2718)
	rm -f $(TARGETS)
	rm -f *.o

.PHONY: dist
dist: e
	mkdir e-$(VERSION)
	cp $(DISTFILES) e-$(VERSION)
	tar cvzf e-$(VERSION).tar.gz e-$(VERSION)
	
