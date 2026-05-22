#include <gmpxx.h>
#include <chrono>
#include <cstdlib>
#include <iostream>
#include <iomanip>
#include <string>

static unsigned long trailing_zeroes(unsigned long n) {
    unsigned long z = 0;
    while (n) { n /= 5; z += n; }
    return z;
}

static mpz_class prod_range(unsigned long lo, unsigned long hi) {
    if (lo > hi) return 1;
    if (lo == hi) return lo;
    if (hi - lo <= 16) {
        mpz_class r = 1;
        for (unsigned long i = lo; i <= hi; ++i) r *= i;
        return r;
    }
    unsigned long mid = lo + (hi - lo) / 2;
    return prod_range(lo, mid) * prod_range(mid + 1, hi);
}

int main(int argc, char **argv) {
    unsigned long n = (argc > 1) ? std::strtoul(argv[1], nullptr, 10) : 99999UL;
    auto t0 = std::chrono::steady_clock::now();
    mpz_class fact = prod_range(1, n);
    auto t1 = std::chrono::steady_clock::now();
    double ms = std::chrono::duration<double, std::milli>(t1 - t0).count();
    size_t digits = mpz_sizeinbase(fact.get_mpz_t(), 10);
    std::cout << "C++23|" << std::fixed << std::setprecision(3) << ms << "|" << digits << "|" << trailing_zeroes(n) << "|GMP product tree\n";
}
