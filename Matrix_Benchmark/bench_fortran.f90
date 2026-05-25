program bench_fortran
    use iso_fortran_env, only: real64, int64
    implicit none
    integer, parameter :: n = 1000
    real(real64), allocatable :: A(:,:), B(:,:), C(:,:)
    real(real64) :: chk, ms
    integer :: i, j, idx, row, col
    integer(int64) :: t0, t1, rate

    allocate(A(n,n), B(n,n), C(n,n))

    do j = 1, n
        do i = 1, n
            A(i,j) = real(mod((i-1)*131 + (j-1)*17 + 13, 1000), real64) * 0.001_real64 - 0.5_real64
            B(i,j) = real(mod((i-1)*19 + (j-1)*137 + 7, 1000), real64) * 0.001_real64 - 0.5_real64
        end do
    end do

    call dgemm('N', 'N', n, n, n, 1.0_real64, A, n, B, n, 0.0_real64, C, n)

    call system_clock(t0, rate)
    call dgemm('N', 'N', n, n, n, 1.0_real64, A, n, B, n, 0.0_real64, C, n)
    call system_clock(t1, rate)

    ms = real(t1 - t0, real64) * 1000.0_real64 / real(rate, real64)

    chk = 0.0_real64
    do idx = 0, n*n-1, 97
        row = idx / n + 1
        col = mod(idx, n) + 1
        chk = chk + C(row, col)
    end do

    print *, "language Fortran BLAS"
    print '(A,F12.6)', "time_ms ", ms
    print '(A,ES24.16)', "checksum ", chk
end program
