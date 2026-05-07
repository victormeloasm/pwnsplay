#!/usr/bin/env python3
import os
import re
import sys
import ctypes
import ctypes.util
import subprocess

PROC_NAME = "cleartext"

# Mesmo padro do programa C++:
# letras maisculas, minsculas, nmeros e smbolos !@#$%^&*
PASSWORD_RE = rb"[A-Za-z0-9!@#$%^&*]{20}"

libc_path = ctypes.util.find_library("c")

if not libc_path:
    print("[-] libc no encontrada.")
    sys.exit(1)

libc = ctypes.CDLL(libc_path, use_errno=True)

PTRACE_ATTACH = 16
PTRACE_DETACH = 17


def ptrace(request, pid, addr=0, data=0):
    ret = libc.ptrace(
        request,
        pid,
        ctypes.c_void_p(addr),
        ctypes.c_void_p(data),
    )

    if ret != 0:
        err = ctypes.get_errno()
        raise OSError(err, os.strerror(err))


def attach(pid):
    ptrace(PTRACE_ATTACH, pid)
    os.waitpid(pid, 0)


def detach(pid):
    ptrace(PTRACE_DETACH, pid, 0, 0)


def find_pid_by_name(name):
    result = subprocess.run(
        ["pgrep", "-n", name],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )

    if result.returncode != 0:
        return None

    out = result.stdout.strip()

    if not out:
        return None

    return int(out)


def parse_maps(pid):
    regions = []

    maps_path = f"/proc/{pid}/maps"

    with open(maps_path, "r", encoding="utf-8") as f:
        for line in f:
            parts = line.split()

            if len(parts) < 2:
                continue

            addr_range = parts[0]
            perms = parts[1]
            path = parts[5] if len(parts) >= 6 else ""

            # S queremos regies legveis.
            if "r" not in perms:
                continue

            # Evita regies especiais que podem dar erro ou no ajudar.
            if path.startswith("[vvar]"):
                continue

            if path.startswith("[vdso]"):
                continue

            if path.startswith("[vsyscall]"):
                continue

            start_s, end_s = addr_range.split("-")

            start = int(start_s, 16)
            end = int(end_s, 16)

            regions.append({
                "start": start,
                "end": end,
                "perms": perms,
                "desc": line.strip(),
            })

    return regions


def read_region(mem, start, end):
    try:
        mem.seek(start)
        return mem.read(end - start)
    except OSError:
        return b""


def score_candidate(raw, region_desc):
    score = 0

    # No nosso toy, a senha foi criada como char secret_password[21],
    # ento ela tende a estar na stack.
    if "[stack]" in region_desc:
        score += 60

    if "[heap]" in region_desc:
        score += 35

    if "rw-p" in region_desc:
        score += 25

    has_upper = any(65 <= c <= 90 for c in raw)
    has_lower = any(97 <= c <= 122 for c in raw)
    has_digit = any(48 <= c <= 57 for c in raw)
    has_symbol = any(c in b"!@#$%^&*" for c in raw)

    score += 10 * sum([
        has_upper,
        has_lower,
        has_digit,
        has_symbol,
    ])

    return score


def looks_like_false_positive(raw):
    false_positives = (
        b"ABCDEFGHIJKLMNOPQRST",
        b"abcdefghijklmnopqrst",
        b"ABCDEFGHIJKLMNOPQRSTUVWXYZ"[:20],
        b"abcdefghijklmnopqrstuvwxyz"[:20],
        b"01234567890123456789",
        b"0123456789ABCDEFGHIJ",
    )

    if raw in false_positives:
        return True

    # Evita pegar sequncias muito repetitivas.
    if len(set(raw)) <= 4:
        return True

    return False


def find_password_candidates(pid):
    candidates = []

    regions = parse_maps(pid)
    mem_path = f"/proc/{pid}/mem"

    with open(mem_path, "rb", buffering=0) as mem:
        for region in regions:
            start = region["start"]
            end = region["end"]
            desc = region["desc"]

            data = read_region(mem, start, end)

            if not data:
                continue

            for match in re.finditer(PASSWORD_RE, data):
                raw = match.group(0)

                if looks_like_false_positive(raw):
                    continue

                addr = start + match.start()
                score = score_candidate(raw, desc)

                candidates.append({
                    "addr": addr,
                    "raw": raw,
                    "text": raw.decode("ascii", errors="ignore"),
                    "region": desc,
                    "score": score,
                })

    candidates.sort(key=lambda x: x["score"], reverse=True)

    return candidates


def main():
    if len(sys.argv) >= 2:
        try:
            pid = int(sys.argv[1])
        except ValueError:
            print("[-] PID invlido.")
            print(f"Uso: sudo {sys.argv[0]} [PID]")
            sys.exit(1)
    else:
        pid = find_pid_by_name(PROC_NAME)

        if pid is None:
            print(f"[-] Processo '{PROC_NAME}' no encontrado.")
            print()
            print("Abra outro terminal e rode:")
            print("    ./cleartext")
            print()
            print("Depois execute:")
            print(f"    sudo {sys.argv[0]}")
            print()
            print("Ou passe o PID manualmente:")
            print(f"    sudo {sys.argv[0]} <PID>")
            sys.exit(1)

    print(f"[+] Alvo: {PROC_NAME}")
    print(f"[+] PID : {pid}")

    print("[+] Anexando com ptrace...")

    try:
        attach(pid)
    except OSError as e:
        print(f"[-] Falha no ptrace attach: {e}")
        print()
        print("Possvel bloqueio do Yama ptrace_scope.")
        print("Para laboratrio local temporrio:")
        print("    echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope")
        sys.exit(1)

    try:
        print("[+] Lendo memria do processo...")
        candidates = find_password_candidates(pid)
    finally:
        print("[+] Desanexando...")
        try:
            detach(pid)
        except OSError as e:
            print(f"[!] Falha ao desanexar: {e}")

    if not candidates:
        print("[-] Nenhuma senha candidata encontrada.")
        print()
        print("Verifique se o programa cleartext j chegou no prompt da senha.")
        sys.exit(1)

    best = candidates[0]

    print()
    print("[+] Melhor candidata encontrada:")
    print(f"    senha : {best['text']}")
    print(f"    addr  : 0x{best['addr']:x}")
    print(f"    score : {best['score']}")
    print(f"    regio: {best['region']}")
    print()

    print("[+] Copie e cole esta senha no programa:")
    print()
    print(best["text"])
    print()


if __name__ == "__main__":
    main()