CC = gcc

TARGET = inspetor

CFLAGS = -Wall

LDFLAGS = -no-pie

OBJS = inspetor.o almoxarife.o

ZIP_DIR = pietro

ZIP_NAME = pietro.zip

ZIP_FILES = inspetor.c almoxarife.s makefile readme.md

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
	rm -f $(TARGET) $(OBJS) $(ZIP_NAME)

zip: clean
	mkdir $(ZIP_DIR)
	cp $(ZIP_FILES) $(ZIP_DIR)/
	zip -r $(ZIP_NAME) $(ZIP_DIR)
	rm -rf $(ZIP_DIR)

.PHONY: all clean zip