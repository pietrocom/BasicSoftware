CC = gcc

TARGET = inspetor

CFLAGS = -Wall

LDFLAGS = -no-pie

OBJS = inspetor.o almoxarife.o

all: $(TARGET)

# $@ é uma variável automática que significa "o nome do alvo" (neste caso, "inspetor")
# $^ é uma variável automática que significa "todas as dependências" (neste caso, "inspetor.o almoxarife.o")
$(TARGET): $(OBJS)
	$(CC) $(LDFLAGS) -o $@ $^

# $< é uma variável automática que significa "o primeiro pré-requisito" ("inspetor.c")
inspetor.o: inspetor.c
	$(CC) $(CFLAGS) -c -o $@ $<

# Regra de Montagem (Assembly): Como construir almoxarife.o a partir de almoxarife.s
almoxarife.o: almoxarife.s
	$(CC) -masm=intel -c -o $@ $<

clean:
	rm -f $(TARGET) $(OBJS)
	@echo "Arquivos gerados removidos."

.PHONY: all clean