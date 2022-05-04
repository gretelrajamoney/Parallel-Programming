// includes
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>
#include <omp.h>

// defines
#define NUMT    4

// variables
int	NowYear;		// 2022 - 2027
int	NowMonth;		// 0 - 11

float	NowPrecip;		// inches of rain per month
float	NowTemp;		// temperature this month
float	NowHeight;		// grain height in inches
int	NowNumDeer;		// number of deer in the current population
int NowNumCheetah;	// number of cheetah in the current population

// makes program global
unsigned int seed = 0;

// constants
const float GRAIN_GROWS_PER_MONTH =		9.0;
const float ONE_DEER_EATS_PER_MONTH =		1.0;
const float ONE_CHEETAH_EATS_PER_MONTH = 	2.0;

const float AVG_PRECIP_PER_MONTH =		7.0;	// average
const float AMP_PRECIP_PER_MONTH =		6.0;	// plus or minus
const float RANDOM_PRECIP =			2.0;	// plus or minus noise

const float AVG_TEMP =				60.0;	// average
const float AMP_TEMP =				20.0;	// plus or minus
const float RANDOM_TEMP =			10.0;	// plus or minus noise

const float MIDTEMP =				40.0;
const float MIDPRECIP =				10.0;	


// function to square things
float
SQR( float x )
{
	return x*x;
}

// returns a randomly generated float between a specified range 
float
Ranf( unsigned int *seedp,  float low, float high )
{
        float r = (float) rand_r( seedp );              // 0 - RAND_MAX

        return(   low  +  r * ( high - low ) / (float)RAND_MAX   );
}

// returns a randomly generated int between a specified range
int
Rani( unsigned int *seedp, int ilow, int ihigh )
{
        float low = (float)ilow;
        float high = (float)ihigh + 0.9999f;

        return (int)(  Ranf(seedp, low,high) );
}

// grain thread 
void 
Grain()
{
	while( NowYear < 2028 )
	{
		// compute a temporary next-value for this quantity
		// based on the current state of the simulation:
		float tempFactor = exp(   -SQR(  ( NowTemp - MIDTEMP ) / 10.  )   );
		float precipFactor = exp(   -SQR(  ( NowPrecip - MIDPRECIP ) / 10.  )   );

		// compute grain height
		float nextHeight = NowHeight;
		nextHeight += tempFactor * precipFactor * GRAIN_GROWS_PER_MONTH;
		nextHeight -= (float)NowNumDeer * ONE_DEER_EATS_PER_MONTH;
		nextHeight -= (float)NowNumCheetah * ONE_CHEETAH_EATS_PER_MONTH;
		
		// clamp nextHeigh against zero
		if( nextHeight < 0. ) nextHeight = 0.;

		// DoneComputing barrier:
		#pragma omp barrier
		NowHeight = nextHeight; // shifts next to now

		// DoneAssigning barrier:
		#pragma omp barrier

		// DonePrinting barrier:
		#pragma omp barrier

	}

}

// deer thread
void 
Deer()
{
	while( NowYear < 2028 )
	{
		// compute a temporary next-value for this quantity
		// based on the current state of the simulation:
		int nextNumDeer = NowNumDeer;
		int carryingCapacity = (int)( NowHeight );

		// if the deer population is smaller than the capacity
		if( nextNumDeer < carryingCapacity )
		{
			// increase the number of deer by one
			nextNumDeer++;
		}
		else
		{
			// if the deer population is greater than the capacity
			if( nextNumDeer > carryingCapacity )
			{
				// decrease the number of deer by one
				nextNumDeer--;
			}
		}

		// it is not possible to have a negative deer population
		if( nextNumDeer < 0 )
		{
			// set deer to one if negative
			nextNumDeer = 0;
		}

		// DoneComputing barrier:
		#pragma omp barrier
		NowNumDeer = nextNumDeer; // shifts next to now

		// DoneAssigning barrier:
		#pragma omp barrier

		// DonePrinting barrier:
		#pragma omp barrier

	}
}

// cheetah thread
void
MyAgent()
{
	while( NowYear < 2028 )
	{
		// compute a temporary next-value for this quantity
		// based on the current state of the simulation:
		int nextNumCheetah = NowNumCheetah;

		// if there are more than double the amount of deer
		if( (NowNumCheetah * 2) < NowNumDeer )
		{
			// add more cheetah
			nextNumCheetah++;
		}

		// if there are too many cheetahs in comparison to deer
		else if ( (NowNumCheetah * 2) > NowNumDeer )
		{
			// get rid of the cheetah population
			nextNumCheetah = 0;
		}

		// it is not possible to have negative cheetah population
		if( nextNumCheetah < 0 )
		{
			// set cheetah population to zero
			nextNumCheetah = 0;
		}

		// DoneComputing barrier:
		#pragma omp barrier
		NowNumCheetah = nextNumCheetah; // shifts next to now

		// DoneAssigning barrier:
		#pragma omp barrier

		// DonePrinting barrier:
		#pragma omp barrier

	}

}

// watcher thread
void
Watcher()
{
	while( NowYear < 2028 )
	{
		// compute a temporary next-value for this quantity
		// based on the current state of the simulation:

		// DoneComputing barrier:
		#pragma omp barrier

		// DoneAssigning barrier:
		#pragma omp barrier
		float ang = (  30.*(float)NowMonth + 15.  ) * ( M_PI / 180. );
		
		float temp = AVG_TEMP - AMP_TEMP * cos( ang );
		NowTemp = temp + Ranf( &seed, -RANDOM_TEMP, RANDOM_TEMP );

		float precip = AVG_PRECIP_PER_MONTH + AMP_PRECIP_PER_MONTH * sin( ang );
		NowPrecip = precip + Ranf( &seed,  -RANDOM_PRECIP, RANDOM_PRECIP );
		if( NowPrecip < 0. )
		{
			NowPrecip = 0.;
		}

		// metric conversions
		float metricHeight; // inches * 2.54
		float metricPrecip; // inches * 2.54
		float metricTemp; // (5./9.)*(F-32)

		metricHeight = NowHeight * 2.54;
		metricPrecip = NowPrecip * 2.54;
		metricTemp = (5./9.)*(NowTemp-32);

		// shifts month over by 1
		NowMonth++;

		// printing
		fprintf(stderr, "%d/%d, %d, %d, %lf, %lf, %lf\n", NowMonth, NowYear, NowNumDeer, NowNumCheetah, metricHeight, metricPrecip, metricTemp);

		// checks if end of the year
		if (NowMonth >= 12)
		{
			NowMonth = 0;
			NowYear++;
		}

		// DonePrinting barrier:
		#pragma omp barrier

	}	
}

int
main( int argc, char *argv[ ] )
{
#ifndef _OPENMP
        fprintf( stderr, "No OpenMP support!\n" );
        return 1;
#endif

		// starting date and time:
		NowMonth =    0;
		NowYear  = 2022;

		// starting state (feel free to change this if you want):
		NowNumDeer = 1;
		NowHeight =  1.;

        omp_set_num_threads( NUMT );    // set the number of threads to use in parallelizing the for-loop:`
		#pragma omp parallel sections
		{
			#pragma omp section
			{
				Deer( );
			}

			#pragma omp section
			{
				Grain( );
			}

			#pragma omp section
			{
				Watcher( );
			}

			#pragma omp section
			{
				MyAgent( );		// your own
			}

			// implied barrier -- all functions must return in order
			// to allow any of them to get past here
		}
}