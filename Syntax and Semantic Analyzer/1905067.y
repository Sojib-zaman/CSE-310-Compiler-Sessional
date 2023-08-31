%{
//tasks : 

//this version is for creating parse tree in old format 
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


SymbolTable* symboltable = new SymbolTable(20); // size defined for symbol table 
int scope_id = 1 ; 
int bucket_size = 11; 


extern FILE* yyin ; 
ofstream logfile;
ofstream errorfile ; 
ofstream parsefile ; 


//for embedded type 
string type ;
string data_type ;  // return data type 
//type used in many cases which is later assigned to data_type (final result)
 


extern int line_count; 
extern int error_count ;
//coming from the lex file


struct parameter 
{
    string parameter_type ; 
    string parameter_name ; // if empty then function declaration 
}demo_param;
vector<parameter>parameter_list; //all the function parameters 
vector<string>func_argument_list ; //function calling ( foo(a,b) ; )
//arg list , only contains the return types of the parameter . 

struct var 
{
    string var_name ; 
    int variable_size ;
    string isarraytype;
}demo_var;


vector<var>var_list ; //variable and array
//for embedded name 
string name ;
string data_name ;

//if a function is found , sets it's parameter into the info 
//then add the info in symboltable 

void function_add_val(string type , string name , bool check , bool check2)
{
    //here check is for declaration
    //check2 is for definition 
    //here type is return type , so assigning it to dtype 
    //cout<<"line 72 : "<<name<<" "<<type<<endl ; 
	SymbolInfo* info = new SymbolInfo(name,"FUNCTION") ; 
    info->set_dtype(type) ; 
    cout<<"LINE 75"<<endl ; 
    cout<<name<<" "<<check<<" "<<check2<<endl ; 
    info->setisdec(check) ; 
    info->setisdef(check2);
    //inside func dec or def , we added elements to parameter list 
    // have to clear list when done 
    for(int i=0 ; i<parameter_list.size() ; i++)
    {
        //info->addnew(parameter_list[i].parameter_type , parameter_list[i].parameter_type) ; 
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
    // for a variable dtype and symbol type means the same thing actually 
    // *** we did not add any var_type ***
     
    SymbolInfo* info = new SymbolInfo(var_not_param.var_name , convert_to_uppercase(type)) ; 
    if(var_not_param.isarraytype!="ARRAY")
        {
           // cout<<"L 100 : "<<var_not_param.isarraytype<<endl ; 
            info->set_dtype(convert_to_uppercase(type)) ;
            cout<<"LINE COUNT : "<<line_count<<endl ; 
            cout<<"IN VARIABLE INSERT : "<<info->getType()<<" "<<var_not_param.var_name<<" "<<info->get_dtype()<<endl ;
        } 
    else 
        {
           // cout<<"L 105 : "<<var_not_param.isarraytype<<endl ; 
            info->set_dtype(convert_to_uppercase(var_not_param.isarraytype)) ; 
            cout<<"LINE COUNT : "<<line_count<<endl ; 
            cout<<"IN ARRAY INSERT : "<<info->getType()<<" "<<var_not_param.var_name<<" "<<info->get_dtype()<<endl ;
        }
    //RECHECK FOR ARRAY AND VAR 
    info->set_size(var_not_param.variable_size) ; // will be -1 if normal int / smth
    symboltable->insert(*info , logfile) ; 
}


//FOR PARSE TREE 
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
                //cout<<info->getparseline()<<endl;
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
start : program {   //NEW RULE STARTS
                    //cout<<$1->getName()<<endl ; 


                    $$=new SymbolInfo((string)$1->getName(),"START");
                    printinlogfile(logfile ,"start : program " );


                    //will have final operations here . 



                    //ParseRelatedCodes
                    $$->setParseString("start : program") ; 
                    ParseLineRelated($$,$1,$1) ; // sets the starting and ending line  
                    vector<SymbolInfo*> ChildrenForParse ; 
                    ChildrenForParse.push_back($1); //can also be done using an array
                    ParseChildRelated($$ , ChildrenForParse) ; // adds the children , sets the leaf information 
                    $$->setspace(0) ; 
                    //$$->showallchildren() ; 
                    $$->printparsetree(parsefile,0) ; //program successful, so print parse tree 
                    
                } ; 
program : program unit {
                        //NEW RULE STARTS
                        $$=new SymbolInfo((string)$1->getName() + (string)$2->getName() ,"PROGRAM");
                        printinlogfile(logfile,"program : program unit " ) ; 
                        
                        //ParseRelatedCodes
                        $$->setParseString("program : program unit") ; 
                        ParseLineRelated($$,$1,$2) ; 
                        vector<SymbolInfo*> ChildrenForParse ; 
                        ChildrenForParse.push_back($1);
                        ChildrenForParse.push_back($2);
                        ParseChildRelated($$ , ChildrenForParse) ; 
                       }
                       | unit {
                        //NEW RULE STARTS
                        $$=new SymbolInfo((string)$1->getName(),"PROGRAM"); 
                        printinlogfile(logfile,"program : unit "  ) ; 
                                                
                        //ParseRelatedCodes
                        $$->setParseString("program : unit") ; 
                        ParseLineRelated($$,$1,$1) ; 
                        vector<SymbolInfo*> ChildrenForParse ; 
                        ChildrenForParse.push_back($1);
                       
                        ParseChildRelated($$ , ChildrenForParse) ;   
                       } ; 
unit : var_declaration {//NEW RULE STARTS
                        $$ = new SymbolInfo($1->getName() ,"UNIT") ;
                        printinlogfile(logfile ,"unit : var_declaration  " ) ; 
                                                    
                        //ParseRelatedCodes
                        $$->setParseString("unit : var_declaration") ; 
                        ParseLineRelated($$,$1,$1) ; 
                        vector<SymbolInfo*> ChildrenForParse ; 
                        ChildrenForParse.push_back($1);
                        ParseChildRelated($$ , ChildrenForParse) ;
                        }          
                        | func_declaration {
                        //NEW RULE STARTS
                        $$ = new SymbolInfo($1->getName() ,"UNIT") ;
                        printinlogfile(logfile ,"unit : func_declaration ") ; 
                                                    
                        //ParseRelatedCodes
                        $$->setParseString("unit : func_declaration") ; 
                        ParseLineRelated($$,$1,$1) ; 
                        vector<SymbolInfo*> ChildrenForParse ; 
                        ChildrenForParse.push_back($1);
                        ParseChildRelated($$ , ChildrenForParse) ;
                        }
                        |func_definition{
                        //NEW RULE STARTS
                        $$ = new SymbolInfo($1->getName() ,"UNIT") ;
                        printinlogfile(logfile ,"unit : func_definition  ") ;
                                                    
                        //ParseRelatedCodes
                        $$->setParseString("unit : func_definition") ; 
                        ParseLineRelated($$,$1,$1) ; 
                        vector<SymbolInfo*> ChildrenForParse ; 
                        ChildrenForParse.push_back($1);
                        
                        ParseChildRelated($$ , ChildrenForParse) ; 
                        } ; 
func_declaration : type_specifier non_term_for_func ADDT LPAREN parameter_list RPAREN ADDT_DEC SEMICOLON { 
                //void foo(int a , int b) ; int foo(int , int ) ; 


                //NEW RULE STARTS
                //here s5 contains all parameter 
                //ADDT will store int foo , then go on 
                
                $$ = new SymbolInfo($1->getName()+""+$2->getName()+$4->getName()+$5->getName()+$6->getName()+$8->getName() ,"FUNC_DECLARATION") ; 
                printinlogfile(logfile ,"func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON ") ; 

                //name = $2->getName() ; 
                                        
                //ParseRelatedCodes
                $$->setParseString("func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON") ; 
                ParseLineRelated($$,$1,$8) ; 
                vector<SymbolInfo*> ChildrenForParse ; 
                ChildrenForParse.push_back($1);
                ChildrenForParse.push_back($2);
                ChildrenForParse.push_back($4);
                ChildrenForParse.push_back($5);
                ChildrenForParse.push_back($6);
                ChildrenForParse.push_back($8);
                ParseChildRelated($$ , ChildrenForParse) ;
                //clear parameter list completely 
                parameter_list.clear() ; 

            }
            |type_specifier non_term_for_func ADDT LPAREN RPAREN ADDT_DEC SEMICOLON {
            // int foo () ; 
            //NEW RULE STARTS
                            
            $$ = new SymbolInfo($1->getName()+""+$2->getName()+$4->getName()+$5->getName()+$7->getName() ,"FUNC_DECLARATION") ; 
            printinlogfile(logfile ,"func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON ") ; 
           // name = $2->getName() ; 

            //ParseRelatedCodes
            $$->setParseString("func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON") ; 
            ParseLineRelated($$,$1,$7) ; 
            vector<SymbolInfo*> ChildrenForParse ; 
            ChildrenForParse.push_back($1);
            ChildrenForParse.push_back($2);
            ChildrenForParse.push_back($4);
            ChildrenForParse.push_back($5);
            ChildrenForParse.push_back($7);
            ParseChildRelated($$ , ChildrenForParse) ;
            //clear parameter list completely , to remove entries of this current function 
            parameter_list.clear() ; 
                        }; 
func_definition : type_specifier non_term_for_func ADDT LPAREN parameter_list RPAREN ADDT_DEF compound_statement
                        {
                        //int foo(int a , int b) {int c ; c=a+b ; return c ;}
                         //name = $2->getName() ; 

                        //NEW RULE STARTS
                        //one function starts and ends , so store all 
                         $$ = new SymbolInfo($1->getName()+""+$2->getName()+$4->getName()+$5->getName()+$6->getName()+ $8->getName(),"FUNC_DEFINITION") ; 
                         printinlogfile(logfile ,"func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement ") ;    
                         //symboltable->print_all(logfile) ; 
                         //symboltable->Exit_scope(logfile) ; 
                         //print and exit is handled on compound statement  

                         //ParseRelatedCodes
                        $$->setParseString("func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement") ; 
                        ParseLineRelated($$,$1,$8) ; 
                        vector<SymbolInfo*> ChildrenForParse ; 
                        ChildrenForParse.push_back($1);
                        ChildrenForParse.push_back($2);
                        ChildrenForParse.push_back($4);
                        ChildrenForParse.push_back($5);
                        ChildrenForParse.push_back($6);
                        ChildrenForParse.push_back($8);
                        ParseChildRelated($$ , ChildrenForParse) ;
                        }
                        |type_specifier non_term_for_func ADDT LPAREN RPAREN ADDT_DEF compound_statement
                        {
                         $$ = new SymbolInfo($1->getName()+""+$2->getName()+$4->getName()+$5->getName()+ $7->getName(),"FUNC_DEFINITION") ;  
                         printinlogfile(logfile ,"func_definition : type_specifier ID LPAREN RPAREN compound_statement") ;    
                         //symboltable->print_all(logfile) ; 
                         //symboltable->Exit_scope(logfile) ;
                            // name = $2->getName() ; 
                         //print and exit is handled on compound statement  
                         //RECHECK do we need ADDT_DEF 
                         //ParseRelatedCodes
                        $$->setParseString("func_definition : type_specifier ID LPAREN RPAREN compound_statement") ;
                        ParseLineRelated($$,$1,$7) ; 
                        vector<SymbolInfo*> ChildrenForParse ; 
                        ChildrenForParse.push_back($1);
                        ChildrenForParse.push_back($2);
                        ChildrenForParse.push_back($4);
                        ChildrenForParse.push_back($5);
                        ChildrenForParse.push_back($7);
                        ParseChildRelated($$ , ChildrenForParse) ;
                    

                         
                        } ;
ADDT : //separate indentation to define outside rules  , EMBEDDED 
{
    //ADDT works with function name , and function return type 
    data_type = type ; 
    data_name = name ;
};
ADDT_DEC: 
{
    cout<<"LINE 343 "<<line_count<<endl ; 
    cout<<data_name<<endl ; 
    SymbolInfo* x = symboltable->LookUp(data_name,logfile) ; 
    if(x!=NULL)
    {
    cout<<"IN DEC"<<endl ;
    cout<<x->getName()<<endl ; 
    }

    if(x==NULL)
    {
       // cout<<"IN ADDT DEC L 326"<<endl ;
       // cout<<data_type<<endl ; 
       // cout<<data_name<<endl ; 
        //same value as previous ADDT
        function_add_val(data_type , data_name , true , false); //declared but not yet defined 
    }
    else //previously declared function or something , again declared 
    {
        //cout<<line_count<<x->getName()<<endl ; 
       if(x->isfunc())
       {
        string msg = "Multiple Declaration of function " + data_name ; //RECHECK : COUNT PARAMETERS ??
        yyerror(msg) ; 
       }
       else // matched with symbol table but not with any function , so maybe any global variable 
       {
         string msg ="'" + data_name + "' redeclared as different kind of symbol" ; //RECHECK : COUNT PARAMETERS ??
       yyerror(msg) ;
       }
    }
} ; 
ADDT_DEF :   
{
   cout<<"IN ADDT DEF L 339 "<<line_count<<endl ;
  
    cout<<data_name<<endl ;
    //same value as previous ADDT

    //cout<<data_name<<endl ; 
    SymbolInfo* info = symboltable->LookUp(data_name,logfile) ; 
    if(info!=NULL) //so this info is used before , here we are just printing  
    {
        // can be : variable , function declaration , function definition 
        // if function declaration , we are defining here (have some catch .. )
    cout<<"IN DEF PREVIOUSLY DECLARED (LET FUNC)"<<endl ;
    cout<<info->getName()<<endl ; 
    cout<<info->isdec()<<" "<<info->isdef()<<endl ; 
    }
    if(info==NULL)
    {
        //never used before , so just add as a function for function definition 
        function_add_val(data_type,data_name,false,true); // not declared before , dec and def at the same time 
    }
    else if(info->isfunc()) // so it is used before , declaration or definition ??? 
    {
        cout<<"NOW IN LINE 403"<<endl ; 
        if(info->isdec() && !info->isdef() ) //declared but we did not define it then , now we are doing it 
        {
            //STEPS : 1. RETVAL MATCH 2. PARAM COUNT MATCH 3. TYPE MATCH
            //declared before and now defined , but have to make sure both have same return value
            //and also no of parameter RECHECK
            cout<<info->getName()<<endl ; 
            cout<<info->get_dtype()<<" "<<data_type<<endl ; 
            if(info->get_dtype()==data_type) // prev declared and now defined , so no prob , return value matched 
            {
                if(info->get_paramcount() == parameter_list.size())
                {  
                    cout<<"PARAM COUNT MATCHED"<<endl ; 
                    if(info->get_paramcount()==0)function_add_val(data_type,data_name,true,true) ; 
                    else 
                    {
                        // cout<<"return type matched "<<info->getName()<<endl ; 
                     int error_show = 0 ; 
                    //still have to make sure all parameters are actually same 

                    cout<<parameter_list.size()<<endl ; 
                    for(int i=0 ; i<parameter_list.size(); i++)
                    {
                        cout<<"IN LINE 418 FOR LINE COUNT "<<line_count<<" : "<<(info->get_param(i)).parameter_dtype<<" "<<parameter_list[i].parameter_type<<endl ; 
                        if( (info->get_param(i)).parameter_dtype != parameter_list[i].parameter_type)
                        {
                            error_show = 1 ;
                            
                        }
                        

                    }
                    cout<<"error show "<<error_show<<endl ; 

                    if(error_show)
                    {
                        string msg = "Conflicting types for '" + data_name +"'" ; //RECHECK : COUNT PARAMETERS ??
                        yyerror(msg) ; 
                    }
                    else function_add_val(data_type,data_name,true,true) ; 
                    }
                    
                }
                else 
                {    
                    //parameter count did not match    
                        string msg = "Conflicting types for '" + data_name +"'" ; //RECHECK : COUNT PARAMETERS ??
                        yyerror(msg) ; 

                }


            }
            else 
            { 

                //same named function , but with different return value .
            string msg = "Conflicting types for '" + data_name +"'" ; 
            yyerror(msg) ; 
            }

        }
        // this part is not in example RECHECK
        else if(info->isdef()) // previously defined , so it is a redefinition 
        {
            string msg = "Redifinition of function '" + data_name +"'" ; 
            yyerror(msg) ; 
        }
        
    }
     else // matched with symbol table but not with any function , so maybe any variable 
    {
         string msg ="'" + data_name + "' redeclared as different kind of symbol" ; //RECHECK : COUNT PARAMETERS ??
       yyerror(msg) ;
    }
    
    
  
// in dec we can have (int , int) , for def we can't have that , also have additional checking 

};
parameter_list : parameter_list COMMA type_specifier ID
                        {
                         
                        //NEW RULE STARTS 
                        // int foo (int a , int b <<----)  
                        //have to add params 
                         $$ = new SymbolInfo($1->getName()+$2->getName()+$3->getName()+ $4->getName(),"PARAMETER_LIST") ; 
                         printinlogfile(logfile ,"parameter_list  : parameter_list COMMA type_specifier ID") ;    
                         //have to check if this in the same parameter list here . 
                        //  cout<<"LINE 381"<<endl ; 
                        //  for(int i=0 ; i<parameter_list.size() ; i++)
                        //     cout<<parameter_list[i].parameter_name<<" "<<parameter_list[i].parameter_type<<endl ;

                        for(int i=0 ; i<parameter_list.size() ; i++)
                        {
                            if(parameter_list[i].parameter_name == $4->getName()) 
                            {
                                string msg = "Redefinition of parameter '"+$4->getName()+"'" ; 
                                yyerror(msg) ; 
                            }
                        }
                        //RECHECK , DO WE ADD IF ERROR FOUND ? 
                         demo_param.parameter_type = $3->getType() ; //INT  
                         demo_param.parameter_name = $4->getName() ; //a
                         parameter_list.push_back(demo_param) ; 
                         cout<<demo_param.parameter_name<<" "<<demo_param.parameter_type<<endl  ; 

                         //ParseRelatedCodes
                        $$->setParseString("parameter_list : parameter_list COMMA type_specifier ID") ;
                        ParseLineRelated($$,$1,$4) ; 
                        vector<SymbolInfo*> ChildrenForParse ; 
                        ChildrenForParse.push_back($1);
                        ChildrenForParse.push_back($2);
                        ChildrenForParse.push_back($3);
                        ChildrenForParse.push_back($4);
                        ParseChildRelated($$ , ChildrenForParse) ;
                        
                        }
                        |parameter_list COMMA type_specifier
                        {
                         //(int a , int <---) ; 
                         $$ = new SymbolInfo($1->getName()+$2->getName()+$3->getName(),"PARAMETER_LIST") ; 
                         printinlogfile(logfile ,"parameter_list  : parameter_list COMMA type_specifier ") ;    
                        //  cout<<"LINE 405"<<endl ; 
                        //  for(int i=0 ; i<parameter_list.size() ; i++)
                        //     cout<<parameter_list[i].parameter_name<<" "<<parameter_list[i].parameter_type<<endl ;


                         demo_param.parameter_type = $3->getType() ; 
                         demo_param.parameter_name ="" ; // does not have any parameter name 
                         parameter_list.push_back(demo_param) ; 


                          //ParseRelatedCodes 
                        $$->setParseString("parameter_list : parameter_list COMMA type_specifier ") ;                      
                        ParseLineRelated($$,$1,$3) ; 
                        vector<SymbolInfo*> ChildrenForParse ; 
                        ChildrenForParse.push_back($1);
                        ChildrenForParse.push_back($2);
                        ChildrenForParse.push_back($3);
                        ParseChildRelated($$ , ChildrenForParse) ;
                         
                        }
                        |type_specifier ID 
                        {
                        //basic (int a <---- )
                        $$ = new SymbolInfo($1->getName()+""+$2->getName(),"PARAMATER_LIST") ; 
                        printinlogfile(logfile ,"parameter_list  : type_specifier ID") ;   
                       
                        // cout<<"LINE 430"<<endl ; 
                        //  for(int i=0 ; i<parameter_list.size() ; i++)
                        //     cout<<parameter_list[i].parameter_name<<" "<<parameter_list[i].parameter_type<<endl ;
                        //name = $2->getName() ; 

                        demo_param.parameter_type = $1->getType() ; //int 
                        demo_param.parameter_name = $2->getName(); //a
                        parameter_list.push_back(demo_param) ; 


                              //ParseRelatedCodes    
                        $$->setParseString("parameter_list : type_specifier ID") ;                      
                        ParseLineRelated($$,$1,$2) ; 
                        vector<SymbolInfo*> ChildrenForParse ; 
                        ChildrenForParse.push_back($1);
                        ChildrenForParse.push_back($2);

                        ParseChildRelated($$ , ChildrenForParse) ;
                        }
                        |type_specifier 
                        {
                            //(int <--)
                        $$ = new SymbolInfo($1->getName(),"PARAMATER_LIST") ; 
                        printinlogfile(logfile ,"parameter_list : type_specifier ") ;    

                        // cout<<"LINE 455"<<endl ; 
                        //  for(int i=0 ; i<parameter_list.size() ; i++)
                        //     cout<<parameter_list[i].parameter_name<<" "<<parameter_list[i].parameter_type<<endl ;


                        demo_param.parameter_type = $1->getType() ; 
                        demo_param.parameter_name =""; 
                        parameter_list.push_back(demo_param) ;

                        //ParseRelatedCodes           
                        $$->setParseString("parameter_list : type_specifier") ;                
                        ParseLineRelated($$,$1,$1) ; 
                        vector<SymbolInfo*> ChildrenForParse ; 
                        ChildrenForParse.push_back($1);
                        ParseChildRelated($$ , ChildrenForParse) ;
                        } ; 
    
compound_statement: LCURL NEW_SCOPE_ADD_PARAM_TO_VAR statements RCURL
                        {
                            //NEW RULE STARTS 
                            // {int c; c=a+b ; return c;}
                            //RECHECK : WHY NEW_SCOPE_ADD_PARAM_TO_VAR , can't be merged in compound statement ?????? 
                         //actually don't need endline.    
                         $$ = new SymbolInfo(($1->getName()+(string)$3->getName()+$4->getName()),"COMPOUND_STATEMENT") ; 
                         printinlogfile(logfile ,"compound_statement : LCURL statements RCURL  ") ;   
                         symboltable->print_all(logfile) ; 
                         symboltable->Exit_scope(logfile) ; 

                        //ParseRelatedCodes     
                        $$->setParseString("compound_statement : LCURL statements RCURL") ;                    
                        ParseLineRelated($$,$1,$4) ; //but check new line , can alter line count (but no prob , as lex handle it )
                        vector<SymbolInfo*> ChildrenForParse ;
                        ChildrenForParse.push_back($1); 
                        ChildrenForParse.push_back($3);
                        ChildrenForParse.push_back($4);
                        ParseChildRelated($$ , ChildrenForParse) ;




                        }
                        | LCURL NEW_SCOPE_ADD_PARAM_TO_VAR RCURL
                        {
                            //{} no operation done . 
                        $$ = new SymbolInfo(($1->getName()+(string)$3->getName()),"COMPOUND_STATEMENT") ; //CHECK
                        printinlogfile(logfile ,"compound_statement : LCURL  RCURL ") ;   
                        symboltable->print_all(logfile) ; 
                        symboltable->Exit_scope(logfile) ; 



                        //ParseRelatedCodes 
                        $$->setParseString("compound_statement : LCURL  RCURL") ;                     
                        ParseLineRelated($$,$1,$3) ; 
                        vector<SymbolInfo*> ChildrenForParse ; 
                        ChildrenForParse.push_back($1);
                        ChildrenForParse.push_back($3);
                       
                        ParseChildRelated($$ , ChildrenForParse) ;
                        } ; 
NEW_SCOPE_ADD_PARAM_TO_VAR: 
{

    //purpose : 
    // create a new scope and enter 
    // the parameter varaibles are added to the variable list 


    scope_id++ ;
   // cout<<"SCOPE ID LINE 428:"<<scope_id<<endl ;
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
                         $$ = new SymbolInfo($1->getName() +"" + $2->getName() + $3->getName(),"VAR_DECLARATION") ;
                         printinlogfile(logfile ,"var_declaration : type_specifier declaration_list SEMICOLON  ") ;  
                         
                         if($1->getName()=="void")
                         { 
                            // void a is not valid ; 
                            string msg = "Variable or field '"+$2->getName()+"' declared void" ;
                            yyerror(msg) ; 


                            // for recovery , we made it float and inserted 
                            string sname ="FLOAT" ; 
                            //in declaration list , we are storing the variables 
                            for(int i =0 ; i<var_list.size() ; i++)
                                variable_insert(sname , var_list[i]) ; 
                         }
                         else 
                         {
                            // it not void , then add (int/float/... , a(-1)) 
                            string sname = $1->getName()  ; 
                            for(int i =0 ; i<var_list.size() ; i++)
                                 variable_insert(sname, var_list[i]) ; 
                         }
                         var_list.clear() ; 
// problem with clearing here is that int a ; int a ; will be detected from symboltable which maybe an error (check if a is outside scope )

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
                    $$ = new SymbolInfo($1->getName(), $1->getType()) ; // (int , INT) ; 
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
                    $$ = new SymbolInfo($1->getName(), $1->getType()) ;
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
                    $$ = new SymbolInfo($1->getName(), $1->getType()) ;
                    printinlogfile(logfile ,"type_specifier	: VOID") ; 
                    $$->setParseString("type_specifier : VOID") ;                 
                    ParseLineRelated($$,$1,$1) ; 
                    vector<SymbolInfo*> ChildrenForParse ; 
                    ChildrenForParse.push_back($1);
                    ParseChildRelated($$ , ChildrenForParse) ;
                }  ; 
non_term_for_func: ID 
        {
            //Here we needed a new non terminal rule 
            //terminal ID can't set the name for embedded system
            //by using a non terminal rule , here we have set our name 
            //this is applicable for function purpose only 
             $$ = new SymbolInfo($1->getName(), $1->getType()) ;
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
                         $$ = new SymbolInfo($1->getName() + $2->getName()+$3->getName() ,"DECLARATION_LIST") ;
                         printinlogfile(logfile ,"declaration_list : declaration_list COMMA ID  ") ; 
                         
                         // VCHECK , error only ignore right ? 

                        
                        cout<<" DECL ERROR "<<$3->getName() <<endl ; 

                        //ParseRelatedCodes
                        $$->setParseString("declaration_list : declaration_list COMMA ID") ;   
                        ParseLineRelated($$,$1,$3) ; 
                        vector<SymbolInfo*> ChildrenForParse ; 
                        ChildrenForParse.push_back($1);
                        ChildrenForParse.push_back($2);
                        ChildrenForParse.push_back($3);
                        ParseChildRelated($$ , ChildrenForParse) ;
                         
                        //check if already declared before with the same name 
                        //RECHECK : check if it collides with function variables 
                        demo_var.var_name = $3->getName() ; 
                         demo_var.variable_size = -1 ; //applicable for all variables 
                         var_list.push_back(demo_var) ; 
                         //have to add in the variable list 
                         //so that when bottom up is  done for this part 
                         //we can add the variables into the symboltable
                        
                        
                        
                        
                        
                        // int a ; 
                        // int a , v, x ;
                        SymbolInfo* x = symboltable->LookUp($3->getName() , logfile) ;
                        if(x!=NULL)
                        {
                            if(symboltable->getscopeID(x->getName() , logfile) == symboltable->currScopeID())
                         {
                            string msg = "Conflicting types for '"+$3->getName()+"'" ; 
                            yyerror(msg) ;
                         }
                        }
                        else 
                        { 

                         // demo var here ? or insert always ? 

                        }



                        // int a , b , c , b ; 
                        // for this error , we have to check the varlist to find error 
                        for(int i=0 ; i<var_list.size() -1 ; i++) // have to do -1 because , in the end of var list , we are inserting the variable himself 
                        {
                                cout<<$3->getName()<<" "<<var_list[i].var_name<<endl ; 
                            if($3->getName()==var_list[i].var_name)
                            {
                                cout<<"here"<<endl ; 
                                cout<<$3->getName()<<" "<<var_list[i].var_name<<endl ; 
                                string msg = "Redefination of variable name '"+$3->getName()+"'" ;  //MODIFIED 
                                yyerror(msg) ;
                            }
                        }
                        
                        }
                        | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
                        {
                         // a,b,c,d[39]
                         $$ = new SymbolInfo($1->getName() + $2->getName() +$3->getName() + $4->getName()+ $5->getName() + $6->getName(),"DECLARATION_LIST") ;
                         printinlogfile(logfile ,"declaration_list : declaration_list COMMA ID LSQUARE CONST_INT RSQUARE ") ; //according to logfile
                        
                        
                         demo_var.var_name = $3->getName() ; 
                         demo_var.isarraytype = "ARRAY";

                         //cout<<"l 641 :"<<demo_var.isarraytype<<endl ; 
                         //RECHECK 
                        //  stringstream szstream((string)$5->getName()) ; 
                        //  szstream >> demo_var.variable_size;
                         string len = $5->getName() ; 
                         demo_var.variable_size = stoi(len) ; 
                        // cout<<"line 628"<<endl ; 
                        // cout<<demo_var.variable_size<<endl ; 
                         var_list.push_back(demo_var) ; 

                         demo_var.isarraytype = ""; //clearing the value for others (won't be used again)
                        //check if already declared before with the same name 
                        SymbolInfo* x = symboltable->LookUp($3->getName() , logfile) ;
                         if(x!=NULL)
                        {
                            if(symboltable->getscopeID(x->getName() , logfile) == symboltable->currScopeID())
                         {
                            string msg = "Conflicting types for '"+$3->getName()+"'" ; 
                            yyerror(msg) ;
                         }
                        }
                        else 
                        {

                        }
                       
                        
                        // int a , b , c , b ; 
                        // for this error , we have to check the varlist to find error 
                        for(int i=0 ; i<var_list.size() -1  ; i++)
                        {
                             cout<<$3->getName()<<" "<<var_list[i].var_name<<endl ; 
                            if($3->getName()==var_list[i].var_name)
                            {
                                cout<<"here"<<endl ; 
                                cout<<$3->getName()<<" "<<var_list[i].var_name<<endl ; 
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
                        $$ = new SymbolInfo($1->getName(),"DECLARATION_LIST") ;
                        printinlogfile(logfile ,"declaration_list : ID ") ; 
                    
                        demo_var.var_name = $1->getName() ; 
                        demo_var.variable_size = -1 ; 
                        var_list.push_back(demo_var) ; 

                         SymbolInfo* x = symboltable->LookUp($1->getName() , logfile) ;
                        if(x!=NULL)
                        {
                            if(symboltable->getscopeID(x->getName() , logfile) == symboltable->currScopeID())
                         {
                            string msg = "Conflicting types for '"+$1->getName()+"'" ; 
                            yyerror(msg) ;
                         }
                        }


                        // int a , b , c , b ; 
                        // for this error , we have to check the varlist to find error 
                        for(int i=0 ; i<var_list.size() -1  ; i++)
                        {
                            
                             cout<<$1->getName()<<" "<<var_list[i].var_name<<endl ; 
                            if($1->getName()==var_list[i].var_name)
                            {
                                cout<<"here"<<endl ; 
                                cout<<$1->getName()<<" "<<var_list[i].var_name<<endl ; 
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
                        $$ = new SymbolInfo($1->getName()+ $2->getName()+$3->getName()+ $4->getName(),"DECLARATION_LIST") ;
                        printinlogfile(logfile ,"declaration_list : ID LSQUARE CONST_INT RSQUARE ") ; 
                       
                        demo_var.var_name = $1->getName() ; 
                        demo_var.isarraytype = "ARRAY";
                        string len = $3->getName() ; 
                        demo_var.variable_size = stoi(len) ; 
                      //  cout<<"line 628"<<endl ; 
                      //  cout<<demo_var.variable_size<<endl ; 
                        var_list.push_back(demo_var) ; 
                        demo_var.isarraytype = ""; //clearing the value for others (won't be used again)
                         SymbolInfo* x = symboltable->LookUp($1->getName() , logfile) ;
                        if(x!=NULL)
                        {
                            if(symboltable->getscopeID(x->getName() , logfile) == symboltable->currScopeID())
                         {
                            string msg = "Conflicting types for '"+$1->getName()+"'" ; 
                            yyerror(msg) ;
                         }
                        }


                        // int a , b , c , b ; 
                        // for this error , we have to check the varlist to find error 
                        for(int i=0 ; i<var_list.size()  -1 ; i++)
                        {
                            
                                    cout<<$1->getName()<<" "<<var_list[i].var_name<<endl ; 
                            if($1->getName()==var_list[i].var_name)
                            {
                                    cout<<"here"<<endl ; 
                                cout<<$1->getName()<<" "<<var_list[i].var_name<<endl ; 
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
                        $$ = new SymbolInfo($1->getName(),"STATEMENT") ;
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
                         $$ = new SymbolInfo($1->getName()+$2->getName(),"STATEMENTS") ;
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
                        $$ = new SymbolInfo($1->getName(),"STATEMENT") ;
                        printinlogfile(logfile ,"statement : var_declaration ") ; 
                        //ParseRelatedCodes
                        $$->setParseString("statement : var_declaration");
                        ParseLineRelated($$,$1,$1) ; 
                        vector<SymbolInfo*> ChildrenForParse ; 
                        ChildrenForParse.push_back($1);
                        ParseChildRelated($$ , ChildrenForParse) ;



                        }
                        |expression_statement { //a=b+c;
                        $$ = new SymbolInfo($1->getName(),"STATEMENT") ;
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
                        $$ = new SymbolInfo($1->getName(),"STATEMENT") ;
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
                            //RECHECK , error ? if for(int <- i ..) ; 
                            // for(a=3; <---  a<5 ;  <--- a++ <---- ){}
                        $$ = new SymbolInfo($1->getName()+$2->getName()+$3->getName()+$6->getName()+$9->getName()+$12->getName()+$13->getName(),"FOR_LOOP") ; //CHECK
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
                            //RECHECK DO IT BY LEFT OR RIGHT 
                            $$ = new SymbolInfo($1->getName()+$2->getName()+$3->getName()+$5->getName()+$7->getName(),"IF") ; //CHECK
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
                        $$ = new SymbolInfo($1->getName()+$2->getName()+$3->getName()+$5->getName()+$7->getName()+$8->getName()+$9->getName(),"IF_ELSE") ; //CHECK
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
                        $$ = new SymbolInfo($1->getName()+$2->getName()+$3->getName()+$5->getName()+$7->getName(),"WHILE_LOOP") ; //CHECK
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
                        $$ = new SymbolInfo($1->getName()+$2->getName()+$3->getName()+$4->getName()+$5->getName()+"\n","PRINT") ; //CHECK
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
                        $$ = new SymbolInfo($1->getName() + $2->getName() + $3->getName()+"\n","RETURN") ; //CHECK
                        //cout<<$3->getName()<<endl ; 
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
                        if($2->getType()=="VOID") //RECHECK 
                        {
                           string msg = "Void cannot be used in expression" ;
                           yyerror(msg) ; 
                        }   
                        } ;
ADDT_EXP:
{
    // it works with expression statement and exp
    // when we write a=3 or a<5 or a++ 
    //RECHECK 
    data_type = type ; 
   // cout<<data_type<<endl ; 
}
ADDT_VOID :
{
    //RECHECK : can be merged with addt_exp 
    // caution : $ number 
    
    //check if we have void+4 / void<4 
    if(data_type=="VOID")
    {
        string msg = "Void cannot be used in expression" ;
        yyerror(msg) ; 
    }
}
expression_statement : SEMICOLON 
            {
              $$ = new SymbolInfo($1->getName() , $1->getType()) ; //CHECK
              printinlogfile(logfile ,"	expression_statement : SEMICOLON		") ;    
              
              //RECHECK : BUT WHY ?? 
            $$->set_dtype($1->get_dtype()) ; //CHANGE
            type = $1->get_dtype() ; //RECHECK

            //FOR PARSE TREE 
              $$->setParseString("expression_statement : SEMICOLON");
              ParseLineRelated($$,$1,$1) ; 
            vector<SymbolInfo*> ChildrenForParse ; 
            ChildrenForParse.push_back($1);
            ParseChildRelated($$ , ChildrenForParse) ;  

            }
            | expression SEMICOLON 
            {
            $$ = new SymbolInfo($1->getName() + $2->getName() ,"EXPRESSION_STATEMENT") ; //CHECK
            printinlogfile(logfile ,"expression_statement : expression SEMICOLON 		 ") ;    
            $$->setType($1->getType()) ; //CHANGE
            type = $1->getType() ; //RECHECK

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

                $$ = new SymbolInfo($1->getName() ,"ID") ;
                //check if prev declared 
                printinlogfile(logfile ,"variable : ID 	 ") ; 


                  //ParseRelatedCodes
                $$->setParseString("variable : ID");
                ParseLineRelated($$,$1,$1) ; 
                vector<SymbolInfo*> ChildrenForParse ; 
                ChildrenForParse.push_back($1);
                ParseChildRelated($$ , ChildrenForParse) ;


                //RECHECK
                SymbolInfo* demo = symboltable->LookUp($1->getName() , logfile) ; 
                if(demo==NULL)//suppose we have not declared K . so it is not added in the variable list . Then we said K = 5 ; In such case K will not be found in the symbol table 
                {
                   string msg  = "Undeclared variable '"+$1->getName()+"'" ; 
                    yyerror(msg) ; 

                    $$->set_dtype("FLOAT") ; 
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
                $$ = new SymbolInfo($1->getName()+$2->getName()+$3->getName()+$4->getName(),"ARRAY") ;
                printinlogfile(logfile ,"variable : ID LSQUARE expression RSQUARE  	 ") ; 
                //$$->set_dtype("INT") ;

                //RECHECK
            SymbolInfo* x = symboltable->LookUp( $1->getName(), logfile) ;
                if(x==NULL) //suppose we have not declared K[8] . so it is not added in the variable list . Then we said K = 5 ; In such case K will not be found in the symbol table 
                {
                    string msg  = "Undeclared variable '"+$1->getName()+"'" ; 
                    yyerror(msg) ; 
                    $$->set_dtype("FLOAT") ;
                }
                else // we used a[43] , now check if it is actually an array 
                {
                    //have to check if a[4] , where is an array or not 
                    //cout<<x->get_size()<<endl ;
                    if(x->isAra()) {if(x->get_dtype()!="VOID") $$->set_dtype(x->get_dtype()) ; // recheck
                    else  $$->set_dtype("FLOAT") ; }
                    else 
                    {
                       string msg  = "'"+$1->getName()+"' is not an array" ; 
                    yyerror(msg) ;   
                    } 
                }

                // error if we say b[3.2]

              // BREAKPOINT : EXPRESSION DTYPE HOW DEFINED . 
              if($3->get_dtype() != "INT" || $3->get_dtype() != "CONST_INT")
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
                
                 $$ = new SymbolInfo($1->getName() ,"EXPRESSION") ;
                printinlogfile(logfile ,"expression 	: logic_expression	 ") ; 

                //recheck
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
                 $$ = new SymbolInfo($1->getName()+$2->getName()+$3->getName(), $3->getType()) ; //NOTICE , ITS DIFFERENT
                printinlogfile(logfile ,"expression 	: variable ASSIGNOP logic_expression 		 ") ; 
               if($1->get_dtype()!=$3->get_dtype()) // int a ; float b ; a = b;
                {
                      
                        string msg = " Warning: possible loss of data in assignment of "+ $3->get_dtype() + " to " + $1->get_dtype();
                        yyerror(msg) ;
                    
                }

                if($3->get_dtype()=="VOID") // a=void is not allowed
                {
                    string msg = "Void cannot be used in expression" ;
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

                $$ = new SymbolInfo($1->getName() ,"") ;
                printinlogfile(logfile ,"logic_expression : rel_expression 	 ") ; 
                $$->set_dtype($1->get_dtype()) ; 
                  //ParseRelatedCodes
                $$->setParseString("logic_expression : rel_expression");  
                ParseLineRelated($$,$1,$1) ; 
                vector<SymbolInfo*> ChildrenForParse ; 
                ChildrenForParse.push_back($1);
                ParseChildRelated($$ , ChildrenForParse) ;
            
            }
            |rel_expression LOGICOP rel_expression
            {
                $$ = new SymbolInfo($1->getName()+$2->getName()+$3->getName() , "") ; 
                printinlogfile(logfile ,"logic_expression : rel_expression LOGICOP rel_expression 	 	 ")  ;  
                $$->set_dtype($1->getType()) ; 
                //keep a type checking if both sides are equal type 
                // RECHECK : 4>"sg"

                if($1->get_dtype()=="VOID") 
                {
                    string msg = "Void cannot be used in expression" ;
                    yyerror(msg) ;
                    $1->set_dtype("FLOAT") ; 
                }

                if($3->get_dtype()=="VOID") 
                {
                    string msg = "Void cannot be used in expression" ;
                    yyerror(msg) ;
                    $1->set_dtype("FLOAT") ; 
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
               
                $$ = new SymbolInfo($1->getName() ,"REL_EXPRESSION") ;
             printinlogfile(logfile ,"rel_expression	: simple_expression ") ; 
               $$->set_dtype($1->get_dtype()) ; 
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
                $$ = new SymbolInfo($1->getName()+$2->getName()+$3->getName() , "REL_EXPRESSION") ; 
                printinlogfile(logfile ,"rel_expression	: simple_expression RELOP simple_expression	  ") ;   
                $$->set_dtype($1->get_dtype()) ; // not something specific 
                   if($1->get_dtype()=="VOID") 
                {
                    string msg = "Void cannot be used in expression" ;
                    yyerror(msg) ;
                    $1->set_dtype("FLOAT") ; 
                }

                if($3->get_dtype()=="VOID") 
                {
                    string msg = "Void cannot be used in expression" ;
                    yyerror(msg) ;
                    $1->set_dtype("FLOAT") ; 
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
              $$ = new SymbolInfo($1->getName() ,"SIMPLE_EXPRESSION") ;
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
                $$ = new SymbolInfo($1->getName()+$2->getName()+$3->getName() , "SIMPLE_EXPRESSION") ; 
                printinlogfile(logfile ,"simple_expression : simple_expression ADDOP term  ")  ;
                if($1->get_dtype()=="VOID")
                {
                     string msg = "Void cannot be used in expression" ;
                    yyerror(msg) ;
                    $1->set_dtype("FLOAT") ; 
                }
                if($3->get_dtype()=="VOID")
                {
                     string msg = "Void cannot be used in expression" ;
                    yyerror(msg) ;
                    $3->set_dtype("FLOAT") ; 
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
             $$ = new SymbolInfo($1->getName() ,"TERM") ;
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
                $$ = new SymbolInfo($1->getName()+$2->getName()+$3->getName() ,  "TERM") ; 
                printinlogfile(logfile ,"term :	term MULOP unary_expression ")  ;
                if($1->get_dtype()=="VOID")
                {
                     string msg = "Void cannot be used in expression" ;
                    yyerror(msg) ;
                    $1->set_dtype("FLOAT") ; 
                }
                if($3->get_dtype()=="VOID")
                {
                     string msg = "Void cannot be used in expression" ;
                    yyerror(msg) ;
                    $3->set_dtype("FLOAT") ; 
                }

                //RECHECK NO VOID DONE HERE . 

                // ex : 5/"hello" 
                 // const int can be 5 and int can be int a ; 

                //cout<<$3->getType()<<endl ;
                if( $2->getName() =="%" &&($1->get_dtype()!="INT" && $3->get_dtype()!="INT"))   
                {
                   // cout<<"LINE 1243 "<<$3->get_dtype()<< " " <<$3->getName()<<endl ; 
                    string msg = "Operands of modulus must be integers"; 
                    yyerror(msg) ; 
                    $$->set_dtype("INT") ;//recover 

                } //recheck ignored some .
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
                $$ = new SymbolInfo($1->getName()+$2->getName() , "UNARY_EXPRESSION") ; 
                printinlogfile(logfile ,"unary_expression : ADDOP unary_expression ")  ;
                 if($2->get_dtype()=="VOID")
                {
                    string msg = "Void cannot be used in expression" ;
                    yyerror(msg) ; 
                    
                    $$->set_dtype("FLOAT") ; 
                }//RECHECK : ++ara , ++string 
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
                 $$ = new SymbolInfo($1->getName()+$2->getName() ,  "UNARY_EXPRESSION") ; //CHECK
                printinlogfile(logfile ,"unary_expression : NOT unary_expression  ")  ;
                if($2->get_dtype()=="VOID")
                {
                    string msg = "Void cannot be used in expression" ;
                    yyerror(msg) ; 
                    
                }//RECHECK : !ara , !string 
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
                $$ = new SymbolInfo($1->getName() ,"UNARY_EXPRESSION") ;
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
                //NEW RULE STARTS 
                // a
                // b[32]
                $$ = new SymbolInfo($1->getName() ,"FACTOR") ; 
                printinlogfile(logfile ,"factor	: variable ") ; 
                 $$->set_dtype($1->get_dtype())     ; //this can be an array , so have to fix data type 



                //ParseRelatedCodes
                $$->setParseString("factor : variable");
                ParseLineRelated($$,$1,$1) ; 
                vector<SymbolInfo*> ChildrenForParse ; 
                ChildrenForParse.push_back($1);
                ParseChildRelated($$ , ChildrenForParse) ;


                }
                 |ID LPAREN argument_list RPAREN
                 {
                    // basic function calling 
                    // addnew(a,b)
                    $$ = new SymbolInfo($1->getName()+$2->getName()+$3->getName()+$4->getName() , "FUNCTION_CALL") ; //CHECK
                    printinlogfile(logfile ,"factor	: ID LPAREN argument_list RPAREN  ")  ;
                    // RECHECK ignoring all set type 
                    // Error check 
                    // check if such function actually exists 
                    SymbolInfo* info = symboltable->LookUp($1->getName(),logfile); 
                    // no such function with the same name 
                    if(info==NULL)
                    {
                        string msg = "Undeclared function '"+$1->getName()+"'" ; 
                        yyerror(msg) ; 
                        
                    } //ok name matched , but still have to make sure they are actually defined 
                    else if(info->isdef()!=true)
                    { 
                        string msg = "Undefined function '"+$1->getName()+"'" ;  //DO WE HAVE ? 
                        yyerror(msg) ; 
                         $$->set_dtype("FLOAT") ;
                        
                    } // ok , so name matched , such function also defined , now check if they are actually same (count parameter and argument length)
                     else if(info->isdef()!=true)
                    { 
                        string msg = "Undefined function '"+$1->getName()+"'" ;  //DO WE HAVE ? 
                        yyerror(msg) ; 
                        
                    } // ok , so name matched , such function also defined , now check if they are actually same (count parameter and argument length)
                    else 
                    {
                        //RECHECK : SKIPPED AN IF
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
                           // cout<<func_argument_list.size() <<endl ; 
                            for(int i=0 ; i<func_argument_list.size() ; i++)
                            {
                                //curr cout 
                               // cout<<"IN FUNCTION ARGUMENT FOR LINE : "<<line_count<<" DATA TYPE IS : "<<func_argument_list[i]<<endl ; 
                                string matchchecker = "" ; 
                                if(func_argument_list[i]=="CONST_INT") matchchecker="INT" ; 
                                else if (func_argument_list[i]=="CONST_FLOAT") matchchecker="FLOAT" ;
                                else matchchecker=func_argument_list[i] ; //for id 

                                //curr cout
                               // cout<<"IN LINE 1525 FOR FUNCTION NAME : " <<info->getName()<<" PARAMETER TYPE :  "<<info->get_param(i).parameter_dtype<<" ARGUMENT TYPE : "<<matchchecker<<endl ; 
                                if(convert_to_uppercase(info->get_param(i).parameter_dtype) !=matchchecker)  
                                {
                                   // cout<<i<<endl ; 
                                    problem.push_back(i+1);
                                    pc++ ; 
                                }
                            }
                            for(int j=0 ; j<pc ; j++)
                            {
                                string msg = "Type mismatch for argument "+to_string(problem[j])+" of '"+$1->getName()+"'" ;
                                yyerror(msg) ; 
                            }
                             $$->set_dtype(info->get_dtype())  ; //RECHECK 
                        }
                    }
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
                    $$ = new SymbolInfo($1->getName()+$2->getName()+$3->getName(),"FACTOR"  ) ; //CHECK
                    printinlogfile(logfile ,"factor	: LPAREN expression RPAREN   ")  ;
                //ParseRelatedCodes
                ParseLineRelated($$,$1,$3) ; 
                   $$->setParseString("factor : LPAREN expression RPAREN");
                vector<SymbolInfo*> ChildrenForParse ; 
                ChildrenForParse.push_back($1);
                ChildrenForParse.push_back($2);
                ChildrenForParse.push_back($3);
                ParseChildRelated($$ , ChildrenForParse) ;

                //RECHECK , CAN'T BE VOID 
                if($2->get_dtype()=="VOID")
                {
                     string msg = "Void cannot be used in expression" ;
                    yyerror(msg) ; 
                    
                    $$->set_dtype("FLOAT") ;
                }

                }
                |CONST_INT
                {
               // cout<<line_count<<" "<<$1->getName()<<" "<<$1->getType()<<endl ; 
                $$ = new SymbolInfo($1->getName() ,"CONST_INT"  ) ;
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
                $$ = new SymbolInfo($1->getName() ,"CONST_FLOAT"  ) ;
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
                $$ = new SymbolInfo($1->getName()+$2->getName() ,"FACTOR"  ) ; 
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
                $$ = new SymbolInfo($1->getName()+$2->getName() ,"FACTOR"  ) ; 
                printinlogfile(logfile ,"factor	: variable DECOP   ")  ;
                 $$->set_dtype($1->get_dtype()) ; 
                //ParseRelatedCodes
                $$->setParseString("factor : variable DECOP");
                ParseLineRelated($$,$1,$2) ; 
                vector<SymbolInfo*> ChildrenForParse ; 
                ChildrenForParse.push_back($1);
                ChildrenForParse.push_back($2);
                ParseChildRelated($$ , ChildrenForParse) ;


                // RECHECK : NO TYPE SETTING DONE . FOR $$ , CHECK PLEASE . 
                }; 
argument_list : arguments 
                {
                    //NEW RULE STARTS 
                    //WHENEVER WE ARE CALLING THE FUNCTION , WE HAVE TO KEEP TRACK OF ARGUMENT LIST 
                    //TO CHECK UP WITH PARAMETER LIST ; 

                    // foo(4,2,2 <---all together)
                $$ = new SymbolInfo($1->getName() ,"ARGUMENT_LIST"  ) ;
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
                $$ = new SymbolInfo($1->getName()+$2->getName()+$3->getName() ,"ARGUMENTS"  ) ; 
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
                    string msg = "Void cannot be used in expression" ;
                    yyerror(msg) ; 
                    $1->set_dtype("FLOAT") ; //for further recovery setting it to float . 
                }
                 else 
                {
                    $1->set_dtype($3->get_dtype()) ; 
                }
                
                 //cout<<" line 1661 type for logic is"<<line_count<<" "<<$1->get_dtype()<<endl  ;
                func_argument_list.push_back($1->get_dtype()) ;  
                //cout<<"FOR LINE : "<<line_count<<endl ; 
                //cout<<"THE TYPE FOR LOGIC EXPRESSION IS "<<$1->get_dtype()<<endl ; 
                //cout<<"THE DATA TYPE FOR LOGIC EXPRESSION IS "<<$1->get_dtype()<<endl ; 


  
                }
                |logic_expression
                {
                $$ = new SymbolInfo($1->getName() ,$1->getType()  ) ;
                printinlogfile(logfile ,"arguments : logic_expression") ; 
              //ParseRelatedCodes
                $$->setParseString("arguments : logic_expression");
                ParseLineRelated($$,$1,$1) ; 
                vector<SymbolInfo*> ChildrenForParse ; 
                ChildrenForParse.push_back($1);
                ParseChildRelated($$ , ChildrenForParse) ;

  if($1->get_dtype()=="VOID")
                {
                    string msg = "Void cannot be used in expression" ;
                    yyerror(msg) ; 
                    $1->set_dtype("FLOAT") ; //for further recovery setting it to float . 
                }
                else 
                {
                    $1->set_dtype($1->get_dtype()) ; 
                }
                //cout<<" line 1697 type for loguc is "<<$1->get_dtype()<<endl  ;
                func_argument_list.push_back($1->get_dtype()) ;  
               // cout<<"FOR LINE : "<<line_count<<endl ; 
               // cout<<"THE TYPE FOR LOGIC EXPRESSION IS "<<$$->get_dtype()<<endl ; 
               // cout<<"THE DATA TYPE FOR LOGIC EXPRESSION IS "<<$$->get_dtype()<<endl ; 

                } ;
%%
int main(int argc , char* argv[])
{
    int scope_id = 1 ;
    int bucket_size = 11; 
    if(argc<2){
        cout<<"Input file not found"<<endl ;
        return 1 ;
    }


    logfile.open("1905067_logfile.txt") ; 
    errorfile.open("1905067_errorfile.txt") ;
    parsefile.open("1905067_parsefile.txt");
    //parsefile<<"hl"<<endl ;
    
   // cout<<"SCOPE ID LINE 1232:"<<scope_id<<endl ;
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
