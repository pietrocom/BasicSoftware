.intel_syntax noprefix

# Torna as funcoes visiveis para outros arquivos
.global memory_alloc
.global memory_free
.global setup_brk
.global dismiss_brk


# Defines utilizados
.equ CABECALHO_TAM, 9       # Tamanho total do cabeçalho
.equ OFFSET_ESTALIVRE, 0    # Offset do flag 'livre' (1 byte)
.equ OFFSET_TAMANHO, 1      # Offset do tamanho (8 bytes)
.equ SPLIT_MIN_TAM, 10      # Tamanho minimo para dividir


.bss

brk_inicial: .zero 8


.text

# Retorna o brk atual em RAX, sem salvar nada
get_current_brk:
    mov rax, 12
    xor rdi, rdi
    syscall
    ret

setup_brk:
    push rbp
    mov rbp, rsp

    call get_current_brk      # rax = brk atual

    # Usar a flag: -no-pie para funcionar
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


# RDI = tamanho_solicitado
memory_alloc:
    push rbp
    mov rbp, rsp

    # Registradores e suas funcoes
    push rbx                    # rbx (fim_heap)
    push r12                    # r12 (tamanho_total_necessario)
    push r13                    # r13 (bloco_worst_fit)
    push r14                    # r14 (tamanho_worst_fit)
    push r15                    # r15 (bloco_atual)

    mov r12, rdi                # r12 = tamanho_solicitado
    add r12, CABECALHO_TAM      # r12 = tamanho_total_necessario

    xor r13, r13
    xor r14, r14

    # brk_inicial deve ter sido inicializado
    mov r15, [brk_inicial]

    mov rax, 12                 # sys_brk
    xor rdi, rdi                # 0
    syscall                     # rax = fim_heap
    mov rbx, rax                # rbx (fim_heap) = rax

loop_busca:
    cmp r15, rbx
    jge fim_loop_busca          # se o bloco atual for >= fim_heap sai do loop_busca

    # Pega o cabecalho
    movzx eax, BYTE PTR [r15 + OFFSET_ESTALIVRE] # eax = esta_livre (1 byte)
    mov rcx, [r15 + OFFSET_TAMANHO]          # rcx = tamanho_bloco_atual (8 bytes) 

    cmp eax, 1
    jne proximo_bloco           # se nao estiver livre, pula para o proximo

    cmp rcx, r12
    jl proximo_bloco            # se for menor que o necessario, pula tambem

    cmp rcx, r14
    jle proximo_bloco           # se nao eh maior que o pior atual, pula tambem

    # Novo bloco worst-fit
    mov r13, r15                # bloco_worst_fit = bloco_atual
    mov r14, rcx                # tamanho_worst_fit = tamanho_bloco_atual

proximo_bloco:
    add r15, rcx                # bloco_atual += tamanho_bloco_atual
    jmp loop_busca

fim_loop_busca:
    cmp r13, 0                  # verifica se encontrou
    je caso_nao_encontrou

    # Caso tenha encontrado
    mov rax, r14                # rax = tamanho_worst_fit
    sub rax, r12                # rax = tamanho_restante

    # Verifica se da para fazer um split
    cmp rax, SPLIT_MIN_TAM
    jl nao_dividir

    # Caso for para dividir, acha novo bloco
    mov rdi, r13                # rdi = bloco_worst_fit
    add rdi, r12                # rdi = novo_bloco_livre_dividido

    # Configura o header
    mov BYTE PTR [rdi + OFFSET_ESTALIVRE], 1 # esta_livre = 1
    mov [rdi + OFFSET_TAMANHO], rax      # tamanho = tamanho_restante

    # Encolhe o bloco original
    mov [r13 + OFFSET_TAMANHO], r12

nao_dividir:
    # Marca como ocupado
    mov BYTE PTR [r13 + OFFSET_ESTALIVRE], 0    

    # Configura o retorno
    mov rax, r13
    add rax, CABECALHO_TAM
    jmp fim_alloc

caso_nao_encontrou:
    mov rdi, rbx        # rdi = brk_atual
    add rdi, r12        # rdi += tamanho_total_necessario

    mov rax, 12         # novo teto
    syscall

    cmp rax, rdi        # confere se o brk bate
    jne falha_alloc

    # Configura header
    mov BYTE PTR [rbx + OFFSET_ESTALIVRE], 0    # esta_livre = 0 
    mov [rbx + OFFSET_TAMANHO], r12             # tamanho = tamanho_total_necessario

    # Configura o pnt para dados
    mov rax, rbx                # rax = pnt_bloco          
    add rax, CABECALHO_TAM
    jmp fim_alloc

falha_alloc:
    xor rax, rax        # retorna NULL

fim_alloc:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx

    pop rbp
    ret


memory_free:
    push rbp
    mov rbp, rsp

    push rbx                    # rbx = bloco_posterior
    push r12                    # r12 = tamanho_bloco_atual
    push r13                    # r13 = fim_heap

    cmp rdi, 0
    je erro_free                # verifica NULL

    sub rdi, CABECALHO_TAM      # aritmetica para bloco_atual

    movzx eax, BYTE PTR [rdi + OFFSET_ESTALIVRE]    # eax = flag_bloco_atual
    mov r12, [rdi + OFFSET_TAMANHO]             # r12 = tamanho_bloco_atual

    cmp eax, 1                  # verifica double free
    je erro_free

    mov BYTE PTR [rdi + OFFSET_ESTALIVRE], 1        # marca como livre

    mov rbx, rdi                # rbx = bloco_atual
    add rbx, r12                # rbx = bloco_posterior

    # Seguranca para nao ler lixo depois da heap
    push rdi
    push r12
    call get_current_brk        # rax = fim_heap
    mov r13, rax                
    pop r12
    pop rdi

    cmp rbx, r13
    jge sucesso_free            # se for >=, esta fora da heap

    movzx eax, BYTE PTR [rbx + OFFSET_ESTALIVRE]    # ocupado/desocupado do prox bloco

    cmp eax, 0
    je sucesso_free             # se estiver ocupado

    mov rax, [rbx + OFFSET_TAMANHO]     # le tamanho do bloco posterior

    add r12, rax                        # r12 = tamanho_atual + tamanho_posterior
    mov [rdi + OFFSET_TAMANHO], r12     # escreve o novo tamanho

sucesso_free:
    xor rax, rax    # retorna 0 (sucesso)
    jmp fim_free    

erro_free:
    mov rax, -1     # retorna -1        

fim_free:
    # Restaurar registradores
    pop r13
    pop r12
    pop rbx

    pop rbp
    ret
