class SymbolInfo
{
    string Symbol_name ;
    string Symbol_type ;

    SymbolInfo* nextSymbolPointer ;

    //all these are defined as private

public :
    SymbolInfo(string name , string type)  //constructor
    {
        nextSymbolPointer = NULL ;
        Symbol_name = name ;
        Symbol_type = type ;
    }
    ~SymbolInfo() //destructor
    {
        //not necessary here .
    }
    string getName() ;
    string getType() ;

    void setName(string) ;
    void setType(string) ;

    void setpointer(SymbolInfo*) ;
    SymbolInfo* nextSymbol() ;


};
string SymbolInfo::getName()
{
    return Symbol_name;
}
string SymbolInfo::getType()
{
    return Symbol_type ;
}
void SymbolInfo::setName(string name)
{
    this->Symbol_name = name ;
}
void SymbolInfo::setType(string type)
{
    this->Symbol_type = type ;
}
void SymbolInfo::setpointer(SymbolInfo* next)
{
    this->nextSymbolPointer = next ;
}
SymbolInfo* SymbolInfo::nextSymbol()
{
    return this->nextSymbolPointer ;
}


//this is basically the hash table
//will have multiple symbol info , an unique id to determine hash#1
//and a parent pointer of type scope table
//for the symbol info it will have pointer to pointer of symbol info
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
                    out<<"\t"<<Symbol.getName()<<" already exists in the current ScopeTable"<<endl ; //have to change later

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
                    out<<"\t'"<<name<<"' found in ScopeTable# "<<ScopeID<<" at position "<<hashvalue+1<<", "<<ps<<endl ; //have to change later

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

        out<<"\tDeleted '"<<name<<"' from ScopeTable# "<<ScopeID<<" at position "<<hashvalue+1<<", "<<pos<<endl ;
        return true ;



    }
    void print(  ofstream &out)
    {out<<"\tScopeTable# "<<ScopeID<<endl ;
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
               out<<currpos->getName()<<","<<currpos->getType()<<"> " ;
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
    SymbolTable()
    {
        current_Scope_Table = NULL ;
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
        out<<"\t'"<<key<<"' not found in any of the ScopeTables"<<endl ;
        return NULL ;



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
        while (ptable != NULL)

        {
            ptable->print(out)  ;
            //out<<endl ;
            ptable = ptable->getparent() ;
        }

        return ;

    }


};
