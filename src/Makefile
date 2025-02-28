TARGETS := all clean
SUBDIRS := awk bash c cxx java perl

.PHONY: $(TARGETS) $(SUBDIRS)

all: $(SUBDIRS)

$(SUBDIRS):
	mkdir -p $@
	bash $@.sh

clean:
	rm -rf $(SUBDIRS)
