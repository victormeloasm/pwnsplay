#define _POSIX_C_SOURCE 200809L
#include <gmp.h>
#include <time.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

static void product_range(mpz_t out, unsigned long lo, unsigned long hi) {
    if (lo > hi) { mpz_set_ui(out, 1); return; }
    if (lo == hi) { mpz_set_ui(out, lo); return; }
    if (hi - lo <= 16) {
        mpz_set_ui(out, 1);
        for (unsigned long i = lo; i <= hi; ++i) mpz_mul_ui(out, out, i);
        return;
    }
    unsigned long mid = lo + ((hi - lo) >> 1);
    mpz_t left, right;
    mpz_init(left); mpz_init(right);
    product_range(left, lo, mid);
    product_range(right, mid + 1, hi);
    mpz_mul(out, left, right);
    mpz_clear(left); mpz_clear(right);
}

static unsigned long trailing_zeroes(unsigned long n) {
    unsigned long z = 0;
    while (n) { n /= 5; z += n; }
    return z;
}

static double elapsed_ms(struct timespec a, struct timespec b) {
    return (double)(b.tv_sec - a.tv_sec) * 1000.0 + (double)(b.tv_nsec - a.tv_nsec) / 1000000.0;
}

int bench_factorial_product_tree(const char *lang, unsigned long n, const char *note) {
    mpz_t fact;
    struct timespec t0, t1;
    mpz_init(fact);
    clock_gettime(CLOCK_MONOTONIC, &t0);
    product_range(fact, 1, n);
    clock_gettime(CLOCK_MONOTONIC, &t1);
    size_t digits = mpz_sizeinbase(fact, 10);
    unsigned long zeros = trailing_zeroes(n);
    printf("%s|%.3f|%zu|%lu|%s\n", lang, elapsed_ms(t0, t1), digits, zeros, note);
    mpz_clear(fact);
    return 0;
}

int bench_fasm(unsigned long n) {
    return bench_factorial_product_tree("FASM", n, "FASM argv/ABI driver + shared C/GMP product tree");
}

int bench_cobol(unsigned long n) {
    return bench_factorial_product_tree("COBOL", n, "COBOL driver + shared C/GMP product tree");
}

int bench_pascal(unsigned long n) {
    return bench_factorial_product_tree("Pascal", n, "Free Pascal driver + shared C/GMP product tree");
}

int bench_basic(unsigned long n) {
    return bench_factorial_product_tree("BASIC", n, "FreeBASIC driver + shared C/GMP product tree");
}
