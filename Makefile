
BUILD_SYSTEM:=$(OS)
ifeq ($(BUILD_SYSTEM),Windows_NT)
BUILD_SYSTEM:=$(shell uname -o 2> uname.err || echo Windows_NT) # set to Cygwin if appropriate
else
BUILD_SYSTEM:=$(shell uname -s)
endif
BUILD_SYSTEM:=$(strip $(BUILD_SYSTEM))

# Figure out where to build the software.
#   Use BUILD_PREFIX if it was passed in.
#   If not, search up to four parent directories for a 'build' directory.
#   Otherwise, use ./build.
ifeq ($(BUILD_SYSTEM), Windows_NT)
ifeq "$(BUILD_PREFIX)" ""
BUILD_PREFIX:=$(shell (for %%x in (. .. ..\.. ..\..\.. ..\..\..\..) do ( if exist %cd%\%%x\build ( echo %cd%\%%x\build & exit ) )) & echo %cd%\build )
endif
# don't clean up and create build dir as I do in linux.  instead create it during configure.
else
ifeq "$(BUILD_PREFIX)" ""
BUILD_PREFIX:=$(shell for pfx in ./ .. ../.. ../../.. ../../../..; do d=`pwd`/$$pfx/build;\
               if [ -d $$d ]; then echo $$d; exit 0; fi; done; echo `pwd`/build)
endif
# create the build directory if needed, and normalize its path name
BUILD_PREFIX:=$(shell mkdir -p $(BUILD_PREFIX) && cd $(BUILD_PREFIX) && echo `pwd`)
endif

ifeq "$(BUILD_SYSTEM)" "Cygwin"
  BUILD_PREFIX:=$(shell cygpath -m $(BUILD_PREFIX))
endif


all: lcm-1.0.0/pod-build/Makefile
	cmake --build lcm-1.0.0/pod-build --config $(BUILD_TYPE) --target install

lcm-1.0.0/pod-build/Makefile:
	"$(MAKE)" configure

.PHONY: configure
configure:
	@echo "\nBUILD_PREFIX: $(BUILD_PREFIX)\n\n"

	# create the temporary build directory if needed
	@mkdir -p lcm-1.0.0/pod-build

	# run CMake to generate and configure the build scripts
	# (note: i'm not passing the CMAKE_FLAGS here because it appears i need to use the 32-bit generator even on my 64-bit machine)
	@cd lcm-1.0.0/pod-build && cmake $(CMAKE_FLAGS) -DCMAKE_INSTALL_PREFIX="$(BUILD_PREFIX)" \
		-DCMAKE_BUILD_TYPE=$(BUILD_TYPE) ..

clean:
ifeq ($(BUILD_SYSTEM),Windows_NT)
	rd /s lcm-1.0.0/pod-build
else
	-if [ -e lcm-1.0.0/pod-build/install_manifest.txt ]; then rm -f `cat lcm-1.0.0/pod-build/install_manifest.txt`; fi
	-if [ -d lcm-1.0.0/pod-build ]; then cmake --build lcm-1.0.0/pod-build --target clean; rm -rf lcm-1.0.0/pod-build; fi
endif

# other (custom) targets are passed through to the cmake-generated Makefile
%::
	cd lcm-1.0.0/pod-build && $(CMAKE_MAKE_PROGRAM) $@

# Default to a less-verbose build.  If you want all the gory compiler output,
# run "make VERBOSE=1"
$(VERBOSE).SILENT:
