// includes
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>
#include <omp.h>

// defines
#define _USE_MATH_DEFINES
#define XMIN     -1.
#define XMAX      1.
#define YMIN     -1.
#define YMAX      1.

// sets thread count
#ifndef NUMT
#define NUMT    2
#endif

// sets node count
#ifndef NUMN
#define NUMN    10000
#endif


// defines constants
const float N = 2.5f;
const float R = 1.2f;

float
Height( int iu, int iv )	// iu,iv = 0 .. NUMNODES-1
{
	float x = -1.  +  2.*(float)iu /(float)(NUMN-1);	// -1. to +1.
	float y = -1.  +  2.*(float)iv /(float)(NUMN-1);	// -1. to +1.

	float xn = pow( fabs(x), (double)N );
	float yn = pow( fabs(y), (double)N );
	float rn = pow( fabs(R), (double)N );
	float r = rn - xn - yn;
	if( r <= 0. )
	        return 0.;
	float height = pow( r, 1./(double)N );
	return height;
}


int main( int argc, char *argv[ ] )
{
    // set the number of threads to use in parallelizing the for-loop
    omp_set_num_threads(NUMT);
    // takes in the time
    double time0 = omp_get_wtime();
	// the area of a single full-sized tile:
	// (not all tiles are full-sized, though)

    // area of full sized tiles
	float fullTileArea = (  ( ( XMAX - XMIN )/(float)(NUMN-1) )  *
				( ( YMAX - YMIN )/(float)(NUMN-1) )  );

    // area of half sized tiles
    float halfTileArea = (  ( ( XMAX - XMIN )/(float)(NUMN-1) )  *
				( ( YMAX - YMIN )/(float)(NUMN-1) )  ) / 2.;

    // area of quarter sized tiles
    float quarterTileArea = (  ( ( XMAX - XMIN )/(float)(NUMN-1) )  *
				( ( YMAX - YMIN )/(float)(NUMN-1) )  ) / 4.;

	// sum up the weighted heights into the variable "volume"
	// using an OpenMP for-loop and a reduction:
	float volume = 0.;
    // You could use a single for-loop over all the nodes that looks like this:
    #pragma omp parallel for default(none), shared(fullTileArea, halfTileArea, quarterTileArea), reduction(+:volume)
    for( int i = 0; i < NUMN*NUMN; i++ )
    {
	    int iu = i % NUMN;
	    int iv = i / NUMN;
	    float z = Height( iu, iv );

        // when the column is 0
        if (iu == (NUMN - 1) || iu == 0)
        {
            if (iv == (NUMN - 1) || iv == 0)
            {
                // add a quarter volume
                volume += quarterTileArea * z;
            }

            // when the row is 0
            else
            {
                // add a half volume
                volume += halfTileArea * z;
            }
        }

        // if the column or row is 0
        else if (iv == (NUMN - 1) || iv == 0)
        {
            // add a half volume
            volume += halfTileArea * z;
        }

        else
        {
            // add a full volume
            volume += fullTileArea * z;
        }
    }

    //  calculates the overall volume
    volume = volume * 2;

    // takes in the time
    double time1 = omp_get_wtime();

    // calculates the max performance
    double maxPerformance = (double)(NUMN * NUMN) / (time1 - time0) / 1000000.;
    
    // prints our the number of threads, number of nodes, volume, and max performance
    fprintf(stderr, "%2d, %8d, %6.2f, %6.2lf\n", NUMT, NUMN, volume, maxPerformance);
    
    return 0;
}