
/******************/
int fatorial(int n)
/******************/
{     
        if(n==0) return 1;        
        else return n * fatorial(n-1); 
}


/**************/
void main(void)
/**************/
{     
        int k;    
        k = 10;   
        k = fatorial(k);  
        printf("%d", k); 
        return;
} 
