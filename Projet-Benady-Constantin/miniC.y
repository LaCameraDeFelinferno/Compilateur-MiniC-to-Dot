%{
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <ctype.h>
#include "types.h"

extern FILE *yyin;
extern int yyparse();
extern int yydebug;

#define taille_max 64
const char* stack_f_type[taille_max]; 
int sommet = -1;

extern int yylineno;
extern char* yytext;
char* running_f_type = NULL; 
int loop_switch = 0; 
int verif_return = 0;
portee* reach_stack = NULL;

int is_declared(const char* name) {
    if (!reach_stack) return 0;
    for (symbole* s = reach_stack->table; s != NULL; s = s->suivant) {
        if (strcmp(s->name, name) == 0) return 1;
    }
    return 0;
}

void start_bloc() {
    portee* nouvelle = malloc(sizeof(portee));
    nouvelle->table = NULL;
    nouvelle->suivante = reach_stack;
    reach_stack = nouvelle;
}

void end_bloc() {
    if (!reach_stack) return;
    symbole* s = reach_stack->table;
    while (s) {
        if (!s->usage) {
            fprintf(stderr, "[miniC] Warning : variable '%s' déclarée à la ligne %d mais jamais utilisée\n", s->name, yylineno);
        }
        symbole* temp = s;
        s = s->suivant;
        free(temp->name);
        free(temp);
    }
    portee* temp = reach_stack;
    reach_stack = reach_stack->suivante;
    free(temp);
}

void add_symbol(const char* name, const char* type, int dim, int* tailles) {
    if (reach_stack == NULL) start_bloc();
    if (is_declared(name)) {
        fprintf(stderr, "Redéclaration de '%s' \n", name);
        exit(1);}
    symbole* s = malloc(sizeof(symbole));
    s->name = strdup(name);
    s->type = strdup(type);
    s->dim = dim;
    s->dim_table = malloc(sizeof(int) * dim);
    for (int i = 0; i < dim; ++i)
        s->dim_table[i] = tailles[i];
    s->usage = 0;
    s->nb_params = 0;
    s->suivant = reach_stack->table;
    reach_stack->table = s;
}

void enter_f(const char* type) {
    if (++sommet < taille_max)
        stack_f_type[sommet] = type;
}

void leave_f() {
    if (sommet >= 0)
        sommet--;
}

const char* f_type() {
    return (sommet >= 0) ? stack_f_type[sommet] : NULL;
}


void add_symbol_f(const char* name, const char* type_retour, int nb_params) {
    if (is_declared(name)) {
        fprintf(stderr, "Redéclaration de '%s'\n", name);
        exit(1);
    }
    symbole* s = malloc(sizeof(symbole));
    s->name = strdup(name);
    s->type = strdup(type_retour);
    s->dim = 0;
    s->dim_table = NULL;
    s->usage = 0;
    s->nb_params = nb_params;
    s->suivant = reach_stack->table;
    reach_stack->table = s;
}
symbole* search_s(const char* name) {
    for (portee* p = reach_stack; p != NULL; p = p->suivante) {
        for (symbole* s = p->table; s != NULL; s = s->suivant) {
            if (strcmp(s->name, name) == 0) {
                return s;
            }
        }
    }
    return NULL;
}

void init_reach_stack() {
    portee* g = malloc(sizeof(portee));
    g->table = NULL;
    g->suivante = NULL;
    reach_stack = g;
}


void free_reach_stack() {
    while (reach_stack != NULL) {
        portee* p = reach_stack;
        symbole* s = p->table;
        while (s != NULL) {
            symbole* suivant = s->suivant;

            free(s->name); 
            free(s->type); 
            free(s);

            s = suivant;
        }
        reach_stack = p->suivante;
        free(p);
    }
}

node* noeud(char* name, char* forme, char* couleur, int num_child, node** enfants);
int print_tree(node* n, FILE* f);
void print_func(node* mon_bloc);
int yylex(void); 
void yyerror(const char* s) {
    fprintf(stderr, "Syntax Error line %d\n",  yylineno);
}

int yydebug = 1;

%}
%union {
    int entier;
    char* ident;
    declarateur_tableau d_infos;
    struct node* node_pointer;
}
%token <entier> CONSTANTE 
%token <ident> IDENTIFICATEUR
%token VOID INT FOR WHILE IF ELSE SWITCH CASE DEFAULT
%token BREAK RETURN PLUS MOINS MUL DIV LSHIFT RSHIFT BAND BOR LAND LOR LT GT 
%token GEQ LEQ EQ NEQ NOT EXTERN
%left PLUS MOINS
%left MUL DIV
%left LSHIFT RSHIFT
%left BOR BAND
%left LAND LOR
%nonassoc THEN
%nonassoc ELSE
%left OP
%left REL
%left '=' 
%right CROCHET
%start programme
%type <node_pointer> mon_bloc liste_instructions
%type <node_pointer> liste_fonctions fonction  instruction iteration selection saut affectation appel variable expression liste_expressions condition
%type <ident> type binary_op binary_rel binary_comp
%type <d_infos> declarateur liste_declarateurs 
%type <entier> liste_parms parm

%%
programme	:	
		liste_declarations liste_fonctions { print_func($2); }
;
liste_declarations	:	
		liste_declarations declaration {} 
	|	{}
;
declaration:
    type liste_declarateurs ';' {
               $1, $2.name, $2.dim;
    }
;

liste_declarateurs	:	
		liste_declarateurs ',' declarateur {if ($3.dim == 0) {
            add_symbol($3.name, "int", 0, 0);
        } else {
            add_symbol($3.name, "tableau", $3.dim,$3.tailles);
        }
}
	|	declarateur {
        $$ = $1;
        if ($1.dim == 0) {
            add_symbol($1.name, "int", 0, 0);
        } else {
            add_symbol($1.name, "tableau", $1.dim,$1.tailles);
            }
        }
;
declarateur:
    IDENTIFICATEUR {
        $$.name = $1;
        $$.dim = 0;
        $$.tailles = NULL;
    }
  | declarateur '[' CONSTANTE ']' %prec CROCHET {
        $$.name = $1.name;
        $$.dim = $1.dim + 1;
        $$.tailles = malloc(sizeof(int) * $$.dim);

        for (int i = 0; i < $1.dim; ++i)
            $$.tailles[i] = $1.tailles[i];

        $$.tailles[$1.dim] = $3;

        free($1.tailles); 
    }
    | IDENTIFICATEUR '=' expression {
        $$.name = $1;
        $$.dim = 0;
    }
;

liste_fonctions:
    liste_fonctions fonction {
        $$ = $1;
        $$->enfants = realloc($$->enfants, sizeof(node*) * ($$->num_child + 1));
        $$->enfants[$$->num_child++] = $2;
    }
    | 	fonction { $$ = $1; }
;
fonction	:	
		type IDENTIFICATEUR '(' liste_parms ')'{
            enter_f($1);   
            verif_return = 0;				
			add_symbol_f($2, $1, $4); 
			running_f_type = $1;
            }
            mon_bloc {
			char label[32];
			snprintf(label, sizeof(label), "%s, %s",$2, $1);
			node* enfants[] = { $7 };
			$$ = noeud(label, "invtrapezium", "blue", 1, enfants);
			if (verif_return == 0) {
            fprintf(stderr, "Error line %d\n" ,yylineno);
            exit(1);
			}
			leave_f(); 
		}
	|   type IDENTIFICATEUR '(' parm ')' {
            enter_f($1); 
            verif_return = 0;				
			add_symbol_f($2, $1, $4); 
			running_f_type = $1;
            }
            mon_bloc {
			char label[32];
			snprintf(label, sizeof(label), "%s, %s",$2, $1);
			node* enfants[] = { $7 };
			$$ = noeud(label, "invtrapezium", "blue", 1, enfants);
			if (verif_return == 0) {
            fprintf(stderr, "Error line %d" ,yylineno);
            exit(1);
			}
			leave_f();
		}
	|	EXTERN type IDENTIFICATEUR '(' liste_parms ')' ';' {
            add_symbol_f($3, $2, $5);
            $$ = noeud(NULL, NULL, NULL, 0, NULL);} 
	|	EXTERN type IDENTIFICATEUR '(' parm ')' ';' {
        add_symbol_f($3, $2, 1);
		$$ = noeud(NULL, NULL, NULL, 0, NULL);}
;
type:
    	VOID { $$ = "void"; }
	| 	INT  { $$ = "int"; }
;
liste_parms	:	
		liste_parms ',' parm { $$ = $1 + $3; 
		}
    | parm { $$ = $1; }
	|	{$$ = 0; 
	}
;
parm	:	
		INT IDENTIFICATEUR {
		add_symbol($2, "int", 0, 0);
		$$ = 1;
		}
;
mon_bloc:
    '{' {
        start_bloc();
    }
    liste_declarations liste_instructions '}' {
        end_bloc();
        $$ = noeud("BLOC", "ellipse", NULL, $4->num_child, $4->enfants);
    }
;

liste_instructions :	
		liste_instructions instruction { 
			$$ = $1;
			$$->enfants = realloc($$->enfants, sizeof(node*) * ($$->num_child + 1));
			$$->enfants[$$->num_child++] = $2;
    	}
	| {$$ = noeud("empty_mon_block", "ellipse", NULL, 0, NULL);} 
;
instruction	:	
		iteration { $$ = $1; }
	|	selection { $$ = $1; }
	|	saut { $$ = $1; }
	|	affectation ';' { $$ = $1; }
 	|	mon_bloc { $$ = $1; }
 	|   declaration { $$ = noeud("DECL-VIDE", NULL, NULL, 0, NULL);}
	|	appel { $$ = $1; }
;
iteration	:	
		FOR '(' affectation ';' condition ';' affectation ')' {loop_switch++;} instruction {  loop_switch--; node* enfants[]={$3, $5, $7, $10}; $$ = noeud("FOR", "ellipse", NULL, 4, enfants);} 
	|	WHILE '(' condition ')' {loop_switch++;} instruction {  loop_switch--; node* enfants[]={$3, $6}; $$ = noeud("WHILE", "ellipse", NULL, 2, enfants); }
;
saut	:	
		BREAK ';' { if (loop_switch == 0) {
            fprintf(stderr, "Error line %d" ,yylineno);
            exit(1);} 
        $$ = noeud("BREAK", "box", NULL, 0, NULL);
        loop_switch--; }
	|	RETURN ';' {
        verif_return = 1;
			const char* type_actuel = f_type();
            if (type_actuel && strcmp(type_actuel, "int") == 0){
                fprintf(stderr, "Error line %d" ,yylineno);
                exit(1);
            }
        $$ = noeud("RETURN", "trapezium", "blue", 0, NULL);
    }
	|	RETURN expression ';' {
        verif_return = 1;
        const char* type_actuel = f_type();
            if (type_actuel && strcmp(type_actuel, "void") == 0){
            fprintf(stderr, "Error line %d" ,yylineno);
            exit(1); 
        }
        node* enfants[] = { $2 };
        $$ = noeud("RETURN", "trapezium", "blue", 1, enfants);
        }
;
selection	:	
		IF '(' condition ')' instruction %prec THEN {
		node* enfants[]={$3, $5}; $$ = noeud("IF", "diamond", NULL, 2, enfants); }
	|	IF '(' condition ')' instruction ELSE instruction {
        node* enfants[]={$3, $5, $7}; $$ = noeud("IF", "diamond", NULL, 3, enfants); }
	|	SWITCH '(' expression ')' {} instruction {
        loop_switch = 0;
        node* enfants[]={$3, $6}; $$ = noeud("SWITCH", "ellipse", NULL, 2, enfants); }
	|	CASE CONSTANTE {loop_switch++;} ':' instruction {
			char label[32];
			snprintf(label, sizeof(label), "case %d", $2);
			node* enfants[]={$5};
			$$ = noeud( label, "ellipse", NULL, 1, enfants);
		}
	|	DEFAULT ':' instruction { node* enfants[]={$3}; $$ = noeud("DEFAULT", "ellipse", NULL, 1, enfants); }
;
condition	:	
		NOT '(' condition ')' { node* enfants[]={$3}; $$ = noeud("NOT", "ellipse", NULL, 1, enfants); }
	|	condition binary_rel condition %prec REL { node* enfants[]={$1, $3}; $$ = noeud($2, "ellipse", NULL, 2, enfants); }
	|	'(' condition ')' { $$ = $2; }
	|	expression binary_comp expression { node* enfants[]={$1, $3}; $$ = noeud($2, "ellipse", NULL, 2, enfants); }
;
affectation	:	
		variable '=' expression {
        symbole* var = search_s($1->name);
        if (!var) {
            fprintf(stderr, "Error line %d" ,yylineno);
            exit(1); 
        }
        if (strcmp(var->type, "tableau") == 0 && $1->index == 0) { 
            fprintf(stderr, "Error line %d" ,yylineno);
            exit(1);
        }
		node* enfants[]={$1, $3}; $$ = noeud(":=", "ellipse", NULL, 2, enfants); }
;
variable	:	
		IDENTIFICATEUR {
		symbole* s = search_s($1);
        if (!s) {
            fprintf(stderr, "Error line %d" ,yylineno);
            exit(1);
        }
        s->usage = 1;
        $$ = noeud($1, "ellipse", NULL, 0, NULL);;
        $$->name = strdup($1);
        $$->index = 0;
        }
	|	variable '[' expression ']' {
        symbole* s = search_s($1->name);
        if (!s) {
            fprintf(stderr, "Error line %d" ,yylineno);
            exit(1);
        }

        if (strcmp(s->type, "int") == 0) {
            fprintf(stderr, "Error line %d" ,yylineno);
            exit(1);
        }
        int nouveau_niveau = $1->index + 1;
        if ($3->name && isdigit($3->name[0])) {
            int index = atoi($3->name);
            if (index >= s->dim_table[nouveau_niveau - 1]) {
            fprintf(stderr, "Error line %d" ,yylineno);
                exit(1);
            }
        }
        if (nouveau_niveau > s->dim) {
            fprintf(stderr, "Error line %d" ,yylineno);
            exit(1);
        }
        node* enfants[] = { $1, $3 };
        $$ = noeud("TAB", "ellipse", NULL, 2, enfants);
        $$->name = strdup(s->name); 
        $$->index = nouveau_niveau;
    }
;
appel:
    IDENTIFICATEUR '(' liste_expressions ')' ';' {
        symbole* f = search_s($1);
        if (!f) {
            fprintf(stderr, "Error line %d" ,yylineno);
            exit(1);
        }

        int nb_args = $3->num_child;
        if (f->nb_params != nb_args) {
            fprintf(stderr, "Error line %d" ,yylineno);
            exit(1);
        }

        node* enfants[] = { $3 };
        $$ = noeud($1, "septagon", NULL, 1, enfants);
        $$->type_expr = strdup(f->type); 
    }
  | IDENTIFICATEUR '(' expression ')' ';' {
        symbole* f = search_s($1);
        if (!f) {
            fprintf(stderr, "Error line %d" ,yylineno);
            exit(1);
        }

        if (f->nb_params != 1) {
            fprintf(stderr, "Error line %d" ,yylineno);
            exit(1);
        }
        node* enfants[] = { $3 };
        $$ = noeud($1, "septagon", NULL, 1, enfants);
        $$->type_expr = strdup(f->type);
    }
  | IDENTIFICATEUR '(' ')' ';' {
        symbole* f = search_s($1);
        if (!f) {
            fprintf(stderr, "Error line %d" ,yylineno);
            exit(1);
        }
        if (f->nb_params != 0) {
            fprintf(stderr, "Error line %d" ,yylineno);
            exit(1);
        }
        $$ = noeud($1, "septagon", NULL, 0, NULL);
        $$->type_expr = strdup(f->type);
    }
;
liste_expressions	:	
		liste_expressions ',' expression {  
			$$ = $1;
			$$->enfants = realloc($$->enfants, sizeof(node*) * ($$->num_child + 1));
			$$->enfants[$$->num_child++] = $3;
    	}
	| 	expression {
            node** enfants = malloc(sizeof(node*));
            enfants[0] = $1;
            $$ = noeud("ARGS", NULL, NULL, 1, enfants);}
;
expression	:	
		'(' expression ')' {$$ = $2;}
	|	expression binary_op expression %prec OP {
        if (strcmp($2, "/") == 0 && $3->name && strcmp($3->name, "0") == 0) {
            fprintf(stderr, "[miniC] Warning : division par zéro détectée à la compilation (ligne %d)\n", yylineno);
        }
        node* enfants[]={$1, $3}; $$ = noeud($2, "ellipse", NULL, 2, enfants);}
	|	MOINS expression {node* enfants[]={$2}; $$ = noeud("-", "ellipse", NULL, 1, enfants);}
	|	CONSTANTE {
			int name = $1;
			char buffer[100];  
			snprintf(buffer, sizeof(buffer), "%d", name);
			$$ = noeud(buffer, "ellipse", NULL, 0, NULL);
			$$->type_expr = "int";
		}
	|	variable {
            if (search_s($1->name) && strcmp(search_s($1->name)->type, "tableau") == 0 && $1->index == 0) {
            fprintf(stderr, "Error line %d" ,yylineno);
            exit(1);
            }
            $$ = $1;}
	|	IDENTIFICATEUR '(' liste_expressions ')' { $$ = $3; } 
;
binary_op	:	
		PLUS {$$ = "+";}
	|   MOINS {$$ = "-";}
	|	MUL {$$ = "*";}
	|	DIV {$$ = "/";}
	|   LSHIFT {$$ = "<<";}
	|   RSHIFT {$$ = ">>";}
	|	BAND {$$ = "&";}
	|	BOR {$$ = "|";}
;
binary_rel	:	
		LAND {$$ = "&&";}
	|	LOR {$$ = "||";}
;
binary_comp	:	
		LT {$$ = "<";}
	|	GT {$$ = ">";}
	|	GEQ {$$ = ">=";}
	|	LEQ {$$ = "<=";}
	|	EQ {$$ = "==" ;}
	|	NEQ {$$ = "!=";}
;
%%

int main(int argc, char **argv) {
    if (argc < 2) {
        return 1;
    }
    yyin = fopen(argv[1], "r");
    if (!yyin) {
        perror("Open File Error");
        return 1;
    }
    yydebug = 1; 
    init_reach_stack();
    yyparse();
    free_reach_stack();
    fclose(yyin);
    return 0;
}

node* noeud(char* name, char* forme, char* couleur, int num_child, node** enfants) {
    node* n = malloc(sizeof(node));
    n->name = name ? strdup(name) : NULL;
    n->forme = forme ? strdup(forme) : NULL;
    n->couleur = couleur ? strdup(couleur) : NULL;
    n->num_child = num_child;
    n->enfants = malloc(sizeof(node*) * num_child);
    for (int i = 0; i < num_child; i++) {n->enfants[i] = enfants[i];}
    return n;
}

int print_tree(node* n, FILE* f) {
    static int id = 0;
    int my_id = id++;
    fprintf(f, "n%d [label=\"%s\", shape=%s", my_id,n->name ? n->name : "",n->forme ? n->forme : "box");
    if (n->couleur) fprintf(f, ", color=%s", n->couleur);fprintf(f, "];\n");
    for (int i = 0; i < n->num_child; i++) {int child_id = print_tree(n->enfants[i], f);fprintf(f, "n%d -> n%d;\n", my_id, child_id);}
    return my_id;
}

void print_func(node* mon_bloc) {
    if (!mon_bloc) return;
    for (int i = 0; i < mon_bloc->num_child; i++) {
        node* fonction = mon_bloc->enfants[i];char name_fichier[64];snprintf(name_fichier, sizeof(name_fichier), "fonction_%d.dot", i);FILE* f = fopen(name_fichier, "w");
        if (f) {fprintf(f, "digraph G {\n");print_tree(fonction, f);fprintf(f, "}\n");fclose(f);
        }
    }
}
