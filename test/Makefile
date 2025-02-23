SRC := ../src
TARGETS := all clean
SUBDIRS := bash java

MESH2CUBES := mesh2cubes
TESTS := Teapot

CLASSES := $(addsuffix .class,$(MESH2CUBES) $(TESTS) Expected java/test)
TESTS := $(addsuffix .java,$(TESTS))

.PHONY: $(TARGETS) $(SUBDIRS)

all: $(SUBDIRS)

java/test.class: java/test.java
	javac -cp $(SRC)/java $<

$(MESH2CUBES).class: $(MESH2CUBES).java $(TESTS)
	javac $^

$(SUBDIRS): $(CLASSES)
	java -ea $(MESH2CUBES) $@

clean:
	rm -f $(CLASSES)
