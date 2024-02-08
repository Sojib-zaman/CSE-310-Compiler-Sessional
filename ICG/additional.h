#include<bits/stdc++.h>
#include <string>
#include <fstream>
#include <iostream>
using namespace std; 

map<int , string> bp_map  ;

int write_for_global( int line_no , string value , int isara = 0 )
{
    // Open the input and output files
    ofstream temporary_file ; 
    ifstream actual_file ; 
    temporary_file.open("temp.asm") ; 
    actual_file.open("1905067assembly.asm") ; 

    if (!actual_file.is_open()) {
        cerr << "Failed to open input file 1905067assembly.asm !" << endl;
        return -1;
    }

    //? Copy the input file to the output file, inserting the new global variable at the appropriate line
    int tline = 0 ; 
    int done = 0 ; 
    string s ; 
    while(getline(actual_file , s))
    {
        // cout<<s<<endl  ;
        if(tline==line_no && isara==0)
        {
            // cout<<"printing in line no  "<<line_no<<" "<<value<<endl  ; 
            temporary_file<<"\t "<<value<<" DW 1 DUP (0000H) "<<endl ; 
            done = 1 ; 
        }
        else if(tline==line_no && isara!=0)
        {
            temporary_file<<"\t "<<value<<" DW "<<isara<<" DUP (0000H) "<<endl ; 
            done = 1 ;
        }
        temporary_file<<s<<endl ; 
        tline++ ; 
    }
    if(done ==0 ){
        if(isara==0)
            temporary_file<<"\t "<<value<<" DW 1 DUP (0000H)"<<endl ; 
        else 
            temporary_file<<"\t "<<value<<" DW "<<isara<<" DUP (0000H)"<<endl ; 
            done = 1 ; 
    }
    remove("1905067assembly.asm")  ; 
    rename("temp.asm" ,"1905067assembly.asm") ; 
    temporary_file.close() ; 
    actual_file.close() ; 


    return 1 ; 

}



void convert_backpatching(  )
{
    // Open the input and output files
    ofstream temporary_file ; 
    ifstream actual_file ; 
    temporary_file.open("temp.asm") ; 
    actual_file.open("1905067assembly.asm") ; 

    if (!actual_file.is_open()) {
        cerr << "Failed to open input file 1905067assembly.asm !" << endl;
        return;
    }

    //? Copy the input file to the output file, inserting the new global variable at the appropriate line
    int tline = 0 ; 
    int done = 0 ; 
    string s ; 
    while(getline(actual_file , s))
    {
        temporary_file<<s<<" "<< bp_map[tline+1]<<endl ;  //!CAUTION +1
        tline++ ; 
        
    }
    remove("1905067assembly.asm")  ; 
    rename("temp.asm" ,"1905067assembly.asm") ; 
    temporary_file.close() ; 
    actual_file.close() ; 


   

}



void backpatch(vector<int>list , string str)
{
    for(int i= 0 ; i<list.size() ; i++)
    {
        bp_map.insert({list[i], str}) ; 
        cout<<list[i]<<" "<<str<<endl ; 
    }
}


vector<int> merge(vector<int>list  , vector<int>list2 )
{
    set<int>s ; 
    for(int i = 0 ; i<list.size() ; i++)
        s.insert(list[i]) ; 
    for(int i = 0 ; i<list2.size() ; i++)
        s.insert(list2[i]) ; 

    vector<int> vc(s.begin(), s.end());
    cout<<"Printing merge list "<<endl ; 
    for(int i = 0 ; i<vc.size() ; i++)
    {
        cout<<vc[i]<<endl ; 
    }
    return vc  ; 
}