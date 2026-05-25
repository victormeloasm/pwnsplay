#!/usr/bin/env python3
import csv
import math
import os
import re
import subprocess
import sys
import time
from pathlib import Path
from shutil import which

EXPECTED_CHECKSUM = 4.808
CHECKSUM_TOL = 1e-6

FAST = [
    ("C23", ["./bench_c"]),
    ("C++23", ["./bench_cpp"]),
    ("Fortran", ["./bench_fortran"]),
    ("FreeBASIC", ["./bench_basic"]),
    ("Pascal", ["./bench_pascal"]),
    ("COBOL OpenBLAS FFI", ["./bench_cobol_blas"]),
    ("FASM", ["./bench_fasm"]),
    ("Rust", ["./bench_rust"]),
    ("Zig", ["./bench_zig"]),
    ("Java", ["java", "MatrixBench"]),
    ("JavaScript Node", ["node", "bench_js.js"]),
    ("TypeScript Node", ["node", "bench_ts.js"]),
    ("Python NumPy ecosystem", ["python3", "bench_python_numpy.py"]),
    ("Ruby Numo ecosystem", ["ruby", "bench_ruby_numo.rb"]),
    ("Perl PDL ecosystem", ["perl", "bench_perl_pdl.pl"]),
    ("Clojure JVM", ["clojure", "bench_clojure.clj"]),
    ("CUDA cuBLAS", ["./bench_cuda_cublas"]),
]

ALL_EXTRA = [
    ("COBOL pure", ["./bench_cobol"]),
    ("Python pure", ["python3", "bench_python_pure.py"]),
    ("Ruby pure", ["ruby", "bench_ruby.rb"]),
    ("Perl pure", ["perl", "bench_perl.pl"]),
]

def command_available(cmd):
    exe = cmd[0]
    if exe.startswith("./"):
        return Path(exe).exists() and os.access(exe, os.X_OK)
    return which(exe) is not None

def parse_float_token(token):
    token = token.strip().replace(",", ".")
    token = re.sub(r"[^0-9eE+\-\.]", "", token)
    if token in ("", ".", "+", "-"):
        return None
    try:
        return float(token)
    except Exception:
        return None

def parse_output(default_name, output):
    language = default_name
    time_ms = None
    checksum_raw = ""
    checksum_float = None
    status = "OK"

    for raw in output.splitlines():
        line = raw.strip()
        if line.startswith("language "):
            language = line[len("language "):].strip()
        elif line.startswith("time_ms "):
            parts = line.split(maxsplit=1)
            if len(parts) == 2:
                time_ms = parse_float_token(parts[1])
        elif line.startswith("checksum "):
            checksum_raw = line[len("checksum "):].strip()
            checksum_float = parse_float_token(checksum_raw)
        elif "missing " in line.lower() or "install " in line.lower():
            if status == "OK":
                status = "MISSING_OPTIONAL_LIB"

    return language, time_ms, checksum_raw, checksum_float, status

def run_one(name, cmd, timeout):
    print(f"========== {name} ==========", flush=True)

    if cmd and cmd[0] == "__skip_slow__":
        msg = cmd[1] if len(cmd) > 1 else "Skipped in fast mode."
        print(f"SKIP: {msg}\n", flush=True)
        return {
            "rank": "",
            "name": name,
            "language_reported": name,
            "time_ms": None,
            "checksum": "",
            "status": "SKIPPED_SLOW_IN_FAST",
        }

    if not command_available(cmd):
        print(f"SKIP: missing command or binary: {cmd[0]}\n", flush=True)
        return {
            "rank": "",
            "name": name,
            "language_reported": name,
            "time_ms": None,
            "checksum": "",
            "status": "SKIPPED_MISSING_BINARY",
        }

    try:
        proc = subprocess.run(
            cmd,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=timeout,
            env={**os.environ, "LC_ALL": "C", "LANG": "C"},
        )
    except subprocess.TimeoutExpired:
        print(f"TIMEOUT after {timeout} seconds\n", flush=True)
        return {
            "rank": "",
            "name": name,
            "language_reported": name,
            "time_ms": None,
            "checksum": "",
            "status": "TIMEOUT",
        }

    output = proc.stdout or ""
    print(output, end="" if output.endswith("\n") else "\n", flush=True)
    print(flush=True)

    language, time_ms, checksum_raw, checksum_float, status = parse_output(name, output)

    if proc.returncode != 0:
        status = f"FAILED_RC_{proc.returncode}"
        time_ms = None
    elif status == "OK":
        if time_ms is None:
            status = "NO_TIME_MS_PARSED"
        elif checksum_float is None:
            status = "NO_CHECKSUM_PARSED"
        elif abs(checksum_float - EXPECTED_CHECKSUM) > CHECKSUM_TOL:
            status = "CHECKSUM_MISMATCH"

    return {
        "rank": "",
        "name": name,
        "language_reported": language,
        "time_ms": time_ms,
        "checksum": checksum_raw,
        "status": status,
    }

def sorted_rows(rows):
    ok = [r for r in rows if r["status"] == "OK" and isinstance(r["time_ms"], float)]
    rest = [r for r in rows if r not in ok]
    ok.sort(key=lambda r: r["time_ms"])

    out = []
    for i, r in enumerate(ok, 1):
        rr = dict(r)
        rr["rank"] = str(i)
        out.append(rr)
    out.extend(rest)
    return out

def fmt_time(x):
    return f"{x:.6f}" if isinstance(x, float) else ""

def make_aligned_table(rows):
    headers = ["Rank", "Name", "Reported language", "Time ms", "Checksum", "Status"]
    data = []
    for r in rows:
        data.append([
            str(r["rank"]),
            str(r["name"]),
            str(r["language_reported"]),
            fmt_time(r["time_ms"]),
            str(r["checksum"]),
            str(r["status"]),
        ])

    widths = [len(h) for h in headers]
    for row in data:
        for i, cell in enumerate(row):
            widths[i] = max(widths[i], len(cell))

    def sep():
        return "+-" + "-+-".join("-" * w for w in widths) + "-+"

    def row_line(row):
        # Rank and Time ms aligned right; others left.
        cells = []
        for i, cell in enumerate(row):
            if i in (0, 3):
                cells.append(cell.rjust(widths[i]))
            else:
                cells.append(cell.ljust(widths[i]))
        return "| " + " | ".join(cells) + " |"

    lines = []
    lines.append("FINAL SORTED TABLE, FASTEST TO SLOWEST")
    lines.append(sep())
    lines.append(row_line(headers))
    lines.append(sep())
    for row in data:
        lines.append(row_line(row))
    lines.append(sep())
    return "\n".join(lines)

def write_outputs(rows):
    final = sorted_rows(rows)

    with open("results_sorted.csv", "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["rank", "name", "language_reported", "time_ms", "checksum", "status"])
        writer.writeheader()
        for r in final:
            rr = dict(r)
            rr["time_ms"] = fmt_time(rr["time_ms"])
            writer.writerow(rr)

    with open("results_sorted.md", "w", encoding="utf-8") as f:
        f.write("# Matrix multiplication benchmark results\n\n")
        f.write("| Rank | Name | Reported language | Time ms | Checksum | Status |\n")
        f.write("|---:|---|---|---:|---|---|\n")
        for r in final:
            f.write(f"| {r['rank']} | {r['name']} | {r['language_reported']} | {fmt_time(r['time_ms'])} | `{r['checksum']}` | {r['status']} |\n")

    table = make_aligned_table(final)
    Path("results_sorted.txt").write_text(table + "\n", encoding="utf-8")

    print("\n" + table + "\n")
    print("Saved: results_sorted.txt")
    print("Saved: results_sorted.csv")
    print("Saved: results_sorted.md")

def main():
    mode = "fast"
    timeout = 900

    args = sys.argv[1:]
    if "--all" in args:
        mode = "all"
    if "--timeout" in args:
        i = args.index("--timeout")
        timeout = int(args[i + 1])

    jobs = list(FAST)
    if mode == "all":
        jobs.extend(ALL_EXTRA)

    rows = [run_one(name, cmd, timeout) for name, cmd in jobs]
    write_outputs(rows)

if __name__ == "__main__":
    main()
