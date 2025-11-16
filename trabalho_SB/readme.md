Projeto de Gerenciador de Heap - Software Básico
Autor: Pietro Comin (GRR20241955)

Visão Geral
Este documento descreve as estratégias de implementação do gerenciador de heap customizado "Almoxarife", desenvolvido para a disciplina de Software Básico. O projeto consiste em uma API de baixo nível, escrita inteiramente em Assembly (x86-64, sintaxe Intel), que replica as funcionalidades centrais das funções malloc e free da biblioteca C.

O objetivo é gerenciar dinamicamente o segmento de dados (heap) de um processo, solicitando memória diretamente ao kernel do sistema operacional através da syscall brk. A API está contida no arquivo almoxarife.s, e sua validação é realizada por um programa de teste em C (inspetor.c), que é linkado ao arquivo objeto do gerenciador.

Estratégia de Implementação

Como filosofia de nomenclatura, o gerenciador foi chamado de almoxarife.s, personificando o código como o agente responsável por controlar o "inventário" (o estoque) de blocos de memória. O programa de testes foi nomeado inspetor.c, o agente que "audita" o trabalho do almoxarife.

Estrutura de Dados: A Lista Implícita
Para equilibrar simplicidade de implementação (essencial em Assembly) e funcionalidade, foi adotada a estratégia de Lista Implícita (Implicit List).

Não há uma lista ligada explícita de blocos livres. Em vez disso, a heap é vista como um conjunto contíguo de blocos. Cada bloco, seja livre ou ocupado, é precedido por um cabeçalho de metadados. Para este projeto, foi definido um cabeçalho de 9 bytes, otimizado para simplicidade:

Offset 0 (1 byte): Flag de Status (1 para LIVRE, 0 para OCUPADO).

Offset 1 (8 bytes): Tamanho Total (Armazena o tamanho completo do bloco, incluindo os 9 bytes do cabeçalho).

O gerenciador é inicializado pela função setup_brk, que obtém o endereço base da heap (o "chão") via sbrk(0) e o armazena na variável global brk_inicial.

Alocação: memory_alloc (Worst-Fit)
A função memory_alloc implementa a estratégia de alocação "Worst-Fit" (Pior Encaixe).

Quando uma alocação é solicitada, o algoritmo calcula o tamanho total necessário (tamanho solicitado + 9 bytes do cabeçalho). Em seguida, ele inicia uma varredura completa da heap, começando do brk_inicial até o topo atual (também obtido via sbrk(0)).

Durante a varredura, ele lê o cabeçalho de cada bloco (pulando para o próximo usando o "tamanho" armazenado) e procura pelo bloco livre que seja, simultaneamente, (1) grande o suficiente para a requisição e (2) o maior bloco livre encontrado até o momento.

Se um bloco adequado (o "pior encaixe") é encontrado, o algoritmo tenta dividi-lo (Split). Se o espaço restante for suficiente para um novo bloco mínimo (10 bytes), o bloco é dividido: o novo bloco "resto" é marcado como livre e o bloco original é encolhido. O bloco encontrado é então marcado como ocupado (0) e o ponteiro para a área de dados (endereço do cabeçalho + 9) é retornado.

Se nenhum bloco livre for encontrado, o alocador expande a heap. Ele chama a syscall brk para mover o topo da heap, alocando exatamente o espaço necessário. Um novo cabeçalho é escrito nesse espaço (marcado como ocupado) e o ponteiro é retornado.

Liberação: memory_free (União para a Frente)
A função memory_free é responsável por liberar um bloco e otimizar a heap.

Primeiro, ela realiza validações de segurança, verificando se o ponteiro não é nulo e se o bloco já não está livre (proteção contra "double free"). O bloco é então marcado como livre (status = 1).

Imediatamente após marcar como livre, o algoritmo implementa a otimização de "União (Coalescing) para a Frente". Ele calcula o endereço do bloco imediatamente posterior (usando o tamanho do bloco atual). Ele verifica se esse bloco posterior está dentro dos limites da heap (comparando com sbrk(0)) e se ele também está marcado como livre.

Se ambos os blocos (o atual e o posterior) estiverem livres, eles são unidos: o tamanho do bloco posterior é somado ao tamanho do bloco atual, e o resultado é escrito no cabeçalho do bloco atual. Isso combate a fragmentação externa, criando "buracos" livres maiores que podem ser reutilizados pelo memory_alloc.