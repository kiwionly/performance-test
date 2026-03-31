;
; clear && nasm -f elf64 -o read.o ./read.asm  &&  ld -o read -s -n -z max-page-size=0x1000 read.o && /usr/bin/time -v ./read
;
%macro parse_float_to_int 0
    xor rax, rax 
    xor rcx, rcx
    xor r10, r10
    movzx r11, byte [rsi]
    cmp r11, '-'
    jne .loop
    mov r10, 1
    inc rcx           ; Move past '-'
.loop:
    cmp rcx, rbx
    je .done
    movzx r11, byte [rsi + rcx]
    inc rcx
    cmp r11, '.'
    je .loop          ; Just skip the dot
    sub r11, '0'
    cmp r11, 9        ; Safety check: is it a digit?
    ja .done
    imul rax, 10      ; More readable than lea/shl for debugging
    add rax, r11
    jmp .loop
.done:
    test r10, r10
    jz .finish
    neg rax
.finish:
%endmacro

section .data
    file db "../out.csv", 0
    initial_min dq 0 
    initial_max dq 0

section .bss
    BUF_SIZE equ 65536
    buffer   resb BUF_SIZE
    fd       resq 1

    min      resq 1
    max      resq 1

    linebuf  resb 256
    min_city resb 256
    max_city resb 256
    min_len  resq 1
    max_len  resq 1
    
    temp_start_ptr resq 1 ; Stores index where temperature begins

section .text
    global _start

_start:
    mov rax, [initial_min]
    mov [min], rax
    mov rax, [initial_max]
    mov [max], rax

    ; Open file
    mov rax, 2
    lea rdi, [file]
    xor rsi, rsi        ; O_RDONLY
    syscall
    mov [fd], rax

    xor r13, r13        ; r13 = index in linebuf
    xor r15, r15        ; r15 = flag (0 for city, 1 for temp)

read_block:
    mov rax, 0          ; sys_read
    mov rdi, [fd]
    lea rsi, [buffer]
    mov rdx, BUF_SIZE
    syscall

    test rax, rax
    jle done 
    
    mov r12, rax        ; r12 = bytes read
    xor r14, r14        ; r14 = buffer position

process_chars:
    mov al, [buffer + r14]
    
    cmp al, 10          ; Newline?
    je handle_newline

    mov [linebuf + r13], al

    cmp al, 59          ; Semicolon?
    je handle_semi

    inc r13
    jmp next_char

handle_semi:
    inc r13
    mov [temp_start_ptr], r13 ; Mark where temperature starts
    jmp next_char

handle_newline:

    mov rsi, [temp_start_ptr]
    lea rsi, [linebuf + rsi] 

    mov rbx, r13
    sub rbx, [temp_start_ptr]

    parse_float_to_int
    
    ; Compare and Update
    cmp rax, [min]
    jl update_min
    cmp rax, [max]
    jg update_max

reset_line:
    xor r13, r13
    jmp next_char

update_min:
    mov [min], rax
    mov [min_len], r13
    lea rsi, [linebuf]
    lea rdi, [min_city]
    mov rcx, r13
    rep movsb
    jmp reset_line

update_max:
    mov [max], rax
    mov [max_len], r13
    lea rsi, [linebuf]
    lea rdi, [max_city]
    mov rcx, r13
    rep movsb
    jmp reset_line

next_char:
    inc r14
    cmp r14, r12
    jl process_chars
    jmp read_block



done:
    ; --- Print MIN City ---
    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    lea rsi, [min_city]
    mov rdx, [min_len]
    mov byte [rsi + rdx], 10
    inc rdx
    syscall

    ; --- Print MAX City ---
    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    lea rsi, [max_city]
    mov rdx, [max_len]
    mov byte [rsi + rdx], 10
    inc rdx
    syscall


exit:

    mov rax, 3          ; sys_close
    mov rdi, [fd]
    syscall

    mov rax, 60         ; sys_exit
    xor rdi, rdi
    syscall