
# Look for the EI library and header files
ERL_BASE_DIR ?= $(shell dirname $(shell which erl|sed -e 's~/erts-[^/]*~~'))/..
ERL_EI_INCLUDE_DIR ?= $(shell find $(ERL_BASE_DIR) -name ei.h -printf '%h\n' 2> /dev/null | head -1)
ERL_EI_LIBDIR ?= $(shell find $(ERL_BASE_DIR) -name libei.a -printf '%h\n' 2> /dev/null | head -1)

ifeq ($(ERL_EI_INCLUDE_DIR),)
   $(error Could not find include directory for ei.h. Check that Erlang header files are available)
endif
ifeq ($(ERL_EI_LIBDIR),)
   $(error Could not find libei.a. Check your Erlang installation)
endif

# Set Erlang-specific compile and linker flags
ERL_CFLAGS ?= -I$(ERL_EI_INCLUDE_DIR)
ERL_LDFLAGS ?= -L$(ERL_EI_LIBDIR) -lei
