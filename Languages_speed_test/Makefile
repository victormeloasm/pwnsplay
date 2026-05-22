N ?= 99999
CFLAGS ?= -O3 -march=native -mtune=native -flto -std=c2x
CXXFLAGS ?= -O3 -march=native -mtune=native -flto -std=c++23
FFLAGS ?= -O3 -march=native -mtune=native -flto -std=f2018
NVCC_ARCH ?= sm_120
NVCCFLAGS ?= -O3 -std=c++20 -arch=$(NVCC_ARCH) -Xptxas -O3

BIN_DIR := bin
NVCC_EXISTS := $(shell command -v nvcc 2>/dev/null)
CUDA_TARGET := $(if $(NVCC_EXISTS),$(BIN_DIR)/fact_cuda,)

.PHONY: all clean run deps

all: $(BIN_DIR)/fact_c23 $(BIN_DIR)/fact_cpp23 $(BIN_DIR)/fact_java $(BIN_DIR)/fact_fortran $(CUDA_TARGET)

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

$(BIN_DIR)/fact_java: src/FactJava.java | $(BIN_DIR)
	javac -d $(BIN_DIR) $<
	printf '#!/usr/bin/env bash\njava -cp "$(BIN_DIR)" FactJava "$$@"\n' > $@
	chmod +x $@

run: all
	./run_all.sh $(N)

deps:
	@echo "Required/optional tools: gcc/g++, libgmp-dev, gfortran, nvcc, python3, ruby, perl, default-jdk"
	@echo "CUDA arch default: $(NVCC_ARCH). Override with: make NVCC_ARCH=sm_120"
	@echo "Ubuntu example: sudo apt install build-essential libgmp-dev gfortran python3 ruby perl default-jdk nvidia-cuda-toolkit"

clean:
	rm -rf $(BIN_DIR) results.csv
