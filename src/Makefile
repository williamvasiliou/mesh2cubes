TARGETS := all clean
SUBDIRS := bash java

.PHONY: $(TARGETS) $(SUBDIRS)

all: $(SUBDIRS)

$(SUBDIRS):
	mkdir -p $@
	bash build.sh $@

clean:
	rm -rf $(SUBDIRS)
