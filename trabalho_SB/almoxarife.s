; Torna as funcoes visiveis para outros arquivos
.global memory_alloc
.global memory_free
.global setup_brk
.global dismiss_brk


.bss




.text

memory_alloc:

memory_free:

setup_brk:
    push rbp
    mov rbp, rsp
    mov rax, 12
    mov rdi, 0
    syscall
    pop rbp
    ret

dismiss_brk:
