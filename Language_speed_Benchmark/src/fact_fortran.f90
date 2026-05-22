program fact_fortran
  use iso_c_binding
  use iso_fortran_env, only: int64, real64
  implicit none

  type, bind(C) :: mpz_t
     integer(c_int) :: alloc
     integer(c_int) :: size
     type(c_ptr) :: limbs
  end type mpz_t

  interface
     subroutine mpz_init(x) bind(C, name="__gmpz_init")
       import :: mpz_t
       type(mpz_t) :: x
     end subroutine
     subroutine mpz_clear(x) bind(C, name="__gmpz_clear")
       import :: mpz_t
       type(mpz_t) :: x
     end subroutine
     subroutine mpz_set_ui(rop, op) bind(C, name="__gmpz_set_ui")
       import :: mpz_t, c_long
       type(mpz_t) :: rop
       integer(c_long), value :: op
     end subroutine
     subroutine mpz_mul_ui(rop, op1, op2) bind(C, name="__gmpz_mul_ui")
       import :: mpz_t, c_long
       type(mpz_t) :: rop
       type(mpz_t) :: op1
       integer(c_long), value :: op2
     end subroutine
     subroutine mpz_mul(rop, op1, op2) bind(C, name="__gmpz_mul")
       import :: mpz_t
       type(mpz_t) :: rop
       type(mpz_t) :: op1
       type(mpz_t) :: op2
     end subroutine
     function mpz_sizeinbase(op, base) result(res) bind(C, name="__gmpz_sizeinbase")
       import :: mpz_t, c_int, c_size_t
       type(mpz_t) :: op
       integer(c_int), value :: base
       integer(c_size_t) :: res
     end function
  end interface

  integer(int64) :: n, z, tmp, digits
  integer :: argc, start_count, end_count, rate
  real(real64) :: ms
  character(len=64) :: arg
  type(mpz_t) :: f

  n = 99999_int64
  argc = command_argument_count()
  if (argc >= 1) then
     call get_command_argument(1, arg)
     read(arg, *) n
  end if

  call mpz_init(f)
  call system_clock(start_count, rate)
  call prod_range(1_int64, n, f)
  call system_clock(end_count, rate)
  ms = 1000.0_real64 * real(end_count - start_count, real64) / real(rate, real64)

  digits = int(mpz_sizeinbase(f, 10_c_int), int64)
  tmp = n; z = 0_int64
  do while (tmp > 0)
     tmp = tmp / 5_int64
     z = z + tmp
  end do

  write(*,'(A,F0.3,A,I0,A,I0,A)') 'Fortran|', ms, '|', digits, '|', z, '|GMP product tree via ISO_C_BINDING'
  call mpz_clear(f)

contains
  recursive subroutine prod_range(lo, hi, out)
    integer(int64), intent(in) :: lo, hi
    type(mpz_t) :: out
    integer(int64) :: i, mid
    type(mpz_t) :: left, right

    if (lo > hi) then
       call mpz_set_ui(out, 1_c_long)
    else if (lo == hi) then
       call mpz_set_ui(out, int(lo, c_long))
    else if (hi - lo <= 32_int64) then
       call mpz_set_ui(out, 1_c_long)
       do i = lo, hi
          call mpz_mul_ui(out, out, int(i, c_long))
       end do
    else
       mid = lo + (hi - lo) / 2_int64
       call mpz_init(left)
       call mpz_init(right)
       call prod_range(lo, mid, left)
       call prod_range(mid + 1_int64, hi, right)
       call mpz_mul(out, left, right)
       call mpz_clear(left)
       call mpz_clear(right)
    end if
  end subroutine prod_range
end program fact_fortran
