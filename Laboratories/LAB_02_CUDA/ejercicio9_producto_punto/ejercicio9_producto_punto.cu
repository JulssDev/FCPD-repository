// Archivo: ejercicio9_producto_punto.cu
// Objetivo: Producto punto combinando multiplicación en GPU y reducción
#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>
 
#define N 4096
#define THREADS 256
 
// Kernel: multiplicación elemento a elemento + reducción por bloque
__global__ void productoPunto(float *d_A, float *d_B, float *d_parciales, int n) {
    extern __shared__ float s_datos[];
 
    int tid = threadIdx.x;
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
 
    // Cada hilo calcula su contribución al producto punto
    s_datos[tid] = (idx < n) ? d_A[idx] * d_B[idx] : 0.0f;
    __syncthreads();
 
    // Reducción para sumar todos los productos del bloque
    for (int stride = blockDim.x / 2; stride > 0; stride /= 2) {
        if (tid < stride)
            s_datos[tid] += s_datos[tid + stride];
        __syncthreads();
    }
 
    if (tid == 0) d_parciales[blockIdx.x] = s_datos[0];
}
 
int main() {
    float *h_A = (float*)malloc(N * sizeof(float));
    float *h_B = (float*)malloc(N * sizeof(float));
    for (int i = 0; i < N; i++) { h_A[i] = 1.0f; h_B[i] = 1.0f; }
 
    int numBloques = (N + THREADS - 1) / THREADS;
    float *h_parciales = (float*)malloc(numBloques * sizeof(float));
 
    float *d_A, *d_B, *d_parciales;
    cudaMalloc((void**)&d_A, N * sizeof(float));
    cudaMalloc((void**)&d_B, N * sizeof(float));
    cudaMalloc((void**)&d_parciales, numBloques * sizeof(float));
 
    cudaMemcpy(d_A, h_A, N * sizeof(float), cudaMemcpyHostToDevice);
    cudaMemcpy(d_B, h_B, N * sizeof(float), cudaMemcpyHostToDevice);
 
    int sharedBytes = THREADS * sizeof(float);
    productoPunto<<<numBloques, THREADS, sharedBytes>>>(d_A, d_B, d_parciales, N);
    cudaDeviceSynchronize();
 
    cudaMemcpy(h_parciales, d_parciales, numBloques * sizeof(float), cudaMemcpyDeviceToHost);
 
    // Suma final en CPU
    float resultado = 0.0f;
    for (int i = 0; i < numBloques; i++) resultado += h_parciales[i];
 
    printf("Producto punto = %.2f\n", resultado);
    printf("Resultado esperado = %d\n", N);
    printf("%s\n", (resultado == (float)N) ? "[OK]" : "[ERROR]");
 
    // TAREA: Prueba con vectores aleatorios y verifica contra resultado en CPU.
 
    cudaFree(d_A); cudaFree(d_B); cudaFree(d_parciales);
    free(h_A); free(h_B); free(h_parciales);
    return 0;
}
 
// Compilar: nvcc ejercicio9_producto_punto.cu -o ejercicio9
