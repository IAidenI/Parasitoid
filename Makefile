CC              = gcc
CFLAGS          = -Wall -g

LEGIT_SRC       = legit-process.c
PAYLOAD_SRC     = payload.c
PARASITOID_ASM_SRC = parasitoid.s

PARASITOID_OBJ       = $(PARASITOID_ASM_SRC:.s=.o)
PAYLOAD_OBJ     = $(PAYLOAD_SRC:.c=.o)

LEGIT_BIN       = $(LEGIT_SRC:.c=)
PARASITOID_BIN       = $(PARASITOID_ASM_SRC:.s=)

all: parasitoid legit payload

parasitoid:
	nasm -f elf64 $(PARASITOID_ASM_SRC) -o $(PARASITOID_OBJ)
	$(CC) $(CFLAGS) $(PARASITOID_OBJ) -o $(PARASITOID_BIN)

legit:
	$(CC) $(CFLAGS) $(LEGIT_SRC) -o $(LEGIT_BIN)

payload:
	$(CC) $(CFLAGS) -c $(PAYLOAD_SRC) -o $(PAYLOAD_OBJ)

clean:
	rm -f $(LEGIT_BIN) $(PARASITOID_BIN) $(PARASITOID_OBJ) $(PAYLOAD_OBJ)
