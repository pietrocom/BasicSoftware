#include <stdio.h>
#include <stdlib.h>

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


int main () {
    

    return 0;
}