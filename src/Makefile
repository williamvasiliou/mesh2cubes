TARGETS := all clean
SUBDIRS := awk bash java

.PHONY: $(TARGETS) $(SUBDIRS)

all: $(SUBDIRS)

$(SUBDIRS):
	mkdir -p $@
	bash $@.sh

clean:
	rm -rf $(SUBDIRS)
