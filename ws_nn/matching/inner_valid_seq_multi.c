#include "mex.h"
#include <math.h>

#define MAX(a,b) (((a)>(b))?(a):(b))
#define INF 10000

void computeScore(double *score, double *Dist,int r,int c,int b,int k)
{

int i,j,kk,ii,m,mm;
double wa,minv,mins;
double *w,*A,*nA,*tmpA;
w = malloc((2*k+1) * sizeof(double));

// multi instance size
m = c/(r*b); 

for (i = 0; i < (2*k+1); i++)
{
    w[i] = 1 + 0.2*pow(abs(i-k),2)/pow(k,2);
    //mexPrintf("%8.4f ", w[i]);
}


       
A = malloc(c * sizeof(double));
nA = malloc(c * sizeof(double));

for (i = 0;i < c;i++) 
{
	A[i] = Dist[r*i];	
} 

for (i = 0;i < r-1;i++) 
{
	for (j = 0;j < c;j++) 
	{
        
		minv = INF;
        for (mm = 0; mm < m; mm++)
            for (kk = 0;kk < (2*k+1);kk++) 
            {
                ii = j/m-b-k+kk;
                if (ii < 0)
                    wa = INF;
                else{
                    //wa = A[ii*m + mm]*w[kk]+Dist[r*j+(i+1)];
                    wa = A[ii*m + mm]+Dist[r*j+(i+1)]*w[kk];
                    //wa = A[ii*m + mm]*Dist[r*j+(i+1)]*w[kk];
                }

                if (wa < minv)
                {
                    minv = wa;
                }
            }		
		//nA[j] = Dist[r*j+(i+1)] + minv;
        nA[j] = minv;
        //mexPrintf("%.5f || ", minv);
	}
    //mexPrintf("\n");
	tmpA = A;
	A = nA;
	nA = tmpA;
}

mins = A[0];
for (i = 1;i < c;i++) 
{
    //mexPrintf("%8.4f", A[i]);
	if (A[i] < mins)
		mins = A[i];
}

*score = mins;

}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	#define D_IN prhs[0]
    #define B prhs[1]
    #define K prhs[2]
	#define SCORE plhs[0]

    //int *b,*k;
    double* bi = mxGetPr(B);
    double* ki = mxGetPr(K);
    int b = (int) bi[0];
    int k = (int) ki[0];
    
	SCORE = mxCreateDoubleMatrix(1,1,mxREAL);
	computeScore(mxGetPr(SCORE),mxGetPr(D_IN),mxGetM(D_IN),mxGetN(D_IN),b,k);

}