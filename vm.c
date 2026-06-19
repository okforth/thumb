#include <stdio.h>

const char mem[] = {1, 2, 3};

int main() {

	printf("Hello, Forth!\n");

	printf("%d\n", mem[0]);
	printf("%d\n", mem[1]);
	printf("%d\n", mem[2]);

	return 0;
}
