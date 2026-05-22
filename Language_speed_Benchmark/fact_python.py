#!/usr/bin/env python3
import math
import sys
import time

if hasattr(sys, "set_int_max_str_digits"):
    sys.set_int_max_str_digits(0)


def trailing_zeroes(n: int) -> int:
    z = 0
    while n:
        n //= 5
        z += n
    return z


def main() -> None:
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 99999
    t0 = time.perf_counter()
    fact = math.factorial(n)
    t1 = time.perf_counter()
    sys.stdout.write(
        "Python|{:.3f}|{}|{}|math.factorial in CPython C core\n".format(
            (t1 - t0) * 1000.0,
            len(str(fact)),
            trailing_zeroes(n),
        )
    )


if __name__ == "__main__":
    main()
