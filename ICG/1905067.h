#pragma once
#include<iostream>
#include<fstream>
#include<string>
#include<vector>
using namespace std; 

class SymbolInfo
{
    string Symbol_name ;
    string Symbol_type ;
    
    SymbolInfo* nextSymbolPointer ;
    

    struct parameterInfo
    {
        string parameter_name ; 
        string parameter_dtype;
        
    };
    int ara_size = -1; 
    string dtype ;
    bool isdeclared = false ;
    bool isdefined = false ; 
    string parsePrint ;
    vector<parameterInfo> functionParam; 
 
    string ParseString ;
    int startingLine ; 
    int EndingLine ; 
    vector<SymbolInfo*>childlist ; 
    bool isleaf ;
    int children_count = 0 ;  
    int space_depth ; 
    bool sameSE = false ;
    int distributing_space ; 



    //! for assembly code 
    bool global_var ; // has to differentiate in code btn local and global
    string asmcode ; // for example , if local variable , then it is bp-2/4 , if it is global variable , then use SI 
    int offset ; // if local , then have to find the value of offset 
    int array_start ; // starting value of array 
    string label ; //



    vector<int>truelist ; 
    vector<int>falselist ; 
    vector<int>nextlist ; 
    bool logicIsBool ; 
    int manyelse ; 
    string andor ; 

public :
    SymbolInfo(string name , string type)  //constructor
    {
        nextSymbolPointer = NULL ;
        Symbol_name = name ;
        Symbol_type = type ;
        asmcode = "";
    }
    SymbolInfo(const SymbolInfo *sym)
    {
        Symbol_name=sym->Symbol_name;
        Symbol_type=sym->Symbol_type;
        asmcode=sym->asmcode;
    }
    ~SymbolInfo() //destructor
    {
        //not necessary here .
        functionParam.clear() ; 
    }
    string getName() const
    {
    return Symbol_name;
    }
string getType()
{
    return Symbol_type ;
}
void setName(string name)
{
    
    this->Symbol_name = name ;
}
void  setType(string type)
{
    this->Symbol_type = type ;
}
void  setpointer(SymbolInfo* next)
{
    this->nextSymbolPointer = next ;
}
SymbolInfo*  nextSymbol()
{
    return this->nextSymbolPointer ;
}
void  addnew(string name , string type)
{
   
     struct parameterInfo p;
     p.parameter_name = name ; 
     p.parameter_dtype = type ; 
     functionParam.push_back(p) ; 
}
int   get_paramcount()
{
    int p = functionParam.size() ; 
    return p ;
}
parameterInfo   get_param(int i)
{
    parameterInfo p = functionParam[i] ; 
    return p ;
}
parameterInfo  get_param(string name)
{
    for(int i =0 ; i<get_paramcount() ; i++) 
    {
        if(functionParam[i].parameter_name == name) return functionParam[i] ;
        
    }
    return functionParam[0];
}
void  set_size(int size)
{
    ara_size = size ; 
}
int   get_size(){return ara_size;}
void   set_dtype(string type)
{
    dtype=type;
}
string   get_dtype()
{
    return dtype;
}
bool  isfunc()
{
    if(Symbol_type=="FUNCTION") return true ; 
    return false ; 
}
bool  isAra()
{
    if(ara_size==-1) return false ; 
    return true ;
}
bool  isVar()
{
    if(isfunc()==false && isAra()==false)return true ; 
    else return false ; 
}
bool isdef(){return isdefined;}
bool isdec(){return isdeclared;} 
void setisdef(bool check){isdefined = check;}
void setisdec(bool check){isdeclared=check;} 



// for 8086 
void setoffset(int val)
{
    offset = val ; 
}
int getoffset()
{
    return offset;
}
void setlabel(string label){this->label = label ; }
string getlabel(){return label;}
void setcode(string code , bool global , int arraystart=0)
{
    asmcode = code ; 
    global_var = global;
    array_start = array_start;
}
string getcode()
{
    return asmcode; // mainly SI or BP-offset will be done in main parser,y
}
bool checkifglobal(){return global_var;}
void setglb(bool x){global_var=x; }

void add_to_true_list(int i)
{
   // cout<<"adding to true list"<<i<<endl  ; 
    truelist.push_back(i) ; 
}
void add_to_false_list(int i)
{
    falselist.push_back(i) ; 
}
void add_to_next_list(int i)
{
   // cout<<"adding to true list"<<i<<endl  ; 
    nextlist.push_back(i) ; 
}
void set_tlist(vector<int>tl)
{ truelist = tl ;}
void set_flist(vector<int>tl){falselist = tl ;}
void set_nextlist(vector<int>nl){nextlist = nl ; }
vector<int> get_truelist()
{ 
    return truelist ; 
}
vector<int> get_falselist()
{
    return falselist ;
}
vector<int> get_nextlist()
{
    return nextlist ; 
}
void setlogic(bool exp){logicIsBool = exp ;}
bool getlogic(){return logicIsBool ; }
int getmanyelse(){return manyelse; }
void setmanyelse(int n){manyelse = n ; }
void setandor(string s){andor = s;}
string getandor(){return andor ; }
};

class ScopeTable
{
    int ScopeID ;
    SymbolInfo** Hashtable ;
    int num_buckets ;
    ScopeTable* parent_scope ;

public :
    ScopeTable(int n)
    {
        this->num_buckets = n ;
        Hashtable = new SymbolInfo*[num_buckets] ;
        for(int i =0 ; i<num_buckets ; i++)
             Hashtable[i] = NULL ;
    }
    ScopeTable(int ID , int num_buckets , ScopeTable *parent)
    {
        this->ScopeID = ID ;
        this->num_buckets = num_buckets ;
        this->parent_scope = parent ;
        Hashtable = new SymbolInfo*[num_buckets] ;
        for(int i =0 ; i<num_buckets ; i++)
            Hashtable[i] = NULL ;

    }
    int getID(){return ScopeID;}

    ScopeTable* getparent()
    {
        return this->parent_scope ;
    }
    //SDBM Hash function will return the bucket number
    unsigned long long int sdbm_hash(string name)
    {
         unsigned long long int x = 0 ;
         long long int l = name.length() ;
        for( long long int i=0 ; i<l ; i++)
        {
            x = (name[i] + (x<<6) + (x<<16)-x) ;

        }
        return x%num_buckets;
    }
    bool Insert(SymbolInfo &Symbol , ofstream &out)
    {
        /*
        if(LookUp(Symbol.getName())!=NULL)
        {
            out<<"Already exists"<<endl ;
            return false ;
        }
        */




        int hashval = this->sdbm_hash(Symbol.getName()) % num_buckets  ;
        SymbolInfo* curr = Hashtable[hashval] ;



        while(curr != NULL )
        {
            if(curr->getName() == Symbol.getName())
                {
                    //out<<"\t"<<Symbol.getName()<<" already exists in the current ScopeTable"<<endl ; //have to change later

                    return false;
                }
            curr = curr->nextSymbol() ;

        }

        hashval = this->sdbm_hash(Symbol.getName()) % num_buckets  ;
        curr = Hashtable[hashval] ;

        int posi0 = hashval , secPos = 1 ;
        if(curr==NULL)
        {
            Hashtable[hashval] = &Symbol ;
            Symbol.setpointer(NULL) ;
            //out<<"ins here"<<endl ;
           // out<<"\tInserted in ScopeTable# "<<ScopeID<<" at position "<<hashval+1<<", "<<secPos<<endl ;


        }
        else
        {
            secPos++ ;
            while (curr->nextSymbol()!=NULL)
            {
                curr = curr->nextSymbol()  ;
                secPos++ ;
            }
            curr->setpointer(&Symbol) ;
            Symbol.setpointer(NULL) ;
             //out<<"\tInserted in ScopeTable# "<<ScopeID<<" at position "<<hashval+1<<", "<<secPos<<endl ;



        }


        return true ;


    }
    SymbolInfo* LookUp(string name  , ofstream &out)
    {
        int ps = 1 ;
        int hashvalue  = sdbm_hash(name) % num_buckets ;
        SymbolInfo* currHashPos = Hashtable[hashvalue] ;
        if(currHashPos == NULL) return NULL ;

        while(currHashPos != NULL )
        {
            if(currHashPos->getName() ==name)
                {
                    //out<<"\t'"<<name<<"' found in ScopeTable# "<<ScopeID<<" at position "<<hashvalue+1<<", "<<ps<<endl ; //have to change later

                    return currHashPos;
                }
            currHashPos = currHashPos->nextSymbol() ;
            ps++ ;
        }
        return NULL ;



    }
       SymbolInfo* deffunc(string name  , ofstream &out)
    {
        int ps = 1 ;
        int hashvalue  = sdbm_hash(name) % num_buckets ;
        SymbolInfo* currHashPos = Hashtable[hashvalue] ;
        if(currHashPos == NULL) return NULL ;

        while(currHashPos != NULL )
        {
            if(currHashPos->getName() ==name && currHashPos->isfunc() && currHashPos->isdef())
                {
                    //out<<"\t'"<<name<<"' found in ScopeTable# "<<ScopeID<<" at position "<<hashvalue+1<<", "<<ps<<endl ; //have to change later

                    return currHashPos;
                }
            currHashPos = currHashPos->nextSymbol() ;
            ps++ ;
        }
        return NULL ;



    }
    bool Delete(string name  , ofstream &out )
    {
        //lookup to make sure that this aint empty

        /*SymbolInfo* checkEmp = this->LookUp(name );
        if(checkEmp == NULL )
        {
            out<<"\tNot found in the current ScopeTable"<<endl ;
            return false ;
        }
        */
        int hashvalue  = sdbm_hash(name) % num_buckets ;
        int pos = 1 ;
        SymbolInfo* curr = Hashtable[hashvalue] ;
        SymbolInfo* previous = NULL ;
        while (curr!=NULL)
        {
            if(curr->getName() == name)
                break;

            previous = curr ;
            curr = curr->nextSymbol() ;
            pos++ ;

        }

        if(curr==NULL)
        {
            out<<"\tNot found in the current ScopeTable"<<endl ;
            return false ;
        }
        else if(previous == NULL )
        {
            delete curr ;
            Hashtable[sdbm_hash(name) % num_buckets] = curr->nextSymbol() ;
        }
        else
        {
            delete curr ;
            previous->setpointer(curr->nextSymbol()) ;
        }

        //out<<"\tDeleted '"<<name<<"' from ScopeTable# "<<ScopeID<<" at position "<<hashvalue+1<<", "<<pos<<endl ;
        return true ;



    }
    void print(  ofstream &out)
    {
        out<<"\tScopeTable# "<<ScopeID<<endl ;
        for(int i = 0 ; i<num_buckets ; i++)
        {
            SymbolInfo* currpos = Hashtable[i] ;
            int fentry = 1  , broke  = 0 ;

            while ( currpos!=NULL )
            {
               //out<<currpos->getName()<<" "<<currpos->getType()<<endl ;
               if(fentry)
                    {
                        out<<"\t"<<i+1<<"--> <" ;
                        fentry = 0 ;
                    }
               if(currpos->isfunc()) 
               {
                //cout<<"IN FUNC T: "<<currpos->getType()<<" DT : "<<currpos->get_dtype() <<" D : "<<currpos->getName()<<endl ; 
                 out<<currpos->getName()<<", "<<currpos->getType()<<", "<<currpos->get_dtype()<<"> " ; 
               }  
               else if(currpos->isAra())   
               {
                //cout<<"IN ARRAY T: "<<currpos->getType()<<" DT : "<<currpos->get_dtype() <<endl ; 
                out<<currpos->getName()<<", "<<currpos->get_dtype()<<", "<<currpos->getType()<<"> " ; 
               } 
               else out<<currpos->getName()<<", "<<currpos->getType()<<"> " ;
               currpos = currpos->nextSymbol() ;
               if(currpos==NULL) out<<endl ;
               else out<<"<" ;
               broke =  1;
            }

           if(broke != 1 )
                {

                    //out<<"\t"<<i+1<<"--> "<<endl ;
                }


        }

    }
    ~ScopeTable()
    {
        delete[] Hashtable;
    }



};



class SymbolTable
{
    ScopeTable* current_Scope_Table ;
    public:
    SymbolTable(int size)
    {
        current_Scope_Table = NULL ;
        //Enter_scope(1 , size) ; //not needed now . 
    }
    ~SymbolTable()
    {
            //do nothing
    }
    void Enter_scope(int id , int sz)
    {
        ScopeTable* ncurr = new ScopeTable(id , sz , current_Scope_Table) ;
        current_Scope_Table = ncurr ;


    }
    bool isemptytable()
    {
        if(current_Scope_Table==NULL )return true ;
        else return false ;
    }
    void Exit_scope(  ofstream &out)
    {
        if(isemptytable())
        {
            out<<"no scope table rn"<<endl ;
            return ;
        }
        ScopeTable* parScope = current_Scope_Table->getparent() ;
        delete current_Scope_Table ;
        current_Scope_Table = parScope ;

    }
    bool insert(SymbolInfo &Symbol , ofstream &out)
    {
        if(isemptytable())
        {
            out<<"No current scope is available"<<endl ;
            return false ;
        }
        return current_Scope_Table->Insert(Symbol,out);

    }
    bool remove(string name , ofstream &out )
    {
        if(isemptytable())
        {
             //out<<"No current scope is available"<<endl ;
            return false ;
        }
        return current_Scope_Table->Delete(name,out );

    }
    SymbolInfo* LookUp(string key , ofstream &out )
    {
         if(isemptytable())
        {
             //out<<"No current scope is available"<<endl ;
            return NULL ;
        }

        ScopeTable *temp = current_Scope_Table ;
        while (temp!=NULL)
        {
            SymbolInfo* data = temp->LookUp(key ,out) ;
            if(data==NULL) temp = temp->getparent() ;
            else
            {
                //out<<"found data"<<endl ;
                return data ;
            }
        }
        //out<<"\t'"<<key<<"' not found in any of the ScopeTables"<<endl ;
        return NULL ;



    }
        SymbolInfo* FindDefFunc(string key , ofstream &out )
    {
         if(isemptytable())
        {
             //out<<"No current scope is available"<<endl ;
            return NULL ;
        }

        ScopeTable *temp = current_Scope_Table ;
        while (temp!=NULL)
        {
            SymbolInfo* data = temp->deffunc(key ,out) ;
            if(data==NULL) temp = temp->getparent() ;
            else
            {
                //out<<"found data"<<endl ;
                return data ;
            }
        }
        //out<<"\t'"<<key<<"' not found in any of the ScopeTables"<<endl ;
        return NULL ;



    }
    int getscopeID(string key, ofstream &out)
    {
         if(isemptytable())
        {
             //out<<"No current scope is available"<<endl ;
            return NULL ;
        }
        ScopeTable *temp = current_Scope_Table ;
        while (temp!=NULL)
        {
            SymbolInfo* data = temp->LookUp(key ,out) ;
            if(data==NULL) temp = temp->getparent() ;
            else
            {
                //out<<"found data"<<endl ;
                return temp->getID() ;
            }
        }
        return 0 ; 
    }
    void Print_curr( ofstream &out)
    {
        if(isemptytable())
        {
             out<<"Current scope is empty"<<endl ;
            return  ;
        }
        return current_Scope_Table->print(out) ;


    }
    int currScopeID()
    {
        return current_Scope_Table->getID() ;
    }
    void print_all(  ofstream &out)
    {
        if(isemptytable())
        {
             out<<"the scope is empty"<<endl ;
            return  ;
        }
        current_Scope_Table->print(out) ;
        ScopeTable* ptable = current_Scope_Table->getparent()  ;
        while (ptable != NULL && ptable->getID()!=0)

        {
            ptable->print(out)  ;
            //out<<endl ;
            ptable = ptable->getparent() ;
        }

        return ;

    }


};
