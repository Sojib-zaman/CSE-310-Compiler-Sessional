%option noyywrap
%x MULTI_LINE_COMMENT
%x STRING_SM
%x SINGLE_COMMENT

%{

#include<bits/stdc++.h>
#include<stdio.h>
#include<cstdlib>
#include<string>
#include<vector>
#include "1905067.h"
#include "y.tab.h"
using namespace std ;


void yyerror(char *);

int line_count=1;
int  error_count = 0 ; 
int startingLine = 0 ; 

string str ; 
string tokstr;
string cmt ; 

int string_line = 0 ; 
int multi_line=0;
// int sc_id = 1 ; 
// int b_size = 10 ; 


 
extern ofstream logfile ;
extern ofstream errorfile; 


char conversion()
{
string str = yytext ; 
string x="\'" ; 
if(str[0]!='\'') 
    {
        str.insert(0,x) ; 
        str.insert(str.length(),x);
    }
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
   char ch = conversion() ; 
   return ch ; 
}
void error_print(string error)
{
    logfile<<"Error at line# "<<line_count<<": "<<error<<" "<<yytext<<endl ; 
    errorfile<<"Error at line# "<<line_count<<": "<<error<<" "<<yytext<<endl ; 
    error_count++ ; 
}
void write_string()
{
        if(multi_line==0)
        {
            logfile<<"Line# "<<string_line<<": Token <SINGLE LINE STRING> Lexeme "<<str<<" found"<<endl ; 
        }
    else if(multi_line==1)
    {
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
INTEGER {DIGIT}+
FLOAT ({DIGIT}+\.?{DIGIT}*|\.{DIGIT}+)([Ee][+-]?{DIGIT}+)?
TOO_MANY_DECIMAL_POINTS ({DIGIT}+\.{DIGIT}+\.{DIGIT}+(\.{DIGIT}+)*)+
ILLFORMED_NUMBER ({DIGIT}+\.?{DIGIT}*|\.{DIGIT}+)([Ee][+-]?({DIGIT}*\.?{DIGIT}*)|\.?{DIGIT}*)+
CHAR '([ !-~]{-}['\\])'|'\\{SPECIAL_CHAR}'
MULTICHAR_CONST_CHAR '{SINGLE_CHAR}{2,}'
UNFINISHED_CONST_CHAR '{SINGLE_CHAR}{1}|('(\\{SPECIAL_CHAR})*)
IDENTIFIER [_A-Za-z][0-9_A-Za-z]*
%%



"if"	{
        string symbolname = yytext ; 
        string symboltype = "IF";
        SymbolInfo* info = new SymbolInfo(symbolname , symboltype ) ;
        yylval.symbol = info ; 
        logfile<<"Line# "<<line_count<<": Token <"<<symboltype<<"> Lexeme "<<symbolname<<" found"<<endl;
          
        
        
        
        return IF;
        }
"else"	{
        string symbolname = yytext ; 
        string symboltype = "ELSE";
        SymbolInfo* info = new SymbolInfo(symbolname , symboltype ) ;
        logfile<<"Line# "<<line_count<<": Token <"<<symboltype<<"> Lexeme "<<symbolname<<" found"<<endl;
        yylval.symbol = info ; 
          
        return ELSE;
        }
"for"   {
        string symbolname = yytext ; 
        string symboltype = "FOR";
        SymbolInfo* info = new SymbolInfo(symbolname , symboltype ) ;
        logfile<<"Line# "<<line_count<<": Token <"<<symboltype<<"> Lexeme "<<symbolname<<" found"<<endl;
        yylval.symbol = info ; 
          
        return FOR;
        }
"while" {
        string symbolname = yytext ; 
        string symboltype = "WHILE";
        SymbolInfo* info = new SymbolInfo(symbolname , symboltype ) ;
        logfile<<"Line# "<<line_count<<": Token <"<<symboltype<<"> Lexeme "<<symbolname<<" found"<<endl;
        yylval.symbol = info ; 
         
        return WHILE;
        }
"do"    {
        string symbolname = yytext ; 
        string symboltype = "DO";
        SymbolInfo* info = new SymbolInfo(symbolname , symboltype ) ;
        logfile<<"Line# "<<line_count<<": Token <"<<symboltype<<"> Lexeme "<<symbolname<<" found"<<endl;
        yylval.symbol = info ; 
         
        return DO;
        }
"int"   {
        string symbolname = yytext ; 
        string symboltype = "INT";
        SymbolInfo* info = new SymbolInfo(symbolname , symboltype ) ;
        logfile<<"Line# "<<line_count<<": Token <"<<symboltype<<"> Lexeme "<<symbolname<<" found"<<endl;
        yylval.symbol = info ; 
         
        return INT;
        }      
"char"  {
        string symbolname = yytext ; 
        string symboltype = "CHAR";
        SymbolInfo* info = new SymbolInfo(symbolname , symboltype ) ;
        logfile<<"Line# "<<line_count<<": Token <"<<symboltype<<"> Lexeme "<<symbolname<<" found"<<endl;
        yylval.symbol = info ; 
         
        return CHAR;
        }
"float" {
        string symbolname = yytext ; 
        string symboltype = "FLOAT";
        SymbolInfo* info = new SymbolInfo(symbolname , symboltype ) ;
        logfile<<"Line# "<<line_count<<": Token <"<<symboltype<<"> Lexeme "<<symbolname<<" found"<<endl;
        yylval.symbol = info ; 
         
        return FLOAT;
        }
"double" {
        string symbolname = yytext ; 
        string symboltype = "DOUBLE";
        logfile<<"Line# "<<line_count<<": Token <"<<symboltype<<"> Lexeme "<<symbolname<<" found"<<endl;
        SymbolInfo* info = new SymbolInfo(symbolname , symboltype ) ;
        yylval.symbol = info ; 
         
        return DOUBLE;
        }       
"void" {
        string symbolname = yytext ; 
        string symboltype = "VOID";
        logfile<<"Line# "<<line_count<<": Token <"<<symboltype<<"> Lexeme "<<symbolname<<" found"<<endl;
        SymbolInfo* info = new SymbolInfo(symbolname , symboltype ) ;
        yylval.symbol = info ;
          
        return VOID;
        }
"return" {
        string symbolname = yytext ; 
        string symboltype = "RETURN";
        logfile<<"Line# "<<line_count<<": Token <"<<symboltype<<"> Lexeme "<<symbolname<<" found"<<endl;
        SymbolInfo* info = new SymbolInfo(symbolname , symboltype ) ;
        yylval.symbol = info ; 
         
        return RETURN;
        } 
"println" {
        string symbolname = yytext ; 
        string symboltype = "PRINTLN";
        logfile<<"Line# "<<line_count<<": Token <"<<symboltype<<"> Lexeme "<<symbolname<<" found"<<endl;
        SymbolInfo* info = new SymbolInfo(symbolname , symboltype ) ;
        yylval.symbol = info ; 
         
        return PRINTLN;
         }          
{INTEGER}  { 
        string symbolname = yytext ; 
        string symboltype = "CONST_INT";
        SymbolInfo* info = new SymbolInfo(symbolname , symboltype ) ;
        yylval.symbol = info ; 
        logfile<<"Line# "<<line_count<<": Token <"<<symboltype<<"> Lexeme "<<symbolname<<" found"<<endl;
         
        return CONST_INT;
        }
{FLOAT} {
        string symbolname = yytext ; 
        string symboltype = "CONST_FLOAT";
        SymbolInfo* info = new SymbolInfo(symbolname , symboltype ) ;
        logfile<<"Line# "<<line_count<<": Token <"<<symboltype<<"> Lexeme "<<symbolname<<" found"<<endl;
        yylval.symbol = info ; 
         
        return CONST_FLOAT;    
        }
{TOO_MANY_DECIMAL_POINTS} {
                            string symbolname = yytext ; 
                            string symboltype = "ERROR_FLOAT";
                            SymbolInfo* info = new SymbolInfo(symbolname , symboltype ) ;
                            error_print("TOO_MANY_DECIMAL_POINTS") ;
                            yylval.symbol = info ; 
                            return ERROR_FLOAT;
                          }
{ILLFORMED_NUMBER}        {
                            string symbolname = yytext ; 
                            string symboltype = "ERROR_FLOAT";
                            SymbolInfo* info = new SymbolInfo(symbolname , symboltype ) ;
                            error_print("ILLFORMED_NUMBER") ;
                            yylval.symbol = info ; 
                            return ERROR_FLOAT;
                          }
''                        {
                            string symbolname = yytext ; 
                            string symboltype = "EMPTY_CONST_CHAR";
                            SymbolInfo* info = new SymbolInfo(symbolname , symboltype ) ;
                            error_print("EMPTY_CONST_CHAR") ;
                            yylval.symbol = info ; 
                            //return EMPTY_CONST_CHAR;
                          }
{CHAR} {
        string symbolname = yytext ; 
        string symboltype = "CONST_CHAR";
        SymbolInfo* info = new SymbolInfo(symbolname , symboltype ) ;
        yylval.symbol = info ; 
         
        return CONST_CHAR;   
        }
{MULTICHAR_CONST_CHAR}    {  error_print("MULTICHAR_CONST_CHAR") ;}
{UNFINISHED_CONST_CHAR}   {error_print("UNFINISHED_CONST_CHAR") ; line_count++ ; }
"+"     |
"-"     {
        string symbolname = yytext ; 
        string symboltype = "ADDOP";
        SymbolInfo* info = new SymbolInfo(symbolname , symboltype ) ;
        yylval.symbol = info ;
          
        logfile<<"Line# "<<line_count<<": Token <"<<symboltype<<"> Lexeme "<<symbolname<<" found"<<endl;
        return ADDOP;
        }
"*"     |
"/"     |
"%"     { 
        string symbolname = yytext ; 
        string symboltype = "MULOP";
        SymbolInfo* info = new SymbolInfo(symbolname , symboltype ) ;
        yylval.symbol = info ; 
        logfile<<"Line# "<<line_count<<": Token <"<<symboltype<<"> Lexeme "<<symbolname<<" found"<<endl;
         //these are not really needed
        return MULOP;  
        }
"++"    {
        string symbolname = yytext ; 
        string symboltype = "INCOP";
        SymbolInfo* info = new SymbolInfo(symbolname , symboltype ) ;
        yylval.symbol = info ; 
         
        logfile<<"Line# "<<line_count<<": Token <"<<symboltype<<"> Lexeme "<<symbolname<<" found"<<endl;
        return INCOP;
        }
"--"    {
        string symbolname = yytext ; 
        string symboltype = "DECOP";
        SymbolInfo* info = new SymbolInfo(symbolname , symboltype ) ;
        yylval.symbol = info ; 
         
        logfile<<"Line# "<<line_count<<": Token <"<<symboltype<<"> Lexeme "<<symbolname<<" found"<<endl;
        return DECOP; 
        }
"<"     |
"<="    |
">"     |
">="    |
"=="    |
"!="    {
        string symbolname = yytext ; 
        string symboltype = "RELOP";
        SymbolInfo* info = new SymbolInfo(symbolname , symboltype ) ;
        yylval.symbol = info ; 
         
        logfile<<"Line# "<<line_count<<": Token <"<<symboltype<<"> Lexeme "<<symbolname<<" found"<<endl;
        return RELOP; 
        }
"="     {
        string symbolname = yytext ; 
        string symboltype = "ASSIGNOP";
        SymbolInfo* info = new SymbolInfo(symbolname , symboltype ) ;
        yylval.symbol = info ; 
         
        logfile<<"Line# "<<line_count<<": Token <ASSIGNOP> Lexeme "<<yytext<<" found"<<endl;
        return ASSIGNOP;
        }
"&&"    |
"||"    {
        string symbolname = yytext ; 
        string symboltype = "LOGICOP";
        SymbolInfo* info = new SymbolInfo(symbolname , symboltype ) ;
        logfile<<"Line# "<<line_count<<": Token <"<<symboltype<<"> Lexeme "<<symbolname<<" found"<<endl;
        yylval.symbol = info ; 
         
        return LOGICOP; 
        }
"&"    |
"|"    |
"^"    |
"<<"   |
">>"   {
        string symbolname = yytext ; 
        string symboltype = "BITOP";
        SymbolInfo* info = new SymbolInfo(symbolname , symboltype ) ;
        yylval.symbol = info ; 
         
        logfile<<"Line# "<<line_count<<": Token <"<<symboltype<<"> Lexeme "<<symbolname<<" found"<<endl;
        
        //return BITOP; //NOT INC
        }
"!"     {
        string symbolname = yytext ; 
        string symboltype = "NOT";
        SymbolInfo* info = new SymbolInfo(symbolname , symboltype ) ;
        yylval.symbol = info ; 
         
        logfile<<"Line# "<<line_count<<": Token <NOT> Lexeme "<<yytext<<" found"<<endl; 
        return NOT;

        }
"("     {
        string symbolname = yytext ; 
        string symboltype = "LPAREN";
        SymbolInfo* info = new SymbolInfo(symbolname , symboltype ) ;
        yylval.symbol = info ; 
         
        logfile<<"Line# "<<line_count<<": Token <LPAREN> Lexeme "<<yytext<<" found"<<endl;
        return LPAREN;
       
        }
")"     {
        string symbolname = yytext ; 
        string symboltype = "RPAREN";
        SymbolInfo* info = new SymbolInfo(symbolname , symboltype ) ;
        yylval.symbol = info ; 
         
        logfile<<"Line# "<<line_count<<": Token <RPAREN> Lexeme "<<yytext<<" found"<<endl;
        return RPAREN;
        }
"{"     {
        string symbolname = yytext ; 
        string symboltype = "LCURL";
        SymbolInfo* info = new SymbolInfo(symbolname , symboltype ) ;
        yylval.symbol = info ; 
         
        logfile<<"Line# "<<line_count<<": Token <LCURL> Lexeme "<<yytext<<" found"<<endl;
        return LCURL;
        }
"}"     {
        string symbolname = yytext ; 
        string symboltype = "RCURL";
        SymbolInfo* info = new SymbolInfo(symbolname , symboltype ) ;
        yylval.symbol = info ; 
         
        logfile<<"Line# "<<line_count<<": Token <RCURL> Lexeme "<<yytext<<" found"<<endl;
        return RCURL;
        }
"["     {
        string symbolname = yytext ; 
        string symboltype = "LSQUARE";
        SymbolInfo* info = new SymbolInfo(symbolname , symboltype ) ;
        yylval.symbol = info ; 
         
        logfile<<"Line# "<<line_count<<": Token <LSQUARE> Lexeme "<<yytext<<" found"<<endl;
        return LTHIRD;
        }
"]"     {
        string symbolname = yytext ; 
        string symboltype = "RSQUARE";
        SymbolInfo* info = new SymbolInfo(symbolname , symboltype ) ;
        yylval.symbol = info ; 
         
        logfile<<"Line# "<<line_count<<": Token <RSQUARE> Lexeme "<<yytext<<" found"<<endl; 
        return RTHIRD;
        }
","     {
        string symbolname = yytext ; 
        string symboltype = "COMMA";
        SymbolInfo* info = new SymbolInfo(symbolname , symboltype ) ;
        yylval.symbol = info ; 
         
        logfile<<"Line# "<<line_count<<": Token <COMMA> Lexeme "<<yytext<<" found"<<endl;
        return COMMA;
        }
";"     {
        string symbolname = yytext ; 
        string symboltype = "SEMICOLON";
        SymbolInfo* info = new SymbolInfo(symbolname , symboltype ) ;
        yylval.symbol = info ; 
         
        logfile<<"Line# "<<line_count<<": Token <SEMICOLON> Lexeme "<<yytext<<" found"<<endl;
        return SEMICOLON;
        }
{IDENTIFIER} {
             string symbolname = yytext ; 
             string symboltype = "ID";
             SymbolInfo* info = new SymbolInfo(symbolname , symboltype ) ;
             yylval.symbol = info ; 
              
             logfile<<"Line# "<<line_count<<": Token <"<<symboltype<<"> Lexeme "<<symbolname<<" found"<<endl;
             return ID;  
             }
"\""           {
                BEGIN STRING_SM ; 
                str="" ; 
                tokstr="";
                str.append(yytext) ;
                string_line = line_count ; 
                }
<STRING_SM>\"     {
                    str.append(yytext) ; 
                    write_string() ; 
                    str= "" ; tokstr="";
                    BEGIN INITIAL ;  
                  }
<STRING_SM>\\[\r]?\n {
                         str.append("\\\n") ; 
                         multi_line = 1 ; 
                         line_count++ ;  
                    }
<STRING_SM>{NEWLINE}        {
                            
                            //logfile<<"Error at line# "<<line_count<<": UNFINISHED_STRING "<<str<<endl; 
                            error_count++ ; 
                            line_count++ ; 
                            //cout<<line_count<<endl ; 
                            str="" ; 
                            tokstr="";
                            BEGIN INITIAL;
                            
                            }
<STRING_SM>\\{SPECIAL_CHAR}    {   
                                    str.append(yytext) ; 
                                    tokstr+=conversion() ;  
                                }
<STRING_SM>. {
               str.append(yytext) ; 
               tokstr.append(yytext) ; 
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

