N ?= 99999
CFLAGS ?= -O3 -march=native -mtune=native -flto -std=c2x
CXXFLAGS ?= -O3 -march=native -mtune=native -flto -std=c++23
FFLAGS ?= -O3 -march=native -mtune=native -flto -std=f2018
NVCC_ARCH ?= sm_120
NVCCFLAGS ?= -O3 -std=c++20 -arch=$(NVCC_ARCH) -Xptxas -O3

BIN_DIR := bin
NVCC_EXISTS := $(shell command -v nvcc 2>/dev/null)
FASM_EXISTS := $(shell command -v fasm 2>/dev/null)
COBOLC_EXISTS := $(shell command -v cobc 2>/dev/null || command -v gcobol 2>/dev/null)
PASCAL_EXISTS := $(shell command -v fpc 2>/dev/null)
BASIC_EXISTS := $(shell command -v fbc 2>/dev/null)
CUDA_TARGET := $(if $(NVCC_EXISTS),$(BIN_DIR)/fact_cuda,)
FASM_TARGET := $(if $(FASM_EXISTS),$(BIN_DIR)/fact_fasm,)
COBOL_TARGET := $(if $(COBOLC_EXISTS),$(BIN_DIR)/fact_cobol,)
PASCAL_TARGET := $(if $(PASCAL_EXISTS),$(BIN_DIR)/fact_pascal,)
BASIC_TARGET := $(if $(BASIC_EXISTS),$(BIN_DIR)/fact_basic,)
SHARED_OBJ := $(BIN_DIR)/fact_shared.o

.PHONY: all clean run deps

all: $(BIN_DIR)/fact_c23 $(BIN_DIR)/fact_cpp23 $(BIN_DIR)/fact_java $(BIN_DIR)/fact_fortran $(SHARED_OBJ) $(CUDA_TARGET) $(FASM_TARGET) $(COBOL_TARGET) $(PASCAL_TARGET) $(BASIC_TARGET)

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

$(BIN_DIR)/fact_c23: src/fact_c23.c | $(BIN_DIR)
	$(CC) $(CFLAGS) $< -o $@ -lgmp

$(BIN_DIR)/fact_cpp23: src/fact_cpp23.cpp | $(BIN_DIR)
	$(CXX) $(CXXFLAGS) $< -o $@ -lgmpxx -lgmp

$(BIN_DIR)/fact_fortran: src/fact_fortran.f90 | $(BIN_DIR)
	gfortran $(FFLAGS) $< -o $@ -lgmp

$(BIN_DIR)/fact_cuda: src/fact_cuda.cu | $(BIN_DIR)
	nvcc $(NVCCFLAGS) $< -o $@ -lgmp

$(BIN_DIR)/fact_shared.o: src/fact_shared.c | $(BIN_DIR)
	$(CC) -O3 -march=native -mtune=native -fPIC -std=c2x -c $< -o $@

$(BIN_DIR)/fact_fasm: src/fact_fasm.asm $(SHARED_OBJ) | $(BIN_DIR)
	fasm $< $(BIN_DIR)/fact_fasm.o
	$(CC) -O3 -march=native -mtune=native -no-pie $(BIN_DIR)/fact_fasm.o $(SHARED_OBJ) -o $@ -lgmp

$(BIN_DIR)/fact_cobol: src/fact_cobol.cob $(SHARED_OBJ) | $(BIN_DIR)
	@if command -v cobc >/dev/null 2>&1; then \
		cobc -x -free -O2 -o $@ $< $(SHARED_OBJ) -lgmp; \
	elif command -v gcobol >/dev/null 2>&1; then \
		gcobol -O2 -o $@ $< $(SHARED_OBJ) -lgmp; \
	else \
		echo "No COBOL compiler found. Install gnucobol or gcobol."; exit 1; \
	fi

$(BIN_DIR)/fact_pascal: src/fact_pascal.pas $(SHARED_OBJ) | $(BIN_DIR)
	fpc -O3 -obin/fact_pascal $< -k$(abspath $(SHARED_OBJ)) -k-lgmp -k-lc -k-lrt

$(BIN_DIR)/fact_basic: src/fact_basic.bas $(SHARED_OBJ) | $(BIN_DIR)
	fbc -O 3 -x $@ $< $(SHARED_OBJ) -l gmp

$(BIN_DIR)/fact_java: src/FactJava.java | $(BIN_DIR)
	javac -d $(BIN_DIR) $<
	printf '#!/usr/bin/env bash\njava -cp "$(BIN_DIR)" FactJava "$$@"\n' > $@
	chmod +x $@

run: all
	./run_all.sh $(N)

deps:
	@echo "Required: gcc/g++, libgmp-dev, gfortran, python3, ruby, perl, default-jdk"
	@echo "Optional: nvcc, clojure, fasm, gnucobol/gcobol, fpc, fbc"
	@echo "CUDA arch default: $(NVCC_ARCH). Override with: make NVCC_ARCH=sm_120"
	@echo "Ubuntu example: sudo apt install build-essential libgmp-dev gfortran python3 ruby perl default-jdk clojure fasm gnucobol fp-compiler nvidia-cuda-toolkit"
	@echo "FreeBASIC usually provides the fbc compiler. Install fbc from your distro or FreeBASIC release if unavailable in apt."

clean:
	rm -rf $(BIN_DIR) results.csv results_sorted.csv .bench_tmp .bench_err src/*.o src/*.ppu src/*.a src/*.res fact_pascal.o fact_pascal.ppu
