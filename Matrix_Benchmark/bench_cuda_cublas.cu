#include <cstdio>
#include <cstdlib>
#include <cuda_runtime.h>
#include <cublas_v2.h>

#define N 1000

#define CUDA_CHECK(call) do { cudaError_t e=(call); if(e!=cudaSuccess){fprintf(stderr,"CUDA error %s:%d %s\n",__FILE__,__LINE__,cudaGetErrorString(e)); exit(1);} } while(0)
#define CUBLAS_CHECK(call) do { cublasStatus_t s=(call); if(s!=CUBLAS_STATUS_SUCCESS){fprintf(stderr,"cuBLAS error %s:%d status=%d\n",__FILE__,__LINE__,(int)s); exit(1);} } while(0)

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
    double *hA, *hB, *hC;
    double *dA, *dB, *dC;

    CUDA_CHECK(cudaMallocHost((void**)&hA, sizeof(double)*(size_t)N*N));
    CUDA_CHECK(cudaMallocHost((void**)&hB, sizeof(double)*(size_t)N*N));
    CUDA_CHECK(cudaMallocHost((void**)&hC, sizeof(double)*(size_t)N*N));
    fill_colmajor(hA, hB);

    CUDA_CHECK(cudaMalloc((void**)&dA, sizeof(double)*(size_t)N*N));
    CUDA_CHECK(cudaMalloc((void**)&dB, sizeof(double)*(size_t)N*N));
    CUDA_CHECK(cudaMalloc((void**)&dC, sizeof(double)*(size_t)N*N));
    CUDA_CHECK(cudaMemcpy(dA, hA, sizeof(double)*(size_t)N*N, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(dB, hB, sizeof(double)*(size_t)N*N, cudaMemcpyHostToDevice));

    cublasHandle_t handle;
    CUBLAS_CHECK(cublasCreate(&handle));
    const double alpha = 1.0, beta = 0.0;

    CUBLAS_CHECK(cublasDgemm(handle, CUBLAS_OP_N, CUBLAS_OP_N, N, N, N, &alpha, dA, N, dB, N, &beta, dC, N));
    CUDA_CHECK(cudaDeviceSynchronize());

    cudaEvent_t start, stop;
    CUDA_CHECK(cudaEventCreate(&start));
    CUDA_CHECK(cudaEventCreate(&stop));
    CUDA_CHECK(cudaEventRecord(start));
    CUBLAS_CHECK(cublasDgemm(handle, CUBLAS_OP_N, CUBLAS_OP_N, N, N, N, &alpha, dA, N, dB, N, &beta, dC, N));
    CUDA_CHECK(cudaEventRecord(stop));
    CUDA_CHECK(cudaEventSynchronize(stop));
    float ms = 0.0f;
    CUDA_CHECK(cudaEventElapsedTime(&ms, start, stop));

    CUDA_CHECK(cudaMemcpy(hC, dC, sizeof(double)*(size_t)N*N, cudaMemcpyDeviceToHost));

    printf("language CUDA cuBLAS DGEMM\n");
    printf("time_ms %.6f\n", ms);
    printf("checksum %.17g\n", checksum_colmajor_as_rowmajor(hC));

    CUDA_CHECK(cudaEventDestroy(start));
    CUDA_CHECK(cudaEventDestroy(stop));
    CUBLAS_CHECK(cublasDestroy(handle));
    CUDA_CHECK(cudaFree(dA)); CUDA_CHECK(cudaFree(dB)); CUDA_CHECK(cudaFree(dC));
    CUDA_CHECK(cudaFreeHost(hA)); CUDA_CHECK(cudaFreeHost(hB)); CUDA_CHECK(cudaFreeHost(hC));
    return 0;
}
