; Torna as funcoes visiveis para outros arquivos
.global memory_alloc
.global memory_free
.global setup_brk
.global dismiss_brk


.bss

brk_atual: .zero 8
brk_inicial: .zero 8


.text

memory_alloc:

memory_free:

setup_brk:
    push rbp
    mov rbp, rsp

    mov rax, 12
    mov rdi, 0
    syscall

    ; Usar a flag: -no-pie para funcionar
    mov [brk_atual], rax
    mov [brk_inicial], rax

    pop rbp
    ret

dismiss_brk:
    push rbp
    mov rbp, rsp

    mov rdi, [brk_inicial]
    mov rax, 12
    syscall

    pop rbp
    ret