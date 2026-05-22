# Factorial Language + GPU Benchmark

Benchmark for exact computation of `99999!` across multiple languages, plus a CUDA assisted version.

It prints a hardware summary and a final terminal table with:

- language
- elapsed time in milliseconds
- number of decimal digits
- number of trailing zeroes
- implementation note

## Dependencies on Ubuntu

```bash
sudo apt update
sudo apt install build-essential libgmp-dev gfortran python3 ruby perl default-jdk nvidia-cuda-toolkit
```

Optional but strongly recommended for Perl:

```bash
sudo apt install libmath-bigint-gmp-perl
```

Without `libmath-bigint-gmp-perl`, Perl falls back to pure Perl / Calc bigint and will be much slower.

## Build

```bash
make -j
```

CUDA is built only if `nvcc` is available.

## Run

```bash
make run
```

or directly:

```bash
./run_all.sh 99999
```

## Notes

The C23, C++23 and Fortran versions use GMP product trees. Fortran calls GMP through `ISO_C_BINDING`, so it is now a fair optimized Fortran entry rather than a naive custom bigint.

Python uses `math.factorial`, which is implemented in CPython's C core. The script disables Python's integer string conversion digit limit so it can count the digits of `99999!` correctly.

Java uses `BigInteger` with a product tree.

Ruby uses native arbitrary precision integers with a product tree.

Perl uses `Math::BigInt try => 'GMP'`; install the optional GMP backend for a fairer result.

CUDA computes small pair/group products on the GPU and reduces the exact giant integer with GMP on the CPU. That is intentional and honest: for exact factorials, the GPU kernel is fast, but the final big integer reduction becomes the real bottleneck.

## Sorting

`run_all.sh` now sorts the final table from fastest to slowest automatically. Successful runs are ordered by `Time ms`; skipped benchmarks are kept at the bottom.


### CUDA architecture

This package now defaults to the Blackwell/RTX 50 series target:

```bash
make clean
make -j NVCC_ARCH=sm_120
./run_all.sh 99999
```

For older NVIDIA GPUs, override the architecture, for example `NVCC_ARCH=sm_89` for RTX 40 series Ada.

### Perl optimization note

The Perl version uses `Math::BigInt try => 'GMP'`, packs many small multiplications into native integer chunks first, and then reduces those chunks with a balanced BigInt product tree. This avoids doing one BigInt multiplication per integer from 1 to n.
