SRC := ../src
TARGETS := all clean
SUBDIRS := awk bash c java

CC := gcc

MESH2CUBES := mesh2cubes
TESTS := Teapot

CLASSES := $(addsuffix .class,$(MESH2CUBES) $(TESTS) Expected)
TESTS := $(addsuffix .java,$(TESTS))

BINS := $(CLASSES) c/test

.PHONY: $(TARGETS) $(SUBDIRS)

all: $(SUBDIRS)

c/test: c/test.c
	$(CC) -Wall -lm -o $@ $<

$(MESH2CUBES).class: $(MESH2CUBES).java $(TESTS)
	javac $^

$(SUBDIRS): $(BINS)
	java -ea $(MESH2CUBES) $@

clean:
	rm -f $(BINS)
