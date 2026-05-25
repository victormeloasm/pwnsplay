#!/usr/bin/env python3
import time
import numpy as np

N = 1000

i = np.arange(N, dtype=np.int64)[:, None]
j = np.arange(N, dtype=np.int64)[None, :]
A = (((i * 131 + j * 17 + 13) % 1000).astype(np.float64)) * 0.001 - 0.5
B = (((i * 19 + j * 137 + 7) % 1000).astype(np.float64)) * 0.001 - 0.5

t0 = time.perf_counter()
C = A @ B
t1 = time.perf_counter()

chk = float(C.ravel()[::97].sum())
print("language Python NumPy ecosystem")
print(f"time_ms {(t1 - t0)*1000:.6f}")
print(f"checksum {chk:.17g}")
