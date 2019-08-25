LAPACKLIBS=/usr/local/opt/lapack/lib/liblapack.3.8.0.dylib
LAPACKFLAGS="-lm"
CXX_FLAGS="$(shell pkg-config --cflags starpu-1.3) -lm -lblas -llapack"
CFLAGS="$(shell pkg-config --cflags starpu-1.3) -lm -lblas -llapack"
CXX_COMPILER=g++-9
BUILD_DIR=./build

COLOR=\033[0;35m
BOLD=\033[1m
RESET=\033[0m

.PHONY: build all

all: build

clean-build:
	rm -rf $(BUILD_DIR)/*

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
