;
; clear && nasm -f elf64 -o read.o ./read.asm  &&  ld -o read -s -n -z max-page-size=0x1000 read.o && /usr/bin/time -v ./read
;
%macro parse_string_to_int 0
    xor rax, rax        ; result
    xor rcx, rcx        ; index
    xor r10, r10        ; negative flag: 0 = positive, 1 = negative
    mov r8, -1          ; dotPos, -1 means no dot found
    cmp byte [rsi], '-'
    jne %%loop
    mov r10, 1
    inc rcx             ; skip '-'
%%loop:
    cmp rcx, rbx
    jae %%done
    movzx r11, byte [rsi + rcx]
    cmp r11b, '.'
    je %%dot
    sub r11, '0'
    cmp r11, 9
    ja %%done           ; non-digit, stop
    imul rax, rax, 10
    add rax, r11
    inc rcx
    jmp %%loop
%%dot:
    mov r8, rcx         ; store real dot position, zero-based
    inc rcx             ; skip '.'
    jmp %%loop
%%done:
    ; Need multiply by 10 for:
    ; positive "12.3"  -> dotPos = 2
    ; negative "-12.3" -> dotPos = 3
    ;
    ; expectedDotPos = 2 + negativeFlag
    lea r11, [r10 + 2]
    cmp r8, r11
    jne %%apply_sign
    imul rax, rax, 10
%%apply_sign:
    test r10, r10
    jz %%finish
    neg rax
%%finish:
%endmacro

section .data
    file db "../out.csv", 0
    initial_min dq 0 
    initial_max dq 0
    records_count dq 0 

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

    start_cycle resq 1
    stop_cycle  resq 1
       

section .text
    global _start

_start:
    mov rax, [initial_min]
    mov [min], rax
    mov rax, [initial_max]
    mov [max], rax

    cpuid
    rdtsc
    shl rdx, 32
    or  rax, rdx
    mov [start_cycle], rax

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

    parse_string_to_int
    inc qword[records_count]
    
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
    
    rdtscp
    shl rdx, 32
    or  rax, rdx
    mov [stop_cycle], rax

    mov rax, [stop_cycle]
    sub rax, [start_cycle]
    xor rdx, rdx
    div qword[records_count]


; --- CONVERT RAX TO STRING ---
    mov rcx, buffer + 19  ; Point to the end of the buffer
    mov rbx, 10           ; Divisor

.convert_loop:
    xor rdx, rdx          ; Clear RDX for division
    div rbx               ; RAX / 10. Remainder in RDX, Quotient in RAX
    add dl, '0'           ; Convert remainder to ASCII ('0'-'9')
    dec rcx               ; Move buffer pointer back
    mov [rcx], dl         ; Store character
    test rax, rax         ; Is quotient 0?
    jnz .convert_loop     ; If not, keep dividing

    ; --- PRINT THE RESULT ---
    ; Calculate length: (buffer + 19) - current rcx
    mov rdx, buffer + 19
    sub rdx, rcx          ; RDX = length of string
    
    mov rsi, rcx          ; RSI = pointer to start of string
    mov rdi, 1            ; stdout
    mov rax, 1            ; sys_write
    mov byte [rsi + rdx], 10
    inc rdx
    syscall

  

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