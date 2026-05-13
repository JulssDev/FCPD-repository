// Archivo: ejercicio8_tiempo.cu
// Objetivo: Medir rendimiento con CUDA Events y calcular bandwidth
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <cuda_runtime.h>
 
#define N 10000000  // 10 millones de elementos
#define THREADS 256
 
// Kernel: multiplica cada elemento por un escalar
__global__ void escalarMult(float *d_vec, float escalar, int n) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx < n) d_vec[idx] *= escalar;
}
 
int main() {
    float escalar = 2.5f;
    size_t bytes = N * sizeof(float);
 
    float *h_vec = (float*)malloc(bytes);
    for (int i = 0; i < N; i++) h_vec[i] = 1.0f;
 
    float *d_vec;
    cudaMalloc((void**)&d_vec, bytes);
    cudaMemcpy(d_vec, h_vec, bytes, cudaMemcpyHostToDevice);
 
    // === MEDIR TIEMPO con CUDA Events ===
    // cudaEvent_t es el tipo de evento CUDA
    // Los eventos se registran en la GPU y miden tiempo con precisión de microsegundos
    cudaEvent_t inicio, fin;
    cudaEventCreate(&inicio);
    cudaEventCreate(&fin);
 
    int numBloques = (N + THREADS - 1) / THREADS;
 
    cudaEventRecord(inicio);  // Marcar inicio
    escalarMult<<<numBloques, THREADS>>>(d_vec, escalar, N);
    cudaEventRecord(fin);     // Marcar fin
    cudaEventSynchronize(fin); // Esperar a que el evento fin se complete
 
    float ms = 0;
    cudaEventElapsedTime(&ms, inicio, fin);  // Tiempo en milisegundos
    printf("Tiempo GPU: %.4f ms\n", ms);
 
    // Calcular bandwidth: cuántos bytes se leyeron/escribieron por segundo
    // Se leen N floats y se escriben N floats = 2 * N * sizeof(float) bytes
    float gb = (2.0f * bytes) / (1024.0f * 1024.0f * 1024.0f);
    float bandwidth = gb / (ms / 1000.0f);
    printf("Bandwidth efectivo: %.2f GB/s\n", bandwidth);
 
    // Verificar primer elemento
    cudaMemcpy(h_vec, d_vec, sizeof(float), cudaMemcpyDeviceToHost);
    printf("h_vec[0] = %.1f (esperado %.1f)\n", h_vec[0], escalar);
 
    cudaEventDestroy(inicio); cudaEventDestroy(fin);
    cudaFree(d_vec); free(h_vec);
 
    // TAREA: Implementa la misma operacion en CPU con clock() y compara los tiempos.
    return 0;
}
 
// Compilar: nvcc ejercicio8_tiempo.cu -o ejercicio8
