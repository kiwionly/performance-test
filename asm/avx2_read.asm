; clear && nasm -f elf64 -o avx2_read.o ./avx2_read.asm && ld -o avx2_read -s -n -z max-page-size=0x1000 avx2_read.o && /usr/bin/time -v ./avx2_read

section .rodata
    file db "../out.csv", 0
    align 32
    newline_mask: times 32 db 10
    semi_mask:    times 32 db 59

section .bss
    align 32
    BUF_SIZE equ 65536
    buffer   resb BUF_SIZE
    fd       resq 1

    min      resq 1
    max      resq 1

    linebuf  resb 512
    min_city resb 256
    max_city resb 256
    min_len  resq 1
    max_len  resq 1
    
    temp_start_ptr resq 1

section .text
    global _start

_start:
    ; Initialize min to Max Int, max to Min Int
    mov rax, 0x7FFFFFFFFFFFFFFF
    mov [min], rax
    mov rax, 0x8000000000000000
    mov [max], rax

    ; Open file
    mov rax, 2
    lea rdi, [file]
    xor rsi, rsi
    syscall
    mov [fd], rax

    ; Load delimiter masks into AVX registers
    vpbroadcastb ymm1, byte [newline_mask]
    vpbroadcastb ymm2, byte [semi_mask]

    xor r13, r13        ; r13 = index in linebuf
    xor r14, r14        ; r14 = buffer position
    xor r12, r12        ; r12 = bytes read

read_block:
    mov rax, 0
    mov rdi, [fd]
    lea rsi, [buffer]
    mov rdx, BUF_SIZE
    syscall

    test rax, rax
    jg .process_start
    
    ; EOF reached: check if we have an unprocessed final line without a newline
    cmp r13, 0
    je done
    call handle_line
    jmp done

.process_start:
    mov r12, rax
    xor r14, r14

process_main:
    ; Ensure we have 32 bytes left for SIMD
    mov rdx, r12
    sub rdx, r14
    cmp rdx, 32
    jl process_tail

    vmovdqu ymm0, [buffer + r14]
    vpcmpeqb ymm3, ymm0, ymm1   ; Check for \n
    vpcmpeqb ymm4, ymm0, ymm2   ; Check for ;
    vpor ymm5, ymm3, ymm4       
    vpmovmskb eax, ymm5
    
    test eax, eax
    jz .no_delimiter

    ; --- PURE SIMD COPY BLOCK ---
    tzcnt ecx, eax              ; ecx = offset to the FIRST delimiter
    
    ; Copy 32 bytes. We safely overwrite garbage on the next loop
    vmovdqu [linebuf + r13], ymm0
    
    add r14, rcx                ; Move pointer strictly to the delimiter
    add r13, rcx                
    
    mov al, [linebuf + r13]     ; Read the delimiter we landed on
    inc r14                     ; Step over delimiter
    inc r13
    
    cmp al, 59                  ; Was it a semicolon?
    je .is_semi
    
    ; It was a newline
    dec r13                     ; Remove \n from line length
    call handle_line
    xor r13, r13                ; Reset line buffer
    jmp process_main

.is_semi:
    mov [temp_start_ptr], r13   ; Temp starts right after semicolon
    jmp process_main

.no_delimiter:
    vmovdqu [linebuf + r13], ymm0
    add r13, 32
    add r14, 32
    jmp process_main

process_tail:
    ; Process the last < 32 bytes of the buffer safely
    cmp r14, r12
    jge read_block
    mov al, [buffer + r14]
    mov [linebuf + r13], al
    inc r14
    inc r13
    cmp al, 59
    je .t_semi
    cmp al, 10
    je .t_nl
    jmp process_tail
.t_semi:
    mov [temp_start_ptr], r13
    jmp process_tail
.t_nl:
    dec r13
    call handle_line
    xor r13, r13
    jmp process_tail


handle_line:
    push rbx
    push rcx
    push rsi
    push rdi

    mov rsi, [temp_start_ptr]
    lea rsi, [linebuf + rsi]
    
    mov rbx, r13
    sub rbx, [temp_start_ptr]   ; Length of the temperature string

    ; --- Parse Float ---
    xor rax, rax 
    xor rcx, rcx
    xor r10, r10
    
    cmp rbx, 0
    jle .h_done

    movzx r11, byte [rsi]
    cmp r11, '-'
    jne .p_loop
    inc r10
    inc rcx
.p_loop:
    cmp rcx, rbx
    jge .p_done
    movzx r11, byte [rsi + rcx]
    inc rcx
    cmp r11, '.'
    je .p_loop
    sub r11, '0'
    cmp r11, 9                  ; Safely ignores \r or bad chars (unsigned cmp)
    ja .p_done
    imul rax, 10
    add rax, r11
    jmp .p_loop
.p_done:
    test r10, r10
    jz .compare_min
    neg rax

    ; --- FIXED MIN/MAX EVALUATION ---
.compare_min:
    cmp rax, [min]
    jge .compare_max            ; If >= min, check max
    mov [min], rax
    mov [min_len], r13
    lea rsi, [linebuf]
    lea rdi, [min_city]
    mov rcx, r13
    rep movsb
    ; Fall through to check max, because first entry is BOTH min and max

.compare_max:
    cmp rax, [max]
    jle .h_done
    mov [max], rax
    mov [max_len], r13
    lea rsi, [linebuf]          ; Reload registers since rep movsb clobbers them
    lea rdi, [max_city]
    mov rcx, r13
    rep movsb

.h_done:
    pop rdi
    pop rsi
    pop rcx
    pop rbx
    ret


done:
    ; Output MIN
    mov rax, 1
    mov rdi, 1
    lea rsi, [min_city]
    mov rdx, [min_len]
    mov byte [rsi + rdx], 10
    inc rdx
    syscall

    ; Output MAX
    mov rax, 1
    mov rdi, 1
    lea rsi, [max_city]
    mov rdx, [max_len]
    mov byte [rsi + rdx], 10
    inc rdx
    syscall

    ; Close fd and exit
    mov rax, 3
    mov rdi, [fd]
    syscall

    mov rax, 60
    xor rdi, rdi
    syscall