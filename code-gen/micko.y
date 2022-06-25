%{
  #include <stdio.h>
  #include <stdlib.h>
  #include "defs.h"
  #include "symtab.h"
  #include "codegen.h"
  #include <string.h>

  int yyparse(void);
  int yylex(void);
  int yyerror(char *s);
  void warning(char *s);

  extern int yylineno;
  int out_lin = 0;
  char char_buffer[CHAR_BUFFER_LENGTH];
  int error_count = 0;
  int warning_count = 0;
  int var_num = 0;
  int fun_idx = -1;
  int fcall_idx = -1;
  int lab_num = -1;
  int struct_num = 1;
  FILE *output;
%}

%union {
  int i;
  char *s;
}

%token <i> _TYPE
%token _IF
%token _ELSE
%token _RETURN
%token <s> _ID
%token <s> _INT_NUMBER
%token <s> _UINT_NUMBER
%token _LPAREN
%token _RPAREN
%token _LBRACKET
%token _RBRACKET
%token _ASSIGN
%token _SEMICOLON
%token <i> _AROP
%token <i> _RELOP
%token _STRUCT
%token _DOT

%type <i> num_exp exp literal
%type <i> function_call argument rel_exp if_part

%nonassoc ONLY_IF
%nonassoc _ELSE

%%

program
  : struct_list struct_init_list function_list
      {  
        if(lookup_symbol("main", FUN) == NO_INDEX)
          err("undefined reference to 'main'");
       }
  ;
  
  
struct_init_list
  :
  | struct_inicialization struct_init_list
  ;
  
  
struct_list
  :
  | struct_list struct
  ;

struct
  : _STRUCT _ID 
  {
  	if(lookup_symbol($2, STRUCT) != NO_INDEX){
  		err("redefinition of struct '%s'", $2);
  	}else{
  		insert_symbol($2, STRUCT, struct_num, NO_ATR, NO_ATR);
  	}
  }
  _LBRACKET struct_variable_list _RBRACKET _SEMICOLON
  {
  	struct_num++;
  }
  ;
  
struct_variable_list
  :
  | struct_variable_list struct_variable
  ;
  
  
struct_variable
  : _TYPE _ID _SEMICOLON
      {
        int i = lookup_symbol($2,VAR|PAR);
        if((i != -1) && (get_atr2(i)==struct_num))
           err("redefinition of '%s'", $2);
        else 
	   insert_symbol($2, VAR, $1, ++var_num, struct_num);
      }
  ;


struct_inicialization
  : _STRUCT _ID _ID 
  {
  	int i = lookup_symbol($3,VAR|PAR|STRUCT_INIT);
        if((i != -1) && (get_atr2(i) == NO_ATR))
           err("redefinition of '%s'", $3);
        else{
          int ind = lookup_symbol($2,STRUCT);
          if(ind == NO_INDEX)
            err("struct '%s' in not defined", $2);
          else{
            int struct_index = get_type(ind);
            insert_symbol($3, STRUCT_INIT, struct_index, NO_ATR, NO_ATR);
   
	    for(int i=0; i < SYMBOL_TABLE_LENGTH; i++) {
	      if(get_atr2(i) == struct_index && get_kind(i)==VAR){
	        printf("tacno je\n");
	        char* name_to_code = malloc(100);
	        strcpy(name_to_code,$3);
	        strcat(name_to_code, "_");
	        strcat(name_to_code, get_name(i));
	        //printf("'%s'",name_to_code);
	        insert_symbol(name_to_code, STRUCT_INIT, get_type(i), NO_ATR, NO_ATR);
	        code("\n%s:\n\t\tWORD\t1", name_to_code);
	      }
	    }
          }
          
        }
        
  }
  _SEMICOLON
  ;


function_list
  : function
  | function_list function
  ;

function
  : _TYPE _ID
      {
        fun_idx = lookup_symbol($2, FUN);
        if(fun_idx == NO_INDEX)
          fun_idx = insert_symbol($2, FUN, $1, NO_ATR, NO_ATR);
        else 
          err("redefinition of function '%s'", $2);

        code("\n%s:", $2);
        code("\n\t\tPUSH\t%%14");
        code("\n\t\tMOV \t%%15,%%14");
      }
    _LPAREN parameter _RPAREN body
      {
        clear_symbols(fun_idx + 1);
        var_num = 0;
        
        code("\n@%s_exit:", $2);
        code("\n\t\tMOV \t%%14,%%15");
        code("\n\t\tPOP \t%%14");
        code("\n\t\tRET");
      }
  ;

parameter
  : /* empty */
      { set_atr1(fun_idx, 0); }

  | _TYPE _ID
      {
        insert_symbol($2, PAR, $1, 1, NO_ATR);
        set_atr1(fun_idx, 1);
        set_atr2(fun_idx, $1);
      }
  ;

body
  : _LBRACKET variable_list
      {
        if(var_num)
          code("\n\t\tSUBS\t%%15,$%d,%%15", 4*var_num);
        code("\n@%s_body:", get_name(fun_idx));
      }
    statement_list _RBRACKET
  ;

variable_list
  : /* empty */
  | variable_list variable
  ;

variable
  : _TYPE _ID _SEMICOLON
      {
        int i = lookup_symbol($2,STRUCT_INIT|VAR|PAR);
        if((i != -1) && (get_atr2(i) == NO_ATR))
           err("redefinition of '%s'", $2);
        else 
	   insert_symbol($2, VAR, $1, ++var_num, NO_ATR);
      }
  ;

statement_list
  : /* empty */
  | statement_list statement
  ;

statement
  : compound_statement
  | assignment_statement
  | if_statement
  | return_statement
  ;

compound_statement
  : _LBRACKET statement_list _RBRACKET
  ;

assignment_statement
  : _ID _ASSIGN num_exp _SEMICOLON
      {
        int idx = lookup_symbol($1, VAR|PAR);
        if(idx == NO_INDEX)
          err("invalid lvalue '%s' in assignment", $1);
        else
          if(get_type(idx) != get_type($3))
            err("incompatible types in assignment");
        gen_mov($3, idx);
      }
  | _ID _DOT _ID _ASSIGN num_exp _SEMICOLON
  {
  	int idx = lookup_symbol($1, STRUCT_INIT);
  	 if(idx == NO_INDEX)
          err("struct variable '%s' in not defined", $1);
         else{
         	int atribute_idx = lookup_symbol($3, VAR);
         	if(idx == NO_INDEX)
          		err("struct atribute '%s' does not exist", $1);
          	else{
          		if(get_atr2(atribute_idx) != get_type(idx)){
          			err("struct does not have atribute '%s'", $3);
          		}
          		if(get_type(atribute_idx) != get_type($5))
            			err("incompatible types in assignment");
          	}
         }
        char* name_to_code = malloc(100);
        strcpy(name_to_code,$1);
        strcat(name_to_code, "_");
        strcat(name_to_code, $3);
        printf("'%s'",name_to_code);
        int index = lookup_symbol(name_to_code,STRUCT_INIT);
        gen_mov($5, index);
  }
  ;

num_exp
  : exp
  | num_exp _AROP exp
      {
        if(get_type($1) != get_type($3))
          err("invalid operands: arithmetic operation");
        int t1 = get_type($1);    
        code("\n\t\t%s\t", ar_instructions[$2 + (t1 - 1) * AROP_NUMBER]);
        gen_sym_name($1);
        code(",");
        gen_sym_name($3);
        code(",");
        free_if_reg($3);
        free_if_reg($1);
        $$ = take_reg();
        gen_sym_name($$);
        set_type($$, t1);
      }
  ;

exp
  : literal
  | _ID
      {
        $$ = lookup_symbol($1, VAR|PAR);
        if($$ == NO_INDEX)
          err("'%s' undeclared", $1);
      }

  | function_call
      {
        $$ = take_reg();
        gen_mov(FUN_REG, $$);
      }
  
  | _LPAREN num_exp _RPAREN
      { $$ = $2; }
  | _ID _DOT _ID
  {
  	char* name_to_code = malloc(100);
        strcpy(name_to_code,$1);
        strcat(name_to_code, "_");
        strcat(name_to_code, $3);
  	$$ = lookup_symbol(name_to_code, STRUCT_INIT);
        if($$ == NO_INDEX)
          err("'%s' undeclared", $1);
  }
  ;

literal
  : _INT_NUMBER
      { $$ = insert_literal($1, INT); }

  | _UINT_NUMBER
      { $$ = insert_literal($1, UINT); }
  ;

function_call
  : _ID 
      {
        fcall_idx = lookup_symbol($1, FUN);
        if(fcall_idx == NO_INDEX)
          err("'%s' is not a function", $1);
      }
    _LPAREN argument _RPAREN
      {
        if(get_atr1(fcall_idx) != $4)
          err("wrong number of arguments");
        code("\n\t\t\tCALL\t%s", get_name(fcall_idx));
        if($4 > 0)
          code("\n\t\t\tADDS\t%%15,$%d,%%15", $4 * 4);
        set_type(FUN_REG, get_type(fcall_idx));
        $$ = FUN_REG;
      }
  ;

argument
  : /* empty */
    { $$ = 0; }

  | num_exp
    { 
      if(get_atr2(fcall_idx) != get_type($1))
        err("incompatible type for argument");
      free_if_reg($1);
      code("\n\t\t\tPUSH\t");
      gen_sym_name($1);
      $$ = 1;
    }
  ;

if_statement
  : if_part %prec ONLY_IF
      { code("\n@exit%d:", $1); }

  | if_part _ELSE statement
      { code("\n@exit%d:", $1); }
  ;

if_part
  : _IF _LPAREN
      {
        $<i>$ = ++lab_num;
        code("\n@if%d:", lab_num);
      }
    rel_exp
      {
        code("\n\t\t%s\t@false%d", opp_jumps[$4], $<i>3);
        code("\n@true%d:", $<i>3);
      }
    _RPAREN statement
      {
        code("\n\t\tJMP \t@exit%d", $<i>3);
        code("\n@false%d:", $<i>3);
        $$ = $<i>3;
      }
  ;

rel_exp
  : num_exp _RELOP num_exp
      {
        if(get_type($1) != get_type($3))
          err("invalid operands: relational operator");
        $$ = $2 + ((get_type($1) - 1) * RELOP_NUMBER);
        gen_cmp($1, $3);
      }
  ;

return_statement
  : _RETURN num_exp _SEMICOLON
      {
        if(get_type(fun_idx) != get_type($2))
          err("incompatible types in return");
        gen_mov($2, FUN_REG);
        code("\n\t\tJMP \t@%s_exit", get_name(fun_idx));        
      }
  ;

%%

int yyerror(char *s) {
  fprintf(stderr, "\nline %d: ERROR: %s", yylineno, s);
  error_count++;
  return 0;
}

void warning(char *s) {
  fprintf(stderr, "\nline %d: WARNING: %s", yylineno, s);
  warning_count++;
}

int main() {
  int synerr;
  init_symtab();
  output = fopen("output.asm", "w+");

  synerr = yyparse();

  clear_symtab();
  fclose(output);
  
  if(warning_count)
    printf("\n%d warning(s).\n", warning_count);

  if(error_count) {
    remove("output.asm");
    printf("\n%d error(s).\n", error_count);
  }

  if(synerr)
    return -1;  //syntax error
  else if(error_count)
    return error_count & 127; //semantic errors
  else if(warning_count)
    return (warning_count & 127) + 127; //warnings
  else
    return 0; //OK
}

