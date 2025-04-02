TARGETS := all clean
SUBDIRS := ada awk bash c cxx d fortran go java javascript perl python

.PHONY: $(TARGETS) $(SUBDIRS)

all: $(SUBDIRS)

$(SUBDIRS):
	mkdir -p $@
	bash $@.sh

clean:
	rm -rf $(SUBDIRS)
