format ELF64
public main

extrn printf
extrn scanf

section '.code' writable
main:
; 1) vector input
        mov rdi, strVecSize
        xor rax, rax
        call printf

        push rbp
        lea rdi, [strScanInt] ;loading format
        lea rsi, [vec_size]
        xor rax, rax
        call scanf
        pop rbp  ;restores stack

        mov rax, [vec_size]
        cmp rax, 0
        jg  getVector
        ; fail size
        mov rdi, strIncorSize
        mov rsi, vec_size
        xor rax, rax
        call printf
        jmp finish
; continue...
getVector:
        xor rcx, rcx            ; rcx = 0
        mov rbx, vec            ; rbx = &vec
getVecLoop:
        mov [tmp], rbx
        cmp rcx, [vec_size]
        jge endInputVector       ; to end of loop

        ; input element
        mov [i], rcx
        mov rdi, strVecElemI
        mov rsi, rcx
        xor rax, rax
        call printf

        push rbp
        lea rdi, [strScanInt] ;loading format
        mov rsi, rbx
        xor rax, rax
        call scanf
        pop rbp  ;restores stack

        mov rcx, [i]
        inc rcx
        mov rbx, [tmp]
        add rbx, 8
        jmp getVecLoop
endInputVector:

; 2) get vector sum
sumVector:
        xor rcx, rcx            ; rcx = 0
        mov rbx, vec            ; rbx = &vec
sumVecLoop:
        ;mov [tmp], rbx
        cmp rcx, [vec_size]
        je endSumVector      ; to end of loop
        mov rax, [sum]
        add rax, [rbx]
        mov [sum], rax
        ;mov [i], rcx

        ;mov rcx, [i]
        inc rcx
        ;mov rbx, [tmp]
        add rbx, 8
        jmp sumVecLoop
endSumVector:

; 3) out of sum
        mov rdi, strSumValue
        mov rsi, [sum]
        xor rax, rax
        call printf

; 4) test vector out
putVector:
        xor rcx, rcx            ; rcx = 0
        mov rbx, vec            ; rbx = &vec
putVecLoop:
        mov [tmp], rbx
        cmp rcx, [vec_size]
        je endOutputVector      ; to end of loop
        mov [i], rcx

        ; output element
        mov rdi, strVecElemOut
        mov rsi, rcx
        mov rdx, [rbx] 
        xor rax, rax
        call printf

        mov rcx, [i]
        inc rcx
        mov rbx, [tmp]
        add rbx, 8
        jmp putVecLoop
endOutputVector:

finish:
        xor rax, rax
        ret

section '.data' writable

        strVecSize   db 'size of vector? ', 0
        strIncorSize db 'Incorrect size of vector = %d', 10, 0
        strVecElemI  db '[%d]? ', 0
        strScanInt   db '%d', 0
        strSumValue  db 'Summa = %d', 10, 0
        strVecElemOut  db '[%d] = %d', 10, 0

        vec_size     dq 0
        sum          dq 0
        i            dq ?
        tmp          dq ?
        tmpStack     dq ?
        vec          rq 100
