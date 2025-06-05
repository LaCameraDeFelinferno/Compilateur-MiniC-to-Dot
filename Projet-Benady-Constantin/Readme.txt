Avant de compiler il faut se trouver dans le dossier contenant les fichiers suivants :
-lex.l
-miniC.y
-types.h
-Makefile

Il faut d'abord executer la ligne suivante :
bison -d miniC.y

/!\ Le terminal affiche 6 conflits de shift/reduce que nous n'avons pas réussi à résoudre. Ils n'empêchent pas la génération du compilateur et du code .dot

Ensuite il faut executer la ligne suivante :
flex lex.l

Ensuite il nous reste à rentrer :
make

à ce stade, le compilateur a été créé. Pour l'utiliser il faut mettre un fichier minic (par exemple un des fichiers de test) dans le même dossier que le compilateur et executer la ligne suivante :
./compilateur [nom du fichier.c]

Si il n'y a pas d'erreur dans le fichier à compiler, un fichier fonction_0.dot devrait être créé dans le dossier.
Si il y a une erreur dans le fichier, elle sera mentionnée et empêchera la génération de code .dot.

/!\ Dans le cas où plusieurs fonctions (donc plusieurs graphes) sont dans un seul fichier, plusieurs fichiers seront créés, c'est le cas du fichier functions.c qui génère deux fichiers (fonction_0.dot et fonction_1.dot)

/!\ ATTENTION : Le compilateur génère toujours un fichier "fonction_0.dot" donc l'utiliser sur deux fichiers différents à la suite écrasera le premier fichier créé. Il est donc recommandé de générer les fichiers .dot 1 par 1 et de les renommer ou/et les déplacer dans un dossier pour ne pas se perdre.

Une façon recommandée de visualiser les graphes des fichiers .dot est de copier leur contenu dans Graphviz Online qui est un outil disponible en ligne et simple d'utilisation. Le site permet d'enregistrer le graphe sous différents format (svg, png, json etc...)

BENADY Semy
CONSTANTIN Pierre
