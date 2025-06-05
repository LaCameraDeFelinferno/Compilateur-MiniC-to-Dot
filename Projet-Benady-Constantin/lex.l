%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "types.h"
#include "miniC.tab.h"

%}

D                       [0-9]
L                       [a-zA-Z_]
H                       [a-fA-F0-9]
E                       [Ee][+-]?{D}+
FS                      (f|F|l|L)
IS                      (u|U|l|L)*

%option noyywrap
%option yylineno

%%
"int"            { printf("à la ligne numero %d l'identificateur est : int\n", yylineno); return INT; }
"void"           { printf("à la ligne numero %d l'identificateur est : void\n", yylineno); return VOID; }
"extern"         { printf("à la ligne numero %d l'identificateur est : extern\n", yylineno); return EXTERN; }
"if"             { printf("à la ligne numero %d l'identificateur est : if\n", yylineno); return IF; }
"else"           { printf("à la ligne numero %d l'identificateur est : else\n", yylineno); return ELSE; }
"while"          { printf("à la ligne numero %d l'identificateur est : while\n", yylineno); return WHILE; }
"for"            { printf("à la ligne numero %d l'identificateur est : for\n", yylineno); return FOR; }
"switch"         { printf("à la ligne numero %d l'identificateur est : switch\n", yylineno); return SWITCH; }
"case"           { printf("à la ligne numero %d l'identificateur est : case\n", yylineno); return CASE; }
"default"        { printf("à la ligne numero %d l'identificateur est : default\n", yylineno); return DEFAULT; }
"break"          { printf("à la ligne numero %d l'identificateur est : break\n", yylineno); return BREAK; }
"return"         { printf("à la ligne numero %d l'identificateur est : return\n", yylineno); return RETURN; }

"("              { printf("à la ligne numero %d le symbole est : (\n", yylineno); return '('; }
")"              { printf("à la ligne numero %d le symbole est : )\n", yylineno); return ')'; }
"{"              { printf("à la ligne numero %d le symbole est : {\n", yylineno); return '{'; }
"}"              { printf("à la ligne numero %d le symbole est : }\n", yylineno); return '}'; }
"["              { printf("à la ligne numero %d le symbole est : [\n", yylineno); return '['; }
"]"              { printf("à la ligne numero %d le symbole est : ]\n", yylineno); return ']'; }
";"              { printf("à la ligne numero %d le symbole est : ;\n", yylineno); return ';'; }
","              { printf("à la ligne numero %d le symbole est : ,\n", yylineno); return ','; }
":"              { printf("à la ligne numero %d le symbole est : :\n", yylineno); return ':'; }
"="              { printf("à la ligne numero %d l'opérateur est : =\n", yylineno); return '='; }

"=="             { printf("à la ligne numero %d l'opérateur est : ==\n", yylineno); return EQ; }
"!="             { printf("à la ligne numero %d l'opérateur est : !=\n", yylineno); return NEQ; }
"<"              { printf("à la ligne numero %d l'opérateur est : <\n", yylineno); return LT; }
">"              { printf("à la ligne numero %d l'opérateur est : >\n", yylineno); return GT; }
"<="             { printf("à la ligne numero %d l'opérateur est : <=\n", yylineno); return LEQ; }
">="             { printf("à la ligne numero %d l'opérateur est : >=\n", yylineno); return GEQ; }
"+"              { printf("à la ligne numero %d l'opérateur est : +\n", yylineno); return PLUS; }
"-"              { printf("à la ligne numero %d l'opérateur est : -\n", yylineno); return MOINS; }
"*"              { printf("à la ligne numero %d l'opérateur est : *\n", yylineno); return MUL; }
"/"              { printf("à la ligne numero %d l'opérateur est : /\n", yylineno); return DIV; }
"&&"             { printf("à la ligne numero %d l'opérateur est : &&\n", yylineno); return LAND; }
"||"             { printf("à la ligne numero %d l'opérateur est : ||\n", yylineno); return LOR; }
"!"              { printf("à la ligne numero %d l'opérateur est : !\n", yylineno); return NOT; }
"<<"             { printf("à la ligne numero %d l'opérateur est : <<\n", yylineno); return LSHIFT; }
">>"             { printf("à la ligne numero %d l'opérateur est : >>\n", yylineno); return RSHIFT; }
"&"              { printf("à la ligne numero %d l'opérateur est : &\n", yylineno); return BAND; }
"|"              { printf("à la ligne numero %d l'opérateur est : |\n", yylineno); return BOR; }

{L}({L}|{D})*     {
                    yylval.ident = strdup(yytext);
                    printf("à la ligne numero %d l'identificateur est : %s\n", yylineno, yytext);
                    return IDENTIFICATEUR;
                 }

0[xX]{H}+{IS}?          { printf("à la ligne numero %d la constante est : %s\n", yylineno, yytext); yylval.entier = strtol(yytext, NULL, 0); return CONSTANTE; }
0{D}+{IS}?              { printf("à la ligne numero %d la constante est : %s\n", yylineno, yytext); yylval.entier = strtol(yytext, NULL, 0); return CONSTANTE; }
{D}+{IS}?               { printf("à la ligne numero %d la constante est : %s\n", yylineno, yytext); yylval.entier = strtol(yytext, NULL, 0); return CONSTANTE; }
L?'(\.|[^\'])+'         { printf("à la ligne numero %d la constante est : %s\n", yylineno, yytext); yylval.entier = strtol(yytext + (yytext[0] == 'L' ? 2 : 1), NULL, 0); return CONSTANTE; }

"/*"([^*]|\*[^/])*"*/" { printf("à la ligne numero %d le commentaire est : %s\n", yylineno, yytext); /* on ignore les commentaires */ }

[ \t\v\n\f]+     { /* on ignore les blancs */ }

.                {
                    printf("à la ligne numero %d il y a un caractère inconnu : %s\n", yylineno, yytext);
                    return yytext[0];
                 }
%%
