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

extern int yylex(void);
void yyerror(const char *msg);
void yyerror(const char *msg,const  char *value);
bool checkDeclaration(std::string &value);
extern int currLine;


char *identToken;
int numberToken;
int  count_names = 0;
int tempCount = 0;       
int labelCount = 0;              
bool mainFunc = false;                    

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
%type <expr_> declarations declaration identifiers var 
%type <stat_> statements statement 
%type <expr_> expression expressions multiplicative_expr term bool_expr relation_and_expr relation_expr comp

%type <expr_> vars

%%

ident : IDENT
{
  $$.code = strdup("");
  $$.place = strdup($1);
}
;

prog_start: functions 
            {
	if (!mainFunc)
	{printf("No main function declared!\n");}
            }

            ;
            
functions:  /*empty*/  
            | function functions 
            ;

function:   FUNCTION ident SEMICOLON BEGIN_PARAMS declarations END_PARAMS BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY statements END_BODY 
{
  std::string temp = "func ";
  temp.append($2.place);
  temp.append("\n");

  std::string name = $2.place;
  if(name == "main") // checks ident name for main
  {mainFunc = true;}

  temp.append($5.code); // declarations appended
  std::string decs = $5.code;
  int decNum = 0; 

  while(decs.find(".") != std::string::npos) // iterates through the beginparams declarations
  {
    int pos = decs.find(".");
    decs.replace (pos, 1, "=");
    std::string part = ", $" + std::to_string(decNum) + "\n";
    decNum++;
    decs.replace(decs.find("\n", pos), 1, part);
  }

  temp.append(decs);

  temp.append($8.code);

  std::string statements = $11.code; 

  if (statements.find("continue") != std::string::npos)
  {printf("ERROR: Continue outsde loop in function %s\n", $2.place);}

  temp.append(statements);
  temp.append("endfunc\n\n");
  printf("%s",temp.c_str());
};

identifiers: ident
{
   $$.place = strdup($1.place);
   $$.code = strdup("");
}
            | ident COMMA identifiers
            {
              std::string temp;
              temp.append($1.place);
              temp.append("|");
              temp.append($3.place);
  
              $$.place = strdup(temp.c_str());
              $$.code = strdup("");
            }
            ;
   
declarations: /*empty*/ 
            {
                $$.code = strdup("");
                $$.place = strdup("");
            }
            | declaration SEMICOLON declarations 
            {
            std::string temp;
	          temp.append($1.code);
            temp.append($3.code);

            $$.code = strdup(temp.c_str());
            $$.place = strdup ("");
            }           
            ;

declaration:  identifiers COLON ENUM L_PAREN identifiers R_PAREN 
            |  identifiers COLON INTEGER 
            {
              std::string idents($1.place);
              std::string temp;
              std::string variable;
              bool cont = true;
              size_t oldpos = 0;
              size_t pos = 0;

              while (cont) {
                pos = idents.find("|", oldpos);
                if (pos == std::string::npos) 
                {
                temp.append(". ");
                variable = idents.substr(oldpos,pos);
                temp.append(variable);
                temp.append("\n");
                cont = false;
                }
                else 
                {
                size_t len = pos - oldpos;
                temp.append(". ");
                variable = idents.substr(oldpos, len);
                temp.append(variable);
                temp.append("\n");
                }
                oldpos = pos + 1;
              }
              $$.code = strdup(temp.c_str());
              $$.place = strdup("");
            }
            |  identifiers COLON ARRAY L_SQAURE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER 
            {  
              std::string vars($1.place);
              std::string temp;
              std::string variable;
              bool cont = true;

              size_t oldpos = 0;
              size_t pos = 0;

              while (cont) {
              pos = vars.find("|", oldpos);

              if (pos == std::string::npos) {
              temp.append(".[] ");
              variable = vars.substr(oldpos, pos);
              temp.append(variable);
              temp.append(", ");
              temp.append(std::to_string($5));
              temp.append("\n");
              cont = false;
              }
              else {
              size_t len = pos - oldpos;
              temp.append(".[] ");
              variable = vars.substr(oldpos, len);
              temp.append(variable);
              temp.append(", ");
              temp.append(std::to_string($5));
              temp.append("\n");
              }
          
              oldpos = pos + 1;
            }
            $$.code = strdup(temp.c_str());
            $$.place = strdup("");	      
            } 
            ;

statements: statement SEMICOLON statements
            {
              std::string temp;
              temp.append($1.code);
              temp.append($3.code);

              $$.code = strdup(temp.c_str());
            }
            | statement SEMICOLON
            {
              std::string temp;
              temp.append($1.code);

              $$.code = strdup(temp.c_str());
            }
            ;

statement: var ASSIGN expression 
{
  std::string temp;
  temp.append($1.code);
  temp.append($3.code);
  std::string part = $3.place;
  /*
  if($1.arr && $3.arr)
  {
    part = new_temp();
    temp.append(". ");
    temp.append(part);
    temp.append("\n");

    temp.append("=[] ");
    temp.append(part);
    temp.append(", ");
    temp.append($3.place);
    temp.append("\n");

    temp.append("[]= ");
  }
  else if ($1.arr) {
    temp.append("[]= ");
  }
  else if ($3.arr){
    temp.append("=[] ");
  }
  else{
    temp.append("= ");
  } */
  temp.append("= ");
  temp.append($1.place);
  temp.append(", ");
  temp.append(part);
  temp.append("\n");

  $$.code = strdup(temp.c_str());
}
            | IF bool_expr THEN statements ENDIF 
            {

              std::string temp;
              std::string then_begin = new_label();
              std::string after = new_label();

              temp.append($2.code);
              temp.append("?:= ");
              temp.append(then_begin);
              temp.append(", ");
              temp.append($2.place);
              temp.append("\n");

              temp.append(": ");
              temp.append(then_begin);
              temp.append("\n");

              temp.append($4.code);
              temp.append(": ");
              temp.append(after);
              temp.append("\n");

              $$.code = strdup(temp.c_str());

            }
            | IF bool_expr THEN statements ELSE statements ENDIF 
            {
              std::string temp;
              std::string then_begin = new_label();
              std::string after = new_label();

              temp.append($2.code);
              temp.append("?:= ");
              temp.append(then_begin);
              temp.append(", ");
              temp.append($2.place);
              temp.append("\n");

              temp.append($6.code);
              temp.append(":= ");
              temp.append(after);
              temp.append("\n");

              temp.append(": ");
              temp.append(then_begin);
              temp.append("\n");

              temp.append($4.code);
              temp.append(": ");
              temp.append(after);
              temp.append("\n");

              $$.code = strdup(temp.c_str());
            }
            | WHILE bool_expr BEGINLOOP statements ENDLOOP 
            {
              std::string temp;
              std::string begin_while = new_label();
              std::string begin_loop = new_label();
              std::string end_loop = new_label();
              std::string statement = $4.code;
              std::string jump;
              jump.append(":= ");
              jump.append(begin_while);
              while (statement.find("continue") != std::string::npos) {
                statement.replace(statement.find("continue"), 8 , jump);
              }
              temp.append(": ");
              temp.append(begin_while);
              temp.append("\n");

              temp.append($2.code);
              temp.append("?:= ");
              temp.append(begin_loop);
              temp.append(", ");
              temp.append($2.place);
              temp.append("\n");

              temp.append(":= ");
              temp.append(end_loop);
              temp.append("\n");

              temp.append(": ");
              temp.append(begin_loop);
              temp.append("\n");

              temp.append(statement);
              temp.append(":= ");
              temp.append(begin_while);
              temp.append("\n");

              temp.append(": ");
              temp.append(end_loop);
              temp.append("\n");

              $$.code = strdup(temp.c_str());
            }
            | DO BEGINLOOP statements ENDLOOP WHILE bool_expr 
            {
              std::string temp;
              std::string begin_loop = new_label();
              std::string begin_while = new_label();
              std::string statement = $3.code;
              std::string jump;
              jump.append(":= ");
              jump.append(begin_while);

              while(statement.find("continue") != std::string::npos) {
                statement.replace(statement.find("continue"), 8, jump);
              }

              temp.append(": ");
              temp.append(begin_loop);
              temp.append("\n");

              temp.append(statement);
              temp.append(": ");
              temp.append(begin_while);
              temp.append("\n");

              temp.append($6.code);
              temp.append("?:= ");
              temp.append(begin_loop);
              temp.append(", ");
              temp.append($6.place);
              temp.append("\n");

              $$.code = strdup(temp.c_str());
            }
            | READ vars 
            {
              std::string temp = $2.code;
              size_t pos = 0;
              do {
               pos = temp.find("|", pos);
                if (pos == std::string::npos)
                {break;}
              temp.replace(pos, 1, "<");
              } while (true);

            $$.code = strdup(temp.c_str());
            }
            | WRITE vars 
            {
              std::string temp = $2.code;
              size_t pos = 0;
              do{
                pos = temp.find("|", pos);
                if (pos == std::string::npos)
                {break;}
                temp.replace(pos, 1, ">");
              } while (true);

              $$.code = strdup(temp.c_str());
            }
            | CONTINUE 
            {
              std::string temp = "continue\n";
              $$.code = strdup(temp.c_str());
            }
            | RETURN expression 
            {
              std::string temp;
              temp.append($2.code);
              temp.append("ret ");
              temp.append($2.place);
              temp.append("\n");

              $$.code = strdup(temp.c_str());
            }
            ;

bool_expr: relation_and_expr 
{
  $$.code = strdup($1.code);
  $$.place = strdup($1.place);
}
            | relation_and_expr OR bool_expr
            {
              std::string temp;
              std::string dst = new_temp();

              temp.append($1.code);
              temp.append($3.code);
              temp.append(". ");
              temp.append(dst);
              temp.append("\n");

              temp.append("|| ");
              temp.append(dst);
              temp.append(", ");
              temp.append($1.place);
              temp.append(", ");
              temp.append($3.place);
              temp.append("\n");

              $$.code = strdup(temp.c_str());
              $$.place = strdup(dst.c_str());
            };

relation_and_expr: relation_expr 
{
  $$.code = strdup($1.code);
  $$.place = strdup($1.place);
}
            | relation_expr AND relation_and_expr
            {
              std::string temp ;
              std::string dst = new_temp();

              temp.append($1.code);
              temp.append($3.code);

              temp.append(". ");
              temp.append(dst);
              temp.append("\n");

              temp.append("&& ");
              temp.append(dst);
              temp.append(", ");
              temp.append($1.place);
              temp.append(", ");
              temp.append($3.place);
              temp.append("\n");

              $$.code = strdup(temp.c_str());
              $$.place = strdup(dst.c_str());
            }
            ;

relation_expr: expression comp expression 
{

  std::string dst = new_temp();
  std::string temp;  

  temp.append($1.code);
  temp.append($3.code);
  temp.append(". ");
  temp.append(dst);
  temp.append("\n");
  
  temp.append($2.place);
  temp.append(dst);
  temp.append(", ");
  temp.append($1.place);
  temp.append(", ");
  temp.append($3.place);
  temp.append("\n");
  
  $$.code = strdup(temp.c_str());
  $$.place = strdup(dst.c_str());
}
            | NOT expression comp expression 
            {
                std::string dst = new_temp();
                std::string temp;  

                temp.append("! ");
                temp.append($2.code);
                temp.append($4.code);
                temp.append(". ");
                temp.append(dst);
                temp.append("\n");
  
                temp.append($3.place);
                temp.append(dst);
                temp.append(", ");
                temp.append($2.place);
                temp.append(", ");
                temp.append($4.place);
                temp.append("\n");
  
                $$.code = strdup(temp.c_str());
                $$.place = strdup(dst.c_str());
            }
            | TRUE 
            {
              std::string temp = "1";

              $$.code = strdup("");
              $$.place = strdup(temp.c_str());

            }
            | NOT TRUE 
            {
              std::string temp = "! 1";

              $$.code = strdup("");
              $$.place = strdup(temp.c_str());
            }
            | FALSE 
            {
              std::string temp = "0";

              $$.code = strdup("");
              $$.place = strdup(temp.c_str());
            }
            | NOT FALSE 
            {
              std::string temp = "! 0";

              $$.code = strdup("");
              $$.place = strdup(temp.c_str());
            }
            | L_PAREN bool_expr R_PAREN
            {
              $$.code = strdup($2.code);
              $$.place = strdup($2.code);
            }
            | NOT L_PAREN bool_expr R_PAREN
            {
              std::string temp;

              temp.append("! ");
              temp.append($3.code);

              $$.code = strdup(temp.c_str());
              $$.place = strdup($3.place);
            }
            ;

comp: EQ 
{
  std::string temp;
  temp.append("== ");

  $$.code = strdup("");
  $$.place = strdup(temp.c_str());
}
            | NEQ 
            {              
              std::string temp;
              temp.append("!= ");

              $$.code = strdup("");
              $$.place = strdup(temp.c_str());
            }
            | LT 
            {  
              std::string temp;
              temp.append("< ");

              $$.code = strdup("");
              $$.place = strdup(temp.c_str());
            }
            | GT 
            {
              std::string temp;
              temp.append("> ");

              $$.code = strdup("");
              $$.place = strdup(temp.c_str());
            }
            | LTE 
            {
              std::string temp;
              temp.append("<= ");

              $$.code = strdup("");
              $$.place = strdup(temp.c_str());
            }
            | GTE 
            {
              std::string temp;
              temp.append(">= ");

              $$.code = strdup("");
              $$.place = strdup(temp.c_str());
            }
            ;

expressions: /*empty*/ 
{
  $$.code = strdup("");
  $$.place = strdup("");
}
            | expression 
            {
              std::string temp;
              temp.append($1.code);
              temp.append("param ");
              temp.append($1.place);
              temp.append("\n");

              $$.code = strdup(temp.c_str());
              $$.place = strdup("");
            }
            | expression COMMA expressions
            {
              std::string temp;
              temp.append($1.code);
              temp.append("param ");
              temp.append($1.place);
              temp.append("\n");
              temp.append($3.code);

              $$.code = strdup(temp.c_str());
              $$.place = strdup("");
            }
            ;

expression: multiplicative_expr 
            {
              $$.code = strdup($1.code);
              $$.place = strdup($1.place);
            }
            | multiplicative_expr ADD expression
            {
              $$.place = strdup(new_temp().c_str());
  
              std::string temp;
              temp.append($1.code);
              temp.append($3.code);
              temp.append(". ");
              temp.append($$.place);
              temp.append("\n");

              temp.append("+ ");
              temp.append($$.place);
              temp.append(", ");
              temp.append($1.place);
              temp.append(", ");
              temp.append($3.place);
              temp.append("\n");

              $$.code = strdup(temp.c_str());
            }
            | multiplicative_expr SUB expression
            {
              $$.place = strdup(new_temp().c_str());
  
              std::string temp;
              temp.append($1.code);
              temp.append($3.code);
              temp.append(". ");
              temp.append($$.place);
              temp.append("\n");

              temp.append("- ");
              temp.append($$.place);
              temp.append(", ");
              temp.append($1.place);
              temp.append(", ");
              temp.append($3.place);
              temp.append("\n");

              $$.code = strdup(temp.c_str());
            };

multiplicative_expr: term 
{
    $$.code = strdup($1.code);
    $$.place = strdup($1.place);
}
            | term MULT multiplicative_expr
            {
              $$.place = strdup(new_temp().c_str());
  
              std::string temp;
              temp.append(". ");
              temp.append($$.place);
              temp.append("\n");

              temp.append($1.code);
              temp.append($3.code);
              temp.append("* ");
              temp.append($$.place);
              temp.append(", ");
              temp.append($1.place);
              temp.append(", ");
              temp.append($3.place);
              temp.append("\n");

              $$.code = strdup(temp.c_str());
            }
            | term DIV multiplicative_expr
            {
              $$.place = strdup(new_temp().c_str());
  
              std::string temp;
              temp.append(". ");
              temp.append($$.place);
              temp.append("\n");

              temp.append($1.code);
              temp.append($3.code);
              temp.append("/ ");
              temp.append($$.place);
              temp.append(", ");
              temp.append($1.place);
              temp.append(", ");
              temp.append($3.place);
              temp.append("\n");

              $$.code = strdup(temp.c_str());
            }
            | term MOD multiplicative_expr
            {
              $$.place = strdup(new_temp().c_str());
  
              std::string temp;
              temp.append(". ");
              temp.append($$.place);
              temp.append("\n");

              temp.append($1.code);
              temp.append($3.code);
              temp.append("% ");
              temp.append($$.place);
              temp.append(", ");
              temp.append($1.place);
              temp.append(", ");
              temp.append($3.place);
              temp.append("\n");

              $$.code = strdup(temp.c_str());
            }            ;

term: var 
{
  /*
  if ($1.arr){
    std::string temp;
    std::string dst = new_temp();

    temp.append($1.code);
    temp.append(". ");
    temp.append(dst);
    temp.append("\n");

    temp += "=[] " + dst + ", ";
    temp.append($1.place);
    temp.append("\n");

    $$.code = strdup(temp.c_str());
    $$.place = strdup(dst.c_str());
    $$.arr = false; 
  }
  else{
    $$.code = strdup($1.code);
    $$.place = strdup($1.place);
  }

  */

  $$.code = strdup($1.code);
  $$.place = strdup($1.place);
}
            | SUB var 
            {

                std::string temp;
                temp.append($2.code);
                temp.append(". ");
                temp.append($$.place);
                temp.append("\n");

                if ($2.arr) {
                temp.append("=[] ");
                temp.append($$.place);
                temp.append(", ");
                temp.append($2.place);
                temp.append("\n");
                }
                else {
                temp.append("= ");
                temp.append($$.place);
                temp.append(", ");
                temp.append($2.place);
                temp.append("\n");
                }

                $$.place = strdup(new_temp().c_str());
                temp.append("* ");
                temp.append($$.place);
                temp.append(", ");
                temp.append($$.place);
                temp.append(", -1\n");
  
                $$.code = strdup(temp.c_str());
                $$.arr = false;

            }
            | NUMBER
            {
            $$.code = strdup("");
            $$.place = strdup(std::to_string($1).c_str());
            }
            | SUB NUMBER
            {
              std::string temp;
              temp.append("-");
              temp.append(std::to_string($2));
              
              $$.place = strdup(temp.c_str());
              $$.code = strdup("");
            } 
            | L_PAREN expression R_PAREN 
            {
                $$.code = strdup($2.code);
                $$.place = strdup($2.place);
            }
            | SUB L_PAREN expression R_PAREN 
            {
                $$.place = strdup($3.place);
                std::string temp;
                temp.append($3.code);
                temp.append("* ");
                temp.append($3.place);
                temp.append(", ");
                temp.append($3.place);
                temp.append(", -1\n");
                $$.code = strdup(temp.c_str());
            }
            | ident L_PAREN expressions R_PAREN 
            {
              $$.place = strdup(new_temp().c_str());
              std::string temp;
              temp.append($3.code);
              temp.append(". ");
              temp.append($$.place);
              temp.append("\n");
              temp.append("call ");
              temp.append($1.place);
              temp.append(", ");
              temp.append($$.place);
              temp.append("\n");
  
              $$.code = strdup(temp.c_str());
              }
            ;

vars:            var
{ 
  std::string temp;
  temp.append($1.code);
  if ($1.arr)
    temp.append(".[]| ");
  else
    temp.append(".| ");
  
  temp.append($1.place);
  temp.append("\n");

  $$.code = strdup(temp.c_str());
  $$.place = strdup(""); 
}
  | var COMMA vars
  {
  std::string temp;
  temp.append($1.code);
  if ($1.arr)
    temp.append(".[]| ");
  else
    temp.append(".| ");
  

  temp.append($1.place);
  temp.append("\n");
  temp.append($3.code);
  
  $$.code = strdup(temp.c_str());
  $$.place = strdup(""); 
  };

var: ident 
{
   $$.code = strdup(""); 
   $$.place = strdup($1.place); 
   $$.arr = false; 
}
            | ident L_SQAURE_BRACKET expression R_SQUARE_BRACKET 
            {
              std::string temp;
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

