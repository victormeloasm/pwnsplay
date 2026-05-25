#!/usr/bin/env python3
import time

N = 1000
BS = 32

def aval(i, j):
    return ((i * 131 + j * 17 + 13) % 1000) * 0.001 - 0.5

def bval(i, j):
    return ((i * 19 + j * 137 + 7) % 1000) * 0.001 - 0.5

A = [0.0] * (N*N)
BT = [0.0] * (N*N)
C = [0.0] * (N*N)

for i in range(N):
    base = i*N
    for j in range(N):
        A[base+j] = aval(i,j)
        BT[j*N+i] = bval(i,j)

t0 = time.perf_counter()

for ii in range(0, N, BS):
    iimax = min(ii + BS, N)
    for jj in range(0, N, BS):
        jjmax = min(jj + BS, N)
        for i in range(ii, iimax):
            abase = i*N
            for j in range(jj, jjmax):
                bbase = j*N
                s = 0.0
                for k in range(N):
                    s += A[abase+k] * BT[bbase+k]
                C[abase+j] = s

t1 = time.perf_counter()

chk = sum(C[0:N*N:97])
print("language Python pure")
print(f"time_ms {(t1 - t0)*1000:.6f}")
print(f"checksum {chk:.17g}")
