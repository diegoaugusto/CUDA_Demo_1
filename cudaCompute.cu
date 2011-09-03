#include <stdio.h>
#include <assert.h>
#include <cuda.h>

// taken from Dr.Dobbs
// http://www.ddj.com/cpp/207200659

// the next line was changed from
// void cudaCompute(void)
// to 
// extern "C" void cudaCompute(void)

extern "C" void cudaCompute(void)
{
   float *a_h, *b_h;     // pointers to host memory
   float *a_d, *b_d;     // pointers to device memory
   int N = 5;
   int i;
   
   // allocate arrays on host
   a_h = (float *)malloc(sizeof(float)*N);
   b_h = (float *)malloc(sizeof(float)*N);
   
   // allocate arrays on device
   cudaMalloc((void **) &a_d, sizeof(float)*N);
   cudaMalloc((void **) &b_d, sizeof(float)*N);
   
   // initialize host data
   printf("initialize host data\n");
   for (i=0; i<N; i++) {
      a_h[i] = 10.f+i; 	// a = 10 to 14
      b_h[i] = 0.f;		// b = 0
      printf(" a_h[%d] = %f\t b_h[%d] = %f\n", i, a_h[i], i, b_h[i]);
   }
   
   // send data from host to device: a_h to a_d
   // target, source, size, direction
   cudaMemcpy(a_d, a_h, sizeof(float)*N, cudaMemcpyHostToDevice);
   
   // copy data within device: a_d to b_d
   cudaMemcpy(b_d, a_d, sizeof(float)*N, cudaMemcpyDeviceToDevice);
   
   // retrieve data from device: b_d to b_h
   cudaMemcpy(b_h, b_d, sizeof(float)*N, cudaMemcpyDeviceToHost);
   
   // check result
   printf("assert received data\n");
   for (i=0; i<N; i++) {
      assert(a_h[i] == b_h[i]);
      // if correct a_h = 10 to 14 
      // if correct b_h = 10 to 14
      printf(" a_h[%d] = %f\t b_h[%d] = %f\n", i, a_h[i], i, b_h[i]); 
   }
   
   // cleanup
   free(a_h); free(b_h); 
   cudaFree(a_d); cudaFree(b_d);
}