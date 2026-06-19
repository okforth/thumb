# 32-bit Forth Operating System

[ 31 30 29 28 27 26 25 24 - 23 22 21 20 19 18 17 16 - 15 14 13 12 11 10 09 08 - 07 06 05 04 03 02 01 00 ]

nop			no operation
	jump		jump thru I
	call		jump thru I, push P to R
;	return		jump thru R (destructive)
ex	execute		jump thru R, save P in R
next			if R is non-zero, jump thru I and decr R
			if R is zero, pop R
if			if T is zero, jump thru I
-if			if T is non-neg, jump thru I
	literal		fetch thru P, incr P
@			fetch thru A
@+			fetch thru A, incr A
!			store thru A
!+			store thru A, incr A
2*			shift T left
2/			shift T right
not			invert T
and			bitwise and of S and T
xor			bitwise exclusive-or of S and T
or			bitwise 
+			add S to T (discard S)
-			sub S by T (discard T)
*			multiply S to T (thus S is lsb and T is msb)
/			divide S by T (thus S is quot and T is rem)
drop			discard T
dup			duplicate T
over			fetch S (non-destructive)
a			fetch A (non-destructive)
pop			fetch R (destructive)
push			push T into R
a!			store into A
