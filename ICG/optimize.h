#include<iostream>
#include<fstream>
#include<string>
#include<vector> 
using namespace std;   
vector<string>split(const string &str , char del)
{
    vector<string>words ; 
    string word = "" ; 
    for(int i = 0 ; i<str.length() ; i++)
    {
        if(str[i]==del || str[i]=='\t')
        {
            if(word!="")
            {
                   words.push_back(word)  ; 
                    word = "" ; 
            }
         
        }
        else word+=str[i]; 
    }
    if(word!="")words.push_back(word) ; 
    return words ; 
}

void perform_optimzation()
{
    ifstream mainfile ; 
    mainfile.open("1905067assembly.asm") ; 
    ofstream optfile ; 
    string currline ; 
    string prevline = "" ; 
    vector<string> line0 ; 
    optfile.open("1905067opt.asm") ; 

    if(!mainfile.is_open())
    {
        cerr<<"Error opening the file"<<endl ; 
        return ; 
    }
    if(!optfile.is_open())
    {
        cerr<<"Error opening the file"<<endl ; 
        return ; 
    }




    while (getline(mainfile , currline))
    {
        vector<string> line1 = split(currline , ' ') ; 
        if(line1.size()==0)continue; 

        if(line0.size()==0)
        {
            optfile<<";assigning line"<<endl ;
            prevline = currline  ;
            line0 = line1 ; 
            continue;
        }

        if(line1[0]=="POP" && line0[0]=="PUSH")
        {
            optfile<<";modified here because of POP PUSH"<<endl ; 
            if(line1[1]!=line0[1])
            {
                optfile<<"\t MOV "<<line1[1]<<" , "<<line0[1]<<endl ; 
            }
            
            line0.clear() ; 
            prevline = "" ; // in this way , the next line will be optimized automatically 
        }
        else if(line1[0]=="MOV")
        {
            //.//.cout<<"INSIDE MOVE"<<endl ; 
            //.cout<<line0[0]<<endl ; 
            if(line1[1] == line1[3]){
                optfile<<";modified here because of MOVING A TO A"<<endl ; 
                //.cout<<"MOVING A TO A "<<endl ; 
            } 
            else if(line0[0]=="MOV")
            {
                //.cout<<"PREVIOUS LINE IS ALSO MOVE"<<endl ; 
                string fp1 = line1[1] ; 
                string fp2 = line1[3] ;
                string sp1 = line0[1] ;
                string sp2 = line1[3] ; 
                if(fp1 == sp1)
                {
                    //.cout<<fp1<<" "<<sp1<<endl ; 
                    optfile<<";modified here because of MOVING A TO B and then C to B"<<endl ; 
                    line0 = line1 ; 
                    prevline = currline ; 
                }
                else if(fp1==sp2 && sp1 == fp2)
                {
                    optfile<<";modified here because of MOVING A TO B and then B to A "<<endl ; 
                    //.cout<<fp1<<" "<<sp2<<" "<<sp1<<" "<<fp2<<endl ; 
                    optfile<<prevline<<endl ; 
                    line0.clear() ; 
                    prevline="" ; 

                }
                else 
                {
                    //.cout<<"SO WRITE IT DOWN"<<endl ; 
                    optfile<<prevline<<endl ; 
                    line0 = line1 ;
                    prevline = currline ; 
                }
            }
            else 
            {
                //.cout<<"SO WRITE IT DOWN"<<endl ; 
                    optfile<<prevline<<endl ; 
                    line0 = line1 ;
                    prevline = currline ; 
            }
            // ignore 
        }
        else if(line0[0]=="ADD" || line0[0]=="SUB")
        {
            if(line0[3]=="0")
            {
                optfile<<"; ignored for zero operation"<<endl ; 
            }
            else 
            {
            optfile<<prevline<<endl ; 
            line0 = line1 ; 
            prevline = currline ; 
            }
        }
        else if(line0[0]=="MUL")
        {
            if(line0[3]=="1")
            {
                optfile<<"; ignored for multiply by 1"<<endl ; 
            }
            else 
            {
             optfile<<prevline<<endl ; 
            line0 = line1 ; 
            prevline = currline ; 
            }
        }
        else 
        {
            optfile<<prevline<<endl ; 
            line0 = line1 ; 
            prevline = currline ; 
        }
       
    }
    optfile<<prevline<<endl  ; 
    mainfile.close() ; 
    optfile.close() ; 

    


}




