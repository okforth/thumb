jump

( inline words cannot have a call to another word )

( OPCODES )
( 0x00 ) : nop ( -- ) nop ; inline
( 0x01 ) ( jump )
( 0x02 ) ( call )
( 0x03 ) : exit ( -- ) exit ; inline
( 0x04 ) ( if )
( 0x05 ) ( -if )
( 0x06 ) ( next )
( 0x07 ) ( lit )
( 0x08 ) : @ ( -- n ) @ ; inline
( 0x09 ) : ! ( n -- ) ! ; inline
( 0x0a ) : c@ ( -- c ) c@ ; inline
( 0x0b ) : c! ( c -- ) c! ; inline
( 0x0c ) : a+ ( -- ) a+ ; inline
( 0x0d ) : 2* ( a -- a<<1 ) 2* ; inline
( 0x0e ) : 2/ ( a -- a>>1 ) 2/ ; inline
( 0x0f ) : not ( a -- ~a ) not ; inline
( 0x10 ) : and ( a b -- a&b ) and ; inline
( 0x11 ) : xor ( a b -- a^b ) xor ; inline
( 0x12 ) : or ( a b -- a|b ) or ; inline
( 0x13 ) : + ( a b -- a+b ) + ; inline
( 0x14 ) : - ( a b -- a-b ) - ; inline
( 0x15 ) : m* ( a b -- low high ) m* ; inline
( 0x16 ) : /mod ( a b -- a/b a%b ) /mod ; inline
( 0x17 ) : drop ( a -- ) drop ; inline
( 0x18 ) : dup  ( a -- a a ) dup ; inline
( 0x19 ) : over ( a b -- a b a ) over ; inline
( 0x1a ) : swap ( a b -- b a ) swap ; inline
( 0x1b ) : pop ( -- n ) pop ; inline
( 0x1c ) : push ( n -- ) push ; inline
( 0x1d ) : a ( -- addr ) a ; inline
( 0x1e ) : a! ( addr -- ) a! ; inline
( 0x1f ) : sys ( n -- ) sys ; inline

( DATA STACK )
: nip ( a b -- b ) push drop pop ; inline
: tuck ( a b -- b a b ) swap over ; inline
: rot ( a b c -- b c a ) push swap pop swap ; inline
: nrot ( a b c -- c a b ) swap push swap pop ; inline
: 2drop ( a b -- ) drop drop ; inline
: 2dup ( a b -- a b a b ) over over ; inline

( RETURN STACK )
: peek ( -- n ) pop dup push ; inline
: rdrop ( -- ) pop drop ; inline

( LOGIC )
: =  ( a b -- f ) - -1 swap  if not then ;
: <  ( a b -- f ) -  0 swap -if not then ;
: >  ( a b -- f ) swap - 0 swap -if not then ;
: <= ( a b -- f ) -  1 + 0 swap -if not then ;
: >= ( a b -- f ) swap - 1 - 0 swap -if not then ;
: 0< ( a -- f ) 0 swap -if not then ;
: 0>= ( a -- f ) not 0 swap -if not then ;

( ARITHMETIC / BITS )
: -^ ( a b -- b-a ) swap - ; inline
: * ( a b -- a*b ) m* drop ; inline
: / ( a b -- a/b ) /mod nip ; inline
: mod ( a b -- a%b ) /mod drop ; inline
: 1+ ( a -- a+1 ) 1 + ; inline
: 1- ( a -- a-1 ) 1 - ; inline
: lshift ( a b -- a<<b ) for 2* next ;
: rshift ( a b -- a>>b ) for 2/ next ;
: max ( a b -- hi ) 2dup < if nip else drop then ;
: min ( a b -- lo ) 2dup > if nip else drop then ;
: negate ( n -- -n ) not 1 + ; inline


: key ( char -- ) 1 sys ;
: emit ( char -- ) 0 sys ;
: cr ( -- ) 10 0 sys ;
: space ( -- ) 32 emit ;

: digit ( u -- ) 10 /mod dup if digit else drop then '0' + 0 sys ;
: . ( n -- ) dup -if negate '-' emit then digit space ;

: bye -1 sys ; inline

then

-237 .

bye
