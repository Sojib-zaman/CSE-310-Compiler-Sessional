%option noyywrap
%x MULTI_LINE_COMMENT
%x STRING_SM
%x SINGLE_COMMENT

%{
#include<bits/stdc++.h>
#include<iostream>
#include<stdio.h>
#include<cstdlib>
#include<string>
#include<vector>
#include<fstream>


using namespace std;

#include "1905067.h"

int line_count=1;
int error_count = 0 ; 
string str ; 
string tokstr;
string cmt ; 
int string_line = 0 ; 
int multi_line=0;
ofstream logfile ;
ofstream tokenfile; 
int sc_id = 1 ; 
int b_size = 10 ; 
SymbolTable symbol_table ; 



char conversion()
{
string str = yytext ; 
string x="\'" ; 
if(str[0]!='\'') 
    {
        str.insert(0,x) ; 
        str.insert(str.length(),x);
    }
    //cout<<"NOW : "<<str<<endl  ;
  /* str = str.substr(1,str.size()-2) ; 
   cout<<int(str)<<endl  ;*/
    //cout<<"IN CONVERSION"<<yytext<<endl ; 
   if(str[1]!='\\')
        return str[1]  ; 
   else if(str[1]=='\\')
       {
        if(str[2]=='n') return '\n' ; 
        else if(str[2]=='t') return '\t' ; 
       else if(str[2]=='\"') return '\"' ; 
       else if(str[2]=='\\') return '\\' ; 
       else if(str[2]=='a') return '\a' ; 
       else if(str[2]=='f') return '\f' ; 
       else if(str[2]=='r') return '\r' ; 
       else if(str[2]=='b') return '\b' ; 
       else if(str[2]=='v') return '\v' ; 
       else if(str[2]=='0') return '\0' ; 
        
       }
    return '0' ;     

}

char store_character()
{
    
     
   string str = yytext ; 
    //cout<<"in store character"<<yytext<<endl ; 
   tokenfile<<"<CONST_CHAR, " ;
   char ch = conversion() ; 
    tokenfile<<ch<<">"<<endl ; 
    return ch ; 
   
   
//tokenfile<<"<CONST_CHAR, "<<ch[1]<<">"<<endl ; 
   
 
}
void insertKeyword()
{
    string keyword = yytext ; 
    transform(keyword.begin() , keyword.end() , keyword.begin() , ::toupper) ; 
    tokenfile<<"<"<<keyword<<", "<<yytext<<">"<<endl ; 
    logfile<<"Line# "<<line_count<<": Token <"<<keyword<<"> Lexeme "<<yytext<<" found"<<endl ;
}
void print_and_insert(string lxm , string type)
{
    SymbolInfo* info = new SymbolInfo(lxm , type) ;
    bool added = symbol_table.insert(*info , logfile) ; 
    if(added)
        symbol_table.print_all(logfile) ; 
}
void do_basic_insert(string type)
{
    tokenfile<<"<"<<type<<", "<<yytext<<">"<<endl ; 
	logfile<<"Line# "<<line_count<<": Token <"<<type<<"> Lexeme "<<yytext<<" found"<<endl ;    
}
void error_print(string error)
{
    logfile<<"Error at line# "<<line_count<<": "<<error<<" "<<yytext<<endl ; 
    error_count++ ; 
}
void write_string()
{
if(multi_line==0)
        {
            tokenfile<<"<SINGLE LINE STRING, "<<tokstr<<">\n" ;
            logfile<<"Line# "<<string_line<<": Token <SINGLE LINE STRING> Lexeme "<<str<<" found"<<endl ; 
        }
    else if(multi_line==1)
    {
        tokenfile<<"<MULTI LINE STRING, "<<tokstr<<">\n" ;
        logfile<<"Line# "<<string_line<<": Token <MULTI LINE STRING> Lexeme "<<str<<" found"<<endl ; 
    }
    multi_line=0 ; 
    string_line=0 ; 
    str="";
}


%}

WHITESPACE [ \t\f\r\v]+ 
LETTER [a-zA-Z]
DIGIT [0-9]
NEWLINE \n
SINGLE_CHAR ([ -~]{-}['\\])
SPECIAL_CHAR [\"\'nfratbv0\\]
%%



"if"	|
"else"	|
"for"   |
"while" |
"do"    |
"break" |
"int"   |       
"char"  |
"float" |
"double" |        
"void" |
"return" |
"switch" |
"case" |
"default" |
"continue" {insertKeyword() ; }            
{DIGIT}+  {do_basic_insert("CONST_INT") ;  }
({DIGIT}+\.?{DIGIT}*|\.{DIGIT}+)([Ee][+-]?{DIGIT}+)? {do_basic_insert("CONST_FLOAT") ;  }
({DIGIT}+\.{DIGIT}+\.{DIGIT}+(\.{DIGIT}+)*)+ {error_print("TOO_MANY_DECIMAL_POINTS") ;}
({DIGIT}+\.?{DIGIT}*|\.{DIGIT}+)([Ee][+-]?({DIGIT}*\.?{DIGIT}*)|\.?{DIGIT}*)+ {error_print("ILLFORMED_NUMBER") ;}
''         {error_print("EMPTY_CONST_CHAR") ;}
'([ !-~]{-}['\\])'|'\\{SPECIAL_CHAR}' {
            //cout<<"hers"<<endl ; 
            char ch = store_character() ;  
			logfile<<"Line# "<<line_count<<": Token <CONST_CHAR> Lexeme "<<ch<<" found"<<endl ;
        }
'{SINGLE_CHAR}{2,}' {  error_print("MULTICHAR_CONST_CHAR") ;   }
'{SINGLE_CHAR}{1}|('(\\{SPECIAL_CHAR})*) {error_print("UNFINISHED_CONST_CHAR") ; }
"+"     |
"-"     {do_basic_insert("ADDOP") ;}
"*"     |
"/"     |
"%"     { do_basic_insert("MULOP") ;  }
"++"    |
"--"    {do_basic_insert("INCOP") ;  }
"<"     |
"<="    |
">"     |
">="    |
"=="    |
"!="    {do_basic_insert("RELOP") ;  }
"="     { do_basic_insert("ASSIGNOP") ;  }
"&&"    |
"||"    {do_basic_insert("LOGICOP") ;  }
"&"    |
"|"    |
"^"    |
"<<"   |
">>"    {do_basic_insert("BITOP") ;  }
"!"     {do_basic_insert("NOT") ;  }
"("     { do_basic_insert("LPAREN") ;  }
")"     { do_basic_insert("RPAREN") ;  }
"{"     {
            do_basic_insert("LCURL") ;  
        symbol_table.Enter_scope(++sc_id , b_size) ; 
        }
"}"     {   line_count-- ; 
            do_basic_insert("RCURL") ;  
        symbol_table.Exit_scope(logfile) ;	
        }
"["     {do_basic_insert("LSQUARE") ;  }
"]"     {do_basic_insert("RSQUARE") ;  }
","     {do_basic_insert("COMMA") ;  }
";"     {do_basic_insert("SEMICOLON") ;  }
[_A-Za-z][0-9_A-Za-z]* {
                         do_basic_insert("ID") ;  
                        print_and_insert(yytext,"ID");
                      }
"\""    {
            BEGIN STRING_SM ; 
            str="" ; 
             tokstr="";
            str.append(yytext) ;//cout<<str<<endl ; 
            //tokstr.append(yytext) ; 
            string_line = line_count ; 
        }
<STRING_SM>\"     {
                    //cout<<"m3333u"<<endl  ;
                    str.append(yytext) ; 
                    //cout<<line_count<<endl ; 
                    //tokstr.append(yytext) ; 
                    write_string() ; 
                    str= "" ; tokstr="";
                    BEGIN INITIAL ;
                     
                }
<STRING_SM>\\[\r]?\n {
                        //cout<<line_count<<endl ; 
                         str.append("\\\n") ; 
                         //tokstr.append("\\\n") ; 
                          multi_line = 1 ; 
                         // string_line++ ;
                         line_count++ ;  
                        }
<STRING_SM>{NEWLINE}        {
                            
                            logfile<<"Error at line# "<<line_count<<": UNFINISHED_STRING "<<str<<endl ; 
                            error_count++ ; 
                            line_count++ ; 
                            //cout<<line_count<<endl ; 
                            str="" ; 
                            tokstr="";
                            BEGIN INITIAL;
                            
                            }
<STRING_SM>\\{SPECIAL_CHAR}    {   
                                    str.append(yytext) ; 
                                    //cout<<str<<endl ; 
                                    tokstr+=conversion() ;  
                                    //cout<<conversion() ; 
                                    //cout<<tokstr<<endl ; 
                                }
<STRING_SM>. {
               str.append(yytext) ; tokstr.append(yytext) ; 
             }
<STRING_SM><<EOF>>  {
                         //ERROR STARTED : 05
                            logfile<<"Error at line# "<<line_count<<": UNFINISHED_STRING "<<yytext<<endl ; 
                            error_count++ ;
                             str="" ; 
                            BEGIN INITIAL;
                            return 0 ; 
                    
                    }
{WHITESPACE} {
                /*nothing*/
             }
{NEWLINE}   {
                line_count++ ; 
            }
"/*"        {
                BEGIN(MULTI_LINE_COMMENT) ; 
                string_line=line_count ; 
                cmt="/*"  ; 
                
               // cout<<"MULTI_LINE_COMMENT"<<endl ; 
            }
<MULTI_LINE_COMMENT>"*/" {
                            BEGIN(INITIAL) ; 
                            logfile<<"Line# "<<line_count<<": Token <MULTI LINE COMMENT> Lexeme ";
                            line_count=string_line ; 
                            //cout<<line_count<<string_line<<endl ; 
                            cmt.append(yytext) ; 
                            line_count-- ;
                            logfile<<cmt<<" found"<<endl ;
                            //line_count+=string_line ; 
                            string_line = 0 ; 
                            cmt ="" ; 
                            //cout<<"INTIAL"<<endl ;
                         }
<MULTI_LINE_COMMENT>([\\r]|\n)+ {
                                            //line_count++ ; 
                                           string_line++ ;
                                           //cout<<string_line<<endl ; 
                                           cmt.append(yytext) ; 
                                           //logfile<<"Line# "<<line_count<<": Token <MULTI LINE COMMENT> Lexeme "<<yytext<<" found"<<endl ; 
                                }
\/\/    {
            //cout<<line_count<<endl ; 
            logfile<<"Line# "<<line_count<<": Token <SINGLE LINE COMMENT> Lexeme " ;
            cmt.append(yytext) ; 
            BEGIN SINGLE_COMMENT ;
        }
<SINGLE_COMMENT>.   {cmt.append(yytext) ;}
<SINGLE_COMMENT>((\\)){NEWLINE} {cmt.append(yytext) ; line_count++ ; 
                                }
<SINGLE_COMMENT>{NEWLINE}   { line_count++ ; 
                             logfile<<cmt<<" found"<<endl ; 
                             cmt="";
                             BEGIN INITIAL;
                             }

<MULTI_LINE_COMMENT><<EOF>>     {
                                    line_count=string_line-1 ;
                                    logfile<<"Error at line# "<<line_count<<": UNFINISHED_COMMENT "<<cmt;  string_line = 0 ; 
                                    //line_count++ ;
                                    error_count++ ; 
                                    BEGIN INITIAL;
                                    return 0 ; 
                                }
<MULTI_LINE_COMMENT>.       {
                                cmt.append(yytext);
                            }
{DIGIT}+[A-Z_a-z]+[0-9A-Z_a-z]*  {
                        //ERROR STARTED : 02
                            logfile<<"Error at line# "<<line_count<<": INVALID_ID_SUFFIX_NUM_PREFIX "<<yytext<<endl ; 
                            error_count++ ; 
                        } 
.           { logfile<<"Error at line# "<<line_count<<": UNRECOGNIZED_CHAR "<<yytext<<endl ; 
                error_count++ ;  }



%%

int main(int argc, char** argv) {
	if(argc!=2){
		printf("No input file name found. Insert input file name .\n");
		return 0;
	}
	
	FILE *fin=fopen(argv[1],"r");
	if(fin==NULL){
		printf("Cannot open specified file\n");
		return 0;
	}
	logfile.open("1905067_log.txt" , ios::out) ; 
	tokenfile.open("1905067_token.txt" , ios::out) ; 
	
	int scope_id=1 ; 
	int bucket_count = 10; 
	symbol_table.Enter_scope(scope_id , bucket_count) ;
	

	yyin= fin;
	yylex();
	symbol_table.print_all(logfile) ; 
	logfile<<"Total lines: "<<line_count<<endl ; 
	logfile<<"Total errors: "<<error_count ; 
	fclose(yyin);
	tokenfile.close() ;
	logfile.close() ;
	return 0;
}
