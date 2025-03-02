# Do not, under any circumstances, allow USE_CCACHE when testing the compiler suite
override USE_CCACHE=0
export USE_CCACHE

# Inherit some things from the environment, setting dumb defaults otherwise
CC_TARGET ?= x86_64-linux-gnu
CPPFLAGS ?=
CFLAGS ?= -g -O2
LDFLAGS ?=

# Set up rpath flags for the different targets
ifneq (,$(findstring mingw,$(CC_TARGET)))
define rpath
-L$(PROJECT_BUILD)/$(1)
endef
exeext ?= .exe
dlext ?= dll
else
ifneq (,$(findstring darwin,$(CC_TARGET)))
define rpath
-Wl,-rpath,@loader_path/$(1) -L$(PROJECT_BUILD)/$(1)
endef
dlext ?= dylib
else
define rpath
-Wl,-z,origin -Wl,-rpath,'$$ORIGIN/$(1)' -L$(PROJECT_BUILD)/$(1)
endef
dlext ?= so
endif
endif

# Define some compiler defaults (they are typically overridden by `export`'ed
# variables in the BB shell)
CC ?= $(CC_TARGET)-cc
CXX ?= $(CC_TARGET)-c++
AR ?= $(CC_TARGET)-ar
RANLIB ?= $(CC_TARGET)-ranlib
OBJCOPY ?= $(CC_TARGET)-objcopy
STRIP ?= $(CC_TARGET)-strip

# Magic variables
SPACE:=$(eval) $(eval)

