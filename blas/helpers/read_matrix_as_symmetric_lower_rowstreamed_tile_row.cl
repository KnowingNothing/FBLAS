/**
    FBLAS: BLAS implementation for Intel FPGA
    Copyright (c) 2019 ETH-Zurich. All rights reserved.
    See LICENSE for license information.

    Reads a symmetric matrix of type TYPE_T from memory and  push it
    into CHANNEL_MATRIX_A. The matrix is read as a triangular lower,
    that is only the elements in the lower part are accessed, but it is
    sent as a complete matrix
    To be used for SYMV

    The name of the kernel can be redefined by means of preprocessor MACROS.
    Tile sizes must be defined by Macros.

    W reads are performed simultaneously.
    If needed, data is padded to tile sizes using zero elements.

*/

__kernel void READ_MATRIX_A(__global volatile TYPE_T *restrict data, int N, unsigned int lda)
{
    const int BlocksN=1+((int)((N-1)/TILE_N));
    const int outer_loop_limit=((int)TILE_N)/W;
    TYPE_T to_send[W];
    for(int tj=0;tj<BlocksN;tj++)
    {
        for(int ti=0;ti<BlocksN;ti++)
        {
            for(int i = 0; i < TILE_N; i++)
            {
                for(int j=0; j < outer_loop_limit; j++ )
                {
                    #pragma unroll
                    for(int jj = 0; jj < W; jj++)
                    {
                        if((ti*TILE_N+i)<N  && tj*TILE_N+j*W+jj<= (ti*TILE_N+i))
                            to_send[jj] = data[(ti*TILE_N+i)*lda + tj*TILE_N+j*W+jj];
                        else
                            if((ti*TILE_N+i)<N  && (tj*TILE_N+j*W+jj)<= N)
                                to_send[jj]=data[(tj*TILE_N+j*W+jj)*lda + (ti*TILE_N+i)]; //padding
                            else
                                to_send[jj]=0;
                    }

                    #pragma unroll
                    for(int jj = 0; jj < W; jj++)
                        write_channel_intel(CHANNEL_MATRIX_A,to_send[jj]);
                }
            }
        }
    }
}
