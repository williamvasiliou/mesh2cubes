SRC := ../src
TARGETS := all clean
SUBDIRS := awk bash c cxx java

CC := gcc
CXX := g++

MESH2CUBES := mesh2cubes
TESTS := Expected Teapot
DOCUMENTS := Cube Cubes Document Expected Header Static

CLASSES := $(addsuffix .class,$(MESH2CUBES) $(TESTS) $(DOCUMENTS))
TESTS := $(addsuffix .java,$(TESTS))
DOCUMENTS := $(addsuffix .java,$(DOCUMENTS))

BINS := $(CLASSES) c/test cxx/test

.PHONY: $(TARGETS) $(SUBDIRS)

all: $(SUBDIRS)

c/test: c/test.c
	$(CC) -Wall -lm -o $@ $<

cxx/test: cxx/test.cpp
	$(CXX) -Wall -lm -o $@ $<

$(MESH2CUBES).class: $(MESH2CUBES).java $(TESTS) $(DOCUMENTS)
	javac $^

$(SUBDIRS): $(BINS)
	java -ea $(MESH2CUBES) $@

clean:
	rm -f $(BINS)
