
boo_c:
		WORD	1
boo_b:
		WORD	1
boo1_aa:
		WORD	1
boo1_bb:
		WORD	1
main:
		PUSH	%14
		MOV 	%15,%14
		SUBS	%15,$20,%15
@main_body:
		MOV 	$25,boo_c
		MOV 	boo_c,boo1_aa
		ADDS	boo_c,boo1_aa,%0
		MOV 	%0,-20(%14)
		MOV 	-20(%14),%13
		JMP 	@main_exit
@main_exit:
		MOV 	%14,%15
		POP 	%14
		RET