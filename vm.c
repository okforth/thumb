#include <stdint.h>
#include <stdio.h>

uint8_t mem[] = {1, 2, 3, 2, 1, 0, 0, 0, 0};

int main() {

	printf("Hello, Forth!\n");

	uint32_t* pc = (uint32_t*) mem;
	uint8_t slot;

	while (1) {
		uint32_t i = *pc;
		pc = pc + 1;
		slot = 0;
		while (slot != 4) {
			uint8_t op = (uint8_t) i;
			i = i >> 8;
			slot = slot + 1;
			switch (op) {
				case 1:
					printf("1\n");
					break;
				case 2:
					printf("2\n");
					break;
				case 3:
					printf("3\n");
					break;
				default:
					printf("Invalid opcode.\n");
					return 0;
			}
		}
	}

	return 0;
}
