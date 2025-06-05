# Makefile pour générer le compilateur

all: compilateur

compilateur: miniC.tab.c lex.yy.c
	@gcc -o compilateur miniC.tab.c lex.yy.c

miniC.tab.c miniC.tab.h: miniC.y
	@bison -d -v miniC.y

lex.yy.c: lex.l
	@flex lex.l

clean:
	@rm -f lex.yy.c miniC.tab.h miniC.tab.c compilateur fonction_0.dot
