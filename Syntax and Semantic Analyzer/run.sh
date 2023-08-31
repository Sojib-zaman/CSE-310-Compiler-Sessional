#!/bin/bash
yacc -d -y 1905067.y
g++ -w -c -o y.o y.tab.c
flex 1905067.l
g++ -w -c -o l.o lex.yy.c
g++ y.o l.o -lfl -o a
./a test.c
