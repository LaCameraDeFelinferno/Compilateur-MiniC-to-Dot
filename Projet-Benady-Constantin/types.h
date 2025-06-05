#ifndef TYPES_H
#define TYPES_H

typedef struct {
    char* name;
    int dim;
    int* tailles;
} declarateur_tableau;

typedef struct symbole {
    char* name;
    int usage;
    char* type;
    int nb_params;
    int dim;
    int* dim_table;
    struct symbole* suivant;
} symbole;
extern int yydebug;

#define taille_max 64

typedef struct portee {
    symbole* table;             
    struct portee* suivante;
} portee;


typedef struct node {
    char* name;
    char* forme;
    char* couleur;
    struct node** enfants;
    int num_child;
    char* type_expr;
    int index;
} node;

#endif
