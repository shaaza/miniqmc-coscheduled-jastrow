LAPACKLIBS=/usr/local/opt/lapack/lib/liblapack.3.8.0.dylib
LAPACKFLAGS="-lm"
CXX_FLAGS="$(shell pkg-config --cflags starpu-1.3) -lm -lblas -llapack"
CFLAGS="$(shell pkg-config --cflags starpu-1.3) -lm -lblas -llapack"
CXX_COMPILER=g++
BUILD_DIR=./build
HWLOC_DIR=$(CURDIR)/../hwloc-2.0.4/build
STARPU_DIR=$(CURDIR)/../starpu-1.3.2/build

COLOR=\033[0;35m
BOLD=\033[1m
RESET=\033[0m

.PHONY: build all

all: build

create-build-dir:
	mkdir -p $(BUILD_DIR)

clean-build:
	rm -rf $(BUILD_DIR)

old-cmake-version-setup:
	cmake -DLAPACK_LIBRARIES=$(LAPACKLIBS) -DLAPACK_LINKER_FLAGS=$(LAPACKFLAGS) -DCMAKE_CXX_FLAGS=$(CXX_FLAGS) -DCMAKE_C_FLAGS=$(CFLAGS) -DCMAKE_CXX_COMPILER=$(CXX_COMPILER) ..

cmake-setup:
	cmake -B $(BUILD_DIR) -DLAPACK_LIBRARIES=$(LAPACKLIBS) -DLAPACK_LINKER_FLAGS=$(LAPACKFLAGS) -DCMAKE_CXX_FLAGS=$(CXX_FLAGS) -DCMAKE_C_FLAGS=$(CFLAGS) -DCMAKE_CXX_COMPILER=$(CXX_COMPILER) .

build: clean-build cmake-setup
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
	rm -rf $(HWLOC_DIR)/..
	cd $(CURDIR)/..; wget https://download.open-mpi.org/release/hwloc/v2.0/hwloc-2.0.4.tar.gz && tar xvzf hwloc-2.0.4.tar.gz && \
	cd hwloc-2.0.4 && mkdir -p build && \
	./configure --prefix=$(HWLOC_DIR) && make && make install
	if grep -q "export PATH=$(HWLOC_DIR)/bin:$$PATH" $(HOME)/.bashrc; then \
		echo "export PATH=$(HWLOC_DIR)/bin:$$PATH" >> $(HOME)/.bashrc && \
		echo "export PKG_CONFIG_PATH=$(HWLOC_DIR)/lib/pkgconfig:$$PATH" >> $(HOME)/.bashrc ; \
	fi

dep-starpu:
	rm -rf $(STARPU_DIR)/..
	cd $(CURDIR)/..; wget http://starpu.gforge.inria.fr/files/starpu-1.3.2/starpu-1.3.2.tar.gz && tar xvzf starpu-1.3.2.tar.gz && \
	cd starpu-1.3.2 && mkdir -p build && cd build && \
	source $(HOME)/.bashrc; ../configure --prefix=$(STARPU_DIR) --with-hwloc=$(HWLOC_DIR) && make && make install
	if grep -q "export PATH=$(STARPU_DIR)/bin:$$PATH" $(HOME)/.bashrc; then \
		echo "export PATH=$(STARPU_DIR)/bin:$$PATH" >> $(HOME)/.bashrc && \
		echo "export PKG_CONFIG_PATH=$(STARPU_DIR)/lib/pkgconfig:$$PATH" >> $(HOME)/.bashrc ; \
	fi

deps: dep-hwloc dep-starpu dep-lapack dep-cmake dep-gc
