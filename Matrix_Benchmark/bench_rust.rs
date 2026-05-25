use std::time::Instant;

const N: usize = 1000;
const CBLAS_COL_MAJOR: i32 = 102;
const CBLAS_NO_TRANS: i32 = 111;

#[link(name = "openblas")]
extern "C" {
    fn cblas_dgemm(
        layout: i32,
        transa: i32,
        transb: i32,
        m: i32,
        n: i32,
        k: i32,
        alpha: f64,
        a: *const f64,
        lda: i32,
        b: *const f64,
        ldb: i32,
        beta: f64,
        c: *mut f64,
        ldc: i32,
    );
}

#[inline(always)]
fn aval(i: usize, j: usize) -> f64 {
    (((i * 131 + j * 17 + 13) % 1000) as f64) * 0.001 - 0.5
}

#[inline(always)]
fn bval(i: usize, j: usize) -> f64 {
    (((i * 19 + j * 137 + 7) % 1000) as f64) * 0.001 - 0.5
}

fn checksum_colmajor_as_rowmajor(c: &[f64]) -> f64 {
    let mut s = 0.0;
    let mut idx = 0usize;
    while idx < N * N {
        let row = idx / N;
        let col = idx % N;
        s += c[row + col * N];
        idx += 97;
    }
    s
}

fn main() {
    let mut a = vec![0.0f64; N * N];
    let mut b = vec![0.0f64; N * N];
    let mut c = vec![0.0f64; N * N];

    for i in 0..N {
        for j in 0..N {
            a[i + j*N] = aval(i,j);
            b[i + j*N] = bval(i,j);
        }
    }

    unsafe {
        cblas_dgemm(CBLAS_COL_MAJOR, CBLAS_NO_TRANS, CBLAS_NO_TRANS,
                    N as i32, N as i32, N as i32,
                    1.0, a.as_ptr(), N as i32, b.as_ptr(), N as i32,
                    0.0, c.as_mut_ptr(), N as i32);
    }

    let t0 = Instant::now();

    unsafe {
        cblas_dgemm(CBLAS_COL_MAJOR, CBLAS_NO_TRANS, CBLAS_NO_TRANS,
                    N as i32, N as i32, N as i32,
                    1.0, a.as_ptr(), N as i32, b.as_ptr(), N as i32,
                    0.0, c.as_mut_ptr(), N as i32);
    }

    let ms = t0.elapsed().as_secs_f64() * 1000.0;
    println!("language Rust OpenBLAS FFI");
    println!("time_ms {:.6}", ms);
    println!("checksum {:.17}", checksum_colmajor_as_rowmajor(&c));
}
