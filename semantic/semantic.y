%{
  #include <stdio.h>
  #include <stdlib.h>
  #include "defs.h"
  #include "symtab.h"

  int yyparse(void);
  int yylex(void);
  int yyerror(char *s);
  void warning(char *s);

  extern int yylineno;
  char char_buffer[CHAR_BUFFER_LENGTH];
  int error_count = 0;
  int warning_count = 0;
  int var_num = 0;
  int fun_idx = -1;
  int fcall_idx = -1;
  int block = 0;
  int array[100];
  int count = 0;
  int branch_idx = 0;
  int* parameter_map[128];
  int arg_counter = 0;
  int struct_num = 1;
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
%token _INC
%token _BRANCH
%token _DO_START
%token _DO_END
%token _COMMA
%token <i> _AROP
%token <i> _RELOP
%token _STRUCT
%token _DOT

%type <i> num_exp exp literal function_call argument rel_exp

%nonassoc ONLY_IF
%nonassoc _ELSE

%%

program
  : struct_list function_list
      {  
        if(lookup_symbol("main", FUN) == NO_INDEX)
          err("undefined reference to 'main'");
       }
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


function_list
  : function
  | function_list function
  ;

function
  : _TYPE _ID
      {
        fun_idx = lookup_symbol($2, FUN);
        if(fun_idx == NO_INDEX){
          int* param_types = (int*) malloc(sizeof(int)*128);
          fun_idx = insert_symbol($2, FUN, $1, NO_ATR, NO_ATR);
          parameter_map[fun_idx] = param_types;
        }
        else 
          err("redefinition of function '%s'", $2);
      }
    _LPAREN parameter_list _RPAREN body
      {
        clear_symbols(fun_idx + 1);
        var_num = 0;
      }
  ;
  
parameter_list
  :
   { set_atr1(fun_idx,0); }
   | parameters
   ;
   
parameters
  : parameter
  | parameters _COMMA parameter
  ;

parameter
  : _TYPE _ID
      {
        if(lookup_symbol($2,PAR) != -1){
          err("Redefinition of parameter %s ", $2);
        }
        
        insert_symbol($2, PAR, $1, 1, NO_ATR);
        int num_params = get_atr1(fun_idx);
        int* param_types = parameter_map[fun_idx];
        param_types[num_params] = $1;
        num_params += 1;
        set_atr1(fun_idx, num_params);
      }
  ;

body
  : _LBRACKET variable_list statement_list _RBRACKET
  ;

variable_list
  : /* empty */
  | variable_list variable
  ;

variable
  : _TYPE _ID _SEMICOLON
      {
        int i = lookup_symbol($2,STRUCT_INC|VAR|PAR);
        fprintf(stderr, "ERROR: %s", get_name(i));
        if((i != -1) && (get_atr2(i) == NO_ATR))
           err("redefinition of '%s'", $2);
        else 
	   insert_symbol($2, VAR, $1, ++var_num, NO_ATR);
      }
  | struct_inicialization
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
  | inc_statement
  | branch_statement
  ;


struct_inicialization
  : _STRUCT _ID _ID 
  {
  	int i = lookup_symbol($3,VAR|PAR|STRUCT_INC);
        if((i != -1) && (get_atr2(i) == NO_ATR))
           err("redefinition of '%s'", $3);
        else{
          int ind = lookup_symbol($2,STRUCT);
          if(ind == NO_INDEX)
            err("struct '%s' in not defined", $2);
          else{
            int struct_index = get_type(ind);
            insert_symbol($3, STRUCT_INC, struct_index, NO_ATR, NO_ATR);
          }
          
        }
        
  }
  _SEMICOLON
  ;

branch_statement
  : _BRANCH _LPAREN _ID
  {
  	branch_idx = lookup_symbol($3,VAR|PAR);
  	if(branch_idx == NO_INDEX)
  	  err("'%s' undeclared",$3);
  }
  _SEMICOLON const_list 
  {
    count = 0;
  }
  _RPAREN do_part
  ;
  
const_list
  : literal
  {
  	if(get_type(branch_idx) != get_type($1))
  	  err("nisu isti tipovi");
  	  
  	int i = 0;
  	while(i < count){
  	  if(array[i] == $1){
  	    err("duplicirani");
  	    break;
  	  }
  	  i++;
  	}
  	
  	if(i==count){
  	  array[i] = $1;
  	  count++;
  	}	
  }
  | const_list _COMMA literal
  {
  	if(get_type(branch_idx) != get_type($3))
  	  err("nisu isti tipovi");
  	  
  	int i = 0;
  	while(i < count){
  	  if(array[i] == $3){
  	    err("duplicirani");
  	    break;
  	  }
  	  i++;
  	}
  	
  	if(i==count){
  	  array[i] = $3;
  	  count++;
  	}	
  }
  ;
  
  
do_part
  : _DO_START statement _DO_END
  | do_part _DO_START statement _DO_END
  ;



inc_statement
  : _ID _INC _SEMICOLON
  {
        if(lookup_symbol($1, VAR|PAR) == NO_INDEX)
          err("'%s' undeclared", $1);
  }
  ;

compound_statement
  : _LBRACKET 
  {
  	block++;
  	$<i>$ = get_last_element();
  }
  variable_list statement_list _RBRACKET
  {
  	print_symtab();
  	block--;
  	clear_symbols($<i>2+1);
  }
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
      }
  | _ID _DOT _ID _ASSIGN num_exp _SEMICOLON
  {
  	int idx = lookup_symbol($1, STRUCT_INC);
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
  }
  ;

num_exp
  : exp
  | num_exp _AROP exp
      {
        if(get_type($1) != get_type($3))
          err("invalid operands: arithmetic operation");
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
  | _ID _INC
  	{
        $$ = lookup_symbol($1, VAR|PAR);
        if($$ == NO_INDEX)
          err("'%s' undeclared", $1);
      }
  | function_call
  | _LPAREN num_exp _RPAREN
      { $$ = $2; }
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
          
        arg_counter = 0;
      }
    _LPAREN argument_list _RPAREN
      {
        if(get_atr1(fcall_idx) != arg_counter)
          err("wrong number of args to function '%s'", 
              get_name(fcall_idx));
        set_type(FUN_REG, get_type(fcall_idx));
        $$ = FUN_REG;
        arg_counter = 0;
      }
  ;


argument_list
  :
  | arguments
  ;
  
arguments
  : argument
  | arguments _COMMA argument
  ;

argument
  : num_exp
    { 
      if(parameter_map[fcall_idx][arg_counter] != get_type($1))
        err("incompatible type for argument in '%s'",
            get_name(fcall_idx));
      arg_counter += 1;
    }
  ;

if_statement
  : if_part %prec ONLY_IF
  | if_part _ELSE statement
  ;

if_part
  : _IF _LPAREN rel_exp _RPAREN statement
  ;

rel_exp
  : num_exp _RELOP num_exp
      {
        if(get_type($1) != get_type($3))
          err("invalid operands: relational operator");
      }
  ;

return_statement
  : _RETURN num_exp _SEMICOLON
      {
        if(get_type(fun_idx) != get_type($2))
          err("incompatible types in return");
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

  synerr = yyparse();

  clear_symtab();
  
  if(warning_count)
    printf("\n%d warning(s).\n", warning_count);

  if(error_count)
    printf("\n%d error(s).\n", error_count);

  if(synerr)
    return -1; //syntax error
  else
    return error_count; //semantic errors
}

