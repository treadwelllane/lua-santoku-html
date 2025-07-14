<% return var("LIBXML2_CFLAGS") %> ?= $(shell pkg-config --cflags libxml-2.0)
<% return var("LIBXML2_LDFLAGS") %> ?= $(shell pkg-config --libs libxml-2.0)

results.mk:
	echo "LIB_CFLAGS += $(<% return var("LIBXML2_CFLAGS") %>)" > "$@"
	echo "LIB_LDFLAGS += $(<% return var("LIBXML2_LDFLAGS") %>)" >> $@
