# 🐸 FrogOverflowLab – Stack Buffer Overflow in C++

## 📌 Overview

This project is a **deliberately vulnerable C++ application** designed to demonstrate a classic **stack-based buffer overflow** caused by unsafe memory operations.

The goal is to show, in a controlled local environment:

* How a simple `strcpy()` can corrupt the stack
* How control flow can be redirected
* Why modern protections prevent this behavior
* How to properly fix the vulnerability

This repository includes:

* A vulnerable program (`sistema2.cpp`)
* A local proof-of-concept exploit (`exploit.py`)
* Instructions to reproduce and understand the issue

---

## ⚠️ Disclaimer

This project is for **educational purposes only**.

Do not use these techniques against systems you do not own or have explicit permission to test.

---

## 🧠 The Vulnerability

The issue is located in the admin console function:

```cpp
char buffer[64];
char comando[200];

cin.getline(comando, 200);
strcpy(buffer, comando);
```

### Why this is dangerous

* `buffer` can hold **64 bytes**
* `comando` can contain up to **199 bytes**
* `strcpy()` performs **no bounds checking**

This allows an attacker to:

* Overflow the stack
* Overwrite saved registers
* Control the return address (RIP)
* Redirect execution flow

---

## 🔥 Build Instructions (Vulnerable)

Compile the program with protections disabled:

```bash
g++ -fno-stack-protector -z execstack -no-pie -fcf-protection=none -g sistema2.cpp -o sistema2
```

### What these flags do

* Disable stack canaries
* Make the stack executable
* Disable position-independent execution
* Remove control-flow protections

This creates a controlled environment where the overflow is observable.

---

## ⚙️ Running the Program

```bash
./sistema2
```

Navigate to:

```
5 - Console Admin (VULNERABLE)
```

This is the entry point used by the exploit.

---

## 💣 Exploit Overview

The provided exploit demonstrates a classic attack chain:

1. Overflow the stack buffer
2. Overwrite the return address
3. Redirect execution to controlled memory
4. Execute injected shellcode

### Payload Structure

```
[NOP sled][Shellcode][Padding][Overwritten RIP]
```

* **NOP sled**: increases reliability of landing
* **Shellcode**: payload to execute
* **Padding**: aligns overwrite
* **RIP overwrite**: redirects execution

---

## 🧭 Understanding the Target Address

The exploit requires a valid return address that points into the injected payload.

This address is obtained through **local debugging**.

### Using GDB

Run the program with:

```bash
gdb ./sistema2
```

Set a breakpoint inside the vulnerable function:

```gdb
break processarComando
run
```

After triggering the vulnerable input, inspect the stack:

```gdb
info frame
x/40x $rsp
```

You are looking for:

* The location of the buffer
* Where your input lands in memory

---

### Finding the Correct Offset

To determine how many bytes are needed to reach the return address, you can:

* Use a cyclic pattern (e.g. pwntools)
* Trigger a crash
* Inspect the overwritten RIP in GDB

This gives you the exact offset used in the payload.

---

### Why Only 6 Bytes of RIP?

The exploit uses:

```python
rip_6bytes = p64(address)[:6]
```

Because:

* `strcpy()` stops at null bytes (`\x00`)
* Full 8-byte addresses often contain nulls
* Partial overwrite avoids premature termination

---

## 🛡️ Why This Fails on Hardened Binaries

If compiled with modern protections:

```bash
g++ -O2 -fstack-protector-strong -D_FORTIFY_SOURCE=2 -fPIE -pie -Wl,-z,relro,-z,now
```

The exploit will fail due to:

* Stack canary detection
* Non-executable stack (NX)
* Address randomization (ASLR + PIE)
* Control-flow protections

---

## ✅ Secure Fix

Replace unsafe code:

```cpp
strcpy(buffer, comando);
```

With safe alternatives:

```cpp
strncpy(buffer, comando, sizeof(buffer) - 1);
buffer[sizeof(buffer) - 1] = '\0';
```

Or better:

```cpp
std::string comando;
getline(cin, comando);
```

---

## 🎯 Learning Goals

This lab helps you understand:

* Memory corruption fundamentals
* Stack layout and function frames
* Control flow hijacking concepts
* The importance of secure coding practices
* How modern mitigations protect real systems

---

## 🐸 Final Notes

This project is meant to bridge the gap between:

* Theory (buffer overflows)
* Practice (controlled exploitation)
* Defense (secure coding and hardening)

---

Enjoy breaking it… and fixing it.
