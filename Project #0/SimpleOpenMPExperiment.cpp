#include <omp.h>
#include <stdio.h>
#include <math.h>

#define NUMT	         4	// number of threads to use
#define SIZE       	 16000	// array size -- you get to decide
#define NUMTRIES         3	// how many times to run the timing -- you get to decide

float A[SIZE];
float B[SIZE];
float C[SIZE];

int
main( )
{
#ifndef _OPENMP
        fprintf( stderr, "OpenMP is not supported here -- sorry.\n" );
        return 1;
#endif

        // PERFORMANCE FOR ONE THREADS !!

        // sets the number of threads to use to 1
        omp_set_num_threads( 1 );
        fprintf( stderr, "Using %d threads\n", 1 );

        // initializes two float variables to 0
        double maxMegaMults = 0.;
        double sumMegaMults = 0.;

        for( int t = 0; t < NUMTRIES; t++ )
        {
                // stores the time prior to running
                double time0 = omp_get_wtime( );

                #pragma omp parallel for
                // creates an array that stores the results
                for( int i = 0; i < SIZE; i++ )
                {
                        // pairwise multiplies two large floating-point arrays
                        C[i] = A[i] * B[i];
                }

                // stores the time after running
                double time1 = omp_get_wtime( );
                // calculates the performance of the trial
                double megaMults = (double)SIZE/(time1-time0)/1000000.;
                // stores the total performances of all runs
                sumMegaMults += megaMults;

                // prints the performance of the run
                printf( " Performance = %8.2lf MegaMults/Sec\n", megaMults );

                if( megaMults > maxMegaMults )
                        maxMegaMults = megaMults;
        }

        // prints out the peak performance
        printf( "Peak Performance = %8.2lf MegaMults/Sec\n", maxMegaMults );

        // calculates the average performance using the accumulated sum
        double meanMegaMults = sumMegaMults / (double)NUMTRIES;
        // prints out the average performance
        printf( "Average Performance = %8.2lf MegaMults/Sec\n", meanMegaMults);

        // stores the peak performance for one thread
        double onethreadSpeed = maxMegaMults;

        // PERFORMANCE FOR FOUR THREADS !!

        // sets the number of threads to use to 4
        omp_set_num_threads( NUMT );
        fprintf( stderr, "Using %d threads\n", NUMT );

        // initializes two float variables to 0
        maxMegaMults = 0.;
        sumMegaMults = 0.;

        for( int t = 0; t < NUMTRIES; t++ )
        {
                // stores the time prior to running
                double time0 = omp_get_wtime( );

                #pragma omp parallel for
                // creates an array that stores the results
                for( int i = 0; i < SIZE; i++ )
                {
                        // pairwise multiplies two large floating-point arrays
                        C[i] = A[i] * B[i];
                }

                // stores the time after running
                double time1 = omp_get_wtime( );
                // calculates the performance of the trial
                double megaMults = (double)SIZE/(time1-time0)/1000000.;
                // stores the total performances of all runs
                sumMegaMults += megaMults;

                // prints the performance of the run
                printf( " Performance = %8.2lf MegaMults/Sec\n", megaMults );

                if( megaMults > maxMegaMults )
                        maxMegaMults = megaMults;
        }

        // prints out the peak performance
        printf( "Peak Performance = %8.2lf MegaMults/Sec\n", maxMegaMults );

        // calculates the average performance using the accumulated sum
        meanMegaMults = sumMegaMults / (double)NUMTRIES;
        // prints out the average performance
        printf( "Average Performance = %8.2lf MegaMults/Sec\n", meanMegaMults);

        // stores the peak performance for four threads
        double fourthreadSpeed = maxMegaMults;

        // calculates the speedup putting four threads over one thread
        double S = fourthreadSpeed / onethreadSpeed;
        // calculated the parallel fraction using our speedup 
        float Fp = (4. / 3.) * (1. - (1. / S));    

        // prints out the 4 thread to 1 thread speed-up
        printf( "4-Thread to 1-Thread Speed-Up = %8.2lf\n", S);  
        // prints out the parallel fraction of our program 
        printf("Parallel Fraction = %f\n", Fp); 

        return 0;
}