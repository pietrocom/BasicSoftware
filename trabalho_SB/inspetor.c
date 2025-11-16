#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Obtém o endereço de brk
extern void setup_brk();

// Restaura o endereço de brk
extern void dismiss_brk();

/*
1. Procura bloco livre com tamanho igual ou maior que a requisição
2. Se encontrar, marca ocupação, utiliza os bytes necessários do bloco, retornando o endereço correspondente
3. Se não encontrar, abre espaço para um novo bloco
*/
extern void * memory_alloc (unsigned long int bytes);

// Marca um bloco ocupado como livre
extern int memory_free(void *pointer);


// Função auxiliar de ajuda no teste
void check(int condition, const char* test_name) {
    if (condition) {
        printf("[ PASS ] %s\n", test_name);
    } else {
        printf("[ FAIL ] %s\n", test_name);
    }
}

/*
Para testar o código, diversos casos de erro serão considerados:
1. malloc normal com atribuição de valor nele
2. mais um malloc e verificação se afetou o resultado anterior
3. mais um malloc normal
4. free do segundo malloc e verificar se afetou algum outro
5. testar double free do segundo malloc
6. dar um malloc menor que o segundo para ver se encaixa no meio e se há segmentação
7. dar um malloc que não cabe em nenhuma das duas posições, mas sim se o espaço das
duas fosse somado para ver se aloca no fim
8. dar free no último bloco para ver se o Coalescing funciona ao mallocar uma última vez.
*/

int main () {
    char *p1, *p2, *p3, *p4, *p5, *p6;
    int ret;
    long size_p2 = 50; // Tamanho do segundo bloco

    printf("--- Iniciando Testes do Almoxarife ---\n");

    setup_brk();

    printf("\n--- Teste 1: Malloc normal com atribuicao de valor\n");
    p1 = (char*)memory_alloc(30);
    check(p1 != NULL, "p1 foi alocado (nao eh NULL)");
    if (p1) {
        memset(p1, 0xAA, 30); // Preenche 30 bytes de p1 com 0xAA
        check(p1[0] == (char)0xAA && p1[29] == (char)0xAA, "p1 foi escrito com sucesso");
    }

    printf("\n--- Teste 2: Mais um malloc e verificacao\n");
    p2 = (char*)memory_alloc(size_p2);
    check(p2 != NULL, "p2 foi alocado (nao eh NULL)");
    if (p2) {
        memset(p2, 0xBB, size_p2);
        check(p2[0] == (char)0xBB, "p2 foi escrito com sucesso");
    }
    check(p1[0] == (char)0xAA, "p1 nao foi corrompido pela alocacao de p2");

    printf("\n--- Teste 3: Mais um malloc normal\n");
    p3 = (char*)memory_alloc(40);
    check(p3 != NULL, "p3 foi alocado (nao eh NULL)");
    if (p3) {
        memset(p3, 0xCC, 40);
    }
    // Estado da Heap: [ p1(30,O) ] [ p2(50,O) ] [ p3(40,O) ]

    printf("\n--- Teste 4: Free do segundo malloc (p2)\n");
    ret = memory_free(p2);
    check(ret == 0, "memory_free(p2) retornou 0 (sucesso)");
    check(p1[0] == (char)0xAA, "p1 nao foi corrompido apos free(p2)");
    check(p3[0] == (char)0xCC, "p3 nao foi corrompido apos free(p2)");
    // Estado da Heap: [ p1(30,O) ] [ p2(50,L) ] [ p3(40,O) ]

    printf("\n--- Teste 5: Double free do segundo malloc (p2)\n");
    ret = memory_free(p2);
    check(ret == -1, "memory_free(p2) pela segunda vez retornou -1 (erro)");

    printf("\n--- Teste 6: Malloc para reutilizar p2 (Worst-Fit e Split)\n");
    // Há um único buraco de 50 bytes (p2).
    // O worst-fit vai encontrar esse buraco.
    // Vamos alocar 20 bytes. O bloco de 50 deve ser dividido.
    p4 = (char*)memory_alloc(20);
    check(p4 != NULL, "p4 foi alocado");
    check(p4 == p2, "p4 reutilizou o ponteiro de p2 (aponta para o mesmo endereco)");
    // O bloco de 50 (total 59) foi dividido em:
    // Bloco p4 (20 dados, 9 header = 29)
    // Bloco resto (59 - 29 = 30) (total 30, dados 21)
    // Estado da Heap: [ p1(30,O) ] [ p4(20,O) ] [ resto(21,L) ] [ p3(40,O) ]

    printf("\n--- Teste 7: Teste de Fragmentacao\n");
    memory_free(p1); // Libera p1 (30 bytes)
    // Estado: [ p1(30,L) ] [ p4(20,O) ] [ resto(21,L) ] [ p3(40,O) ]
    // free(p1) olhou para frente e viu p4(Ocupado), então não uniu.
    // Agora há dois blocos livres: p1(30) e resto(21)
    
    // Tentar alocar 40 bytes.
    // Worst-Fit: p1 (30) não serve. resto (21) não serve.
    // Deve alocar no FIM da heap, mesmo que tenhamos 30+21 = 51 bytes livres.
    p5 = (char*)memory_alloc(40);
    check(p5 != NULL, "p5 foi alocado");
    check(p5 > p3, "p5 foi alocado no FIM da heap (fragmentacao ocorreu)");
    // Estado: [ p1(30,L) ] [ p4(20,O) ] [ resto(21,L) ] [ p3(40,O) ] [ p5(40,O) ]

    printf("\n--- Teste 8: Teste de Uniao (Coalescing) com sucesso\n");
    // Vamos liberar p3 e p5.
    memory_free(p3); // p3(40,L). Olha para p5 (Ocupado). Não une.
    memory_free(p5); // p5(40,L). Olha para o fim da heap. Não une.
    // Estado: [ p1(L,30) ] [ p4(O,20) ] [ resto(L,21) ] [ p3(L,40) ] [ p5(L,40) ]
    
    // Liberando p4.
    memory_free(p4);
    // Deve ocorrer uniao: O bloco p4 (total 29) é unido ao 'resto' (total 30).
    // O novo "super-bloco" p4 agora tem um tamanho total de 59 bytes
    // (ou seja, 50 bytes de dados).
    // Estado: [ p1(L,30) ] [ p4_unido(L,50) ] [ p3(L,40) ] [ p5(L,40) ]
    
    // Vamos alocar 40. Worst-Fit deve escolher p4 (o maior, com 50)
    p6 = (char*)memory_alloc(40);
    check(p6 != NULL, "p6 foi alocado");
    check(p6 == p4, "p6 foi alocado no bloco p4 unido (Worst-Fit + Coalescing funcionou!)");

    dismiss_brk();
    printf("\n--- Testes Concluidos ---\n");
    return 0;
}