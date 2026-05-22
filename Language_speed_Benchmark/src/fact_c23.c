#define _POSIX_C_SOURCE 200809L
#include <gmp.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <time.h>

static double now_ms(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec * 1000.0 + (double)ts.tv_nsec / 1.0e6;
}

static unsigned long trailing_zeroes(unsigned long n) {
    unsigned long z = 0;
    while (n) { n /= 5; z += n; }
    return z;
}

static void prod_range(mpz_t out, unsigned long lo, unsigned long hi) {
    if (lo > hi) { mpz_set_ui(out, 1); return; }
    if (lo == hi) { mpz_set_ui(out, lo); return; }
    if (hi - lo <= 16) {
        mpz_set_ui(out, 1);
        for (unsigned long i = lo; i <= hi; ++i) mpz_mul_ui(out, out, i);
        return;
    }
    unsigned long mid = lo + (hi - lo) / 2;
    mpz_t left, right;
    mpz_init(left); mpz_init(right);
    prod_range(left, lo, mid);
    prod_range(right, mid + 1, hi);
    mpz_mul(out, left, right);
    mpz_clear(left); mpz_clear(right);
}

int main(int argc, char **argv) {
    unsigned long n = (argc > 1) ? strtoul(argv[1], NULL, 10) : 99999UL;
    mpz_t fact;
    mpz_init(fact);
    double t0 = now_ms();
    prod_range(fact, 1, n);
    double t1 = now_ms();
    size_t digits = mpz_sizeinbase(fact, 10);
    printf("C23|%.3f|%zu|%lu|GMP product tree\n", t1 - t0, digits, trailing_zeroes(n));
    mpz_clear(fact);
    return 0;
}
