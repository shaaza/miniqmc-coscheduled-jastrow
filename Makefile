MACLAPACKLIBS=/usr/local/opt/lapack/lib/liblapack.3.8.0.dylib
LAPACKLIBS=
LAPACKFLAGS="-lm"
CXX_FLAGS="-lm -lblas -llapack"
CFLAGS="-lm -lblas -llapack"
CXX_COMPILER=g++-9
BUILD_DIR=./build

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

# Others not included: dep-lapack dep-cmake dep-gc

# Lonsdale specific targets since:
# i) dependencies are module loaded
# ii) cmake version is too low

old-cmake-version-setup:
	cmake -DLAPACK_LIBRARIES=$(LAPACKLIBS) -DLAPACK_LINKER_FLAGS=$(LAPACKFLAGS) -DCMAKE_CXX_FLAGS=$(CXX_FLAGS) -DCMAKE_C_FLAGS=$(CFLAGS) -DCMAKE_CXX_COMPILER=$(CXX_COMPILER) ..

build-for-old-cmake: clean-build create-build-dir
	source $(CURDIR)/module_loader.sh; module load cports6 cports apps lapack/3.7.1-gnu gcc/7.4.0-gnu cmake/3.8.2-gnu && \
	cp Makefile $(BUILD_DIR)/ && \
	cd $(BUILD_DIR); make old-cmake-version-setup && make -j 8