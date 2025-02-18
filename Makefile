SRC := src
TARGETS := all clean

.PHONY: $(TARGETS)

$(TARGETS):
	make -C $(SRC) $@
