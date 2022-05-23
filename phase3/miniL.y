%{
    #include <stdio.h>
    #include <stdlib.h>
    extern int yylex();
    #include "lib.h"
    #include<string>
    #include<vector>
    #include<string.h>

extern int yylex(void);
void yyerror(const char *msg);
void yyerror(const char *msg,const  char *value);
bool checkDeclaration(std::string &value);
extern int currLine;

char *identToken;
int numberToken;
int  count_names = 0;

enum Type { Integer, Array };

struct Symbol {
  std::string name;
  Type type;
};

struct Function {
  std::string name;
  std::vector<Symbol> declarations;
};

std::vector <Function> symbol_table;


Function *get_function() {
  int last = symbol_table.size()-1;
  return &symbol_table[last];
}

bool find(std::string &value) {
  Function *f = get_function();
  for(int i=0; i < f->declarations.size(); i++) {
    Symbol *s = &f->declarations[i];
    if (s->name == value) {
      return true;
    }
  }
  return false;
}

void add_function_to_symbol_table(std::string &value) {
  Function f; 
  f.name = value; 
  symbol_table.push_back(f);
}

void add_variable_to_symbol_table(std::string &value, Type t) {
  Symbol s;
  s.name = value;
  s.type = t;
  Function *f = get_function();
  f->declarations.push_back(s);
}

void print_symbol_table(void) {
  printf("symbol table:\n");
  printf("--------------------\n");
  for(int i=0; i<symbol_table.size(); i++) {
    printf("function: %s\n", symbol_table[i].name.c_str());
    for(int j=0; j<symbol_table[i].declarations.size(); j++) {
      printf("  locals: %s\n", symbol_table[i].declarations[j].name.c_str());
    }
  }
  printf("--------------------\n");
}

%}

%union{
 char *op_val;
}

%error-verbose
%start prog_start
%token  FUNCTION BEGIN_PARAMS END END_PARAMS 
%token BEGIN_LOCALS END_LOCALS BEGIN_BODY END_BODY INTEGER ARRAY ENUM
%token OF IF THEN ENDIF ELSE FOR WHILE DO BEGINLOOP ENDLOOP READ WRITE
%token TRUE FALSE RETURN COLON COMMA SEMICOLON CONTINUE
%right ASSIGN
%left OR 
%left AND
%right NOT
%left LT LTE GT GTE EQ NEQ 
%left ADD SUB
%left MULT DIV MOD
%left L_SQAURE_BRACKET R_SQUARE_BRACKET
%left L_PAREN R_PAREN 
%token <op_val> NUMBER 
%token <op_val> IDENT
%type <op_val> var
%type <op_val> expression


%%

prog_start: functions 
            | error {yyerrok; yyclearin;}
            ;
            
functions:  /*empty*/  
            | function functions 
            ;

function:   FUNCTION IDENT
{
  // midrule:
  // add the function to the symbol table.
  std::string func_name = $2;
  add_function_to_symbol_table(func_name);
  {printf("func %s\n", $2);}
}
SEMICOLON BEGIN_PARAMS declarations END_PARAMS BEGIN_LOCALS declarations END_LOCALS 
{}
BEGIN_BODY statements END_BODY 
{printf("endfunc\n");}
            ;

identifiers: /*empty*/
            | COMMA IDENT identifiers
            ;
   

declarations: /*empty*/ 
            | declaration SEMICOLON declarations 
            ;

declaration:   IDENT identifiers COLON ENUM L_PAREN IDENT identifiers R_PAREN 
            {
              // add the variable to the symbol table.
              std::string value = $1;
              Type t = Integer;
              add_variable_to_symbol_table(value, t);
              {printf(". %s\n", $1);}
            }
            |  IDENT identifiers COLON INTEGER 
            {
              // add the variable to the symbol table.
              
              std::string value = $1;
              Type t = Integer;
              add_variable_to_symbol_table(value, t);
              {printf(". %s\n", $1);}
            }
            |  IDENT identifiers COLON ARRAY L_SQAURE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER 
            {
              // add the variable to the symbol table.
              std::string value = $1;
              Type t = Integer;
              add_variable_to_symbol_table(value, t);
              {printf(". %s\n", $1);}
              }
            ;

states: /*empty*/ 
            | statements 
            ;

statements: statement SEMICOLON states 
            ;

statement: var ASSIGN expression 
{
  std::string value = $1;
  checkDeclaration( value);
  printf("= %s, %s\n", $1, $3);
}
            | IF bool_expr THEN statements ENDIF 
            | IF bool_expr THEN statements ELSE statements ENDIF 
            | WHILE bool_expr BEGINLOOP statements ENDLOOP 
            | DO BEGINLOOP statements ENDLOOP WHILE bool_expr 
            | READ var vars 
            | WRITE var vars 
            {
              std::string value $2;
              checkDeclaration(value);
              printf("-> %s\n", $2);
            }
            | CONTINUE 
            | RETURN expression 
            ;

or_expr: /*empty*/ 
            | OR relation_and_expr or_expr 
            ;
            
and_expr: /*empty*/ 
            | AND relation_expr and_expr 
            ;

bool_expr: relation_and_expr or_expr 
            ;

relation_and_expr: relation_expr and_expr 
            ;

relation_expr: expression comp expression 
            | NOT expression comp expression 
            | TRUE 
            | NOT TRUE 
            | FALSE 
            | NOT FALSE 
            | L_PAREN bool_expr R_PAREN
            | NOT L_PAREN bool_expr R_PAREN
            ;

comp: EQ 
            | NEQ 
            | LT 
            | GT 
            | LTE 
            | GTE 
            ;

expressions: /*empty*/ 
            | expression 
            | expression COMMA expressions
            ;

expr: /*empty*/ 
            | ADD multiplicative_expr expr
            | SUB multiplicative_expr expr
            ;

expression: multiplicative_expr expr 
            ;

mult_expr: /*empty*/
            | MULT term 
            | DIV term 
            | MOD term 
            ;

multiplicative_expr: term mult_expr 
            ;

term: var 
            | SUB var 
            | NUMBER 
            | SUB NUMBER 
            | L_PAREN expression R_PAREN 
            | SUB L_PAREN expression R_PAREN 
            | IDENT L_PAREN expressions R_PAREN 
            ;

vars: /*empty*/ 
            | COMMA var vars 
            ;

var: IDENT 
            | IDENT L_SQAURE_BRACKET expression R_SQUARE_BRACKET 
            ;

%%
int main(int argc, char **argv) {
   yyparse();
   //print_symbol_table();
   return 0;
}

void yyerror(const char *msg)
{
   printf("** Line %d: %s\n", currLine, msg);
   exit(1);
}

void yyerror(const char *msg, const char *value)
{
 printf("** Line %d: Error: Token \"%s\" %s\n", currLine, value, msg);
   exit(1);
}

bool checkDeclaration(std::string &value)
{
  if (find(value))
  { /*printf("testing ... true ... checkDeclaration\n");
  return true;*/}
  else
   yyerror("used but not declared\n", value.c_str());
}