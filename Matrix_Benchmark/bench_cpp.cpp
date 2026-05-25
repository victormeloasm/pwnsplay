#include <algorithm>
#include <chrono>
#include <cblas.h>
#include <iostream>
#include <vector>

static constexpr int N = 1000;

static inline double aval(int i, int j) {
    return double((i * 131 + j * 17 + 13) % 1000) * 0.001 - 0.5;
}

static inline double bval(int i, int j) {
    return double((i * 19 + j * 137 + 7) % 1000) * 0.001 - 0.5;
}

static void fill_colmajor(std::vector<double>& A, std::vector<double>& B) {
    for (int i = 0; i < N; ++i)
        for (int j = 0; j < N; ++j) {
            A[i + (size_t)j * N] = aval(i,j);
            B[i + (size_t)j * N] = bval(i,j);
        }
}

static double checksum_colmajor_as_rowmajor(const std::vector<double>& C) {
    double s = 0.0;
    for (size_t idx = 0; idx < C.size(); idx += 97) {
        int row = int(idx / N);
        int col = int(idx % N);
        s += C[row + (size_t)col * N];
    }
    return s;
}

int main() {
    std::vector<double> A((size_t)N*N), B((size_t)N*N), C((size_t)N*N);
    fill_colmajor(A, B);

    cblas_dgemm(CblasColMajor, CblasNoTrans, CblasNoTrans,
                N, N, N, 1.0, A.data(), N, B.data(), N, 0.0, C.data(), N);

    auto t0 = std::chrono::steady_clock::now();
    cblas_dgemm(CblasColMajor, CblasNoTrans, CblasNoTrans,
                N, N, N, 1.0, A.data(), N, B.data(), N, 0.0, C.data(), N);
    auto t1 = std::chrono::steady_clock::now();

    double ms = std::chrono::duration<double, std::milli>(t1 - t0).count();
    std::cout << "language C++23 OpenBLAS\n";
    std::cout << "time_ms " << ms << "\n";
    std::cout.precision(17);
    std::cout << "checksum " << checksum_colmajor_as_rowmajor(C) << "\n";
}
