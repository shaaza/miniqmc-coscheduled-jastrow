MACLAPACKLIBS=/usr/local/opt/lapack/lib/liblapack.3.8.0.dylib
LAPACKLIBS=
LAPACKFLAGS="-lm"
CXX_FLAGS="$(shell pkg-config --cflags starpu-1.3) -lm -lblas -llapack"
CFLAGS="$(shell pkg-config --cflags starpu-1.3) -lm -lblas -llapack"
CXX_COMPILER=g++
BUILD_DIR=./build

HWLOC_VERSION=hwloc-2.0.4
HWLOC_URL=https://download.open-mpi.org/release/hwloc/v2.0/$(HWLOC_VERSION).tar.gz
HWLOC_DIR=$(abspath $(CURDIR)/../hwloc-2.0.4)
HWLOC_BUILD_DIR=$(abspath $(CURDIR)/../hwloc-2.0.4/build)

STARPU_VERSION=starpu-1.3.2
STARPU_URL=http://starpu.gforge.inria.fr/files/starpu-1.3.2/$(STARPU_VERSION).tar.gz
STARPU_DIR=$(abspath $(CURDIR)/../starpu-1.3.2)
STARPU_BUILD_DIR=$(abspath $(CURDIR)/../starpu-1.3.2/build)

COLOR=\033[0;35m
BOLD=\033[1m
RESET=\033[0m

.PHONY: build all

all: build

create-build-dir:
	mkdir -p $(BUILD_DIR)

clean-build:
	rm -rf $(BUILD_DIR)

cmake-setup:
	cmake -B $(BUILD_DIR) -DLAPACK_LIBRARIES=$(LAPACKLIBS) -DLAPACK_LINKER_FLAGS=$(LAPACKFLAGS) -DCMAKE_CXX_FLAGS=$(CXX_FLAGS) -DCMAKE_C_FLAGS=$(CFLAGS) -DCMAKE_CXX_COMPILER=$(CXX_COMPILER) .

build: clean-build create-build-dir cmake-setup
	make -C build -j 8

run:
	$(BUILD_DIR)/bin/miniqmc

tests:
	@echo $$"$(COLOR)$(BOLD)\n[TESTS] Running unit tests$(RESET)"
	@echo $$"$(COLOR)$(BOLD)===============================================================================$(RESET)\n"
	@echo $$"[UNIT TEST] Running Drivers tests"
	$(BUILD_DIR)/tests/bin/test_Drivers
	@echo $$"[UNIT TEST] Running Particle tests"
	$(BUILD_DIR)/tests/bin/test_particle
	@echo $$"[UNIT TEST] Running WaveFunction tests"
	$(BUILD_DIR)/tests/bin/test_wavefunction
	@echo $$"[UNIT TEST] Running utilities tests"
	$(BUILD_DIR)/tests/bin/test_utilities

	@echo $$"$(COLOR)$(BOLD)[TESTS] Running integration tests$(RESET)"
	@echo $$"$(COLOR)$(BOLD)===============================================================================$(RESET)\n"
	@echo $$"[INTEGRATION TEST] Checking wavefunction components against reference implementation"
	$(BUILD_DIR)/bin/check_wfc
	@echo $$"$(COLOR)$(BOLD)===============================================================================$(RESET)\n"
	@echo $$"[INTEGRATION TEST] Checking single-particle orbitals against reference implementation"
	$(BUILD_DIR)/bin/check_spo
	@echo $$"$(COLOR)$(BOLD)===============================================================================$(RESET)\n"

	@echo $$"$(COLOR)$(BOLD)[TESTS] Done$(RESET)"

dep-hwloc:
	rm -rf $(HWLOC_DIR)
	cd $(abspath $(CURDIR)/..); wget $(HWLOC_URL) && tar xvzf $(HWLOC_VERSION).tar.gz && \
	cd $(HWLOC_VERSION) && mkdir -p build && \
	./configure --prefix=$(HWLOC_BUILD_DIR) && make && make install
	if grep -q "#HWLOC" $(HOME)/.bashrc; then \
		echo "#HWLOC" >> $(HOME)/.bashrc && \
		echo "export PATH=$(HWLOC_BUILD_DIR)/bin:$$PATH" >> $(HOME)/.bashrc && \
		echo "export PKG_CONFIG_PATH=$(HWLOC_BUILD_DIR)/lib/pkgconfig:$$PATH" >> $(HOME)/.bashrc ; \
	fi

dep-starpu:
	rm -rf $(STARPU_DIR)
	cd $(abspath $(CURDIR)/..); wget $(STARPU_URL) && tar xvzf $(STARPU_VERSION).tar.gz && \
	cd $(STARPU_VERSION) && mkdir -p build && cd build && \
	source $(HOME)/.bashrc; ../configure --prefix=$(STARPU_BUILD_DIR) --with-hwloc=$(HWLOC_BUILD_DIR) && make && make install
	if grep -q "#STARPU" $(HOME)/.bashrc; then \
		echo "#STARPU" >> $(HOME)/.bashrc && \
		echo "export PATH=$(STARPU_BUILD_DIR)/bin:$$PATH" >> $(HOME)/.bashrc && \
		echo "export PKG_CONFIG_PATH=$(STARPU_BUILD_DIR)/lib/pkgconfig:$$PATH" >> $(HOME)/.bashrc ; \
	fi

load-modules:
	/usr/bin/modulecmd bash load cports6 cports apps
	/usr/bin/modulecmd bash load hwloc lapack/3.7.1-gnu gcc/7.4.0-gnu cmake/3.8.2-gnu

deps: dep-hwloc dep-starpu

# dep-lapack dep-cmake dep-gc

old-cmake-version-setup:
	cmake -DLAPACK_LIBRARIES=$(LAPACKLIBS) -DLAPACK_LINKER_FLAGS=$(LAPACKFLAGS) -DCMAKE_CXX_FLAGS=$(CXX_FLAGS) -DCMAKE_C_FLAGS=$(CFLAGS) -DCMAKE_CXX_COMPILER=$(CXX_COMPILER) ..

build-for-old-cmake: clean-build create-build-dir
	cp Makefile $(BUILD_DIR)/
	cd $(BUILD_DIR); make old-cmake-version-setup && make -j 8