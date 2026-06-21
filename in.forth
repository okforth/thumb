237 237 sys

def drop	drop exit
def dup		dup exit
def ?dup	dup if dup then exit
def nip		push drop pop exit
def over	over exit


align
," hello, world!"
,' 170 187 204'
if

170 187 204

then

1 -if 170 then

sys

nop jump call exit next lit @ ! c@ c! a+ 2* 2/ not and xor or + - * / drop dup   over swap pop push a a!  sys
