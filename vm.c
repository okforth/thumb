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


uint8_t mem[SIZE];
uint32_t *dstack = ((uint32_t*) (mem + POS_DSTACK)) - 1;
uint32_t *rstack = ((uint32_t*) (mem + POS_RSTACK)) - 1;

uint32_t pc = 0;
uint32_t word;
uint8_t slot;
uint8_t op;
uint32_t addr;

void status() {
	printf("pc: %8X\tI: %8X\top: %8X\tT: %8X\tR: %8X\n",
		 pc, word, op, *dstack, *rstack);
}

uint32_t fetch(uint32_t x) {
	return *((uint32_t*) (mem + x));
}

void dpush(uint32_t x) {
	*++dstack = x;
}

uint32_t dpop() {
	return *dstack--;
}

void rpush(uint32_t x) {
	*++rstack = x;
}

uint32_t rpop() {
	return *rstack--;
}


int execute() {
	uint32_t x;
	switch (op) {
		case 0x00: // nop
			break;

		case 0x01: // jump
			pc = fetch(pc);
			slot = 4;
			break;

		case 0x02: // call
			rpush(pc + 4);
			pc = fetch(pc);
			slot = 4;
			break;

		case 0x03: // exit
			pc = rpop();
			slot = 4;
			break;

		case 0x04: // if
			x = dpop();
			if (x != 0) {
				pc += 4;
			} else {
				pc = fetch(pc);
				slot = 4;
			}
			break;
			
		case 0x05: // -if
			x = dpop();
			if ((int32_t) x < 0) {
				pc += 4;
			} else {
				pc = fetch(pc);
				slot = 4;
			}
			break;

		case 0x06: // next
			if (--*rstack != 0) {
				pc = fetch(pc);
				slot = 4;
			} else {
				rpop();
				pc += 4;
			}
			break;

		case 0x07: // lit
			dpush(fetch(pc));
			pc += 4;
			break;

		case 0x08: // @
			dpush(fetch(addr));
			break;

		case 0x09: // !
			*((uint32_t*) (mem + addr)) = dpop();
			break;

		case 0x0a: // c@
			dpush(*(mem + addr));
			break;

		case 0x0b: // c!
			*(mem + addr) = (uint8_t) dpop();
			break;

		case 0x0c: // a+
			addr++;
			break;

		case 0x0d: // 2*
			*dstack <<= 1;
			break;

		case 0x0e: // 2/
			*dstack >>= 1;
			break;

		case 0x0f: // not
			*dstack = ~*dstack;
			break;

		case 0x10: // and
			x = dpop();
			*dstack &= x;
			break;

		case 0x11: // xor
			x = dpop();
			*dstack ^= x;
			break;

		case 0x12: // or
			x = dpop();
			*dstack |= x;
			break;

		case 0x13: // +
			x = dpop();
			*dstack += x;
			break;

		case 0x14: // -
			x = dpop();
			*dstack -= x;
			break;

		case 0x15: { // *
			int64_t a = (int64_t) *(dstack - 1);
			int64_t b = (int64_t) *dstack;
			uint64_t product = (uint64_t) (a * b);
			*(dstack - 1) = (uint32_t) product;
			*dstack = (uint32_t) (product >> 32);
			break;
		}

		case 0x16: { // /
			int32_t dividend = (int32_t) *(dstack - 1);
			int32_t divisor = (int32_t) *dstack;
			int32_t quotient = dividend / divisor;
			int32_t remainder = dividend % divisor;
			*(dstack - 1) = (uint32_t) remainder;
			*dstack = (uint32_t) quotient;
			break;
		}

		case 0x17: // drop
			dstack--;
			break;

		case 0x18: // dup
			x = *dstack++;
			*dstack = x;
			break;

		case 0x19: // over
			x = *(dstack++ - 1);
			*dstack = x;
			break;

		case 0x1a: // swap
			x = *dstack;
			*dstack = *(dstack - 1);
			*(dstack - 1) = x;
			break;

		case 0x1b: // pop
			dpush(rpop());
			break;

		case 0x1c: // push
			rpush(dpop());
			break;

		case 0x1d: // a
			dpush(addr);
			break;

		case 0x1e: // a!
			addr = dpop();
			break;

		case 0x1f: // sys
			switch(dpop()) {
				case 0:
					putchar(dpop());
					break;
				case 1:
					dpush(getchar());
					break;
				case -1:
					printf("Exit success!\n");
					return 1;
				default:
					printf("Invalid system call.\n");
					return 1;
			}
			break;

		default:
			printf("Invalid opcode.\n");
			return 1;
	}
	return 0;
}

void interpret() {
	while (1) {
		word = fetch(pc);
		pc += 4;
		slot = 0;
		while (slot < 4) {
			op = (uint8_t) (word >> (8 * slot++));
			if (execute()) return;
		}
	}
}


const char *filename = "out.bin";

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

int main() {
	read_file();

	interpret();

	write_file();

	return 0;
}
