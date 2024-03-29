  /* cs152-miniL phase1 */
   
%{   
   /* write your C code here for definitions of variables and including headers */
   #include <string.h>
   #include "miniL-parser.hpp"
   extern char *identToken;
   extern int numberToken;
	int currLine = 1, currPos = 0;
%}

   /* some common rules */

DIGIT [0-9]

%%

   /* specific lexer rules in regex */

   /* Reserved Words */


"function" {currPos += yyleng; return FUNCTION;}
"beginparams" {currPos += yyleng; return BEGIN_PARAMS;}
"endparams" {currPos += yyleng; return END_PARAMS;}
"beginlocals" {currPos += yyleng; return BEGIN_LOCALS;}
"endlocals" {currPos += yyleng; return END_LOCALS;}
"beginbody" {currPos += yyleng; return BEGIN_BODY;}
"endbody" {currPos += yyleng; return END_BODY;}
"integer" {currPos += yyleng; return INTEGER;}
"array" {currPos += yyleng; return ARRAY;}
"enum" {currPos += yyleng; return ENUM;}
"of" {currPos += yyleng; return OF;}
"if" {currPos += yyleng; return IF;}
"then" {currPos += yyleng; return THEN;}
"endif" {currPos += yyleng; return ENDIF;}
"else" {currPos += yyleng; return ELSE;}
"for" {currPos += yyleng; return FOR;}
"while" {currPos += yyleng; return WHILE;}
"do" {currPos += yyleng; return DO;}
"beginloop" {currPos += yyleng; return BEGINLOOP;}
"endloop" {currPos += yyleng; return ENDLOOP;}
"continue" {currPos += yyleng; return CONTINUE;}
"read" {currPos += yyleng; return READ;}
"write" {currPos += yyleng; return WRITE;}
"and" {currPos += yyleng; return AND;}
"or" {currPos += yyleng; return OR;}
"not" {currPos += yyleng; return NOT;}
"true" {currPos += yyleng; return TRUE;}
"false" {currPos += yyleng; return FALSE;}
"return" {currPos += yyleng; return RETURN;}

    /* Arithmetic Operators */


"-" {currPos += yyleng; return SUB;}
"+" {currPos += yyleng; return ADD;}
"*" {currPos += yyleng; return MULT;}
"/" {currPos += yyleng; return DIV;}
"%" {currPos += yyleng; return MOD;}

   /* Comparison Operators */

"==" {currPos += yyleng; return EQ;}
"<>" {currPos += yyleng; return NEQ;}
"<" {currPos += yyleng; return LT;}
">" {currPos += yyleng; return GT;}
"<=" {currPos += yyleng; return LTE;}
">=" {currPos += yyleng; return GTE;}

   /* Identifiers and Numbers */


[a-zA-Z]([a-zA-Z0-9_]*[a-zA-Z0-9])* {
   currPos += yyleng;
   char * token = new char[yyleng];
   strcpy(token, yytext);
   yylval.id_val = token;
   identToken = yytext; 
   return IDENT;
   }


(\.{DIGIT}+)|({DIGIT}+(\.{DIGIT}*)?([eE][+-]?[0-9]+)?) {
   currPos += yyleng;
   yylval.num_val = atoi(yytext); 
   return NUMBER;
   }

   /* Other Special Symbols */

";" {currPos += yyleng; return SEMICOLON;}
":" {currPos += yyleng; return COLON;}
"," {currPos += yyleng; return COMMA;} 
"(" {currPos += yyleng; return L_PAREN;}
")" {currPos += yyleng; return R_PAREN;}
"[" {currPos += yyleng; return L_SQAURE_BRACKET;}
"]" {currPos += yyleng; return R_SQUARE_BRACKET;}
":=" {currPos += yyleng; return ASSIGN;}


[ \t]+ {currPos += yyleng;}
"##".*  {currPos = 0;}

"\n" {currLine++; currPos = 0;}
 

   /* Error Rules */

[0-9_][a-zA-Z0-9_]* {printf("Error at line %d, column %d: identifier \"%s\" must begin with a letter\n", currLine, currPos, yytext);}

[a-zA-Z][a-zA-Z0-9_]*[_] {printf("Error at line %d, column %d: identifier \"%s\" cannot end with an underscore\n", currLine, currPos, yytext);}

. {printf("Error at line %d, column %d: unrecognized symbol \"%s\"\n", currLine, currPos, yytext);} 

%%	/* C functions used in lexer */