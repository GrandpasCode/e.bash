#! make -f

TARGETS = e
LDFLAGS = -lm

VERSION = 0.02718
DISTFILES = ChangeLog AUTHORS COPYING EXAMPLES GRAMMAR Makefile README e e.c

.PHONY: all
all: $(TARGETS)

e: e.c

.PHONY: clean
clean:
	rm -f $(TARGETS)

.PHONY: dist
dist: e
	mkdir e-$(VERSION)
	cp $(DISTFILES) e-$(VERSION)
	tar cvzf e-$(VERSION).tar.gz e-$(VERSION)
	
