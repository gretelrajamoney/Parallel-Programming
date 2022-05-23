kernel
void
ArrayMultAdd( global const float *dA, global const float *dB, global float *dC )
{
	int gid = get_global_id( 0 );

	dC[gid] = dA[gid] * dB[gid];
    dC[gid] += dA[gid] * dB[gid];
}
