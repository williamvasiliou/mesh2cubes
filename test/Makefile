SRC := ../src
TARGETS := all clean
SUBDIRS := ada awk bash c cxx d fortran go java javascript perl python

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
	cxx/test \
	d/test \
	fortran/test \
	go/test go/test.o

.PHONY: $(TARGETS) $(SUBDIRS)

all: $(SUBDIRS)

ada: ada/test
c: c/test
cxx: cxx/test
d: d/test
fortran: fortran/test
go: go/test

ada/test: ada/test.adb ada/io.adb ada/io.ads $(SRC)/ada/$(MESH2CUBES).adb $(SRC)/ada/$(MESH2CUBES).ads
	gnatmake -i -I$(SRC)/ada -o $@ $<

c/test: c/test.c $(SRC)/c/$(MESH2CUBES).h
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $<

cxx/test: cxx/test.cpp $(SRC)/cxx/$(MESH2CUBES).hpp
	$(CXX) $(CXXFLAGS) $(LDFLAGS) -o $@ $<

d/test: d/test.d $(SRC)/d/$(MESH2CUBES).d
	gdc -Wall -o $@ $^

fortran/test: fortran/test.f90 $(SRC)/fortran/$(MESH2CUBES).f90
	gfortran -Wall -J$(SRC)/fortran -o $@ $^

go/test.o: go/test.go
	gccgo -Wall -I$(SRC)/go -o $@ -c $<

$(SRC)/go/$(MESH2CUBES).o: $(SRC)/go/$(MESH2CUBES).go
	gccgo -Wall -o $@ -c $<

go/test: go/test.o $(SRC)/go/$(MESH2CUBES).o
	gccgo -o $@ $^

$(MESH2CUBES).class: $(MESH2CUBES).java $(TESTS) $(DOCUMENTS)
	javac $^

$(SUBDIRS): $(CLASSES)
	java -ea $(MESH2CUBES) $@

clean:
	rm -f $(BINS)
