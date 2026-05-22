#!/usr/bin/env bash
set -u
N="${1:-99999}"
OUT="results.csv"
: > "$OUT"

print_hw() {
  echo "Hardware"
  echo "--------"
  if command -v lscpu >/dev/null 2>&1; then
    lscpu | awk -F: '/Model name|CPU\(s\)|Thread\(s\) per core|Core\(s\) per socket|Socket\(s\)|CPU max MHz/ {gsub(/^[ \t]+/,"",$2); printf "%s: %s\n", $1, $2}'
  fi
  if command -v nvidia-smi >/dev/null 2>&1; then
    nvidia-smi --query-gpu=name,driver_version,memory.total,compute_cap --format=csv,noheader 2>/dev/null | awk -F, '{printf "GPU: %s, driver %s, VRAM %s, compute capability %s\n", $1, $2, $3, $4}'
  else
    echo "GPU: nvidia-smi not found"
  fi
  if command -v nvcc >/dev/null 2>&1; then
    nvcc --version | awk '/release/ {print "CUDA: " $0}'
  fi
  echo "Benchmark: ${N}!"
  echo
}

clean_msg() {
  tr '\n' ' ' < "$1" | sed 's/[[:space:]][[:space:]]*/ /g; s/|/ /g' | cut -c1-90
}

run_one() {
  local label="$1"; shift
  if "$@" > .bench_tmp 2>.bench_err; then
    local line
    line="$(head -n 1 .bench_tmp)"
    if [[ "$line" == *"|"* ]]; then
      printf '%s\n' "$line" >> "$OUT"
    else
      echo "$label|SKIPPED|0|0|invalid output: $line" >> "$OUT"
    fi
  else
    echo "$label|SKIPPED|0|0|$(clean_msg .bench_err)" >> "$OUT"
  fi
}

sort_results() {
  awk -F'|' '
    $2 == "SKIPPED" { printf "1|999999999999|%s\n", $0; next }
    { printf "0|%020.6f|%s\n", $2 + 0, $0 }
  ' "$OUT" | sort -t'|' -k1,1n -k2,2n | cut -d'|' -f3- > results_sorted.csv
}

print_table() {
  local table_file="${1:-results_sorted.csv}"
  awk -F'|' '
  BEGIN {
    n=0;
    h0="#"; h1="Language"; h2="Time ms"; h3="Digits"; h4="Trailing 0s"; h5="Notes";
    w0=length(h0); w1=length(h1); w2=length(h2); w3=length(h3); w4=length(h4); w5=length(h5);
  }
  {
    ++n; rank[n]=n; lang[n]=$1; ms[n]=$2; dig[n]=$3; zero[n]=$4; note[n]=$5;
    if (length(rank[n])>w0) w0=length(rank[n]);
    if (length($1)>w1) w1=length($1);
    if (length($2)>w2) w2=length($2);
    if (length($3)>w3) w3=length($3);
    if (length($4)>w4) w4=length($4);
    if (length($5)>w5) w5=length($5);
  }
  function rep(ch, count,    s,i){s=""; for(i=0;i<count;i++) s=s ch; return s}
  function border(l,m,r){print l rep("─",w0+2) m rep("─",w1+2) m rep("─",w2+2) m rep("─",w3+2) m rep("─",w4+2) m rep("─",w5+2) r}
  function row(a,b,c,d,e,f){printf "│ %*s │ %-*s │ %*s │ %*s │ %*s │ %-*s │\n", w0,a,w1,b,w2,c,w3,d,w4,e,w5,f}
  END {
    border("┌","┬","┐"); row(h0,h1,h2,h3,h4,h5); border("├","┼","┤");
    for (i=1;i<=n;i++) row(rank[i],lang[i],ms[i],dig[i],zero[i],note[i]);
    border("└","┴","┘");
  }' "$table_file"
}

print_hw

echo "Running benchmarks one by one..."
run_one C23 ./bin/fact_c23 "$N"
run_one C++23 ./bin/fact_cpp23 "$N"
run_one Python ./fact_python.py "$N"
run_one Ruby ./fact_ruby.rb "$N"
run_one Perl ./fact_perl.pl "$N"
run_one Fortran ./bin/fact_fortran "$N"
run_one Java ./bin/fact_java "$N"
if [[ -x ./bin/fact_cuda ]]; then
  run_one CUDA+CPU ./bin/fact_cuda "$N"
else
  echo "CUDA+CPU|SKIPPED|0|0|CUDA binary not built" >> "$OUT"
fi
rm -f .bench_tmp .bench_err

echo
sort_results

echo "Final table, fastest to slowest"
echo "-------------------------------"
print_table results_sorted.csv
