#include <cuda_runtime.h>
#include <gmp.h>
#include <cstdio>
#include <cstdlib>
#include <ctime>
#include <vector>

static double now_ms(void) {
    timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec * 1000.0 + (double)ts.tv_nsec / 1.0e6;
}

static unsigned long trailing_zeroes(unsigned long n) {
    unsigned long z = 0;
    while (n) { n /= 5; z += n; }
    return z;
}

__global__ void pair_products(unsigned long long *out, unsigned long n) {
    unsigned long idx = blockIdx.x * blockDim.x + threadIdx.x;
    unsigned long a = idx * 2 + 1;
    if (a > n) return;
    unsigned long b = a + 1;
    unsigned long long v = (unsigned long long)a;
    if (b <= n) v *= (unsigned long long)b;
    out[idx] = v;
}

static void prod_chunks(mpz_t out, const unsigned long long *chunks, size_t lo, size_t hi) {
    if (lo >= hi) { mpz_set_ui(out, 1); return; }
    if (hi - lo == 1) { mpz_set_ui(out, chunks[lo]); return; }
    if (hi - lo <= 16) {
        mpz_set_ui(out, 1);
        for (size_t i = lo; i < hi; ++i) mpz_mul_ui(out, out, chunks[i]);
        return;
    }
    size_t mid = lo + (hi - lo) / 2;
    mpz_t left, right;
    mpz_init(left); mpz_init(right);
    prod_chunks(left, chunks, lo, mid);
    prod_chunks(right, chunks, mid, hi);
    mpz_mul(out, left, right);
    mpz_clear(left); mpz_clear(right);
}

int main(int argc, char **argv) {
    unsigned long n = (argc > 1) ? strtoul(argv[1], nullptr, 10) : 99999UL;
    size_t groups = (n + 1) / 2;
    std::vector<unsigned long long> host(groups);
    unsigned long long *dev = nullptr;

    cudaEvent_t e0, e1;
    cudaEventCreate(&e0); cudaEventCreate(&e1);

    double total0 = now_ms();
    cudaMalloc(&dev, groups * sizeof(unsigned long long));
    int block = 256;
    int grid = (int)((groups + block - 1) / block);
    cudaEventRecord(e0);
    pair_products<<<grid, block>>>(dev, n);
    cudaEventRecord(e1);
    cudaEventSynchronize(e1);
    float kernel_ms = 0.0f;
    cudaEventElapsedTime(&kernel_ms, e0, e1);
    cudaMemcpy(host.data(), dev, groups * sizeof(unsigned long long), cudaMemcpyDeviceToHost);
    cudaFree(dev);

    mpz_t fact;
    mpz_init(fact);
    prod_chunks(fact, host.data(), 0, groups);
    double total1 = now_ms();
    size_t digits = mpz_sizeinbase(fact, 10);
    printf("CUDA+CPU|%.3f|%zu|%lu|GPU pair products %.3f ms, CPU GMP reduction\n", total1 - total0, digits, trailing_zeroes(n), kernel_ms);
    mpz_clear(fact);
    cudaEventDestroy(e0); cudaEventDestroy(e1);
    return 0;
}
