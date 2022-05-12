// Monte Carlo simulation of a snowball fight:

// system includes
#include <stdio.h>
#include <assert.h>
#include <malloc.h>
#include <math.h>
#include <stdlib.h>

// CUDA runtime
#include <cuda_runtime.h>

// Helper functions and utilities to work with CUDA
#include "helper_functions.h"
#include "helper_cuda.h"
#include "helper_image.h"
#include "helper_timer.h"
#include "helper_string.h"
#include "exception.h"

// setting the number of trials in the monte carlo simulation:
#ifndef NUMTRIALS
#define NUMTRIALS	2048
#endif

#ifndef BLOCKSIZE
#define BLOCKSIZE	16     // number of threads per block
#endif

#define NUMBLOCKS	( NUMTRIALS / BLOCKSIZE )


// ranges for the random numbers:
//#define PROJECT1

#ifdef PROJECT1
const float TXMIN =		-10.0;	// truck starting location in feet
const float TXMAX =	 	 10.0;	// truck starting location in feet
const float TYMIN  =	 45.0;	// depth distance to truck in feet
const float TYMAX  =	 55.0;	// depth distance to truck in feet
const float TXVMIN =	 10.0;	// truck x velocity in feet/sec
const float TXVMAX =	 30.0;	// truck x velocity in feet/sec
const float SVMIN  =	 10.0;	// snowball velocity in feet/sec
const float SVMAX  =	 30.0;	// snowball velocity in feet/sec
const float STHMIN = 	 10.0;	// snowball launch angle in degrees
const float STHMAX =	 90.0;	// snowball launch angle in degrees
//const float HALFLENMIN =  20.;	// half length of the truck in feet
//const float HALFLENMAX =  20.;	// half length of the truck in feet
#else
const float TXMIN =		-10.0;	// truck starting location in feet
const float TXMAX =	 	 10.0;	// truck starting location in feet
const float TXVMIN =	 15.0;	// truck x velocity in feet/sec
const float TXVMAX =	 35.0;	// truck x velocity in feet/sec
const float TYMIN  =	 40.0;	// depth distance to truck in feet
const float TYMAX  =	 50.0;	// depth distance to truck in feet
const float SVMIN  =	  5.0;	// snowball velocity in feet/sec
const float SVMAX  =	 30.0;	// snowball velocity in feet/sec
const float STHMIN = 	 10.0;	// snowball launch angle in degrees
const float STHMAX =	 70.0;	// snowball launch angle in degrees
//const float HALFLENMIN =  15.;	// half length of the truck in feet
//const float HALFLENMAX =  30.;	// half length of the truck in feet
#endif


// these are here just to be pretty labels, other than that, they do nothing:
#define IN
#define OUT


// function prototypes:
float		Ranf( float, float );
int		Ranf( int, int );
void		TimeOfDaySeed( );


void
CudaCheckError()
{
	cudaError_t e = cudaGetLastError();
	if(e != cudaSuccess)
	{
   		fprintf( stderr, "Cuda failure %s:%d: '%s'\n", __FILE__, __LINE__, cudaGetErrorString(e));
	}
}


// degrees-to-radians:
__device__
float
Radians( float d )
{
	return (M_PI/180.f) * d;
}


__global__
void
MonteCarlo( float *dtxs, float *dtys, float *dtxvs, float *dsvs, float *dsths, int *dhits )
{
	__shared__ int numHits[BLOCKSIZE];
	
	unsigned int numItems = blockDim.x;
	unsigned int wgNum    = blockIdx.x;
	unsigned int tnum     = threadIdx.x;
	unsigned int gid      = blockIdx.x*blockDim.x + threadIdx.x;

	numHits[tnum] = 0;

	// randomize everything:
	float tx   = dtxs[gid];
	float ty   = dtys[gid];
	float txv  = dtxvs[gid];
	float sv   = dsvs[gid];
	float sthd = dsths[gid];
	//float halflen = dhalflens[gid];
	float sthr = Radians( sthd );
	float svx  = sv * cos(sthr);
	float svy  = sv * sin(sthr);

	// how long until the snowball reaches the y depth:
	float tstar = ty / svy;
	float truckx = tx + (txv * tstar);
	float sbx = svx * tstar;

	if( fabs(truckx - sbx) < 20. )
	{
		numHits[tnum] = 1;
	}

	// do the reduction:
	for ( int offset = 1; offset < numItems; offset *= 2 )
	{
		int mask = 2 * offset - 1;
		__syncthreads();

		if ( (tnum & mask) == 0 )
		{
			numHits[tnum] += numHits[tnum + offset];
		}
	}

	__syncthreads();
	if ( tnum == 0 )
	{
		dhits[wgNum] = numHits[0];
	}
}


// main program:
#define IN
#define OUT 

int
main( int argc, char* argv[ ] )
{
	TimeOfDaySeed( );

	int dev = findCudaDevice(argc, (const char **)argv);

	
	float *htxs  = new float [NUMTRIALS];
	float *htys  = new float [NUMTRIALS];
	float *htxvs = new float [NUMTRIALS];
	float *hsvs  = new float [NUMTRIALS];
	float *hsths = new float [NUMTRIALS];
	//float *hhalflens = new float [NUMTRIALS];

	// fill the random-value arrays:
	for( int n = 0; n < NUMTRIALS; n++ )
	{
		htxs[n]  = Ranf(  TXMIN,  TXMAX );
		htys[n]  = Ranf(  TYMIN,  TYMAX );
 		htxvs[n] = Ranf(  TXVMIN, TXVMAX );
 		hsvs[n]  = Ranf(  SVMIN,  SVMAX );
 		hsths[n] = Ranf(  STHMIN, STHMAX );
		//hhalflens[n] = Ranf( HALFLENMIN, HALFLENMAX );
	}

	//int *hhits = new int [NUMTRIALS];
	int *hhits = new int [BLOCKSIZE];

	// allocate device memory:

	float *dtxs, *dtys, *dtxvs, *dsvs, *dsths; //, *dhalflens;
	int   *dhits;


	cudaError_t status;
	status = cudaMalloc( reinterpret_cast<void **>(&dtxs),   NUMTRIALS*sizeof(float) );
	checkCudaErrors(status);

	status = cudaMalloc( reinterpret_cast<void **>(&dtys),   NUMTRIALS*sizeof(float) );
	checkCudaErrors(status);

	status = cudaMalloc( reinterpret_cast<void **>(&dtxvs),   NUMTRIALS*sizeof(float) );
	checkCudaErrors(status);

	status = cudaMalloc( reinterpret_cast<void **>(&dsvs),   NUMTRIALS*sizeof(float) );
	checkCudaErrors(status);

	status = cudaMalloc( reinterpret_cast<void **>(&dsths),   NUMTRIALS*sizeof(float) );
	checkCudaErrors(status);

	//status = cudaMalloc( reinterpret_cast(&dhalflens),   NUMTRIALS*sizeof(float) );
	//checkCudaErrors(status);

	status = cudaMalloc( reinterpret_cast<void **>(&dhits),   BLOCKSIZE*sizeof(int) );
	checkCudaErrors(status);


	// copy host memory to the device:

	status = cudaMemcpy( dtxs,  htxs,  NUMTRIALS*sizeof(float), cudaMemcpyHostToDevice );
	checkCudaErrors(status);

	status = cudaMemcpy( dtys,  htys,  NUMTRIALS*sizeof(float), cudaMemcpyHostToDevice );
	checkCudaErrors(status);

	status = cudaMemcpy( dtxvs,  htxvs,  NUMTRIALS*sizeof(float), cudaMemcpyHostToDevice );
	checkCudaErrors(status);

	status = cudaMemcpy( dsvs,  hsvs,  NUMTRIALS*sizeof(float), cudaMemcpyHostToDevice );
	checkCudaErrors(status);

	status = cudaMemcpy( dsths,  hsths,  NUMTRIALS*sizeof(float), cudaMemcpyHostToDevice );
	checkCudaErrors(status);

	//status = cudaMemcpy( dhalflens,  hhalflens,  NUMTRIALS*sizeof(float), cudaMemcpyHostToDevice );
	//checkCudaErrors(status);


	// setup the execution parameters:

	dim3 threads(BLOCKSIZE, 1, 1 );
	dim3 grid(BLOCKSIZE, 1, 1 );

	// create and start timer

	cudaDeviceSynchronize( );

	// allocate CUDA events that we'll use for timing:

	cudaEvent_t start, stop;
	status = cudaEventCreate( &start );
	checkCudaErrors(status);
	status = cudaEventCreate( &stop );
	checkCudaErrors(status);

	// record the start event:

	status = cudaEventRecord( start, NULL );
	checkCudaErrors(status);

	// execute the kernel:

	MonteCarlo<<< grid, threads >>>( IN dtxs, IN dtys, IN dtxvs, IN dsvs, IN dsths, OUT dhits );

	// record the stop event:

	status = cudaEventRecord( stop, NULL );
	checkCudaErrors(status);

	// wait for the stop event to complete:

	status = cudaEventSynchronize( stop );
	checkCudaErrors(status);

	float msecTotal = 0.0f;
	status = cudaEventElapsedTime( &msecTotal, start, stop );
	checkCudaErrors(status);

	// copy result from the device to the host:

	status = cudaMemcpy( hhits, dhits, BLOCKSIZE *sizeof(int), cudaMemcpyDeviceToHost );
	checkCudaErrors(status);

	// compute the sum :

	int numHits = 0;
	for ( int x = 0; x < BLOCKSIZE; x++)
	{
		numHits += hhits[x];
		// fprintf(stderr, "hhits[ %6d ] = %5d ; Total numhits = %5d\n", x, hhits[x], numHits);
	}

	float probability = 100.*((float)numHits / (float)( NUMTRIALS ));

	// compute and printL

	double secondsTotal = 0.001 * (double)msecTotal;
	double trialsPerSecond = (float)NUMTRIALS / secondsTotal;
	double megaTrialsPerSecond = trialsPerSecond / 1000000.;
	fprintf( stderr, "Number of Trials = %10d, Blocksize = %8d, MegaTrials/Second = %10.4lf, Probability = %6.2f%%\n",
		NUMTRIALS, BLOCKSIZE, megaTrialsPerSecond, probability );

	// clean up memory:
	delete [ ] htxs;
	delete [ ] htys;
	delete [ ] htxvs;
	delete [ ] hsvs;
	delete [ ] hsths;
	delete [ ] hhits;

	status = cudaFree( dtxs );
	checkCudaErrors(status);
	status = cudaFree( dtys );
	checkCudaErrors(status);
	status = cudaFree( dtxvs );
	checkCudaErrors(status);
	status = cudaFree( dsvs );
	checkCudaErrors(status);
	status = cudaFree( dsths );
	checkCudaErrors(status);
	status = cudaFree( dhits );
	checkCudaErrors(status);


	return 0;
}

float
Ranf( float low, float high )
{
	float r = (float) rand();               // 0 - RAND_MAX
	float t = r  /  (float) RAND_MAX;       // 0. - 1.

	return   low  +  t * ( high - low );
}

int
Ranf( int ilow, int ihigh )
{
	float low = (float)ilow;
	float high = ceil( (float)ihigh );

	return (int) Ranf(low,high);
}

void
TimeOfDaySeed( )
{
	struct tm y2k = { 0 };
	y2k.tm_hour = 0;   y2k.tm_min = 0; y2k.tm_sec = 0;
	y2k.tm_year = 100; y2k.tm_mon = 0; y2k.tm_mday = 1;

	time_t  timer;
	time( &timer );
	double seconds = difftime( timer, mktime(&y2k) );
	unsigned int seed = (unsigned int)( 1000.*seconds );    // milliseconds
	srand( seed );
}