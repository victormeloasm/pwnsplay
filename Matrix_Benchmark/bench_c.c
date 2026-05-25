#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <cblas.h>

#define N 1000

static inline double now_ms(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec * 1000.0 + (double)ts.tv_nsec / 1000000.0;
}

static inline double aval(int i, int j) {
    return ((double)((i * 131 + j * 17 + 13) % 1000)) * 0.001 - 0.5;
}

static inline double bval(int i, int j) {
    return ((double)((i * 19 + j * 137 + 7) % 1000)) * 0.001 - 0.5;
}

static void fill_colmajor(double *A, double *B) {
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            A[i + (size_t)j*N] = aval(i,j);
            B[i + (size_t)j*N] = bval(i,j);
        }
    }
}

static double checksum_colmajor_as_rowmajor(const double *C) {
    double s = 0.0;
    for (size_t idx = 0; idx < (size_t)N*N; idx += 97) {
        int row = (int)(idx / N);
        int col = (int)(idx % N);
        s += C[row + (size_t)col*N];
    }
    return s;
}

int main(void) {
    double *A = aligned_alloc(64, sizeof(double) * (size_t)N * N);
    double *B = aligned_alloc(64, sizeof(double) * (size_t)N * N);
    double *C = aligned_alloc(64, sizeof(double) * (size_t)N * N);
    if (!A || !B || !C) {
        fprintf(stderr, "allocation failed\n");
        return 1;
    }

    fill_colmajor(A, B);

    double alpha = 1.0;
    double beta = 0.0;

    cblas_dgemm(CblasColMajor, CblasNoTrans, CblasNoTrans,
                N, N, N, alpha, A, N, B, N, beta, C, N);

    double t0 = now_ms();
    cblas_dgemm(CblasColMajor, CblasNoTrans, CblasNoTrans,
                N, N, N, alpha, A, N, B, N, beta, C, N);
    double t1 = now_ms();

    printf("language C23 OpenBLAS\n");
    printf("time_ms %.6f\n", t1 - t0);
    printf("checksum %.17g\n", checksum_colmajor_as_rowmajor(C));

    free(A);
    free(B);
    free(C);
    return 0;
}
