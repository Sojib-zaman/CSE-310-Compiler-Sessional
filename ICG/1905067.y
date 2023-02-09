%{
#include<bits/stdc++.h>
#include<stdio.h>
#include<stdlib.h>
#include<fstream>
#include"1905067.h"
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
int temp_count = 0 ; 
int global_varcount = 0 ; 
int local_varcount = 0 ;
int offset = 0 ; 



//!helper functions for ICG 

//> creates a new label based on label_count 
char *newLabel()
{
	char *lb= new char[4];
	strcpy(lb,"L");
	char b[3];
	sprintf(b,"%d", label_count);
	label_count++;
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

//> starts the assembly code segment 
void init_segment()
{
    a_code<<".MODEL SMALL"<<endl<<".STACK 100H"<<endl<<".DATA"<<endl ; 
}





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

string convert_to_uppercase(string x)
{
    for(int i=0 ; x[i] ; i++)x[i] = toupper(x[i]) ; 
    return x ;
}
void variable_insert(string type , var var_not_param)
{

    SymbolInfo* info = new SymbolInfo(var_not_param.var_name , convert_to_uppercase(type)) ; 
    if(var_not_param.isarraytype!="ARRAY")
        {
           
            info->set_dtype(convert_to_uppercase(type)) ; 
        } 
    else 
        {
           
            info->setType(convert_to_uppercase(type)) ;
            info->set_dtype("ARRAY") ;
        }

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



void ParseLineRelated(SymbolInfo* ss , SymbolInfo* start , SymbolInfo* End)
{
    ss->setStartingLine(start->getStartingLine()) ; 
    ss->setEndingLIne(End->getEndingLine()) ; 
} 
void ParseChildRelated(SymbolInfo* ss , vector<SymbolInfo*>ListOfChildren)
{
    if(ss->getType()=="PROGRAM") 
    {
        for(SymbolInfo* info : ListOfChildren)
            {
                ////cout<<info->getparseline()<<endl;
            }
    }
   ss->addmultiplechildren(ListOfChildren) ; 
    ss->setleaf(false) ; 
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
%type <symbol> start program unit func_declaration func_definition parameter_list compound_statement var_declaration type_specifier
%type <symbol> non_term_for_func declaration_list statements statement expression_statement variable expression logic_expression rel_expression simple_expression term unary_expression factor argument_list arguments 

%nonassoc LOWER_THAN_ELSE 
%nonassoc ELSE 
%%
start : program {  
                    $$=new SymbolInfo(makeSymbolName({$1}),"START");

                    
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
                        
                         $$ = new SymbolInfo(makeSymbolName({$1 , $2 , $4 , $5 , $6 , $8}),"FUNC_DEFINITION") ; 
                         
                        }
                        |type_specifier non_term_for_func ADDT LPAREN RPAREN ADDT_DEF compound_statement
                        {
                      
                         $$ = new SymbolInfo(makeSymbolName({$1 , $2 , $4 , $5 , $7 }),"FUNC_DEFINITION") ;  
                         

                         
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
   // //cout<<"SCOPE ID LINE 428:"<<scope_id<<endl ;
    symboltable->Enter_scope(scope_id , bucket_size) ; 
     
    if(parameter_list.size()==1 && parameter_list[0].parameter_type=="void"){}
    else 
    {
        for(int i=0 ; i<parameter_list.size() ; i++)
        {
           
            demo_var.var_name = parameter_list[i].parameter_name ; 
            demo_var.variable_size = -1  ; //so its a variable 
            variable_insert(parameter_list[i].parameter_type , demo_var ) ;
        }
    }
    parameter_list.clear();

}
var_declaration:   type_specifier declaration_list SEMICOLON
                        {
                            //NEW RULE STARTS 
                            // int a,v,c,x ;
                         $$ = new SymbolInfo(makeSymbolName({$1 , $2 , $3  }),"VAR_DECLARATION") ;
                         printinlogfile(logfile ,"var_declaration : type_specifier declaration_list SEMICOLON  ") ;  
                       
                         if($1->getName()=="void")
                         { 
                            // void a is not valid ; 
                            string msg = "Variable or field '"+$2->getName()+"' declared void" ;
                            yyerror(msg) ; 

                         }
                         else 
                         {
                            // it not void , then add (int/float/... , a(-1)) 
                            string sname = $1->getName()  ;  //in declaration list , we are storing the variables 
                            for(int i =0 ; i<var_list.size() ; i++)
                                 variable_insert(sname, var_list[i]) ; 
                         }
                         var_list.clear() ; 

                         //ParseRelatedCodes    
                        $$->setParseString("var_declaration : type_specifier declaration_list SEMICOLON") ;                 
                        ParseLineRelated($$,$1,$3) ; 
                        vector<SymbolInfo*> ChildrenForParse ; 
                        ChildrenForParse.push_back($1);
                        ChildrenForParse.push_back($2);
                        ChildrenForParse.push_back($3);
                        ParseChildRelated($$ , ChildrenForParse) ;
                        } ; 
type_specifier :   INT
                {
                    type ="INT" ; //setting for function return type (visit embedded ADDT)
                    //NEW RULE STARTS
                    // int <- foo () , int <- a
                    $$ = new SymbolInfo(makeSymbolName({$1}), $1->getType()) ; // (int , INT) ; 
                    printinlogfile(logfile ,"type_specifier	: INT ") ;  
                    //parse related codes 
                    $$->setParseString("type_specifier : INT") ;                 
                    ParseLineRelated($$,$1,$1) ; 
                    vector<SymbolInfo*> ChildrenForParse ; 
                    ChildrenForParse.push_back($1);
                    ParseChildRelated($$ , ChildrenForParse) ;
                }    
                | FLOAT
                {
                    type ="FLOAT" ;
                    $$ = new SymbolInfo(makeSymbolName({$1 }), $1->getType()) ;
                    printinlogfile(logfile ,"type_specifier	: FLOAT ") ; 
                    //parse related codes 
                    $$->setParseString("type_specifier : FLOAT") ;                 
                    ParseLineRelated($$,$1,$1) ; 
                    vector<SymbolInfo*> ChildrenForParse ; 
                    ChildrenForParse.push_back($1);
                    ParseChildRelated($$ , ChildrenForParse) ;

                }
                | VOID
                {
                    type ="VOID" ;  //setting for function return type (visit embedded ADDT)
                    $$ = new SymbolInfo(makeSymbolName({$1 }), $1->getType()) ;
                    printinlogfile(logfile ,"type_specifier	: VOID") ; 
                    $$->setParseString("type_specifier : VOID") ;                 
                    ParseLineRelated($$,$1,$1) ; 
                    vector<SymbolInfo*> ChildrenForParse ; 
                    ChildrenForParse.push_back($1);
                    ParseChildRelated($$ , ChildrenForParse) ;
                }  ; 
non_term_for_func: ID 
        {
            //this is applicable for function purpose only 
             $$ = new SymbolInfo(makeSymbolName({$1 }), $1->getType()) ;
             name = $1->getName() ; 
             string msg = "ID : "+name ; 
             $$->setParseString(msg) ; 
            ParseLineRelated($$,$1,$1) ; // sets the starting and ending line  
             $$->setleaf(true) ;
        }    
declaration_list : declaration_list COMMA ID 
                        {
                         //NEW RULE STARTS 
                         // a, b,c, d 
                         $$ = new SymbolInfo(makeSymbolName({$1 , $2 , $3}) ,"DECLARATION_LIST") ;
                         printinlogfile(logfile ,"declaration_list : declaration_list COMMA ID  ") ; 
                         
                        
                         // VCHECK , error only ignore right ? 

                        
                        //cout<<" DECL ERROR "<<$3->getName() <<endl ; 

                        //ParseRelatedCodes
                        $$->setParseString("declaration_list : declaration_list COMMA ID") ;   
                        ParseLineRelated($$,$1,$3) ; 
                        vector<SymbolInfo*> ChildrenForParse ; 
                        ChildrenForParse.push_back($1);
                        ChildrenForParse.push_back($2);
                        ChildrenForParse.push_back($3);
                        ParseChildRelated($$ , ChildrenForParse) ;
                         
                        //check if already declared before with the same name 
                       
                        demo_var.var_name = $3->getName() ; 
                         demo_var.variable_size = -1 ; //applicable for all variables 
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

                         // demo var here ? or insert always ? 

                        }

                        for(int i=0 ; i<var_list.size() -1 ; i++) 
                        {
                                //cout<<$3->getName()<<" "<<var_list[i].var_name<<endl ; 
                            if($3->getName()==var_list[i].var_name)
                            {
                                //cout<<"here"<<endl ; 
                                //cout<<$3->getName()<<" "<<var_list[i].var_name<<endl ; 
                                string msg = "Redefination of variable name '"+$3->getName()+"'" ;  //MODIFIED 
                                yyerror(msg) ;
                            }
                        }
                        
                        }
                        | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
                        {
                         // a,b,c,d[39]
                         $$ = new SymbolInfo(makeSymbolName({$1 , $2 , $3 , $4 , $5 , $6}),"DECLARATION_LIST") ;
                         printinlogfile(logfile ,"declaration_list : declaration_list COMMA ID LSQUARE CONST_INT RSQUARE ") ; //according to logfile
                        
                        
                         demo_var.var_name = $3->getName() ; 
                         demo_var.isarraytype = "ARRAY";

                         ////cout<<"l 641 :"<<demo_var.isarraytype<<endl ; 

                         string len = $5->getName() ; 
                         demo_var.variable_size = stoi(len) ; 
                        // //cout<<"line 628"<<endl ; 
                        // //cout<<demo_var.variable_size<<endl ; 
                         var_list.push_back(demo_var) ; 

                         demo_var.isarraytype = ""; //clearing the value for others (won't be used again)
                        //check if already declared before with the same name 
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
                             //cout<<$3->getName()<<" "<<var_list[i].var_name<<endl ; 
                            if($3->getName()==var_list[i].var_name)
                            {
                                //cout<<"here"<<endl ; 
                                //cout<<$3->getName()<<" "<<var_list[i].var_name<<endl ; 
                                string msg = "Redefination of variable name '"+$3->getName()+"'" ;  //MODIFIED 
                                yyerror(msg) ;
                            }
                        }

                        

                        //ParseRelatedCodes
                        $$->setParseString("declaration_list : declaration_list COMMA ID LSQUARE CONST_INT RSQUARE") ;   
                        ParseLineRelated($$,$1,$6) ; 
                        vector<SymbolInfo*> ChildrenForParse ; 
                        ChildrenForParse.push_back($1);
                        ChildrenForParse.push_back($2);
                        ChildrenForParse.push_back($3);
                        ChildrenForParse.push_back($4);
                        ChildrenForParse.push_back($5);
                        ChildrenForParse.push_back($6);
                        ParseChildRelated($$ , ChildrenForParse) ;




                        }
                        |ID
                        {
                            //a
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


                        // int a , b , c , b ; 
                        // for this error , we have to check the varlist to find error 
                        for(int i=0 ; i<var_list.size() -1  ; i++)
                        {
                            
                             ////cout<<$1->getName()<<" "<<var_list[i].var_name<<endl ; 
                            if($1->getName()==var_list[i].var_name)
                            {
                                ////cout<<"here"<<endl ; 
                                ////cout<<$1->getName()<<" "<<var_list[i].var_name<<endl ; 
                                string msg = "Redefination of variable name '"+$1->getName()+"'" ;  //MODIFIED 
                                yyerror(msg) ;
                            }
                        }

                        //ParseRelatedCodes
                        $$->setParseString("declaration_list : ID") ;   
                        ParseLineRelated($$,$1,$1) ; 
                        vector<SymbolInfo*> ChildrenForParse ; 
                        ChildrenForParse.push_back($1);
                        ParseChildRelated($$ , ChildrenForParse) ;





                        }
                        |ID LTHIRD CONST_INT RTHIRD
                        {
                            //a[4]
                        $$ = new SymbolInfo(makeSymbolName({$1 , $2 , $3 , $4}),"DECLARATION_LIST") ;
                        printinlogfile(logfile ,"declaration_list : ID LSQUARE CONST_INT RSQUARE ") ; 
                       
                        demo_var.var_name = $1->getName() ; 
                        demo_var.isarraytype = "ARRAY";
                        string len = $3->getName() ; 
                        demo_var.variable_size = stoi(len) ; 
                      //  //cout<<"line 628"<<endl ; 
                      //  //cout<<demo_var.variable_size<<endl ; 
                        var_list.push_back(demo_var) ; 
                        demo_var.isarraytype = ""; //clearing the value for others (won't be used again)
                         SymbolInfo* x = symboltable->LookUp($1->getName() , logfile) ;
                        if(x!=NULL)
                        {
                            if(symboltable->getscopeID(x->getName() , logfile) == symboltable->currScopeID())
                         {
                            string msg = "Conflicting types for'"+$1->getName()+"'" ; 
                            yyerror(msg) ;
                         }
                        }


                        // int a , b , c , b ; 
                        // for this error , we have to check the varlist to find error 
                        for(int i=0 ; i<var_list.size()  -1 ; i++)
                        {
                            
                                    ////cout<<$1->getName()<<" "<<var_list[i].var_name<<endl ; 
                            if($1->getName()==var_list[i].var_name)
                            {
                                    ////cout<<"here"<<endl ; 
                                ////cout<<$1->getName()<<" "<<var_list[i].var_name<<endl ; 
                                string msg = "Redefination of variable name '"+$1->getName()+"'" ;  //MODIFIED 
                                yyerror(msg) ;
                            }
                        }


                         //ParseRelatedCodes
                        $$->setParseString("declaration_list : ID LSQUARE CONST_INT RSQUARE") ;   
                        ParseLineRelated($$,$1,$4) ; 
                        vector<SymbolInfo*> ChildrenForParse ; 
                        ChildrenForParse.push_back($1);
                        ChildrenForParse.push_back($2);
                        ChildrenForParse.push_back($3);
                        ChildrenForParse.push_back($4);
                        ParseChildRelated($$ , ChildrenForParse) ;
                        
                        
                        
                        } ; 
statements : statement {
                        //NEW RULE STARTS 
                        //consider your code inside {}
                        $$ = new SymbolInfo(makeSymbolName({$1}),"STATEMENT") ;
                        printinlogfile(logfile ,"statements : statement  ") ; 

                        //ParseRelatedCodes
                        $$->setParseString("statements : statement");
                        ParseLineRelated($$,$1,$1) ; 
                        vector<SymbolInfo*> ChildrenForParse ; 
                        ChildrenForParse.push_back($1);
                        ParseChildRelated($$ , ChildrenForParse) ;
                       }
                        | statements statement 
                        { 
                         $$ = new SymbolInfo(makeSymbolName({$1 , $2}),"STATEMENTS") ;
                         printinlogfile(logfile ,"statements : statements statement  ") ; 

                        //ParseRelatedCodes
                        $$->setParseString("statements : statements statement");
                        ParseLineRelated($$,$1,$2) ; 
                        vector<SymbolInfo*> ChildrenForParse ; 
                        ChildrenForParse.push_back($1);
                        ChildrenForParse.push_back($2);
                        ParseChildRelated($$ , ChildrenForParse) ;

                        }
statement : var_declaration {  
                        // int a , int b ; 
                        //new line else amb
                        $$ = new SymbolInfo(makeSymbolName({$1 }),"STATEMENT") ;
                        printinlogfile(logfile ,"statement : var_declaration ") ; 
                        //ParseRelatedCodes
                        $$->setParseString("statement : var_declaration");
                        ParseLineRelated($$,$1,$1) ; 
                        vector<SymbolInfo*> ChildrenForParse ; 
                        ChildrenForParse.push_back($1);
                        ParseChildRelated($$ , ChildrenForParse) ;



                        }
                        |expression_statement { //a=b+c;
                        $$ = new SymbolInfo(makeSymbolName({$1 }),"STATEMENT") ;
                        printinlogfile(logfile ,"statement : expression_statement  ") ; 

                        //ParseRelatedCodes
                        $$->setParseString("statement : expression_statement");
                        ParseLineRelated($$,$1,$1) ; 
                        vector<SymbolInfo*> ChildrenForParse ; 
                        ChildrenForParse.push_back($1);
                        ParseChildRelated($$ , ChildrenForParse) ;



                        } 
                        | compound_statement { 
                        //{c=a+b}
                        $$ = new SymbolInfo(makeSymbolName({$1}),"STATEMENT") ;
                        printinlogfile(logfile ,"statement : compound_statement ") ; 
                        //ParseRelatedCodes
                        $$->setParseString("statement : compound_statement");
                        ParseLineRelated($$,$1,$1) ; 
                        vector<SymbolInfo*> ChildrenForParse ; 
                        ChildrenForParse.push_back($1);
                        ParseChildRelated($$ , ChildrenForParse) ;
                        }
                        |FOR LPAREN expression_statement ADDT_EXP ADDT_VOID expression_statement ADDT_EXP ADDT_VOID expression ADDT_EXP ADDT_VOID RPAREN statement
                        {
                            //expression does not have any ; which ES does 
                            // for(a=3; <---  a<5 ;  <--- a++ <---- ){}
                            
                        $$ = new SymbolInfo(makeSymbolName({$1 , $2 , $3 , $6 , $9 , $12 , $13}),"FOR_LOOP") ; //CHECK
                        printinlogfile(logfile ,"statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement") ;  
                        //ParseRelatedCodes
                        $$->setParseString("statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement");
                        ParseLineRelated($$,$1,$13) ; 
                        vector<SymbolInfo*> ChildrenForParse ; 
                        ChildrenForParse.push_back($1);
                        ChildrenForParse.push_back($2);
                        ChildrenForParse.push_back($3);
                        ChildrenForParse.push_back($6);
                        ChildrenForParse.push_back($9);
                        ChildrenForParse.push_back($12);
                        ChildrenForParse.push_back($13);
                        ParseChildRelated($$ , ChildrenForParse) ;  
                        }
                        |IF LPAREN expression ADDT_EXP RPAREN ADDT_VOID statement %prec LOWER_THAN_ELSE
                        {
                            //if(a<5<---) <---{}
                            //problem , have shift reduce conflict 
                            // shift ELSE or reduce the statement ?? 
                         
                            $$ = new SymbolInfo( makeSymbolName({$1 , $2 , $3 , $5 , $7 }),"IF") ; //CHECK
                            printinlogfile(logfile ,"statement : IF LPAREN expression RPAREN statement %prec THEN") ; // to make log same    
                            //ParseRelatedCodes
                            $$->setParseString("statement : IF LPAREN expression RPAREN statement");
                            ParseLineRelated($$,$1,$7) ; 
                            vector<SymbolInfo*> ChildrenForParse ; 
                            ChildrenForParse.push_back($1);
                            ChildrenForParse.push_back($2);
                            ChildrenForParse.push_back($3);
                            ChildrenForParse.push_back($5);
                            ChildrenForParse.push_back($7);
                            ParseChildRelated($$ , ChildrenForParse) ;  
                        
                        }
                        |IF LPAREN expression ADDT_EXP RPAREN ADDT_VOID statement ELSE statement
                        { 
                             //if(a<5<---) <---{} else {}

                               
                        $$ = new SymbolInfo( makeSymbolName({$1 , $2 , $3 , $5 , $7 , $8 , $9 }),"IF_ELSE") ; //CHECK
                        printinlogfile(logfile ,"statement : IF LPAREN expression RPAREN statement ELSE statement ") ;   
                        //ParseRelatedCodes
                        $$->setParseString("statement : IF LPAREN expression RPAREN statement ELSE statement");
                        ParseLineRelated($$,$1,$9) ; 
                        vector<SymbolInfo*> ChildrenForParse ; 
                        ChildrenForParse.push_back($1);
                        ChildrenForParse.push_back($2);
                        ChildrenForParse.push_back($3);
                        ChildrenForParse.push_back($5);
                        ChildrenForParse.push_back($7);
                        ChildrenForParse.push_back($8);
                        ChildrenForParse.push_back($9);
                        ParseChildRelated($$ , ChildrenForParse) ; 
                        }
                        |WHILE LPAREN expression ADDT_EXP RPAREN  ADDT_VOID statement
                        {
                            //while ( a<5 <----)<---- {}

                             
                        $$ = new SymbolInfo(makeSymbolName({$1 , $2 , $3 , $5 , $7}),"WHILE_LOOP") ; //CHECK
                        printinlogfile(logfile ,"statement : WHILE LPAREN expression RPAREN statement") ;   
                        //ParseRelatedCodes
                        $$->setParseString("statement : WHILE LPAREN expression RPAREN statement");
                        ParseLineRelated($$,$1,$7) ; 
                        vector<SymbolInfo*> ChildrenForParse ; 
                        ChildrenForParse.push_back($1);
                        ChildrenForParse.push_back($2);
                        ChildrenForParse.push_back($3);
                        ChildrenForParse.push_back($5);
                        ChildrenForParse.push_back($7);
                        ParseChildRelated($$ , ChildrenForParse) ; 
                        }
                        |PRINTLN LPAREN ID RPAREN SEMICOLON
                        {
                        // println(A)
                        $$ = new SymbolInfo(makeSymbolName({$1 , $2 , $3 , $4 , $5}),"PRINT") ; //CHECK
                        printinlogfile(logfile ,"statement : PRINTLN LPAREN ID RPAREN SEMICOLON ") ;  
                        //ParseRelatedCodes
                        $$->setParseString("statement : PRINTLN LPAREN ID RPAREN SEMICOLON");
                        ParseLineRelated($$,$1,$5) ; 
                        vector<SymbolInfo*> ChildrenForParse ; 
                        ChildrenForParse.push_back($1);
                        ChildrenForParse.push_back($2);
                        ChildrenForParse.push_back($3);
                        ChildrenForParse.push_back($4);
                        ChildrenForParse.push_back($5);
                        ParseChildRelated($$ , ChildrenForParse) ;
                        }
                        |RETURN expression SEMICOLON
                        {
                            //return a ; 
                        $$ = new SymbolInfo(makeSymbolName({$1 , $2 , $3 }),"RETURN") ; //CHECK
                        ////cout<<$3->getName()<<endl ; 
                        printinlogfile(logfile ,"statement : RETURN expression SEMICOLON") ; 
                        //ParseRelatedCodes
                        $$->setParseString("statement : RETURN expression SEMICOLON");
                        ParseLineRelated($$,$1,$3) ; 
                        vector<SymbolInfo*> ChildrenForParse ; 
                        ChildrenForParse.push_back($1);
                        ChildrenForParse.push_back($2);
                        ChildrenForParse.push_back($3);
                        ParseChildRelated($$ , ChildrenForParse) ; 
                        // we can not return void ;
                        if($2->getType()=="VOID") 
                        {
                           string msg = "Void cannot be used in expression " ;
                           yyerror(msg) ; 
                        }   
                        } ;
ADDT_EXP:
{
    // it works with expression statement and exp
    // when we write a=3 or a<5 or a++ 
 
    data_type = type ; 
   // //cout<<data_type<<endl ; 
}
ADDT_VOID :
{

    // caution : $ number 
    
    //check if we have void+4 / void<4 
    if(data_type=="VOID")
    {
        string msg = "Void cannot be used in expression " ;
        yyerror(msg) ; 
    }
}
expression_statement : SEMICOLON 
            {
              $$ = new SymbolInfo(makeSymbolName({$1 }) , $1->getType()) ;
              printinlogfile(logfile ,"expression_statement : SEMICOLON		") ;    
              
 
            $$->set_dtype($1->get_dtype()) ; 
            type = $1->get_dtype() ;
            

            //FOR PARSE TREE 
              $$->setParseString("expression_statement : SEMICOLON");
              ParseLineRelated($$,$1,$1) ; 
            vector<SymbolInfo*> ChildrenForParse ; 
            ChildrenForParse.push_back($1);
            ParseChildRelated($$ , ChildrenForParse) ;  

            }
            | expression SEMICOLON 
            {
            $$ = new SymbolInfo(makeSymbolName({$1 , $2 }) ,"EXPRESSION_STATEMENT") ;
            printinlogfile(logfile ,"expression_statement : expression SEMICOLON 		 ") ;    
            $$->setType($1->getType()) ; 
            type = $1->getType() ;

            //ParseRelatedCodes
            $$->setParseString("expression_statement : expression SEMICOLON");
            ParseLineRelated($$,$1,$2) ; 
            vector<SymbolInfo*> ChildrenForParse ; 
            ChildrenForParse.push_back($1);
             ChildrenForParse.push_back($2);
            ParseChildRelated($$ , ChildrenForParse) ;
            
            } ; 
variable : ID 
            {
                name = $1->getName() ; // setting up , for the function declaration or definition 
                // it will be the function name . 

                $$ = new SymbolInfo(makeSymbolName({$1}) ,"ID") ;
                //check if prev declared 
                printinlogfile(logfile ,"variable : ID 	 ") ; 
               
                  //ParseRelatedCodes
                $$->setParseString("variable : ID");
                ParseLineRelated($$,$1,$1) ; 
                vector<SymbolInfo*> ChildrenForParse ; 
                ChildrenForParse.push_back($1);
                ParseChildRelated($$ , ChildrenForParse) ;


       
                SymbolInfo* demo = symboltable->LookUp($1->getName() , logfile) ; 
                if(demo==NULL)//suppose we have not declared K . so it is not added in the variable list . Then we said K = 5 ; In such case K will not be found in the symbol table 
                {
                   string msg  = "Undeclared variable '"+$1->getName()+"'" ; 
                    yyerror(msg) ; 

                    $$->set_dtype("") ; 
                    
                }
                else 
                {
                     if(demo->get_dtype()!="VOID") $$->set_dtype(demo->get_dtype()) ;
                    else  $$->set_dtype("FLOAT") ; // not supposed to be void 
                }
                 
            }
            |ID LTHIRD expression RTHIRD
            {
                //array type variable
                $$ = new SymbolInfo(makeSymbolName({$1 , $2 , $3 , $4}),"ARRAY") ;
                printinlogfile(logfile ,"variable : ID LSQUARE expression RSQUARE  	 ") ; 
               
                SymbolInfo* x = symboltable->LookUp( $1->getName(), logfile) ;
                if(x==NULL) //suppose we have not declared K[8] . so it is not added in the variable list . Then we said K = 5 ; In such case K will not be found in the symbol table 
                {
                    string msg  = "Undeclared variable '"+$1->getName()+"'" ; 
                    yyerror(msg) ; 
                    $$->set_dtype("") ;
                }
                else // we used a[43] , now check if it is actually an array 
                {
                    //have to check if a[4] , where is an array or not 
                    ////cout<<x->get_size()<<endl ;
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

                // error if we say b[3.2]

              // BREAKPOINT : EXPRESSION DTYPE HOW DEFINED . 
              if($3->get_dtype() != "INT" && $3->get_dtype() != "CONST_INT")
              {
                string msg  = "Array subscript is not an integer" ;  
                    yyerror(msg) ;  
              }
              //ParseRelatedCodes
            $$->setParseString("variable : ID LSQUARE expression RSQUARE");
            ParseLineRelated($$,$1,$4) ; 
            vector<SymbolInfo*> ChildrenForParse ; 
            ChildrenForParse.push_back($1);
            ChildrenForParse.push_back($2);
            ChildrenForParse.push_back($3);
            ChildrenForParse.push_back($4);
            ParseChildRelated($$ , ChildrenForParse) ;
            
            
            } ; 
expression : logic_expression 
            {
                
                 $$ = new SymbolInfo(makeSymbolName({$1}) ,"EXPRESSION") ;
                printinlogfile(logfile ,"expression 	: logic_expression	 ") ; 

               
                $$->set_dtype($1->get_dtype()) ; // FULL EXPRESSION NOW HAVE THE DTYPE AS LOGIC EXP.
                type = $1->get_dtype() ; 
                  //ParseRelatedCodes
                $$->setParseString("expression : logic_expression");  
                ParseLineRelated($$,$1,$1) ; 
                vector<SymbolInfo*> ChildrenForParse ; 
                ChildrenForParse.push_back($1);
                ParseChildRelated($$ , ChildrenForParse) ;
            }
            |variable ASSIGNOP logic_expression
            {
                // error happening , because correct foo is not valid but we are still assigning , in this case we have to ignore 
                // if error then the type must be empty 
                // adding it to if 
                 $$ = new SymbolInfo(makeSymbolName({$1 , $2 , $3 }), "EXPRESSION") ;
                printinlogfile(logfile ,"expression 	: variable ASSIGNOP logic_expression 		 ") ; 

               
               if($1->get_dtype()!=$3->get_dtype() && $3->get_dtype()!="" && $1->get_dtype()!="" ) // int a ; float b ; a = b; but notice float d ; d = 2 is valid . 
                {
                    //if($1->get_dtype()=="VOID" || $3->get_dtype()=="VOID"){} // for void return type assignment , no error in sample , Later declared in moodle . 

                    // cout<<line_count<<" FOR CHECKING "<<$1->getName()+$2->getName()+$3->getName()<<"   1"<<$1->get_dtype()<< "2"<<$3->get_dtype()<<"3"<<endl ; 
                    if($1->get_dtype()=="FLOAT" && $3->get_dtype()=="INT"){
                                //cout<<"he"<<endl ; 
                    }
                    else 
                    {
                    //cout<<"here"<<endl ;
                    // cout<<line_count<<" "<<$1->getName()<<" "<<$3->getName()<<endl ;
                    // cout<<line_count<<" "<<$1->get_dtype()<<" "<<$3->get_dtype()<<endl ; 
                    //  cout<<line_count<<" "<<$1->getType()<<" "<<$3->getType()<<endl ;
                    string msg = "Warning: possible loss of data in assignment of "+ $3->get_dtype() + " to " + $1->get_dtype();
                    yyerror(msg) ;
                    
                    }

                    
                }

                if($3->get_dtype()=="VOID") // a=void is not allowed
                {
                    string msg = "Void cannot be used in expression " ;
                    yyerror(msg) ;
                    $3->set_dtype("FLOAT") ; 
                }
                  //ParseRelatedCodes
                $$->setParseString("expression : variable ASSIGNOP logic_expression");  
                ParseLineRelated($$,$1,$3) ; 
                vector<SymbolInfo*> ChildrenForParse ; 
                ChildrenForParse.push_back($1);
                ChildrenForParse.push_back($2);
                ChildrenForParse.push_back($3);
                ParseChildRelated($$ , ChildrenForParse) ;

            $$->set_dtype($1->get_dtype()) ; 
                type = $1->get_dtype() ; 
            
            
            } ; 
logic_expression : rel_expression 
            {

                $$ = new SymbolInfo(makeSymbolName({$1 }) ,"LOGIC_EXPRESSION") ;
                printinlogfile(logfile ,"logic_expression : rel_expression 	 ") ; 
                $$->set_dtype($1->get_dtype()) ; 
               
                //cout<<"for logic op"<<$1->get_dtype()<<endl  ;
                  //ParseRelatedCodes
                $$->setParseString("logic_expression : rel_expression");  
                ParseLineRelated($$,$1,$1) ; 
                vector<SymbolInfo*> ChildrenForParse ; 
                ChildrenForParse.push_back($1);
                ParseChildRelated($$ , ChildrenForParse) ;
            
            }
            |rel_expression LOGICOP rel_expression
            {
                $$ = new SymbolInfo(makeSymbolName({$1 , $2 , $3 }) , "LOGIC_EXPRESSION") ; 
                printinlogfile(logfile ,"logic_expression : rel_expression LOGICOP rel_expression 	 	 ")  ;  
                $$->set_dtype($1->get_dtype()) ; 
                //keep a type checking if both sides are equal type 
               

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
                 

                //ParseRelatedCodes
                $$->setParseString("logic_expression : rel_expression LOGICOP rel_expression"); 
                ParseLineRelated($$,$1,$3) ; 
                vector<SymbolInfo*> ChildrenForParse ; 
                ChildrenForParse.push_back($1);
                ChildrenForParse.push_back($2);
                ChildrenForParse.push_back($3);
                ParseChildRelated($$ , ChildrenForParse) ;
            } ; 
rel_expression : simple_expression
            {
               
                $$ = new SymbolInfo(makeSymbolName({$1 }) ,"REL_EXPRESSION") ;
             printinlogfile(logfile ,"rel_expression	: simple_expression ") ; 
               $$->set_dtype($1->get_dtype()) ; 
               
               //cout<<"for rel op"<<$1->get_dtype()<<endl  ;
               //ParseRelatedCodes
               $$->setParseString("rel_expression : simple_expression");
                ParseLineRelated($$,$1,$1) ; 
                vector<SymbolInfo*> ChildrenForParse ; 
                ChildrenForParse.push_back($1);
                ParseChildRelated($$ , ChildrenForParse) ;
            }
            | simple_expression RELOP simple_expression
            {
                // a<b
                $$ = new SymbolInfo(makeSymbolName({$1 , $2 , $3 }) , "REL_EXPRESSION") ; 
                printinlogfile(logfile ,"rel_expression	: simple_expression RELOP simple_expression	  ") ;   
                $$->set_dtype($1->get_dtype()) ;  
                //cout<<"for rel op"<<$1->get_dtype()<<endl  ;
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
                 //ParseRelatedCodes
                 $$->setParseString("rel_expression : simple_expression RELOP simple_expression");
                ParseLineRelated($$,$1,$3) ; 
                vector<SymbolInfo*> ChildrenForParse ; 
                ChildrenForParse.push_back($1);
                ChildrenForParse.push_back($2);
                   ChildrenForParse.push_back($3);
                ParseChildRelated($$ , ChildrenForParse) ;
            } ; 
            //start here . 
simple_expression : term 
            {
              $$ = new SymbolInfo(makeSymbolName({$1 }) ,"SIMPLE_EXPRESSION") ;
             printinlogfile(logfile ,"simple_expression : term ") ;  
               $$->set_dtype($1->get_dtype()) ; 
                
               //ParseRelatedCodes
                $$->setParseString("simple_expression : term");
                ParseLineRelated($$,$1,$1) ; 
                vector<SymbolInfo*> ChildrenForParse ; 
                ChildrenForParse.push_back($1);
                ParseChildRelated($$ , ChildrenForParse) ;
            }
            |simple_expression ADDOP term
            {

                // A+B
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
                
                
                     //ParseRelatedCodes
                 $$->setParseString("simple_expression : simple_expression ADDOP term");
                ParseLineRelated($$,$1,$3) ; 
                vector<SymbolInfo*> ChildrenForParse ; 
                ChildrenForParse.push_back($1);
                ChildrenForParse.push_back($2);
                   ChildrenForParse.push_back($3);
                ParseChildRelated($$ , ChildrenForParse) ;
            
            } ; 
 term : unary_expression
            {
                //NEW RULE STARTS 
                //++a , a-- 
             $$ = new SymbolInfo(makeSymbolName({$1 }) ,"TERM") ;
             printinlogfile(logfile ,"term :	unary_expression ") ;   
            $$->set_dtype($1->get_dtype()) ; //helps in future error checking 
            
                //ParseRelatedCodes
                 $$->setParseString("term : unary_expression");
                ParseLineRelated($$,$1,$1) ; 
                vector<SymbolInfo*> ChildrenForParse ; 
                ChildrenForParse.push_back($1);
                ParseChildRelated($$ , ChildrenForParse) ;
            }
            | term MULOP unary_expression
            {
                // a/b , a*b 
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

                
                // ex : 5/"hello" 
                 // const int can be 5 and int can be int a ; 

                ////cout<<$3->getType()<<endl ;
               // cout<<"FOR MODULUS : "<<line_count<<" "<<$1->get_dtype()<<"  and "<<$3->get_dtype()<<endl ; 
                if( $2->getName() =="%")   
                {
                    if(($1->get_dtype()=="INT" && $3->get_dtype()=="INT")) {}
                    else 
                    {
                        // //cout<<"LINE 1243 "<<$3->get_dtype()<< " " <<$3->getName()<<endl ; 
                    string msg = "Operands of modulus must be integers "; 
                    yyerror(msg) ; 
                    $$->set_dtype("INT") ;//recover
                    }
                   

                } 
                else  if( $2->getName() =="%" &&($1->get_dtype()!="FLOAT" && $3->get_dtype()!="FLOAT"))
                {$$->set_dtype("FLOAT") ;}
                else {$$->set_dtype($1->get_dtype()) ;}




                if($3->getName()=="0" && ($2->getName()=="/" || $2->getName() =="%")) //divide by zero error 
                {
                    string msg = "Warning: division by zero i=0f=1Const=0";  // WARNING : HAVE i=0f=1Const=0
                    yyerror(msg) ; 
                }


                           //ParseRelatedCodes
                  $$->setParseString("term : term MULOP unary_expression");
                ParseLineRelated($$,$1,$3) ; 
                vector<SymbolInfo*> ChildrenForParse ; 
                ChildrenForParse.push_back($1);
                ChildrenForParse.push_back($2);
                   ChildrenForParse.push_back($3);
                ParseChildRelated($$ , ChildrenForParse) ;
            } ; 
unary_expression : ADDOP unary_expression 
            {
                // NEW RULE STARTS
                // +a 
                $$ = new SymbolInfo(makeSymbolName({$1 , $2 }) , "UNARY_EXPRESSION") ; 
                printinlogfile(logfile ,"unary_expression : ADDOP unary_expression  ")  ;
                 if($2->get_dtype()=="VOID")
                {
                    string msg = "Void cannot be used in expression " ;
                    yyerror(msg) ; 

                    $$->set_dtype("") ; 
                }
                else $$->set_dtype($2->get_dtype()) ;
                       //ParseRelatedCodes
                  $$->setParseString("unary_expression : ADDOP unary_expression");
                ParseLineRelated($$,$1,$2) ; 
                vector<SymbolInfo*> ChildrenForParse ; 
                ChildrenForParse.push_back($1);
                ChildrenForParse.push_back($2);
                ParseChildRelated($$ , ChildrenForParse) ;
            
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
                           //ParseRelatedCodes
                 $$->setParseString("unary_expression : NOT unary_expression");
                ParseLineRelated($$,$1,$2) ; 
                vector<SymbolInfo*> ChildrenForParse ; 
                ChildrenForParse.push_back($1);
                ChildrenForParse.push_back($2);
                ParseChildRelated($$ , ChildrenForParse) ;
            }
            |factor
            {
                $$ = new SymbolInfo(makeSymbolName({$1}) ,"UNARY_EXPRESSION") ;
                printinlogfile(logfile ,"unary_expression : factor ") ;
                $$->set_dtype($1->get_dtype())  ; 
               
                //ParseRelatedCodes
                $$->setParseString("unary_expression : factor");
                ParseLineRelated($$,$1,$1) ; 
                vector<SymbolInfo*> ChildrenForParse ; 
                ChildrenForParse.push_back($1);
                ParseChildRelated($$ , ChildrenForParse) ;
            } ; 
factor: variable {
                
                $$ = new SymbolInfo(makeSymbolName({$1 }) ,"FACTOR") ; 
                $$->set_dtype($1->get_dtype())     ; 


                }
                 |ID LPAREN argument_list RPAREN
                 {
                    // basic function calling 
                    // addnew(a,b)
                    $$ = new SymbolInfo(makeSymbolName({$1 , $2 , $3 , $4}), "FUNCTION_CALL") ; //CHECK
                    printinlogfile(logfile ,"factor	: ID LPAREN argument_list RPAREN  ")  ;
                    //cout<<"---->"<<$1->get_dtype()<<" "<<$1->getType()<<endl ; 
                    
                    // Error check 
                    // check if such function actually exists 
                    SymbolInfo* info = symboltable->LookUp($1->getName(),logfile); 


                    // no such function with the same name 
                    if(info==NULL)
                    {
                        string msg = "Undeclared function '"+$1->getName()+"'" ; 
                        yyerror(msg) ; 
                         $$->set_dtype("") ; //return type float error handle 
                        
                    } //ok name matched , but still have to make sure they are actually defined 
                    else if(info->isdef()!=true)
                    { 
                         //cout<<info->getName()<<" "<<line_count<< " "<<info->get_dtype()<<" "<<info->getType()<<" " << info->isdec()<< " "<<info->isdef() <<endl ; 
                        string msg = "Undefined function '"+$1->getName()+"'" ;  //DO WE HAVE ? 
                        yyerror(msg) ; 
                        $$->set_dtype("FLOAT") ;//return type float error handle 
                        
                    } // ok , so name matched , such function also defined , now check if they are actually same (count parameter and argument length)
                    else 
                    {
                        //cout<<info->getName()<<" "<<line_count<< " "<<info->get_dtype()<<" "<<info->getType() ; 
                        
                
                        if(info->get_paramcount()!=func_argument_list.size())
                        {
                            //so the matching function don't match no. of arguments 
                            // foo(int a , int b) ; 
                            // foo(5) 
                            //have to check for more or less 
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
                        else // ok , so number of arg = no. of param , but can be mismatch , for error we also have to keep track where error happened (sserror)
                        {
                            vector<int>problem ; 
                            int pc =0 ; 
                           // //cout<<func_argument_list.size() <<endl ; 
                            for(int i=0 ; i<func_argument_list.size() ; i++)
                            {
                                //curr //cout 
                               // //cout<<"IN FUNCTION ARGUMENT FOR LINE : "<<line_count<<" DATA TYPE IS : "<<func_argument_list[i]<<endl ; 
                                string matchchecker = "" ; 
                                if(func_argument_list[i]=="CONST_INT") matchchecker="INT" ; 
                                else if (func_argument_list[i]=="CONST_FLOAT") matchchecker="FLOAT" ;
                                else matchchecker=func_argument_list[i] ; //for id 

                                //curr //cout
                               // //cout<<"IN LINE 1525 FOR FUNCTION NAME : " <<info->getName()<<" PARAMETER TYPE :  "<<info->get_param(i).parameter_dtype<<" ARGUMENT TYPE : "<<matchchecker<<endl ; 
                                if(convert_to_uppercase(info->get_param(i).parameter_dtype) !=matchchecker)  
                                {
                                   // //cout<<i<<endl ; 
                                    problem.push_back(i+1);
                                    pc++ ; 
                                }
                            }
                            for(int j=0 ; j<pc ; j++)
                            {
                                string msg = "Type mismatch for argument "+to_string(problem[j])+" of '"+$1->getName()+"'" ;
                                yyerror(msg) ; 
                            }
                             $$->set_dtype(info->get_dtype())  ; 
                             $1->set_dtype(info->get_dtype())  ; 
                             //cout<<info->get_dtype()<<endl ; 
                        }
                    }


                   // cout<<$$->get_dtype()<<endl ; 
                  //  cout<<$1->get_dtype()<<endl ; 


                    func_argument_list.clear()  ; 
                    //ParseRelatedCodes
                    $$->setParseString("factor : ID LPAREN argument_list RPAREN");
                    ParseLineRelated($$,$1,$4) ; 
                    vector<SymbolInfo*> ChildrenForParse ; 
                    ChildrenForParse.push_back($1);
                    ChildrenForParse.push_back($2);
                    ChildrenForParse.push_back($3);
                    ChildrenForParse.push_back($4);
                    ParseChildRelated($$ , ChildrenForParse) ;
                
                 }
                 |LPAREN expression RPAREN
                {
                    //(a>5)
                    $$ = new SymbolInfo(makeSymbolName({$1 , $2 , $3 }),"FACTOR"  ) ; //CHECK
                    printinlogfile(logfile ,"factor	: LPAREN expression RPAREN   ")  ;
                //ParseRelatedCodes
                ParseLineRelated($$,$1,$3) ; 
                   $$->setParseString("factor : LPAREN expression RPAREN");
                vector<SymbolInfo*> ChildrenForParse ; 
                ChildrenForParse.push_back($1);
                ChildrenForParse.push_back($2);
                ChildrenForParse.push_back($3);
                ParseChildRelated($$ , ChildrenForParse) ;

               
                if($2->get_dtype()=="VOID")
                {
                     string msg = "Void cannot be used in expression " ;
                    yyerror(msg) ; 
                    
                    $$->set_dtype("") ;
                }

                }
                |CONST_INT
                {
               // //cout<<line_count<<" "<<$1->getName()<<" "<<$1->getType()<<endl ; 
                $$ = new SymbolInfo(makeSymbolName({$1  }) ,"CONST_INT"  ) ;
                printinlogfile(logfile ,"factor	: CONST_INT   ") ; 
                 $$->set_dtype("INT") ; 
                //ParseRelatedCodes
                $$->setParseString("factor : CONST_INT");
                ParseLineRelated($$,$1,$1) ; 
                vector<SymbolInfo*> ChildrenForParse ; 
                ChildrenForParse.push_back($1);
                ParseChildRelated($$ , ChildrenForParse) ;
                }
                |CONST_FLOAT
                {
                $$ = new SymbolInfo(makeSymbolName({$1 }) ,"CONST_FLOAT"  ) ;
                printinlogfile(logfile ,"factor	: CONST_FLOAT   ") ; 
                  $$->set_dtype("FLOAT") ; 
                //ParseRelatedCodes
                $$->setParseString("factor : CONST_FLOAT");
                ParseLineRelated($$,$1,$1) ; 
                vector<SymbolInfo*> ChildrenForParse ; 
                ChildrenForParse.push_back($1);
                ParseChildRelated($$ , ChildrenForParse) ;
                }
                |variable INCOP
                {
                $$ = new SymbolInfo(makeSymbolName({$1 , $2 }) ,"FACTOR"  ) ; 
                printinlogfile(logfile ,"factor	: variable INCOP   ")  ;
                $$->set_dtype($1->get_dtype()) ;
                //ParseRelatedCodes
                $$->setParseString("factor : variable INCOP");
                ParseLineRelated($$,$1,$2) ; // should be same anyway , checkSE will verify it though  
                vector<SymbolInfo*> ChildrenForParse ; 
                ChildrenForParse.push_back($1);
                ChildrenForParse.push_back($2);
                ParseChildRelated($$ , ChildrenForParse) ;
                }
                |variable DECOP
                {
                $$ = new SymbolInfo(makeSymbolName({$1 , $2 }) ,"FACTOR"  ) ; 
                printinlogfile(logfile ,"factor	: variable DECOP   ")  ;
                 $$->set_dtype($1->get_dtype()) ; 
                //ParseRelatedCodes
                $$->setParseString("factor : variable DECOP");
                ParseLineRelated($$,$1,$2) ; 
                vector<SymbolInfo*> ChildrenForParse ; 
                ChildrenForParse.push_back($1);
                ChildrenForParse.push_back($2);
                ParseChildRelated($$ , ChildrenForParse) ;


               
                }; 
argument_list : arguments 
                {
                    //NEW RULE STARTS 
                    //WHENEVER WE ARE CALLING THE FUNCTION , WE HAVE TO KEEP TRACK OF ARGUMENT LIST 
                    //TO CHECK UP WITH PARAMETER LIST ; 

                    // foo(4,2,2 <---all together)
                $$ = new SymbolInfo(makeSymbolName({$1 }) ,"ARGUMENT_LIST"  ) ;
                printinlogfile(logfile ,"argument_list : arguments  ") ; 
                //ParseRelatedCodes
                $$->setParseString("argument_list : arguments");
                ParseLineRelated($$,$1,$1) ; 
                vector<SymbolInfo*> ChildrenForParse ; 
                ChildrenForParse.push_back($1);
                ParseChildRelated($$ , ChildrenForParse) ;
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
            //ParseRelatedCodes
                $$->setParseString("arguments : arguments COMMA logic_expression");
                ParseLineRelated($$,$1,$3) ; 
                vector<SymbolInfo*> ChildrenForParse ; 
                ChildrenForParse.push_back($1);
                ChildrenForParse.push_back($2);
                ChildrenForParse.push_back($3);
                ParseChildRelated($$ , ChildrenForParse) ;
                
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
                
                 ////cout<<" line 1661 type for logic is"<<line_count<<" "<<$1->get_dtype()<<endl  ;
                func_argument_list.push_back($1->get_dtype()) ;  
                ////cout<<"FOR LINE : "<<line_count<<endl ; 
                ////cout<<"THE TYPE FOR LOGIC EXPRESSION IS "<<$1->get_dtype()<<endl ; 
                ////cout<<"THE DATA TYPE FOR LOGIC EXPRESSION IS "<<$1->get_dtype()<<endl ; 


  
                }
                |logic_expression
                {
                $$ = new SymbolInfo(makeSymbolName({$1 }) ,$1->getType()  ) ;
                printinlogfile(logfile ,"arguments : logic_expression") ; 
              //ParseRelatedCodes
                $$->setParseString("arguments : logic_expression");
                ParseLineRelated($$,$1,$1) ; 
                vector<SymbolInfo*> ChildrenForParse ; 
                ChildrenForParse.push_back($1);
                ParseChildRelated($$ , ChildrenForParse) ;

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
                ////cout<<" line 1697 type for loguc is "<<$1->get_dtype()<<endl  ;
                func_argument_list.push_back($1->get_dtype()) ;  
               // //cout<<"FOR LINE : "<<line_count<<endl ; 
               // //cout<<"THE TYPE FOR LOGIC EXPRESSION IS "<<$$->get_dtype()<<endl ; 
               // //cout<<"THE DATA TYPE FOR LOGIC EXPRESSION IS "<<$$->get_dtype()<<endl ; 

                } ;
%%
int main(int argc , char* argv[])
{
    int scope_id = 1 ;
    int bucket_size = 11; 
    if(argc<2){
        //cout<<"Input file not found"<<endl ;
        return 1 ;
    }


    logfile.open("log.txt") ; 
    errorfile.open("error.txt") ;
    parsefile.open("parsetree.txt"); //name fixed according to spec. 
    //parsefile<<"hl"<<endl ;



    a_code.open("1905067assembly.asm") ; 
    
   // //cout<<"SCOPE ID LINE 1232:"<<scope_id<<endl ;
    symboltable->Enter_scope(scope_id++ , bucket_size);
    yyin = NULL ; 
    yyin = fopen(argv[1] ,"r") ; 
    if( yyin == NULL) return 1 ;
    yyparse() ; 
    fclose(yyin) ; 
    //symboltable->print_all(logfile) ;  //not needed 
   
    logfile<<"Total Lines: "<<line_count<<endl ; 
    logfile<<"Total Errors: "<<error_count<<endl ;
    logfile.close() ; 
    errorfile.close(); 
    parsefile.close() ; 
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
