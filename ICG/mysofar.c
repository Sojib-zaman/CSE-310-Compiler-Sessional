int i,j;
int a,b,c;
int gbara[20] ;
void func_a(){
	a = 7;
}
void foo(int a)
{
	println(a) ; 
}
int raet(int a)
{
	a = a + 1 ;
	return a ; 
}
int sec(int a , int b)
{
	a = a + b ; 
	return a ; 
}
int third(int a , int b , int c)
{
	int d ; 
	d = a+b+c ; 
	return d ; 
}
int bar(int a, int b){	
	c = 4*a + 2*b;
	return c;
}

int foos(int a){
	a = a + 3;
	return a;
}
int inner(int a)
{
	a = a + 4 ; 
	return a ; 
}
int outer(int a )
{
	int r ; 
	r= inner(a) ; 
	return r ; 
}
int main(){
 
	int k,ll,m,n,o,p;
	int ara[3] ; 
 
	i = 1;
	println(i);
	j = 5 + 8;
	println(j);
	k = i + 2*j;
	println(k);

	m = k%9;
	println(m);
 
	o = i> j ; 
	println(o) ; 
	n = m==0 ; 
	println(n) ; 

	if(i!=j)
		p=10 ; 
	else 
		p=5 ; 
	
	println(p) ; 
	if(j==12)
		p = 9 ; 
	else p=2 ;

	func_a() ; 
	println(a) ; 

	foo(20); 
	println(i) ; 

	
	p++;
	println(p);
 
	k = -p;
	println(k);


	int al , bl ; 
	al = k * p ;
	println(al) ; 
	k = 18 ; 
	p = 6 ; 
	println(k) ; 
	println(p) ; 
	bl = k / p  ; 
	println(bl) ; 
	bl = k%5 ; 
	println(bl) ; 
	al = +bl  ; 
	println(al) ; 
	m = -al ; 
	println(m);  
 
	int v,b,c ; 
	b = 12 ; 
	v = raet(b) ; 
	println(v) ; 
	b++ ; 
	v = v + 4 ; 
	c = sec(b,v) ; 
	println(c)  ; 
	
	c = third(b,c,v) ; 
	println(c) ; 
	int l ;
	l = bar(i,j);
	println(l);
	
	j = 6 * bar(i,j) + 2 - 3 * foos(i);
	println(j);
	
	for(i=0 ; i<4 ; i++)
	{
		println(i) ; 
	}

	k = 9 ; 
	while (k>5)
	{
		println(k) ; 
		k-- ; 
	}



	 k = 0 ; 
	 j = 0 ; 
	 l=1 ; 
	 b=1; 
	c = b||k ; println(c) ; 
	c = l||b ; println(c) ; 
	c = k||b ; println(c) ; 
	c = k||j ; println(c) ; 


	c = j&&k ; println(c) ; 
	c = l&&b ; println(c) ; 
	c = j && b ; println(c) ; 
	c = l&&k ; println(c) ; 


	c=k>j || b==l ; println(c) ; 
	c=j<l && j<b ; println(c) ; 
	c=j>l && b==1 ; println(c) ; 

	if(j==0 && k==0) println(j) ; 
	else println(b) ; 
	l++; 
	if(l==2 || l<b) println(l) ; 
	else println(b) ; 
	b=3;
	if(b==2 || b==1)println(k) ; 
	else println(b) ; 
	
	c = 2 ; 
	if(c==1 && b==3) println(c) ; //this will not print 

	int w ; 
	w = outer(c) ;
	println(w) ;  
	

	int px  ; 
	px = 0 ; 
	gbara[px]  = 2 ;
	int aa ; 
	aa=gbara[px] ; 
	println(aa) ; 

	while (aa)
	{
		println(aa) ; 
		aa-- ; 		
	}


	
 
	return 0;
}

