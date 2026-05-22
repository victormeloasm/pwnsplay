#!/usr/bin/env ruby
n = (ARGV[0] || "99999").to_i

def trailing_zeroes(n)
  z = 0
  while n > 0
    n /= 5
    z += n
  end
  z
end

def prod_range(lo, hi)
  return 1 if lo > hi
  return lo if lo == hi
  if hi - lo <= 16
    r = 1
    lo.upto(hi) { |i| r *= i }
    return r
  end
  mid = lo + (hi - lo) / 2
  prod_range(lo, mid) * prod_range(mid + 1, hi)
end

t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
f = prod_range(1, n)
t1 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
puts "Ruby|#{format('%.3f', (t1-t0)*1000)}|#{f.to_s.length}|#{trailing_zeroes(n)}|Integer product tree"
