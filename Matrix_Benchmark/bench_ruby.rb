N = 1000
BS = 32

def aval(i, j)
  ((i * 131 + j * 17 + 13) % 1000) * 0.001 - 0.5
end

def bval(i, j)
  ((i * 19 + j * 137 + 7) % 1000) * 0.001 - 0.5
end

a = Array.new(N*N, 0.0)
bt = Array.new(N*N, 0.0)
c = Array.new(N*N, 0.0)

(0...N).each do |i|
  (0...N).each do |j|
    a[i*N+j] = aval(i,j)
    bt[j*N+i] = bval(i,j)
  end
end

t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)

ii = 0
while ii < N
  iimax = [ii + BS, N].min
  jj = 0
  while jj < N
    jjmax = [jj + BS, N].min
    i = ii
    while i < iimax
      abase = i*N
      j = jj
      while j < jjmax
        bbase = j*N
        s = 0.0
        k = 0
        while k < N
          s += a[abase+k] * bt[bbase+k]
          k += 1
        end
        c[abase+j] = s
        j += 1
      end
      i += 1
    end
    jj += BS
  end
  ii += BS
end

t1 = Process.clock_gettime(Process::CLOCK_MONOTONIC)

chk = 0.0
idx = 0
while idx < N*N
  chk += c[idx]
  idx += 97
end

puts "language Ruby pure"
puts "time_ms #{((t1 - t0)*1000).round(6)}"
puts "checksum %.17g" % chk
