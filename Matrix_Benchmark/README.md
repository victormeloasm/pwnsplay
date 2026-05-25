# MatrixMul 1000x1000 Benchmark v2

Corrected benchmark.

Rules:
- N = 1000
- Operation: C = A * B
- Time only the multiplication step
- No shared C driver hidden behind other languages
- Each language uses its own implementation or its own ecosystem tools
- CUDA uses cuBLAS because this was explicitly requested
- CPU native implementations use B transposition before timing, then multiply with contiguous rows
- Dynamic languages include pure versions and optional ecosystem optimized versions where practical

Languages included:
- C23
- C++23
- Fortran
- FreeBASIC
- Pascal
- COBOL
- FASM
- CUDA cuBLAS
- Ruby
- Python
- Java
- Clojure
- Perl
- Rust
- Zig
- JavaScript
- TypeScript

Matrix values are deterministic:
A[i,j] = ((i*131 + j*17 + 13) mod 1000) / 1000 - 0.5
B[i,j] = ((i*19 + j*137 + 7) mod 1000) / 1000 - 0.5

## Install on Ubuntu

Core:

```bash
sudo apt update
sudo apt install build-essential gfortran openjdk-21-jdk nodejs npm ruby perl python3 python3-numpy fpc gnucobol fasm make unzip
```

FreeBASIC:

```bash
sudo apt install freebasic
```

If Ubuntu does not provide `fbc`, install FreeBASIC from the official release tarball.

Clojure:

```bash
sudo apt install clojure
```

Rust:

```bash
sudo apt install curl
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"
```

Zig:
Download Zig from https://ziglang.org/download and put `zig` in PATH.

TypeScript:

```bash
sudo npm install -g typescript
```

CUDA/cuBLAS:
Install NVIDIA CUDA Toolkit. Check:

```bash
nvcc --version
ldconfig -p | grep cublas
```

Optional ecosystem libraries:

```bash
pip install numpy
gem install numo-narray
sudo apt install libpdl-perl
```

## Build

```bash
./build_all.sh
```

## Run

Fast practical subset:

```bash
./run_fast.sh
```

Everything available, including slow pure dynamic language versions:

```bash
./run_all.sh
```

## Output format

Each program prints:

```text
language ...
time_ms ...
checksum ...
```

Tiny checksum differences can happen due to floating point order and library kernels.


## Final table

Version 3 adds automatic result aggregation.

Run:

```bash
./run_fast.sh
```

At the end it prints a sorted Markdown table and writes:

```text
results_sorted.csv
results_sorted.md
```

Run everything, including the slow pure dynamic versions and optional ecosystem versions:

```bash
./run_all.sh
```


## Ruby performance note

Ruby pure loops are extremely slow for 1000x1000 matrix multiplication because that is roughly one billion multiply add operations in the Ruby interpreter.

Version 4 uses Ruby Numo::NArray in the fast runner:

```bash
gem install numo-narray
```

Then:

```bash
./run_fast.sh
```

The pure Ruby version is still available in:

```bash
ruby bench_ruby.rb
```

and in:

```bash
./run_all.sh
```


## v5 compilation fixes

This version fixes two common compilation errors:

1. C23 on glibc may hide `clock_gettime()` and `CLOCK_MONOTONIC` unless the POSIX feature macro is enabled. `bench_c.c` now defines:

```c
#define _POSIX_C_SOURCE 200809L
```

2. TypeScript may complain that `process` is unknown if `@types/node` is not installed. `bench_ts.ts` now declares:

```ts
declare const process: any;
```

so it can compile with the global `tsc` package without requiring a local npm project.

If Ruby Numo fails to install on Ruby 3.3 or GCC 15, that is an upstream native extension compatibility problem. The runner treats Ruby Numo as optional. Ruby pure is still available, but it is very slow for one billion multiply add operations.


## v6 Perl performance note

Perl pure loops are too slow for the fast benchmark because 1000x1000 matrix multiplication is about one billion multiply add operations.

Version 6 changes the fast runner to use Perl PDL ecosystem instead of Perl pure:

```bash
sudo apt update
sudo apt install pdl
```

If your distro uses a different package name, search with:

```bash
apt-cache search '^pdl$|libpdl-perl'
```

Perl pure is still available manually:

```bash
perl bench_perl.pl
```

and is included only in:

```bash
./run_all.sh
```


## v7 final table and locale fixes

The final table is sorted from fastest to slowest.

The runner writes:

```text
results_sorted.csv
results_sorted.md
```

and prints:

```text
FINAL SORTED TABLE, FASTEST TO SLOWEST
```

Version 7 also fixes decimal comma parsing for runtimes that inherit a non English locale. Java now forces `Locale.US`, and the Python aggregator accepts both `660.123` and `660,123`.


## v8 fixes

This version fixes the problems found in v7:

- COBOL now builds with `cobc -free` and uses a simpler 1D array implementation.
- Zig undeclared identifier `j` fixed.
- Clojure source rewritten with balanced parentheses.
- Perl PDL checksum now uses explicit row/column indexing instead of PDL internal flat order.
- The final table is now a fixed width aligned ASCII table.
- Results are sorted from fastest to slowest.
- Failed, skipped, missing, and checksum mismatch entries are placed after ranked OK results.
- The runner now writes three files:

```text
results_sorted.txt
results_sorted.csv
results_sorted.md
```

Use:

```bash
./run_fast.sh
```

The aligned table is printed at the end and saved to `results_sorted.txt`.


## v9 fixes

This version fixes the next practical bottleneck:

- COBOL pure still builds, but is skipped in `./run_fast.sh` because it can take too long and appear frozen.
- COBOL pure is still available in `./run_all.sh` and manually with `./bench_cobol`.
- Ruby now tries to use `Numo::Linalg` with OpenBLAS before falling back to the slower Numo built-in `dot`.
- The final table remains a fixed width aligned ASCII table in `results_sorted.txt`.

For faster Ruby:

```bash
sudo apt update
sudo apt install ruby-dev build-essential libopenblas-dev liblapacke-dev
gem install numo-linalg
```

Test Ruby acceleration:

```bash
ruby -e "require 'numo/narray'; require 'numo/linalg'; require 'numo/linalg/use/openblas'; puts Numo::Linalg"
```

Then run:

```bash
./run_fast.sh
```


## v10 COBOL solution

COBOL pure loops are not practical for the fast benchmark at N = 1000 because the inner loop performs about one billion floating point multiply add operations through COBOL arithmetic.

Version 10 adds a practical COBOL path:

```text
bench_cobol_blas.cob
```

It is still COBOL code, but it calls the system BLAS routine `dgemm_` through GNUCOBOL FFI and links with OpenBLAS:

```bash
sudo apt install libopenblas-dev
```

Build line:

```bash
cobc -x -free -O3 bench_cobol_blas.cob -lopenblas -o bench_cobol_blas
```

The fast runner now uses:

```text
COBOL OpenBLAS FFI
```

The old pure COBOL version still builds as `bench_cobol` and remains available in:

```bash
./run_all.sh
```

or manually:

```bash
./bench_cobol
```

This keeps the benchmark honest:

- COBOL pure remains available for language purity.
- COBOL OpenBLAS FFI is the practical ecosystem style version, comparable to Python NumPy, Perl PDL, and Ruby Numo Linalg.


## v11 rule clarification

This version follows the corrected rule:

There is no special "pure" ranking. Each language may use a library that is normally available to that language or callable from that language ecosystem. What is not allowed is hiding the work in a shared C driver written only for the benchmark.

This means:

- C uses OpenBLAS through CBLAS.
- C++ uses OpenBLAS through CBLAS.
- Fortran uses BLAS `dgemm`.
- FreeBASIC calls CBLAS directly.
- Pascal calls CBLAS directly.
- COBOL calls CBLAS directly through GNUCOBOL FFI.
- Rust calls OpenBLAS through its own FFI declaration.
- Zig calls OpenBLAS through its own FFI declaration.
- Python uses NumPy.
- Ruby uses Numo::Linalg/OpenBLAS when available.
- Perl uses PDL.
- CUDA uses cuBLAS.
- Java, JavaScript, TypeScript, Clojure, and FASM remain native array implementations unless their ecosystem library is installed and added later.

Install OpenBLAS:

```bash
sudo apt update
sudo apt install libopenblas-dev
```

Ruby fast path:

```bash
sudo apt install ruby-dev build-essential libopenblas-dev liblapacke-dev
gem install numo-linalg
```

Perl PDL:

```bash
sudo apt install pdl
```


## v12 fixes

This version fixes the remaining build/runtime problems seen in v11:

- Zig no longer fails on `local variable is never mutated`; OpenBLAS slices are now bound as `const`.
- COBOL OpenBLAS FFI now uses `CALL STATIC "cblas_dgemm"` so GNUCOBOL calls the linked CBLAS symbol instead of trying to load a COBOL module named `cblas_dgemm`.
- COBOL build output filters only the harmless `_FORTIFY_SOURCE redefined` warning while preserving real errors.
- Fortran now measures wall clock time with `system_clock`, not `cpu_time`, because OpenBLAS is multithreaded and `cpu_time` can report accumulated CPU time across threads.

Run:

```bash
./build_all.sh
./run_fast.sh
```
