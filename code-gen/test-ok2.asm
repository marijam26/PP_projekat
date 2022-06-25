
book1_c:
		WORD	1
book1_b:
		WORD	1
book2_c:
		WORD	1
book2_b:
		WORD	1
main:
		PUSH	%14
		MOV 	%15,%14
		SUBS	%15,$20,%15
@main_body:
@main_exit:
		MOV 	%14,%15
		POP 	%14
		RET