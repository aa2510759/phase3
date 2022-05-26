%{
    #include <stdio.h>
    #include <stdlib.h>
    extern int yylex();
    #include "lib.h"
    #include<string>
    #include<vector>
    #include<string.h>
    #include <map>
    #include <set>

std::map<std::string, int> funcs;
std::map<std::string, int> vars_;

extern int yylex(void);
void yyerror(const char *msg);
void yyerror(const char *msg,const  char *value);
bool checkDeclaration(std::string &value);
extern int currLine;

std::map<std::string, std::string> varTemp;
std::map<std::string, int> arrSize;


char *identToken;
int numberToken;
int  count_names = 0;
int tempCount = 0;       
int labelCount = 0;              
bool mainFunc = false;                    

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

std::string new_temp();
std::string new_label();


%}

%union{
 char *id_val;
 int num_val;

 struct E {
    char* place;
    char* code;
    bool arr;
  } expr_;

  struct S {
    char* code;
  } stat_;
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
%token <num_val> NUMBER 
%token <id_val> IDENT

%type <expr_> ident
%type <expr_> declarations declaration identifiers var vars
%type <stat_> statements statement 
%type <expr_> expression expressions mult_expr term boolExp relation_and_expr relation_expr comp

%%

ident : IDENT
      ;
prog_start: functions 
            | error {yyerrok; yyclearin;}
            ;
            
functions:  /*empty*/  
            | function functions 
            ;

function:   FUNCTION ident
SEMICOLON BEGIN_PARAMS declarations END_PARAMS BEGIN_LOCALS declarations END_LOCALS 
BEGIN_BODY statements END_BODY 
            ;

identifiers: /*empty*/
            | COMMA ident identifiers
            ;
   

declarations: /*empty*/ 
            | declaration SEMICOLON declarations 
            ;

declaration:  ident identifiers COLON ENUM L_PAREN ident identifiers R_PAREN 
            |  ident identifiers COLON INTEGER 
            |  ident identifiers COLON ARRAY L_SQAURE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER 
            ;

states: /*empty*/ 
            | statements 
            ;

statements: statement SEMICOLON states 
            ;

statement: var ASSIGN expression 
            | IF bool_expr THEN statements ENDIF 
            | IF bool_expr THEN statements ELSE statements ENDIF 
            | WHILE bool_expr BEGINLOOP statements ENDLOOP 
            | DO BEGINLOOP statements ENDLOOP WHILE bool_expr 
            | READ var vars 
            | WRITE var vars 
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
{
  
};
            | NEQ 
            {
              
            };
            | LT {
              
            };
            | GT 
            {
           
            };
            | LTE {
           
            };
            | GTE 
            {
             
            };
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
{
  std::string dst = new_temp();
  std::string temp;
  if ($1.arr){
    temp.append($1.code);
    temp.append(". ");
    temp.append(dst);
    temp.append("\n");
    temp += "=[] " + dst + ", ";
    temp.append($1.place);
    temp.append("\n");
  }
  else{
    temp.append(". ");
    temp.append(dst);
    temp.append("\n");
    temp = temp + "= " + dst + ", ";
    temp.append($1.place); 
    temp.append("\n");
    temp.append($1.code);
  }
  if (varTemp.find($1.place) != varTemp.end())
  {
    varTemp[$1.place] = dst;
  }
  $$.code= strdup(temp.c_str());
  $$.place = strdup(dst.c_str());
}
            | SUB var 
            | NUMBER 
            | SUB NUMBER 
            | L_PAREN expression R_PAREN 
            | SUB L_PAREN expression R_PAREN 
            | ident L_PAREN expressions R_PAREN 
            ;

vars: var COMMA vars
{
  std::string temp;
  temp.append($1.code);
  if ($1.arr)
  {
    temp.append(".[]| ");
  } else {
    temp.append(".| ");
  }
  temp.append($1.place);
  temp.append("\n");
  temp.append($3.code);
  $$.code = strdup(temp.c_str());
  $$.place = strdup("");
}
            | var
            {
              std::string temp;
              temp.append($1.code);
              if($1.arr)
              {
                temp.append(".[]| ");
              } else {
                temp.append(".| ");
              }
              temp.append($1.place);
              temp.append("\n");
              $$.place = strdup(temp.c_str());
              $$.code = strdup("");
            }
            ;

var: ident 
{
   std::string temp;
   std::string ident = $1.place;
   if(funcs.find(ident) == funcs.end() && varTemp.find(ident) == varTemp.end()){
     printf("Identifiers %s is not declared.\n", ident.c_str());
   } else if (arrSize[ident] > 1) {
     printf("Did not provide index for array Identifier %s\n", ident.c_str());
   }
   $$.code = strdup(""); 
   $$.place = strdup(ident.c_str()); 
   $$.arr = false; 
}
            | ident L_SQAURE_BRACKET expression R_SQUARE_BRACKET 
            {
              std::string temp;
              std::string ident = $1.place;
              if (funcs.find(ident) == funcs.end() && varTemp.find(ident) == varTemp.end()){
                printf("Identifier %s is not declared.\n", ident.c_str());
              } else if (arrSize[ident] == 1){
                printf("Provided index for non-array Identifier %s \n", ident.c_str());
              }
              temp.append($1.place);
              temp.append(", ");
              temp.append($3.place);
              $$.code = strdup($3.place);
              $$.place = strdup(temp.c_str());
              $$.arr = true;
            }
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

std::string new_temp()
{
  std::string t = "t" + std::to_string(tempCount);
   tempCount++;
   return t;
}

std::string new_label()
{
  std::string l = "l" + std::to_string(labelCount);
   labelCount++;
   return l;
}


bool checkDeclaration(std::string &value)
{
  if (find(value))
  { /*printf("testing ... true ... checkDeclaration\n");
  return true;*/}
  else
   yyerror("used but not declared\n", value.c_str());
}