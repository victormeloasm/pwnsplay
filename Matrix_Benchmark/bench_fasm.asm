format ELF64

public main
extrn printf
extrn aligned_alloc
extrn free
extrn clock_gettime

section '.data' writeable
fmt_lang db 'language FASM pure',10,0
fmt_time db 'time_ms %.6f',10,0
fmt_chk  db 'checksum %.17g',10,0
one_over_1000 dq 0x3f50624dd2f1a9fc
half dq 0x3fe0000000000000
thousand dq 1000
nval dq 1000
size_bytes dq 8000000
clock_mono dq 1
million dq 1000000.0
thousand_d dq 1000.0

section '.bss' writeable
Aptr rq 1
BTptr rq 1
Cptr rq 1
ts0 rq 2
ts1 rq 2

section '.text' executable

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    mov rdi, 64
    mov rsi, [size_bytes]
    call aligned_alloc
    mov [Aptr], rax

    mov rdi, 64
    mov rsi, [size_bytes]
    call aligned_alloc
    mov [BTptr], rax

    mov rdi, 64
    mov rsi, [size_bytes]
    call aligned_alloc
    mov [Cptr], rax

    ; fill A and BT
    xor r12d, r12d              ; i
.fill_i:
    cmp r12d, 1000
    jge .fill_done
    xor r13d, r13d              ; j
.fill_j:
    cmp r13d, 1000
    jge .fill_next_i

    ; A value = ((i*131+j*17+13)%1000)/1000 - .5
    mov eax, r12d
    imul eax, eax, 131
    mov ebx, r13d
    imul ebx, ebx, 17
    add eax, ebx
    add eax, 13
    xor edx, edx
    mov ecx, 1000
    div ecx
    cvtsi2sd xmm0, edx
    mulsd xmm0, [one_over_1000]
    subsd xmm0, [half]
    mov rax, r12
    imul rax, 1000
    add rax, r13
    shl rax, 3
    mov rbx, [Aptr]
    movsd [rbx + rax], xmm0

    ; BT[j,i] = B(i,j)
    mov eax, r12d
    imul eax, eax, 19
    mov ebx, r13d
    imul ebx, ebx, 137
    add eax, ebx
    add eax, 7
    xor edx, edx
    mov ecx, 1000
    div ecx
    cvtsi2sd xmm0, edx
    mulsd xmm0, [one_over_1000]
    subsd xmm0, [half]
    mov rax, r13
    imul rax, 1000
    add rax, r12
    shl rax, 3
    mov rbx, [BTptr]
    movsd [rbx + rax], xmm0

    inc r13d
    jmp .fill_j
.fill_next_i:
    inc r12d
    jmp .fill_i
.fill_done:

    ; start time
    mov rdi, [clock_mono]
    lea rsi, [ts0]
    call clock_gettime

    ; naive dot with transposed B
    xor r12d, r12d              ; i
.outer_i:
    cmp r12d, 1000
    jge .mul_done
    xor r13d, r13d              ; j
.outer_j:
    cmp r13d, 1000
    jge .next_i
    xorpd xmm0, xmm0
    xor r14d, r14d              ; k
.inner_k:
    cmp r14d, 1000
    jge .store_c

    mov rax, r12
    imul rax, 1000
    add rax, r14
    shl rax, 3
    mov rbx, [Aptr]
    movsd xmm1, [rbx + rax]

    mov rax, r13
    imul rax, 1000
    add rax, r14
    shl rax, 3
    mov rbx, [BTptr]
    mulsd xmm1, [rbx + rax]
    addsd xmm0, xmm1

    inc r14d
    jmp .inner_k

.store_c:
    mov rax, r12
    imul rax, 1000
    add rax, r13
    shl rax, 3
    mov rbx, [Cptr]
    movsd [rbx + rax], xmm0

    inc r13d
    jmp .outer_j
.next_i:
    inc r12d
    jmp .outer_i

.mul_done:
    mov rdi, [clock_mono]
    lea rsi, [ts1]
    call clock_gettime

    ; print language
    lea rdi, [fmt_lang]
    xor eax, eax
    call printf

    ; compute time ms = secdiff*1000 + nsecdiff/1e6
    mov rax, [ts1]
    sub rax, [ts0]
    cvtsi2sd xmm0, rax
    mulsd xmm0, [thousand_d]
    mov rax, [ts1+8]
    sub rax, [ts0+8]
    cvtsi2sd xmm1, rax
    divsd xmm1, [million]
    addsd xmm0, xmm1
    lea rdi, [fmt_time]
    mov eax, 1
    call printf

    ; checksum
    xorpd xmm0, xmm0
    xor r12, r12
.chk_loop:
    cmp r12, 1000000
    jge .chk_done
    mov rbx, [Cptr]
    mov rax, r12
    shl rax, 3
    addsd xmm0, [rbx + rax]
    add r12, 97
    jmp .chk_loop
.chk_done:
    lea rdi, [fmt_chk]
    mov eax, 1
    call printf

    mov rdi, [Aptr]
    call free
    mov rdi, [BTptr]
    call free
    mov rdi, [Cptr]
    call free

    xor eax, eax
    leave
    ret
