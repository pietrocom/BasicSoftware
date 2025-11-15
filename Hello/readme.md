Pietro Comin - GRR20241955

Para resolver este desafio, iniciei minha análise tentando entender o código de forma geral, mas logo passei a utilizar o GDB para 
uma investigação mais a fundo. De cara, minha primeira hipótese foi a de um ataque de Buffer Overflow. Usando objdump, percebi que os 
endereços de memória usados na verificação, 0x402073 e 0x402094, eram muito próximos, o que me fez pensar que, ao entrar com uma 
senha grande o bastante, eu poderia sobrescrever a área de verificação.

No entanto, essa abordagem não funcionou. Analisando as chamadas de sistema com mais calma, notei que a syscall read usava um 
limitador de buffer no registrador rdx, o que na prática impedia o estouro que eu estava tentando causar. Foi um detalhe no qual eu 
não tinha me atentado inicialmente.

Descartada a primeira ideia, parti para uma análise dinâmica, instrução por instrução. O GDB e o 
comando hexdump se mostrou muito útil para visualizar o que estava acontecendo nas regiões de memória. Depois de me familiarizar com 
o fluxo do programa, foquei no laço de comparação principal, onde o segredo deveria estar. Foi ali que o papel dos registradores 
começou a fazer sentido: o r15 claramente funcionava como um contador para o laço, baseado no tamanho da senha que eu digitava; o r14 
era usado como um índice para buscar caracteres do nome de usuário; e o al servia como um "depósito" temporário de 1 byte para cada 
caractere durante a comparação.

Depois de algumas sessões de depuração, a instrução add al, 0x5 revelou o mecanismo. Descobri que a lógica não era estática. O 
programa pegava cada caractere do nome do usuário, somava 5 ao seu valor ASCII, e comparava o resultado com o caractere 
correspondente da senha que eu havia digitado. Portanto, a senha correta é derivada do nome. Para o nome "pietro", a senha correta, 
calculada com a fórmula letra_da_senha = letra_do_nome + 5, é unjywt. 