#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>

#define KiB 1024
#define MiB KiB*KiB
#define Page 4*KiB

#define SIZE 64*MiB
#define KERNEL 2*MiB
#define DSTACK Page /* 1024 cells */
#define RSTACK Page /* 1024 cells */
#define BLOCK MiB   /* 1024 blocks */

#define POS_DSTACK KERNEL
#define POS_RSTACK KERNEL+DSTACK
#define POS_BLOCK  KERNEL+DSTACK+RSTACK
#define POS_USER   KERNEL+DSTACK+RSTACK+BLOCK

/*
-- MEMORY LAYOUT --
   kernel/dictionary
   data stack
   return stack
   block storage
   user application space
*/


uint8_t mem[SIZE];
uint32_t *dstack = (uint32_t*) (mem + POS_DSTACK);
uint32_t *rstack = (uint32_t*) (mem + POS_RSTACK);


uint8_t *filename = "out.bin";

void read_file() {
	/* open file */
	FILE *fp = fopen(filename, "rb");

	if (fp == NULL) {
		perror("fopen");
		exit(EXIT_FAILURE);
	}

	/* check file size */
	fseek(fp, 0, SEEK_END); /* set cursor to end of file */
	size_t size = ftell(fp); /* fetch cursor position */
	rewind(fp);

	if (size != SIZE) {
		printf("Wrong input file size.");
		exit(EXIT_FAILURE);
	}

	/* read file into memory buffer */
	size_t read = fread(mem, 1, SIZE, fp);

	if (read != SIZE) {
		perror("fread");
		exit(EXIT_FAILURE);
	}

	fclose(fp);
}

void write_file() {
	/* write memory back to same file */
	FILE *fp = fopen(filename, "wb");

	if (fp == NULL) {
		perror("fopen");
		exit(EXIT_FAILURE);
	}

	size_t write = fwrite(mem, 1, SIZE, fp);

	if (write != SIZE) {
		perror("fwrite");
		exit(EXIT_FAILURE);
	}

	fclose(fp);
}

void interpret() {
}

int main() {
	read_file();

	mem[SIZE-1] = 0xed;

	interpret();

	write_file();

	return 0;
}
