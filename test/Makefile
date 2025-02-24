SRC := ../src
TARGETS := all clean
SUBDIRS := awk bash java

MESH2CUBES := mesh2cubes
TESTS := Teapot

CLASSES := $(addsuffix .class,$(MESH2CUBES) $(TESTS) Expected)
TESTS := $(addsuffix .java,$(TESTS))

.PHONY: $(TARGETS) $(SUBDIRS)

all: $(SUBDIRS)

$(MESH2CUBES).class: $(MESH2CUBES).java $(TESTS)
	javac $^

$(SUBDIRS): $(CLASSES)
	java -ea $(MESH2CUBES) $@

clean:
	rm -f $(CLASSES)
