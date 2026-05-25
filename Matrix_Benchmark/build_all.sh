#!/usr/bin/env bash
set -u

echo "Building MatrixMul 1000x1000 Benchmark v12"
echo

build() {
    name="$1"
    shift
    echo "========== build $name =========="
    if command -v "$1" >/dev/null 2>&1; then
        "$@" && echo "OK: $name" || echo "FAILED: $name"
    else
        echo "SKIP: command not found: $1"
    fi
    echo
}

build_cobol() {
    name="$1"
    shift
    echo "========== build $name =========="
    if command -v cobc >/dev/null 2>&1; then
        # GNUCOBOL on some hardened Ubuntu builds prints a harmless _FORTIFY_SOURCE
        # redefinition warning from the generated C compiler command line. Filter
        # only that known warning while preserving real diagnostics.
        "$@" 2> >(grep -v "_FORTIFY_SOURCE" | grep -v "this is the location of the previous definition" >&2)
        rc=$?
        if [ $rc -eq 0 ]; then
            echo "OK: $name"
        else
            echo "FAILED: $name"
        fi
    else
        echo "SKIP: command not found: cobc"
    fi
    echo
}

build "C23" gcc -O3 -march=native -ffast-math -std=c23 bench_c.c -lopenblas -o bench_c
build "C++23" g++ -O3 -march=native -ffast-math -std=c++23 bench_cpp.cpp -lopenblas -o bench_cpp
build "Fortran" gfortran -O3 -march=native -ffast-math bench_fortran.f90 -lopenblas -o bench_fortran
build "FreeBASIC" fbc -O 3 bench_basic.bas -x bench_basic -l openblas
build "Pascal" fpc -O4 -XX -Xs bench_pascal.pas -obench_pascal
build_cobol "COBOL" cobc -x -free -O3 bench_cobol.cob -o bench_cobol
build_cobol "COBOL OpenBLAS FFI" cobc -x -free -O3 bench_cobol_blas.cob -lopenblas -o bench_cobol_blas
build "FASM object" fasm bench_fasm.asm bench_fasm.o
if [ -f bench_fasm.o ]; then
    echo "========== link FASM =========="
    gcc -no-pie bench_fasm.o -o bench_fasm && echo "OK: FASM" || echo "FAILED: FASM link"
    echo
fi
build "Rust" rustc -C opt-level=3 -C target-cpu=native bench_rust.rs -o bench_rust
build "Zig" zig build-exe bench_zig.zig -O ReleaseFast -lopenblas -lc -femit-bin=bench_zig
build "Java" javac MatrixBench.java
build "Clojure AOT skipped" clojure -e "(println \"Clojure will run interpreted/JIT\")"
build "TypeScript" tsc bench_ts.ts --target ES2020 --module commonjs --outDir .
build "CUDA cuBLAS" nvcc -O3 -std=c++17 bench_cuda_cublas.cu -lcublas -o bench_cuda_cublas

echo "Done."
