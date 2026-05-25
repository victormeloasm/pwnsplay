#!/usr/bin/env ruby
begin
  require 'numo/narray'
rescue LoadError
  puts "language Ruby Numo Linalg ecosystem"
  puts "missing numo-narray. Install with: gem install numo-narray"
  exit 0
end

linalg_loaded = false
linalg_backend = "Numo built-in dot"

begin
  require 'numo/linalg'
  begin
    require 'numo/linalg/use/openblas'
    linalg_backend = "Numo::Linalg OpenBLAS"
  rescue LoadError
    linalg_backend = "Numo::Linalg"
  end
  linalg_loaded = true
rescue LoadError
  linalg_loaded = false
end

N = 1000

i = Numo::Int64.new(N, 1).seq
j = Numo::Int64.new(1, N).seq

a = (((i * 131 + j * 17 + 13) % 1000).cast_to(Numo::DFloat)) * 0.001 - 0.5
b = (((i * 19 + j * 137 + 7) % 1000).cast_to(Numo::DFloat)) * 0.001 - 0.5

t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)

# numo-linalg monkey patches/accelerates dot when loaded.
# If it is not loaded, this falls back to Numo::NArray built-in dot, which warns and is slower.
c = a.dot(b)

t1 = Process.clock_gettime(Process::CLOCK_MONOTONIC)

chk = 0.0
idx = 0
while idx < N * N
  row = idx / N
  col = idx % N
  chk += c[row, col]
  idx += 97
end

if linalg_loaded
  puts "language Ruby Numo Linalg ecosystem"
else
  puts "language Ruby Numo ecosystem fallback"
end
puts "backend #{linalg_backend}"
puts "time_ms #{format('%.6f', (t1 - t0) * 1000.0)}"
puts "checksum #{format('%.17g', chk)}"
