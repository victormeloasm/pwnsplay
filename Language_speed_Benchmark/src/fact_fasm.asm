format ELF64

public main
extrn strtoull
extrn bench_fasm

section '.text' executable
main:
    push rbp
    mov rbp, rsp
    push rbx
    push r12

    mov rbx, rdi        ; argc
    mov r12, rsi        ; argv
    mov rdi, 99999      ; default n

    cmp rbx, 1
    jle .run
    mov rdi, [r12+8]
    xor esi, esi
    mov edx, 10
    call strtoull
    mov rdi, rax

.run:
    call bench_fasm

    pop r12
    pop rbx
    pop rbp
    ret
