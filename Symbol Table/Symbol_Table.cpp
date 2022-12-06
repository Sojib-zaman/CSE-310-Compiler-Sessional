#include<iostream>
#include<stdio.h>
#include<bits/stdc++.h>
#include<string>
#include<fstream>
using namespace std;
//symbol class containing <symbol name , symbol type> and hash pointer
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
     long long int sdbm_hash(string name)
    {
         long long int x = 0 ;
         long long int l = name.length() ;
        for( long long int i=0 ; i<l ; i++)
        {
            x = (name[i] + (x<<6) + (x<<16)-x)%num_buckets ;

        }
        return x ;
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
                    out<<"\t'"<<Symbol.getName()<<"' already exists in the current ScopeTable"<<endl ; //have to change later

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
            out<<"\tInserted in ScopeTable# "<<ScopeID<<" at position "<<hashval+1<<", "<<secPos<<endl ;


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
             out<<"\tInserted in ScopeTable# "<<ScopeID<<" at position "<<hashval+1<<", "<<secPos<<endl ;



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

                    out<<"\t"<<i+1<<"--> "<<endl ;
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


int main ()

{

    ifstream in("in18.txt") ;
    ofstream out("my_out.txt") ;

    if(in.is_open()!=true || out.is_open()!=true)
    {
    out<<"error in opening files"<<endl ;

    }

    int bucket_no , sc_id = 1 ;
    in>>bucket_no ;
    //SymbolTable* S = new SymbolTable() ;
    SymbolTable S;
    S.Enter_scope(sc_id , bucket_no) ;
    out<<"\tScopeTable# "<<sc_id<<" created"<<endl ;
    int command_count = 1 ;
    int current_scope = 1 ;
    int no_of_scope = 1 ;
    int ok=1 ;
    string instruction , aux_info;
    string sname , stype ;
    while (ok)
    {
        in>>instruction  ;
        if(instruction =="I")
        {
            /*
            in>>sname>>stype ;
            out<<"Cmd "<<command_count<<": "<<instruction<<" "<<sname<<" "<<stype<<endl ;
            command_count++ ;
            */
            string data ;
            getline(in , data ) ;
           // out<<data.length()<<endl ;
            out<<"Cmd "<<command_count<<": "<<instruction<<""<<data<<endl ;
            command_count++ ;
            int data_count  = 0 ;
            string y ;
            stringstream P(data) ;
            while(getline(P , y ,' ' ))
            {
                //out<<y<<endl ;
                data_count++ ;
            }

           // out<<data_count<<endl ;

            if(data==" " || data_count!=3)
                out<<"\tNumber of parameters mismatch for the command I"<<endl ;
            else
            {

                string x ;
                stringstream T(data) ;
                while(getline(T , x ,' ' ))
                {
                    if(x!=" ")
                   {
                     sname = stype ;
                        stype = x ;
                   }
                }



                //out<<sname<<" "<<stype<<endl ;
                SymbolInfo* info = new SymbolInfo(sname , stype) ;
                S.insert(*info  ,out) ;
            } //check
        }
        else if (instruction == "L")
        {

           string data ;
           getline(in , data) ;
           out<<"Cmd "<<command_count<<": "<<instruction<<""<<data<<endl ;
           command_count++ ;




            int data_count  = 0 ;
            string y ;
            stringstream P(data) ;
            while(getline(P , y ,' ' ))
            {
                //out<<y<<endl ;
                data_count++ ;
            }

           // out<<data_count<<endl ;

            if(data==" " || data_count!=2)
                out<<"\tNumber of parameters mismatch for the command L"<<endl ;
            else
               {
                   string x ;
                   stringstream T(data) ;
                   while(getline(T , x ,' ' ))
                   {
                       //out<<x<<endl ;
                   }

                   S.LookUp(x ,out) ;
               }




        }
          else if (instruction == "D")
        {
            string data ;
           getline(in , data) ;
           out<<"Cmd "<<command_count<<": "<<instruction<<""<<data<<endl ;
           command_count++ ;




            int data_count  = 0 ;
            string y ;
            stringstream P(data) ;
            while(getline(P , y ,' ' ))
            {
                //out<<y<<endl ;
                data_count++ ;
            }

           // out<<data_count<<endl ;

            if(data==" " || data_count!=2)
                out<<"\tNumber of parameters mismatch for the  command D"<<endl ;
            else
               {
                   string x ;
                   stringstream T(data) ;
                   while(getline(T , x ,' ' ))
                   {
                       //out<<x<<endl ;
                   }
                S.remove(x ,out) ;
               }
        }
          else if (instruction == "P")
        {
            getline(in , aux_info) ;
           out<<"Cmd "<<command_count<<": "<<instruction<<""<<aux_info<<endl ;
           command_count++ ;

            if(aux_info==" A")
            {
                S.print_all( out)  ;
            }
            else if(aux_info==" C")
            {
                S.Print_curr(out) ;
            }
            else
            {
                out<<"\tNumber of parameters mismatch for the command P"<<endl ;
            }

        }
        else if(instruction=="S")
        {


            getline(in , aux_info) ;
            out<<"Cmd "<<command_count<<": "<<instruction<<""<<aux_info<<endl ;
command_count++ ;
            if(aux_info.length()!=0)
            {
                out<<"\tNumber of parameters mismatch for the command S"<<endl ;
            }
            else
            {
                sc_id++ ;
            S.Enter_scope(sc_id , bucket_no) ;
            current_scope = sc_id ;

           out<<"\tScopeTable# "<<sc_id<<" created"<<endl ;
           no_of_scope++ ;

            }


        }
        else if(instruction=="E")
        {

             getline(in , aux_info) ;
              out<<"Cmd "<<command_count<<": "<<instruction<<""<<aux_info<<endl ;
            command_count++ ;


           if(aux_info.length()!=0)
            {
                out<<"\tNumber of parameters mismatch for the command E"<<endl ;
            }
            else
            {

                if(current_scope!=1)
                 {
                    out<<"\tScopeTable# "<<current_scope<<" removed"<<endl ;
                    no_of_scope--  ;

                    S.Exit_scope(out) ;
                    current_scope = S.currScopeID() ;
                 }
                 else
                    out<<"\tScopeTable# "<<current_scope<<" cannot be removed"<<endl ;
            }


        }
        else if(instruction=="Q")
        {



            out<<"Cmd "<<command_count<<": "<<instruction<<endl ;
            while (no_of_scope!=0)
            {
                out<<"\tScopeTable# "<<S.currScopeID()<<" removed"<<endl ;
                 S.Exit_scope(out) ;
                 no_of_scope-- ;

            }




            break;
        }


    }


    // exit all scope

    in.close() ;
  out.close() ;

    return 0 ;



}










