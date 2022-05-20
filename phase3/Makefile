CC = gcc
CFLAGS = -g -O0 -std=c99

parse: miniL.lex miniL.y
	bison -v -d --file-prefix=y miniL.y
	flex miniL.lex
	gcc -o miniL y.tab.c lex.yy.c -lfl
miniL: miniL-lex.o miniL-parser.o
	$(CC) $^ -o $@ -lfl

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

miniL-lex.c: miniL.lex miniL-parser.c
	flex -o $@ $< 

miniL-parser.c: miniL.y
	bison -d -v -g -o $@ $<

clean:
	rm -f *.o miniL-lex.c miniL-parser.c miniL-parser.h *.output *.dot miniL
	rm -f lex.yyls
	.c y.tab.* y.output *.o miniL
