%{
#include<bits/stdc++.h>
#include<stdio.h>
#include<string>
#include<stdlib.h>
#include<fstream>
#include"1905067.h"
#include"additional.h"
#include"optimize.h" 

using namespace std;

int yyparse(void) ; 
int yylex(void) ; 
void yyerror(string err);
void printinlogfile(ofstream &log , string msg ) ; 


SymbolTable* symboltable = new SymbolTable(20); 
int scope_id = 1 ; 
int bucket_size = 11; 


extern FILE* yyin ; 
ofstream logfile;
ofstream errorfile ; 
ofstream parsefile ; 

string type ;
string data_type ; 

extern int line_count; 
extern int error_count ;


//! files for 8086
ofstream a_code ; 
ofstream opt_code ; 
ofstream buffer ; 

//! For ICG implementation 
int label_count = 0 ; 
int temp_count = 0 ; // no. of temporary variables generated 
int global_varcount = 0 ; 
int local_varcount = 0 ;
int offset = 0 ; 
int assembly_line_count = 0 ;
int data_segment_endline = 0 ;
int code_segment_endline = 0 ;
string function_name; 
bool isthisassignop = false ; 
int for_st_nextLine = 0 ; 
int pcc = 0 ;

struct parameter 
{
    string parameter_type ; 
    string parameter_name ; 
}demo_param;
vector<parameter>parameter_list; 
vector<string>func_argument_list ;

struct var 
{
    string var_name ; 
    int variable_size ;
    string isarraytype;
}demo_var;


vector<var>var_list ;
string name ;
string data_name ;

void function_add_val(string type , string name , bool check , bool check2)
{
    
	SymbolInfo* info = new SymbolInfo(name,"FUNCTION") ; 
    info->set_dtype(type) ; 
    info->setisdec(check) ; 
    info->setisdef(check2);
    for(int i=0 ; i<parameter_list.size() ; i++)
    {
        info->addnew(parameter_list[i].parameter_name , parameter_list[i].parameter_type) ; 
    }
    symboltable->insert(*info , logfile) ; 
}
//!helper functions for ICG 
void AsmCodeInc(int inc)
{
    assembly_line_count+=inc ; 
}
void CodeLastLineInc(int inc)
{
    code_segment_endline+=inc ; 
}

string convert_to_uppercase(string x)
{
    for(int i=0 ; x[i] ; i++)x[i] = toupper(x[i]) ; 
    return x ;
}
void write_code(string code )
{
    a_code<<code<<endl ;
    AsmCodeInc(1) ;  
}
void variable_insert(string type , var var_not_param , int extra = 0 , int ff = 0 ) //! extra 0 means normal variable , meanwhile extra 1 means function arguments . change in offset 
{

    SymbolInfo* info = new SymbolInfo(var_not_param.var_name , convert_to_uppercase(type)) ; 
    if(var_not_param.isarraytype!="ARRAY")
        {
           
            info->set_dtype(convert_to_uppercase(type)) ; 
            if(scope_id!=1) 
               {
               if(extra!=1)
               {
                write_code("\t SUB SP , 2 ; push "+var_not_param.var_name+" into the stack");  //? NOTICE THAT BP IS FIXED 
                offset+=2 ;
                
                info->setoffset(offset) ; 
                info->setglb(false) ;
               }
               else 
               {
                pcc++ ; 
              
                info->setoffset(-1*ff) ; 
                info->setglb(false) ;
               }
               
              
               // //cout<<"Current print : "<<var_not_param.var_name << " " << offset <<" "<< info->getoffset()<<endl ; 
               }
            else 
                {

                    info->setglb(true) ; 
                    
                   
                    //! for global variable , do we need a temporary file ? 
                    //! we have track of the endline of datasegment 
                    int increment = write_for_global(data_segment_endline++ , var_not_param.var_name );
                    AsmCodeInc(increment) ; 
                    a_code.close() ; 
                    a_code.open("1905067assembly.asm" , ios::app) ; 
                    
                      
                }
        } 
    else 
        {
            if(scope_id!=1)
            {
                 //cout<<"array "<<var_not_param.variable_size*2<<endl ; 
            //> for array type  , have to check local and global too 
            info->setglb(false) ;
            write_code("\t SUB SP , "+to_string( var_not_param.variable_size*2)); 
            //cout<<"done"<<endl ; 
            info->setType(convert_to_uppercase(type)) ;
            info->set_dtype("ARRAY") ;
            
            info->setoffset(offset+2) ; 
            offset+=var_not_param.variable_size*2; 
            }
            else 
            {
                 info->setglb(true) ;
                 int increment = write_for_global(data_segment_endline++ , var_not_param.var_name ,var_not_param.variable_size);
                AsmCodeInc(increment) ; 
                a_code.close() ; 
                a_code.open("1905067assembly.asm" , ios::app) ; 
            }
           
        }
    //cout<<"LINE 177 "<<var_not_param.variable_size<<endl ; 
    info->set_size(var_not_param.variable_size) ; 
 
    
    symboltable->insert(*info , logfile) ; 
    
}
string makeSymbolName(vector<SymbolInfo*> info)
{
    string s = "" ; 
    for(SymbolInfo *x:info)
    {
        s+= x->getName() ; 
    }
    return s;  

}



void print_int()
{
    ////cout<<"writing in print "<<endl ; 
    write_code("print_output proc  ;print what is in ax \n\
    push ax \n\
    push bx \n\
    push cx \n\
    push dx \n\
    push si \n\
    lea si,number \n\
    mov bx,10 \n\
    add si,4 \n\
    cmp ax,0 \n\
    jnge negate \n\
    print: \n\
    xor dx,dx \n\
    div bx \n\
    mov [si],dl \n\
    add [si],'0' \n\
    dec si \n\
    cmp ax,0 \n\
    jne print \n\
    inc si \n\
    lea dx,si \n\
    mov ah,9 \n\
    int 21h \n\
    pop si \n\
    pop dx \n\
    pop cx \n\
    pop bx \n\
    pop ax \n\
    ret \n\
    negate: \n\
    push ax \n\
    mov ah,2 \n\
    mov dl,'-' \n\
    int 21h \n\
    pop ax \n\
    neg ax \n\
    jmp print \n\
print_output endp \n"); 


}

void print_newline()
{
    write_code("new_line proc \n\
    push ax \n\
    push dx \n\
    mov ah,2 \n\
    mov dl,cr \n\
    int 21h \n\
    mov ah,2 \n\
    mov dl,lf \n\
    int 21h \n\
    pop dx \n\
    pop ax \n\
    ret \n\
new_line endp \n");
}

//> creates a new label based on label_count 
char *newLabel()
{
	char *lb= new char[4];
	strcpy(lb,"L");
	char b[3];
    label_count++;
	sprintf(b,"%d", label_count);
	strcat(lb,b);
	return lb;
}
//> Temporary variable 
char *newTemp()
{
	char *t= new char[4];
	strcpy(t,"t");
	char b[3];
	sprintf(b,"%d", temp_count);
	temp_count++;
	strcat(t,b);
	return t;
}
// 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 
//> starts the assembly code segment 
void init_segment()
{
   // a_code.open("1905067assmebly.asm") ; 

    write_code(".MODEL SMALL") ; 
    write_code(".STACK 1000H") ; 
    write_code(".DATA") ;  
    write_code("\t CR EQU 0DH") ;
	write_code("LF EQU 0AH") ; 
    write_code("\t number DB \"00000$\" ");  // done hard code so that print can work 
    data_segment_endline = assembly_line_count;
    // storing this , so that we can write the global variables later on 
    write_code(".CODE"); 
    

    //a_code.close() ; 
}
void init_mainProc()
{
   
    write_code("main PROC") ; 
    write_code("\t MOV AX , @DATA ") ; 
    write_code("\t MOV DS , AX") ; 
    write_code("\t PUSH BP") ; 
    write_code("\t MOV BP , SP ; setting the stack pointers and base pointers") ; 
   
}
void finish_mainProc()
{
    // interrupt to exit 
    //! add later  => SP+12 , PUSH BP 

    write_code("\t MOV AH , 4CH "); 
    write_code("\t INT 21H") ; 
    write_code("\t MAIN ENDP") ; 


}
void finishCode()
{
    write_code("END main") ; 


   
}
string DecodeRelop(string name)
{
    string s[] = {
        "==" , "!=" , "<" , "<=" , ">" , ">="
    } ; 
    string retval[] = {"JE" , "JNE" , "JL" , "JLE" , "JG" , "JGE"} ; 
    for(int i = 0 ; i<6 ; i++)
    {
        if(name == s[i])
            return retval[i] ; 
    }
    return " " ; 
}
string DecodeLogic(string name)
{
    string s[]={"&&" , "||"}  ; 
    string retval[]={"AND" , "OR"}; 
    for(int i = 0 ; i<2 ; i++)
    {
        if(name == s[i])
            return retval[i] ; 
    }
    return " " ; 
}
void finish_otherFunction(int pcount)
{
    //? check if problem with push ax
     write_code("\t POP AX ; return value stored in AX"); 
     string temp_label = newLabel() ; 
     write_code(temp_label+":") ; 
     write_code("\t MOV SP , BP") ; 
     write_code("\t POP BP") ; 
     write_code("\t RET "+((pcount>0)?to_string(pcount*2):" ")) ; 
     write_code(function_name+" ENDP") ; 
     offset =  0 ; 
     pcc = 0 ; 
}
void endvoidfunc()
{
    string temp_label = newLabel() ; 
     write_code(temp_label+":") ; 
     write_code("\t MOV SP , BP") ; 
     write_code("\t POP BP") ; 
     write_code("\t RET ") ; 
     write_code(function_name+" ENDP") ;  
      offset =  0 ; 
}
void start_func(string fname)
{
    //> we may need a total ID count here 

    if(fname == "main")
    {
        init_mainProc() ; 
    }
    else 
    {
        write_code("\t ; starting function "+fname) ; 
        write_code(fname+" PROC") ; 
        write_code("\t PUSH BP") ; 
       // offset = offset+2 ; 
        write_code("\t MOV BP , SP ") ; 
    }
   ; 
    
}




//type -> NON TERMINAL , token -> terminal 
%}
%union 
{
    SymbolInfo* symbol ; 
}

%token <symbol> IF ELSE FOR WHILE DO INT CHAR FLOAT DOUBLE VOID RETURN PRINTLN
%token <symbol>  CONST_INT CONST_FLOAT CONST_CHAR ERROR_FLOAT
%token <symbol>  ADDOP MULOP RELOP LOGICOP 
%token <symbol>INCOP DECOP ASSIGNOP NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD
%token <symbol>COMMA SEMICOLON
%token <symbol>  ID
%type <symbol> start program unit func_declaration func_definition parameter_list compound_statement var_declaration type_specifier ADDT_VOID M
%type <symbol> non_term_for_func end_if setup_else declaration_list statements statement expression_statement variable expression logic_expression rel_expression simple_expression term unary_expression factor argument_list arguments 

%nonassoc LOWER_THAN_ELSE 
%nonassoc ELSE 
%%
start : program {  
                    $$=new SymbolInfo(makeSymbolName({$1}),"START");
                    //init_segment() ; 
                   
                    
                } ; 
program : program unit {
                        
                        $$=new SymbolInfo(makeSymbolName({$1 , $2}) ,"PROGRAM");

                       }
                       | unit {
                       
                        $$=new SymbolInfo(makeSymbolName({$1}),"PROGRAM"); 

                       } ; 
unit : var_declaration {
                        $$ = new SymbolInfo(makeSymbolName({$1}) ,"UNIT") ;

                        }          
                        | func_declaration {
                       
                        $$ = new SymbolInfo(makeSymbolName({$1}) ,"UNIT") ;

                        }
                        |func_definition{
                       
                        $$ = new SymbolInfo(makeSymbolName({$1}) ,"UNIT") ;
 
                        } ; 
func_declaration : type_specifier non_term_for_func ADDT LPAREN parameter_list RPAREN ADDT_DEC SEMICOLON { 
                
                $$ = new SymbolInfo(makeSymbolName({$1 , $2 , $4 , $5 , $6 , $8}) ,"FUNC_DECLARATION") ; 
                parameter_list.clear() ; 
            }
            |type_specifier non_term_for_func ADDT LPAREN RPAREN ADDT_DEC SEMICOLON {
            $$ = new SymbolInfo(makeSymbolName({$1 , $2 , $4 , $5 , $7}) ,"FUNC_DECLARATION") ; 
            parameter_list.clear() ; 
                        }; 
func_definition : type_specifier non_term_for_func ADDT LPAREN parameter_list RPAREN ADDT_DEF compound_statement
                        {
                             ////cout<<"here in fdef"<<endl ; 
                         $$ = new SymbolInfo(makeSymbolName({$1 , $2 , $4 , $5 , $6 , $8}),"FUNC_DEFINITION") ;  
                        ////cout<<data_type<<endl ; 
                        if(data_type=="VOID")
                        {
                            ////cout<<"here"<<endl ; 
                            endvoidfunc() ; 
                        } 
                        }
                        |type_specifier non_term_for_func ADDT LPAREN RPAREN ADDT_DEF compound_statement
                        {
                            ////cout<<"here in fdef"<<endl ; 
                         $$ = new SymbolInfo(makeSymbolName({$1 , $2 , $4 , $5 , $7 }),"FUNC_DEFINITION") ;  
                        ////cout<<data_type<<endl ; 
                        if(data_type=="VOID")
                        {
                            ////cout<<"here"<<endl ; 
                              endvoidfunc() ; 
                        } 
                        } ;
ADDT :
{   
    data_type = type ; 
    data_name = name ;
};
ADDT_DEC: 
{  
    SymbolInfo* x = symboltable->LookUp(data_name,logfile) ; 
    if(x!=NULL)
    {
   
    }

    if(x==NULL)
    {
       
        function_add_val(data_type , data_name , true , false); 
    }
   
} ; 
ADDT_DEF :   
{
    SymbolInfo* info = symboltable->LookUp(data_name,logfile) ; 
    start_func(data_name) ;

};
parameter_list : parameter_list COMMA type_specifier ID
                        {
                         $$ = new SymbolInfo(makeSymbolName({$1 , $2 , $3 , $4 }),"PARAMETER_LIST") ; 
                         demo_param.parameter_type = $3->getType() ; //INT  
                         demo_param.parameter_name = $4->getName() ; //a
                         parameter_list.push_back(demo_param) ; 
                        }
                        |parameter_list COMMA type_specifier
                        {
                         $$ = new SymbolInfo(makeSymbolName({$1 , $2 , $3 }),"PARAMETER_LIST") ;                          
                         demo_param.parameter_type = $3->getType() ; 
                         demo_param.parameter_name ="" ; // does not have any parameter name 
                         parameter_list.push_back(demo_param) ; 
                         
                        }
                        |type_specifier ID 
                        {
                        //basic (int a <---- )
                        $$ = new SymbolInfo(makeSymbolName({$1 , $2 }),"PARAMATER_LIST") ; 
                       

                        demo_param.parameter_type = $1->getType() ; //int 
                        demo_param.parameter_name = $2->getName(); //a
                        parameter_list.push_back(demo_param) ; 


                        }
                        |type_specifier 
                        {
                            //(int <--)
                        $$ = new SymbolInfo(makeSymbolName({$1 }),"PARAMATER_LIST") ; 
                        
                        demo_param.parameter_type = $1->getType() ; 
                        demo_param.parameter_name =""; 
                        parameter_list.push_back(demo_param) ;

                        } ; 
    
compound_statement: LCURL NEW_SCOPE_ADD_PARAM_TO_VAR statements RCURL
                        {
                            
                         $$ = new SymbolInfo(makeSymbolName({$1 , $3 , $4 }),"COMPOUND_STATEMENT") ; 
                         
                         symboltable->print_all(logfile) ; 
                         symboltable->Exit_scope(logfile) ; 
                        }
                        | LCURL NEW_SCOPE_ADD_PARAM_TO_VAR RCURL
                        {
                            //{} no operation done . 
                        $$ = new SymbolInfo(makeSymbolName({$1 , $3 }),"COMPOUND_STATEMENT") ; //CHECK
                        
                        symboltable->print_all(logfile) ; 
                        symboltable->Exit_scope(logfile) ; 
                        } ; 
NEW_SCOPE_ADD_PARAM_TO_VAR: 
{
    scope_id++ ;
    symboltable->Enter_scope(scope_id , bucket_size) ;  
    if(parameter_list.size()==1 && parameter_list[0].parameter_type=="void"){}
    else 
    {
        int k  = parameter_list.size() ; 
        for(int i=0 ; i<parameter_list.size() ; i++)
        {
           
            demo_var.var_name = parameter_list[i].parameter_name ; 
            demo_var.variable_size = -1  ; //so its a variable 
            variable_insert(parameter_list[i].parameter_type , demo_var , 1 , 2 + k * 2 ) ;
            k-- ; 
        }
    }

    parameter_list.clear();

}
var_declaration:   type_specifier declaration_list SEMICOLON
                        {
                         $$ = new SymbolInfo(makeSymbolName({$1 , $2 , $3  }),"VAR_DECLARATION") ;
                         printinlogfile(logfile ,"var_declaration : type_specifier declaration_list SEMICOLON  ") ;  
                    
                         if($1->getName()=="void")
                         { 
                           
                            string msg = "Variable or field '"+$2->getName()+"' declared void" ;
                            yyerror(msg) ; 

                         }
                         else 
                         {
                           
                            string sname = $1->getName()  ; 
                            for(int i =0 ; i<var_list.size() ; i++)
                                 variable_insert(sname, var_list[i]) ;  
                         }
                        
                         var_list.clear() ; 
                         

                        } ; 
type_specifier :   INT
                {
                    type ="INT" ; 
                    $$ = new SymbolInfo(makeSymbolName({$1}), $1->getType()) ; // (int , INT) ; 
                    printinlogfile(logfile ,"type_specifier	: INT ") ;  

                }    
                | FLOAT
                {
                    type ="FLOAT" ;
                    $$ = new SymbolInfo(makeSymbolName({$1 }), $1->getType()) ;
                    printinlogfile(logfile ,"type_specifier	: FLOAT ") ; 


                }
                | VOID
                {
                    type ="VOID" ;  
                    $$ = new SymbolInfo(makeSymbolName({$1 }), $1->getType()) ;
                    printinlogfile(logfile ,"type_specifier	: VOID") ; 

                }  ; 
non_term_for_func: ID 
        {
            
             $$ = new SymbolInfo(makeSymbolName({$1 }), $1->getType()) ;
             name = $1->getName() ; 
             function_name = name ; 
             ////cout<<"NAME OF THE FUNCTION : "<<name<<endl ; 
            // if(name == "main") init_mainProc() ; 
        }    
declaration_list : declaration_list COMMA ID 
                        {
                         
                         $$ = new SymbolInfo(makeSymbolName({$1 , $2 , $3}) ,"DECLARATION_LIST") ;
                         printinlogfile(logfile ,"declaration_list : declaration_list COMMA ID  ") ; 
                        
                        demo_var.var_name = $3->getName() ; 
                        demo_var.variable_size = -1 ; 
                        var_list.push_back(demo_var) ; 

                        SymbolInfo* x = symboltable->LookUp($3->getName() , logfile) ;
                        if(x!=NULL)
                        {
                            if(symboltable->getscopeID(x->getName() , logfile) == symboltable->currScopeID())
                         {
                            string msg = "Conflicting types for'"+$3->getName()+"'" ; 
                            yyerror(msg) ;
                         }
                        }
                        else 
                        { 
                        }

                        for(int i=0 ; i<var_list.size() -1 ; i++) 
                        {
                            
                            if($3->getName()==var_list[i].var_name)
                            {
                            
                                string msg = "Redefination of variable name '"+$3->getName()+"'" ;  
                                yyerror(msg) ;
                            }
                        }

                        
                        }
                        | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
                        {

                         $$ = new SymbolInfo(makeSymbolName({$1 , $2 , $3 , $4 , $5 , $6}),"DECLARATION_LIST") ;
                         printinlogfile(logfile ,"declaration_list : declaration_list COMMA ID LSQUARE CONST_INT RSQUARE ") ;
                         demo_var.var_name = $3->getName() ; 
                         demo_var.isarraytype = "ARRAY";
                         string len = $5->getName() ; 
                         demo_var.variable_size = stoi(len) ; 
                        
                         var_list.push_back(demo_var) ; 

                         demo_var.isarraytype = ""; 
                        SymbolInfo* x = symboltable->LookUp($3->getName() , logfile) ;
                         if(x!=NULL)
                        {
                            if(symboltable->getscopeID(x->getName() , logfile) == symboltable->currScopeID())
                         {
                            string msg = "Conflicting types for'"+$3->getName()+"'" ; 
                            yyerror(msg) ;
                         }
                        }
                        else 
                        {

                        }

                        for(int i=0 ; i<var_list.size() -1  ; i++)
                        {
                            
                            if($3->getName()==var_list[i].var_name)
                            {
                                string msg = "Redefination of variable name '"+$3->getName()+"'" ; 
                                yyerror(msg) ;
                            }
                        }
                        }
                        |ID
                        {
                        $$ = new SymbolInfo(makeSymbolName({$1}),"DECLARATION_LIST") ;
                        printinlogfile(logfile ,"declaration_list : ID ") ; 
                        
                        demo_var.var_name = $1->getName() ; 
                        demo_var.variable_size = -1 ; 
                        var_list.push_back(demo_var) ; 

                         SymbolInfo* x = symboltable->LookUp($1->getName() , logfile) ;
                        if(x!=NULL)
                        {
                            if(symboltable->getscopeID(x->getName() , logfile) == symboltable->currScopeID())
                         {
                            string msg = "Conflicting types for'"+$1->getName()+"'" ; 
                            yyerror(msg) ;
                         }
                        }
                        for(int i=0 ; i<var_list.size() -1  ; i++)
                        {
                          
                            {
                                string msg = "Redefination of variable name '"+$1->getName()+"'" ;  //MODIFIED 
                                yyerror(msg) ;
                            }
                        }

                        }
                        |ID LTHIRD CONST_INT RTHIRD
                        {
                        $$ = new SymbolInfo(makeSymbolName({$1 , $2 , $3 , $4}),"DECLARATION_LIST") ;
                        printinlogfile(logfile ,"declaration_list : ID LSQUARE CONST_INT RSQUARE ") ; 
                       
                        demo_var.var_name = $1->getName() ; 
                        demo_var.isarraytype = "ARRAY";
                        string len = $3->getName() ; 
                        demo_var.variable_size = stoi(len) ; 
                        var_list.push_back(demo_var) ; 
                        demo_var.isarraytype = ""; 
                         SymbolInfo* x = symboltable->LookUp($1->getName() , logfile) ;
                        if(x!=NULL)
                        {
                            if(symboltable->getscopeID(x->getName() , logfile) == symboltable->currScopeID())
                         {
                            string msg = "Conflicting types for'"+$1->getName()+"'" ; 
                            yyerror(msg) ;
                         }
                        }
                        for(int i=0 ; i<var_list.size()  -1 ; i++)
                        {

                            if($1->getName()==var_list[i].var_name)
                            {
                                string msg = "Redefination of variable name '"+$1->getName()+"'" ;  //MODIFIED 
                                yyerror(msg) ;
                            }
                        }
                        } ; 
statements : statement {
                        $$ = new SymbolInfo(makeSymbolName({$1}),"STATEMENT") ;
                        printinlogfile(logfile ,"statements : statement  ") ; 

                       }
                        | statements statement 
                        { 
                         $$ = new SymbolInfo(makeSymbolName({$1 , $2}),"STATEMENTS") ;
                         printinlogfile(logfile ,"statements : statements statement  ") ; 


                        }
statement : var_declaration {  

                        $$ = new SymbolInfo(makeSymbolName({$1 }),"STATEMENT") ;
                        printinlogfile(logfile ,"statement : var_declaration ") ; 

                        }
                        |expression_statement { 
                        $$ = new SymbolInfo(makeSymbolName({$1 }),"STATEMENT") ;
                        printinlogfile(logfile ,"statement : expression_statement  ") ; 
                        } 
                        | compound_statement { 

                        $$ = new SymbolInfo(makeSymbolName({$1}),"STATEMENT") ;
                        printinlogfile(logfile ,"statement : compound_statement ") ; 

                        }
                        |FOR LPAREN
                         {
                            string init_label = newLabel() ; 
                            write_code(init_label+":") ; 
                            $1->setlabel(init_label) ; 

                     

                         } expression_statement ADDT_EXP 
                         {
                            string start_check = newLabel() ; 
                            write_code(start_check+":") ; 
                            $4->setlabel(start_check) ; 
                            
                         } expression_statement ADDT_EXP {
                            string inc_label = newLabel() ; 
                            write_code(inc_label+":") ; 
                          
                            $7->setlabel(inc_label) ;  
                           

                         } expression ADDT_EXP RPAREN
                         {
                            write_code("\t JMP "+$4->getlabel()) ; 
                            string true_label = newLabel() ; 
                            backpatch($7->get_truelist() , true_label) ;
                            write_code(true_label+":") ;   
                         }  statement
                        {
                            
                        $$ = new SymbolInfo(makeSymbolName({$1 , $2 , $4 , $7 , $10 , $12 , $14}),"FOR_LOOP") ; 
                        printinlogfile(logfile ,"statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement") ;  
                        write_code("\t JMP "+$7->getlabel()) ; 

                        string false_label = newLabel() ; 
                        backpatch($7->get_falselist() , false_label) ; 
                        write_code(false_label+":") ; 


                        }
                        |IF LPAREN expression ADDT_EXP RPAREN ADDT_VOID statement %prec LOWER_THAN_ELSE
                        {

                           
                            $$ = new SymbolInfo( makeSymbolName({$1 , $2 , $3 , $5 , $7 }),"IF") ; 
                            printinlogfile(logfile ,"statement : IF LPAREN expression RPAREN statement %prec THEN") ;   
                            //? NOTICE THAT EXPRESSION IS ALREADY EVALUATED BEFORE 

                            string tlbl = $6->getlabel() ; //* already written in addt_void
                            string flbl = newLabel() ; 
                            write_code(flbl+":") ; 
                            backpatch($3->get_falselist() , flbl) ; 
                            backpatch($3->get_truelist() , tlbl)  ; 



                        }
                        |IF LPAREN expression ADDT_EXP RPAREN ADDT_VOID statement  ELSE end_if setup_else statement
                        {       
                            //!WRONG ....  
                        $$ = new SymbolInfo( makeSymbolName({$1 , $2 , $3 , $5 , $7 , $8 , $11 }),"IF_ELSE") ;
                        printinlogfile(logfile ,"statement : IF LPAREN expression RPAREN statement ELSE statement ") ; 
                        
                        string tlbl = $6->getlabel() ; 
                        string flbl = $10->getlabel() ; 
                        string nlbl = $9->getlabel() ; 
                        $7->add_to_next_list($9->getmanyelse()) ; 
                        backpatch($3->get_truelist() , tlbl) ; 
                        backpatch($3->get_falselist() , flbl) ;
                        for(int i = 0 ; i<$7->get_nextlist().size() ; i++)
                        {
                            ////cout<<"ne"<<endl ; 
                            ////cout<<$7->get_nextlist()[i]<<endl ; 
                        } 
                        backpatch($7->get_nextlist() , nlbl) ; 
                        write_code(nlbl+":") ; 
                        


                        }
                        |WHILE LPAREN 
                        {
                            string begin = newLabel() ; 
                            $1->setlabel(begin) ; 
                            write_code(begin+":") ; 

                        }expression 
                        {
                            if($4->getlogic()==0)
                            {
                                write_code("\t POP AX") ; 
                                write_code("\t CMP AX , 0 ")  ;
                                write_code("\t JNE ") ; 
                                $4->add_to_true_list(assembly_line_count) ; 
                                write_code("\t JMP ") ;
                                $4->add_to_false_list(assembly_line_count) ; 

                            }
                        } RPAREN  ADDT_VOID
                        {
                           
                                backpatch($4->get_truelist() , $7->getlabel()) ; 
                               
                               

                        }statement
                        {
                        $$ = new SymbolInfo(makeSymbolName({$1 , $2 , $4 , $6 , $9}),"WHILE_LOOP") ; 
                        printinlogfile(logfile ,"statement : WHILE LPAREN expression RPAREN statement") ;   
                        write_code("\t JMP "+$1->getlabel()) ; 

                        string break_while = newLabel() ;
                        write_code(break_while+":") ; 
                        backpatch($4->get_falselist() , break_while) ; 
                        }
                        |PRINTLN LPAREN ID RPAREN SEMICOLON
                        {
                        $$ = new SymbolInfo(makeSymbolName({$1 , $2 , $3 , $4 , $5}),"PRINT") ; 
                        printinlogfile(logfile ,"statement : PRINTLN LPAREN ID RPAREN SEMICOLON ") ;  

                        //> for ID print in assembly , call the print procedure . 
                        SymbolInfo *info = symboltable->LookUp($3->getName() , logfile) ; 
                        if(info->checkifglobal()==0)
                        {
                            if(info->getoffset()>=0)
                                {
                                    write_code("\t PUSH [BP-"+to_string(info->getoffset())+"]"); 
                                }//pushed this on stack , in print will pop and then  print 
                            else 
                            { 
                                write_code("\t PUSH [BP+"+to_string(-1*info->getoffset())+"]"); 

                            }
                        write_code("\t POP AX") ; 
                       

                        }
                        else 
                        {
                        write_code("\t PUSH "+info->getName()+" ; "+info->getName()+" pushed into the stack") ; //pushed this on stack , in print will pop and then  print 
                        write_code("\t POP AX") ; 
                        }
                        
                         write_code("\t CALL print_output") ; 
                        write_code("\t CALL new_line") ; 

                        }
                        |RETURN expression SEMICOLON
                        {
 
                        $$ = new SymbolInfo(makeSymbolName({$1 , $2 , $3 }),"RETURN") ;

                        printinlogfile(logfile ,"statement : RETURN expression SEMICOLON") ; 

                        
                       
                       // //cout<<function_name<<endl ; 
                        if(function_name=="main")
                        {
                            //- if main then we use int 21H 
                            finish_mainProc() ; 
                        }
                        else 
                        { 
                             finish_otherFunction(pcc) ;   
                             //write_code(function_name+"ENDP") ; 
                        }
                        } ;
ADDT_EXP:
{

 
    data_type = type ; 

}
ADDT_VOID :
{

    
    if(data_type=="VOID")
    {
        string msg = "Void cannot be used in expression " ;
        yyerror(msg) ; 
    }



    //- FIXED UP USING BACKPATCHING 
    $$ = new SymbolInfo("ADDT_VOID" , "" )  ;
    string statement_is_true = newLabel() ; 
    write_code(statement_is_true+":") ; 
    $$->setlabel(statement_is_true) ; 

}

end_if:
{
    
    $$ = new SymbolInfo("end if" , " ") ;
    string endif = newLabel() ; 
    $$->setlabel(endif) ; 
    
    write_code("\t JMP ") ; 
    $$->setmanyelse(assembly_line_count) ; 
   

}

setup_else:
{
     $$ = new SymbolInfo("setup_else" , " ") ;
    string goelse = newLabel() ; 
     write_code(goelse+":") ; 
     $$->setlabel(goelse) ; 
   
}
expression_statement : SEMICOLON 
            {
            $$ = new SymbolInfo(makeSymbolName({$1 }) , $1->getType()) ;
            printinlogfile(logfile ,"expression_statement : SEMICOLON		") ;    
            $$->set_dtype($1->get_dtype()) ; 
            type = $1->get_dtype() ;

              $$->setlogic($1->getlogic()) ;  
                $$->set_tlist($1->get_truelist()) ; 
                 $$->set_flist($1->get_falselist()) ; 


            }
            | expression SEMICOLON 
            {
            $$ = new SymbolInfo(makeSymbolName({$1 , $2 }) ,"EXPRESSION_STATEMENT") ;
            printinlogfile(logfile ,"expression_statement : expression SEMICOLON 		 ") ;    
            $$->setType($1->getType()) ; 
            type = $1->getType() ;
            
            $$->setlogic($1->getlogic()) ;  
            $$->set_tlist($1->get_truelist()) ; 
            $$->set_flist($1->get_falselist()) ; 


            
            } ; 
variable : ID 
            {
                name = $1->getName() ; 
                $$ = new SymbolInfo(makeSymbolName({$1}) ,"ID") ;
                printinlogfile(logfile ,"variable : ID 	 ") ; 
               
                SymbolInfo* demo = symboltable->LookUp($1->getName() , logfile) ; 
                if(demo==NULL)
                {
                   string msg  = "Undeclared variable '"+$1->getName()+"'" ; 
                    yyerror(msg) ; 

                    $$->set_dtype("") ; 
                    
                }
                else 
                {
                     if(demo->get_dtype()!="VOID") $$->set_dtype(demo->get_dtype()) ;
                    else  $$->set_dtype("FLOAT") ; 

            //? for assembly code , think a = 5 ; so a is detected as variable -> id , so we do BP - offset (remember BP = SP )
                if(demo->checkifglobal()==0)
                {
                    if(demo->getoffset()>=0)
                    {
                         write_code("\t PUSH [BP-"+to_string(demo->getoffset())+"] ; "+demo->getName()+" is pushed in stack"); 
                    }
                    else 
                    {
                         write_code("\t PUSH [BP+"+to_string(-1*demo->getoffset())+"] ; "+demo->getName()+" is pushed in stack"); 
                    }
                    

                }
                else 
                {
                    write_code("\t PUSH "+demo->getName()+" ; "+demo->getName()+" pushed into the stack") ;
                }
               

                }


                
                 
            }
            |ID LTHIRD expression RTHIRD
            {
               
                $$ = new SymbolInfo(makeSymbolName({$1 , $2 , $3 , $4}),"ARRAY") ;
                printinlogfile(logfile ,"variable : ID LSQUARE expression RSQUARE  	 ") ; 
               
                SymbolInfo* x = symboltable->LookUp( $1->getName(), logfile) ;
                if(x==NULL)
                {
                    string msg  = "Undeclared variable '"+$1->getName()+"'" ; 
                    yyerror(msg) ; 
                    $$->set_dtype("") ;
                }
                else 
                {
                    if(x->isAra()) {
                        if(x->getType()!="VOID") $$->set_dtype(x->getType()) ; 
                        else  $$->setType("FLOAT") ;
                    }
                    else 
                    {
                       string msg  = "'"+$1->getName()+"' is not an array" ; 
                    yyerror(msg) ;   
                    } 
                }
              if($3->get_dtype() != "INT" && $3->get_dtype() != "CONST_INT")
              {
                string msg  = "Array subscript is not an integer" ;  
                    yyerror(msg) ;  
              }


              //! FINISH ARRAY
            write_code(";using the array "+x->getName()) ; 
            write_code("\t POP BX ; pop index no. "+$3->getName()) ; 
            write_code("\t SHL BX , 1") ; 
            //cout<<x->checkifglobal()<<endl  ; 
            //. LOCAL ARRAY 
            if(x->checkifglobal()!=1)
            {
                write_code("\t NEG BX") ; 
                write_code("\t ADD BX , "+to_string(-1*x->getoffset()))  ; 
                write_code("\t PUSH BP") ; 
                write_code("\t ADD BP , BX") ; 
                write_code("\t MOV BX , BP ") ; 
                write_code("\t MOV AX , [BP]") ; 
                write_code("\t POP BP") ; 


                // write_code("\t LEA BX , "+$1->getName()) ; 
                // write_code("\t SUB BX , AX") ; 
                // write_code("\t PUSH BX") ; 

            }
            else 
            {
               write_code("\t MOV AX , "+$1->getName()+"[BX]") ;  
            }
            write_code("\t PUSH AX")  ; 
            write_code("\t PUSH BX")  ; 

            
            } ; 
expression : logic_expression 
            {
                
                $$ = new SymbolInfo(makeSymbolName({$1}) ,"EXPRESSION") ;
                printinlogfile(logfile ,"expression 	: logic_expression	 ") ;          
                $$->set_dtype($1->get_dtype()) ; 
                type = $1->get_dtype() ; 

                $$->setlogic($1->getlogic()) ;  
                $$->set_tlist($1->get_truelist()) ; 
                 $$->set_flist($1->get_falselist()) ; 

            }
            |variable ASSIGNOP logic_expression
            {
                //cout<<"IN ASSIGNOP"<<endl ; 
                 $$ = new SymbolInfo(makeSymbolName({$1 , $2 , $3 }), "EXPRESSION") ;
                printinlogfile(logfile ,"expression 	: variable ASSIGNOP logic_expression 		 ") ; 


                 $$->set_dtype($1->get_dtype()) ; 
                 type = $1->get_dtype() ; 

                string actual_name; 
                //cout<<"name of array : "<<$1->getName()<<endl ; 
                int stop = 0 ; 
                for(int i = 0 ;i<$1->getName().size(); i++)
                {
                    
                    if($1->getName()[i] == '[' )
                        {
                             stop = i ; 
                             break ;
                        }
                   
                }
                actual_name = $1->getName().substr(0,stop) ; 
                //cout<<actual_name<<endl ; 


                
 
            SymbolInfo* info   ; 
                if(stop==0)
                   info = symboltable->LookUp($1->getName(),logfile); 
                else 
                 info = symboltable->LookUp(actual_name,logfile); 
                
                
                //cout<<"in line 1155  : "<<info->get_size()<<endl ; 
               
                if(info->get_size()!=-1)
                    write_code("\t POP AX")  ; 
                ////cout<<$3->getlogic()<<endl ; 
                //> for assembly (still nothing done)

                //. a = b ; 
                if($3->getlogic()==0)
                {
                    //* LOCAL VARIABLE 
                   if(info->checkifglobal()==0)
                            {
                                if(info->get_size()!=-1)
                                {
                                    write_code("\t POP BX");
                                    write_code("\t PUSH BP") ; 
                                    write_code("\t MOV BP , BX") ; 
                                    write_code("\t MOV [BP] , AX") ; 
                                    write_code("\t POP BP") ; 

                                   
                                }
                                else 
                                {
                                    write_code("\t POP AX"); // now AX has 5 
                                    if(info->getoffset()>=0)
                                    {
                                        write_code("\t MOV [BP - "+to_string(info->getoffset())+"] , AX") ; // local variable now has the popped value 5 , a = 5 ;  
                                    }
                                    else 
                                    {
                                        write_code("\t MOV [BP +"+to_string(-1*info->getoffset())+"] , AX") ; 
                                    }
                                    
                                    write_code("\t POP AX") ; // NOW AX FINALLY HAS THE VALUE AS AX = 5 ;
                                }
                                
                            }
                    else 
                            {
                                //- GLOBAL VARIABLE 
                            // write_code("\t PUSH "+$1->getName()+" ; "+$1->getName()+"Pushed into stack") ; 
                            // write_code("\t PUSH "+$3->getName()) ; 
                                if(info->get_size()!=-1)
                                {
                                    write_code("\t POP BX");
                                     write_code("\t MOV "+actual_name+"[BX] , AX") ;
                                     write_code("\t POP AX") ;
                                }
                                else 
                                {
                                write_code("\t POP AX") ; 
                                write_code("\t MOV "+$1->getName()+" , AX") ; 
                                write_code("\t POP AX ") ; 
                                }
                            }
                } //. a = b>c ---------- o = n || p 
                else 
                {
                    if($3->getandor()=="||")
                    {
                       string j_ne = newLabel() ; 
                       string flist = newLabel();  
                       string nxt = newLabel() ; 
                       write_code("\t "+j_ne+":") ; 
                       write_code("\t MOV AX , 1") ; 
                       write_code("\t JMP "+nxt) ; 
                       write_code("\t "+flist+":") ; 
                       write_code("\t MOV AX , 0") ; 
                       write_code("\t "+nxt+":") ; 
                       write_code("\t MOV [BP - "+to_string(info->getoffset())+"] , AX") ; 
                       write_code("\t POP AX") ; 

                      backpatch($3->get_truelist() , j_ne) ; 
                      backpatch($3->get_falselist() , flist) ; 


                    }
                    else if($3->getandor()=="&&")
                    {
                        string tlist = newLabel() ; 
                       string flist = newLabel();  
                       string nxt = newLabel() ; 
                          write_code("\t "+tlist+":") ; 
                       write_code("\t MOV AX , 1") ; 
                       write_code("\t JMP "+nxt) ; 
                       write_code("\t "+flist+":") ; 
                       write_code("\t MOV AX , 0") ; 
                       write_code("\t "+nxt+":") ; 
                       write_code("\t MOV [BP - "+to_string(info->getoffset())+"] , AX") ; 
                       write_code("\t POP AX") ; 
                      backpatch($3->get_truelist() , tlist) ; 
                      backpatch($3->get_falselist() , flist) ; 


                    }
                    else 
                    {
                    string l_true = newLabel() ; 
                    string l_false = newLabel() ; 
                    string n_jump = newLabel() ; 
                    write_code("\t "+l_true+":") ; 
                    write_code("PUSH 1") ; 
                    write_code("JMP "+n_jump) ; 
                    backpatch($3->get_truelist() , l_true) ; 

                    write_code("\t "+l_false+":") ; 
                    write_code("PUSH 0") ; 
                    backpatch($3->get_falselist() , l_false) ; 
                    write_code(n_jump+":");

                    write_code("\t POP AX ; has the value 0/1 ") ; 
                    //write_code("\t POP [BP - "+to_string(info->getoffset())+"] ; pop "+info->getName())  ;
                    write_code("\t MOV [BP - "+to_string(info->getoffset())+"] , AX") ; 
                    write_code("\t POP AX") ; 
                    }
                    
                    

                }
             
               
            
            
            } ; 
logic_expression : rel_expression 
            {

                $$ = new SymbolInfo(makeSymbolName({$1 }) ,"LOGIC_EXPRESSION") ;
                printinlogfile(logfile ,"logic_expression : rel_expression 	 ") ; 
                $$->set_dtype($1->get_dtype()) ; 
               // //cout<<"in line 1065 "<<$1->getlogic()<<endl ;



               $$->setlogic($1->getlogic()) ;  
              // //cout<<"calling true list"<<endl ;
                $$->set_tlist($1->get_truelist()) ; 
                 $$->set_flist($1->get_falselist()) ; 

            
            }
            |rel_expression LOGICOP M rel_expression
            {
                //cout<<"INSIDE LOGICOP"<<endl ; 
                //cout<<$1->get_truelist().size()<<" "<<$4->get_truelist().size()<<endl ; 
                //cout<<$1->get_falselist().size()<<" "<<$4->get_falselist().size()<<endl ; 
                //cout<<"*************"<<endl ; 
                $$ = new SymbolInfo(makeSymbolName({$1 , $2 , $4 }) , "LOGIC_EXPRESSION") ; 
                printinlogfile(logfile ,"logic_expression : rel_expression LOGICOP rel_expression 	 	 ")  ;  
                $$->set_dtype($1->get_dtype()) ; 
            
                if($1->get_dtype()=="VOID") 
                {
                    string msg = "Void cannot be used in expression " ;
                    yyerror(msg) ;
                    $1->set_dtype("") ; 
                }

                if($4->get_dtype()=="VOID") 
                {
                    string msg = "Void cannot be used in expression " ;
                    yyerror(msg) ;
                    $1->set_dtype("") ; 
                }


                //> Assembly code for assignment operation , this is for AND OR , Has not done yet 
                
                //- FOR BACK PATCHING 
                if($1->getlogic()==0 && $4->getlogic()==0)
                {
                    write_code("\t POP AX ; contains "+ $4->getName()) ; 
                    write_code("\t POP BX ; contains "+$1->getName()) ;
                    write_code("\t CMP BX , 0") ; 
                if($2->getName()=="||")
                {
                    write_code("\t JNE ") ; //. Keeping empty label
                    $$->add_to_true_list(assembly_line_count)  ; 
                    write_code("\t CMP AX , 0") ; 
                    write_code("\t JNE ") ; 
                    $$->add_to_true_list(assembly_line_count)  ; 
                    write_code("\t JMP") ; 
                    $$->add_to_false_list(assembly_line_count) ; 
                }
                else if($2->getName()=="&&")
                {  
                    string cmp2ndtime = newLabel()  ; 
                    write_code("\t JNE "+cmp2ndtime) ; //. Keeping empty label
                    write_code("\t JMP") ; 
                    $$->add_to_false_list(assembly_line_count)  ; 
                    write_code("\t "+cmp2ndtime+":") ; 
                    write_code("\t CMP AX , 0") ; 
                    write_code("\t JNE ") ; 
                    $$->add_to_true_list(assembly_line_count)  ; 
                    write_code("\t JMP ") ; 
                    $$->add_to_false_list(assembly_line_count) ; 
               }

              }
              else 
              {
                        
                    write_code("\t POP AX ; contains "+ $4->getName()) ; 
                    write_code("\t POP BX ; contains "+$1->getName()) ;
                    if($2->getName()=="&&")
                    {
                        string m_instr = $3->getlabel() ; 
                        $$->set_tlist($4->get_truelist()) ;
                        $$->set_flist(merge($1->get_falselist() , $4->get_falselist())) ; 
                        backpatch($1->get_truelist() , m_instr) ; 
                    }
                    else  if($2->getName()=="||")
                    {
                        string m_instr = $3->getlabel() ; 
                        $$->set_flist($4->get_falselist()) ;
                        $$->set_tlist(merge($1->get_truelist() , $4->get_truelist())) ; 
                        backpatch($1->get_falselist() , m_instr) ; 
                    }
            
              }
               
       
             

               $$->setlogic(true) ; 
               $$->setandor($2->getName()) ; 
               
            } ; 
M   : {
    $$ = new SymbolInfo("m" , "" )  ;
    string m_instr = newLabel() ; 
   write_code(m_instr+":") ; 
    $$->setlabel(m_instr) ; 
}
rel_expression : simple_expression
            {
               
                $$ = new SymbolInfo(makeSymbolName({$1 }) ,"REL_EXPRESSION") ;
                printinlogfile(logfile ,"rel_expression	: simple_expression ") ; 
                $$->set_dtype($1->get_dtype()) ;
                //cout<<"in line 1406"<<$1->getName()<<endl ;
                $$->setlogic($1->getlogic()) ;  //> ayo
                $$->set_tlist($1->get_truelist()) ; 
                $$->set_flist($1->get_falselist()) ; 

              
            }
            | simple_expression RELOP simple_expression
            {
               
                $$ = new SymbolInfo(makeSymbolName({$1 , $2 , $3 }) , "REL_EXPRESSION") ; 
                //cout<<"In line 1417 "<<$$->getName()<<endl ; 
                printinlogfile(logfile ,"rel_expression	: simple_expression RELOP simple_expression	  ") ;   
                $$->set_dtype($1->get_dtype()) ;  
                   if($1->get_dtype()=="VOID") 
                {
                    string msg = "Void cannot be used in expression " ;
                    yyerror(msg) ;
                    $1->set_dtype("") ; 
                }

                if($3->get_dtype()=="VOID") 
                {
                    string msg = "Void cannot be used in expression " ;
                    yyerror(msg) ;
                    $1->set_dtype("") ; 
                }
                // here we evaluate the value of relational expression 
                // will be later used in condition checking 
                //> part of set logic false is in comment ;  
                write_code("\t POP BX ; BX has the value of "+$3->getName()) ; 
                write_code("\t POP CX ; CX has the value of "+$1->getName());
                write_code("\t CMP CX , BX ") ; 
                ////cout<<"current line : "<<assembly_line_count<<endl ; 
                //? comparing done , at first it will go to truelist 
                write_code("\t "+DecodeRelop($2->getName())) ; //! gap to backpatch later 
                $$->add_to_true_list(assembly_line_count) ; 
                write_code("\t JMP") ; //! gap to backpatch later to false 
                $$->add_to_false_list(assembly_line_count) ; 
                $$->setlogic(true) ;

                //cout<<"INSIDE RELOP"<<endl ; 
                //cout<<$$->get_truelist().size()<<" "<<$$->get_truelist().size()<<endl ; 
                //cout<<$$->get_falselist().size()<<" "<<$$->get_falselist().size()<<endl ; 
                //cout<<"*************"<<endl ; 
               ////cout<<"in line 1167"<<$$->getlogic()<<endl ; 







            } ; 
          
simple_expression : term 
            {
              $$ = new SymbolInfo(makeSymbolName({$1 }) ,"SIMPLE_EXPRESSION") ;
                printinlogfile(logfile ,"simple_expression : term ") ;  
               $$->set_dtype($1->get_dtype()) ; 
                $$->setlogic($1->getlogic()) ;  //> ayo
                $$->set_tlist($1->get_truelist()) ; 
                $$->set_flist($1->get_falselist()) ; 
                

            }
            |simple_expression ADDOP term
            {

               
                $$ = new SymbolInfo(makeSymbolName({$1 , $2 , $3}) , "SIMPLE_EXPRESSION") ; 
                printinlogfile(logfile ,"simple_expression : simple_expression ADDOP term  ")  ;
                if($1->get_dtype()=="VOID")
                {
                     string msg = "Void cannot be used in expression " ;
                    yyerror(msg) ;
                    $1->set_dtype("") ; 
                }
                if($3->get_dtype()=="VOID")
                {
                     string msg = "Void cannot be used in expression " ;
                    yyerror(msg) ;
                    $3->set_dtype("") ; 
                }
                if($1->get_dtype()=="FLOAT" || $3->get_dtype()=="FLOAT")
                    $$->set_dtype("FLOAT") ; 
                else 
                    $$->set_dtype($1->get_dtype()) ; 


                



                //> Assembly code (not done anything yet)
                write_code("\t POP BX ; BX has value "+$3->getName()) ; //as bottom up parsing , term was last evaluated (consider tree)
                write_code("\t POP AX ; AX has value "+$1->getName()) ; 
                if($2->getName()=="+") write_code("\t ADD AX , BX ; AX has value "+$1->getName()+"+"+$3->getName()) ; // CX and AX add and then stored in CX 
                else if($2->getName()=="-") write_code("\t SUB AX , BX; AX has value "+$1->getName()+"-"+$3->getName()) ;
                write_code("\t PUSH AX ; AX = AX addop BX") ; //output pushed in AX , so that it can do associative operation 
            
            } ; 
 term : unary_expression
            {
              
             $$ = new SymbolInfo(makeSymbolName({$1 }) ,"TERM") ;
             printinlogfile(logfile ,"term :	unary_expression ") ;   
            $$->set_dtype($1->get_dtype()) ; 
             $$->setlogic($1->getlogic()) ;  //> ayo
                $$->set_tlist($1->get_truelist()) ; 
                $$->set_flist($1->get_falselist()) ; 
            
                
            }
            | term MULOP unary_expression
            {
               
                $$ = new SymbolInfo(makeSymbolName({$1 , $2 , $3 }) ,  "TERM") ; 
                printinlogfile(logfile ,"term :	term MULOP unary_expression ")  ;
                if($1->get_dtype()=="VOID")
                {
                     string msg = "Void cannot be used in expression " ;
                    yyerror(msg) ;
                    $1->set_dtype("") ; 
                }
                if($3->get_dtype()=="VOID")
                {
                     string msg = "Void cannot be used in expression " ;
                    yyerror(msg) ;
                    $3->set_dtype("") ; 
                }
                if( $2->getName() =="%")   
                {
                    if(($1->get_dtype()=="INT" && $3->get_dtype()=="INT")) {}
                    else 
                    {
                      
                    string msg = "Operands of modulus must be integers "; 
                    yyerror(msg) ; 
                    $$->set_dtype("INT") ;
                    }
                   

                } 
                else  if( $2->getName() =="%" &&($1->get_dtype()!="FLOAT" && $3->get_dtype()!="FLOAT"))
                {$$->set_dtype("FLOAT") ;}
                else {$$->set_dtype($1->get_dtype()) ;}




                if($3->getName()=="0" && ($2->getName()=="/" || $2->getName() =="%")) 
                {
                    string msg = "Warning: division by zero i=0f=1Const=0"; 
                    yyerror(msg) ; 
                }

                //> Assmebly 
                //? imul BX , do DX:AX = BX * AX 
                //? idiv BX , DX has reminder , AX has quotient 
                string op = $2->getName() ; 
                write_code("\t POP BX ; pop the value "+$3->getName()) ; 
                write_code("\t POP AX; pop the value "+$1->getName()) ; 
                if(op=="*")
                {
                    write_code("\t CWD") ; 
                    write_code("\t IMUL BX"); 
                } 
                else 
                {
                    write_code("\t XOR DX , DX") ; 
                    write_code("\t IDIV BX") ; 
                    if(op=="%")
                    {
                        write_code("\t MOV AX , DX") ;
                    }
                }
                write_code("\t PUSH AX") ; 




            } ; 
unary_expression : ADDOP unary_expression 
            {
                
                $$ = new SymbolInfo(makeSymbolName({$1 , $2 }) , "UNARY_EXPRESSION") ; 
                printinlogfile(logfile ,"unary_expression : ADDOP unary_expression  ")  ;
                 if($2->get_dtype()=="VOID")
                {
                    string msg = "Void cannot be used in expression " ;
                    yyerror(msg) ; 

                    $$->set_dtype("") ; 
                }
                else $$->set_dtype($2->get_dtype()) ;

                //> Assembly 
                //? pop the last used value in a reg , if +a , then don't care , but if -a , then neg that value and store 
                if($1->getName()=="-")
                {
                           write_code("\t POP AX") ; 
                            write_code("\t NEG AX") ; 
                            write_code("\t PUSH AX") ; 
                }
             

            
            }
            | NOT unary_expression
            {
                 $$ = new SymbolInfo(makeSymbolName({$1 , $2 }) ,  "UNARY_EXPRESSION") ; //CHECK
                printinlogfile(logfile ,"unary_expression : NOT unary_expression  ")  ;
                if($2->get_dtype()=="VOID")
                {
                    string msg = "Void cannot be used in expression " ;
                    yyerror(msg) ; 
                    
                }
                $$->set_dtype("INT")  ; 
                $$->setlogic(true) ; 
                if($2->getlogic()==0)
                {
                    write_code("\t POP AX") ; 
                    write_code("\t CMP AX , 0 ")  ;
                    write_code("\t JE ") ; 
                    $2->add_to_true_list(assembly_line_count) ; 
                    write_code("\t JMP ") ;
                    $2->add_to_false_list(assembly_line_count) ; 

                }
                $$->set_tlist($2->get_truelist()) ;
                $$->set_flist($2->get_falselist()) ;


            }
            |factor
            {
                $$ = new SymbolInfo(makeSymbolName({$1}) ,"UNARY_EXPRESSION") ;
                printinlogfile(logfile ,"unary_expression : factor ") ;
                $$->set_dtype($1->get_dtype())  ; 

                $$->setlogic($1->getlogic()) ;  //> ayo
                $$->set_tlist($1->get_truelist()) ; 
                $$->set_flist($1->get_falselist()) ; 


            } ; 
factor: variable {
                
                $$ = new SymbolInfo(makeSymbolName({$1 }) ,"FACTOR") ; 
                $$->set_dtype($1->get_dtype())     ; 


                string actual_name; 
                int stop = 0 ; 
                for(int i = 0 ;i<$1->getName().size(); i++)
                {
                    
                    if($1->getName()[i] == '[' )
                        {
                             stop = i ; 
                             break ;
                        }
                   
                }
                actual_name = $1->getName().substr(0,stop) ; 
                



                SymbolInfo* demo ; 
                if(stop==0)
                demo = symboltable->LookUp($1->getName() , logfile) ; 
                else demo=symboltable->LookUp(actual_name , logfile) ; 
                if(demo!=NULL)
                    {
                        cout<<demo->get_size()<<" "<<demo->getName()<<endl ; 
                    if(demo->get_size()>0)
                    {
                        write_code("\t POP BX") ; 
                    }

                }
                else cout<<$1->getName()<<endl ; 
                

                }
                 |ID LPAREN argument_list RPAREN
                 {
                 
                    $$ = new SymbolInfo(makeSymbolName({$1 , $2 , $3 , $4}), "FUNCTION_CALL") ; //CHECK
                    printinlogfile(logfile ,"factor	: ID LPAREN argument_list RPAREN  ")  ;
                    SymbolInfo* info = symboltable->LookUp($1->getName(),logfile); 
                    if(info==NULL)
                    {
                        string msg = "Undeclared function '"+$1->getName()+"'" ; 
                        yyerror(msg) ; 
                         $$->set_dtype("") ; 
                    }
                    else if(info->isdef()!=true)
                    { 
                        string msg = "Undefined function '"+$1->getName()+"'" ;  //DO WE HAVE ? 
                        yyerror(msg) ; 
                        $$->set_dtype("FLOAT") ;
                        
                    } 
                    else 
                    {
                        if(info->get_paramcount()!=func_argument_list.size())
                        {
                          
                            if(info->get_paramcount() > func_argument_list.size())
                            {
                                string msg ="Too few arguments to function '"+$1->getName()+"'" ;
                                yyerror(msg) ; 
                                
                            }
                            else if(info->get_paramcount() < func_argument_list.size())
                            {
                                string msg ="Too many arguments to function '"+$1->getName()+"'" ;
                                yyerror(msg) ; 
                            }
                        }
                        else 
                        {
                            vector<int>problem ; 
                            int pc =0 ; 
                        
                            for(int i=0 ; i<func_argument_list.size() ; i++)
                            {
                                string matchchecker = "" ; 
                                if(func_argument_list[i]=="CONST_INT") matchchecker="INT" ; 
                                else if (func_argument_list[i]=="CONST_FLOAT") matchchecker="FLOAT" ;
                                else matchchecker=func_argument_list[i] ; 
                                if(convert_to_uppercase(info->get_param(i).parameter_dtype) !=matchchecker)  
                                {
                                
                                    problem.push_back(i+1);
                                    pc++ ; 
                                }
                            }
                            for(int j=0 ; j<pc ; j++)
                            {
                               // string msg = "Type mismatch for argument "+to_string(problem[j])+" of '"+$1->getName()+"'" ;
                                //yyerror(msg) ; 
                            }
                             $$->set_dtype(info->get_dtype())  ; 
                             $1->set_dtype(info->get_dtype())  ; 
             
                        }
                    }
                    //. calling the function from source 
                    int storing_offset = offset ; 
                    write_code("\t call "+ $1->getName()) ; 
                    write_code("\t PUSH AX ") ; 
                    offset = storing_offset ; 

                  func_argument_list.clear()  ; 

                
                 }
                 |LPAREN expression RPAREN
                {
                    //(a>5)
                    $$ = new SymbolInfo(makeSymbolName({$1 , $2 , $3 }),"FACTOR"  ) ; //CHECK
                    printinlogfile(logfile ,"factor	: LPAREN expression RPAREN   ")  ;

                    $$->setlogic(true) ; 
                    if($2->getlogic()==0)
                    {
                        write_code("\t POP AX") ; 
                        write_code("\t CMP AX , 0 ")  ;
                        write_code("\t JNE ") ; 
                        $2->add_to_true_list(assembly_line_count) ; 
                        write_code("\t JMP ") ;
                        $2->add_to_false_list(assembly_line_count) ; 

                    }
                    $$->set_tlist($2->get_truelist()) ;
                    $$->set_flist($2->get_falselist()) ;


               
                if($2->get_dtype()=="VOID")
                {
                     string msg = "Void cannot be used in expression " ;
                    yyerror(msg) ; 
                    
                    $$->set_dtype("") ;
                }

                }
                |CONST_INT
                {
               
                $$ = new SymbolInfo(makeSymbolName({$1  }) ,"CONST_INT"  ) ;
                printinlogfile(logfile ,"factor	: CONST_INT   ") ; 
                 $$->set_dtype("INT") ; 

                 //? For a = 5 , we get factor can be const_int , pushing the 5 in stack and then will pop and merge 
                 write_code("\t PUSH "+$1->getName()+";"+$1->getName()+" is pushed into the stack") ; 

                }
                |CONST_FLOAT
                {
                $$ = new SymbolInfo(makeSymbolName({$1 }) ,"CONST_FLOAT"  ) ;
                printinlogfile(logfile ,"factor	: CONST_FLOAT   ") ; 
                  $$->set_dtype("FLOAT") ; 

                }
                |variable INCOP
                {
                $$ = new SymbolInfo(makeSymbolName({$1 , $2 }) ,"FACTOR"  ) ; 
                printinlogfile(logfile ,"factor	: variable INCOP   ")  ;
                $$->set_dtype($1->get_dtype()) ;

                SymbolInfo* info = symboltable->LookUp($1->getName(),logfile); 
                
                //! if they are not array 
                if(info->checkifglobal()==0)
                {
                    //> local variable , doing for only variable now , not array 
                    write_code("\t POP AX") ; 
                    write_code("\t PUSH AX") ; 
                    write_code("\t INC AX ; incrementing the value of "+$1->getName());
                    if(info->getoffset()>=0)
                    {
                        write_code("\t MOV [BP-"+to_string(info->getoffset())+"] , AX") ; 
                    }
                    else 
                    {
                        write_code("\t MOV [BP+"+to_string(-1*info->getoffset())+"] , AX"); 
                    }

                }
                else 
                {
                     write_code("\t POP AX"); 
                     write_code("\t PUSH AX") ; 
                     write_code("\t INC AX ; incrementing the value of "+$1->getName()) ;
                     write_code("\t MOV "+$1->getName()+" , AX ; storing the incremented value in global variable") ; 

                }
                //write_code("\t POP AX") ;  //!WARNING

                }
                |variable DECOP
                {
                $$ = new SymbolInfo(makeSymbolName({$1 , $2 }) ,"FACTOR"  ) ; 
                printinlogfile(logfile ,"factor	: variable DECOP   ")  ;
                $$->set_dtype($1->get_dtype()) ; 
                
                
                 SymbolInfo* info = symboltable->LookUp($1->getName(),logfile); 
                
                //! if they are not array 
                 if(info->checkifglobal()==0)
                {
                    //> local variable , doing for only variable now , not array 
                    write_code("\t POP AX") ; 
                    write_code("\t PUSH AX") ; 
                    write_code("\t DEC AX ; decrementing the value of "+$1->getName());
                    if(info->getoffset()>=0)
                    {
                          write_code("\t MOV [BP-"+to_string(info->getoffset())+"] , AX") ; 
                    }
                    else 
                    {
                          write_code("\t MOV [BP+"+to_string(-1*info->getoffset())+"] , AX"); 
                    }
                  

                }
                else 
                {
                     write_code("\t POP AX"); 
                     write_code("\t PUSH AX") ; 
                     write_code("\t DEC AX ; decrementing the value of "+$1->getName()) ;
                     write_code("\t MOV "+$1->getName()+" , AX ; storing the incremented value in global variable") ; 

                }
             //   write_code("\t POP AX") ; //!WARNING
                }; 
argument_list : arguments 
                {
                $$ = new SymbolInfo(makeSymbolName({$1 }) ,"ARGUMENT_LIST"  ) ;
                printinlogfile(logfile ,"argument_list : arguments  ") ; 

                }
                |
                {
                $$ = new SymbolInfo("" ,"ARGUMENT)LIST" ) ; 
                printinlogfile(logfile ,"argument_list :")  ;
                } ;
arguments : arguments COMMA logic_expression
                {
                $$ = new SymbolInfo(makeSymbolName({$1 , $2 , $3 }) ,"ARGUMENTS"  ) ; 
                printinlogfile(logfile ,"arguments : arguments COMMA logic_expression ")  ;

                
                //  the logic expression part can't be void 
             if($3->get_dtype()=="VOID")
                {
                    string msg = "Void cannot be used in expression " ;
                    yyerror(msg) ; 
                    $1->set_dtype("") ; //for further recovery setting it to float . 
                }
                 else 
                {
                    $1->set_dtype($3->get_dtype()) ; 
                }
                
                
                func_argument_list.push_back($1->get_dtype()) ;  



  
                }
                |logic_expression
                {
                $$ = new SymbolInfo(makeSymbolName({$1 }) ,$1->getType()  ) ;
                printinlogfile(logfile ,"arguments : logic_expression") ; 


  if($1->get_dtype()=="VOID")
                {
                    string msg = "Void cannot be used in expression " ;
                    yyerror(msg) ; 
                    $1->set_dtype("") ; 
                }
                else 
                {
                    $1->set_dtype($1->get_dtype()) ; 
                }

                func_argument_list.push_back($1->get_dtype()) ;  


                } ;
%%
int main(int argc , char* argv[])
{
    int scope_id = 1 ;
    int bucket_size = 11; 
    if(argc<2){
        ////cout<<"Input file not found"<<endl ;
        return 1 ;
    }


    logfile.open("log.txt") ; 
    errorfile.open("error.txt") ;
    parsefile.open("parsetree.txt"); //name fixed according to spec. 
    //parsefile<<"hl"<<endl ;



    a_code.open("1905067assembly.asm") ; 
    init_segment() ; 
  
    symboltable->Enter_scope(scope_id++ , bucket_size);
    yyin = NULL ; 
    yyin = fopen(argv[1] ,"r") ; 
    if( yyin == NULL) return 1 ;
    yyparse() ; 
    fclose(yyin) ; 
   


    print_int() ; 
    print_newline() ; 
    finishCode() ; 

     convert_backpatching() ; 

    logfile<<"Total Lines: "<<line_count<<endl ; 
    logfile<<"Total Errors: "<<error_count<<endl ;
    logfile.close() ; 
    errorfile.close(); 
    parsefile.close() ; 

       perform_optimzation()  ; 
    ////cout<<data_segment_endline<<endl ; 
    delete symboltable;

     return 0 ; 
     
}
void yyerror(string err)
{
    error_count++ ; 
    errorfile<<"Line# "<<line_count<<": "<<err<<""<<endl ; 
    
}
void printinlogfile(ofstream &log , string msg )
{
    logfile<<msg<<endl ; 
}
