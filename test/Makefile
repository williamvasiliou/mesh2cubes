SRC := ../src
TARGETS := all clean
SUBDIRS := ada awk bash c cxx java perl

CC := gcc
CXX := g++

CFLAGS := -Wall
CXXFLAGS := -Wall
LDFLAGS := -lm

MESH2CUBES := mesh2cubes
TESTS := Expected Teapot
DOCUMENTS := Cube Cubes Document Expected Header Static

CLASSES := $(addsuffix .class,$(MESH2CUBES) $(TESTS) $(DOCUMENTS))
TESTS := $(addsuffix .java,$(TESTS))
DOCUMENTS := $(addsuffix .java,$(DOCUMENTS))

BINS := $(CLASSES) \
	ada/test ada/io.ali ada/io.o ada/test.ali ada/test.o \
	c/test \
	cxx/test

.PHONY: $(TARGETS) $(SUBDIRS)

all: $(SUBDIRS)

ada/test: ada/test.adb ada/io.adb ada/io.ads $(SRC)/ada/$(MESH2CUBES).adb $(SRC)/ada/$(MESH2CUBES).ads
	gnatmake -i -I$(SRC)/ada -o $@ $<

c/test: c/test.c $(SRC)/c/$(MESH2CUBES).h
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $<

cxx/test: cxx/test.cpp $(SRC)/cxx/$(MESH2CUBES).hpp
	$(CXX) $(CXXFLAGS) $(LDFLAGS) -o $@ $<

$(MESH2CUBES).class: $(MESH2CUBES).java $(TESTS) $(DOCUMENTS)
	javac $^

$(SUBDIRS): $(BINS)
	java -ea $(MESH2CUBES) $@

clean:
	rm -f $(BINS)
