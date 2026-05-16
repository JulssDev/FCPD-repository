// Archivo: ejercicio9_producto_punto.cu
// Objetivo: Producto punto combinando multiplicación en GPU y reducción

#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>
#include <cuda_runtime.h>

#define N 4096
#define THREADS 256

// Kernel: multiplicación elemento a elemento + reducción por bloque
__global__ void productoPunto(
    float *d_A,
    float *d_B,
    float *d_parciales,
    int n
) {
    extern __shared__ float s_datos[];

    int tid = threadIdx.x;
    int idx = blockIdx.x * blockDim.x + threadIdx.x;

    // Producto elemento a elemento
    if (idx < n)
        s_datos[tid] = d_A[idx] * d_B[idx];
    else
        s_datos[tid] = 0.0f;

    __syncthreads();

    // Reducción paralela
    for (int stride = blockDim.x / 2;
         stride > 0;
         stride /= 2) {

        if (tid < stride)
            s_datos[tid] += s_datos[tid + stride];

        __syncthreads();
    }

    // Guardar suma parcial
    if (tid == 0)
        d_parciales[blockIdx.x] = s_datos[0];
}

int main() {

    srand((unsigned)time(NULL));

    // Reservar memoria CPU
    float *h_A =
        (float*)malloc(N * sizeof(float));

    float *h_B =
        (float*)malloc(N * sizeof(float));

    // Inicializar vectores aleatorios
    for (int i = 0; i < N; i++) {

        h_A[i] =
            (float)(rand() % 100) / 10.0f;

        h_B[i] =
            (float)(rand() % 100) / 10.0f;
    }

    // Calcular resultado esperado en CPU
    float resultado_cpu = 0.0f;

    for (int i = 0; i < N; i++) {
        resultado_cpu += h_A[i] * h_B[i];
    }

    // Cantidad de bloques
    int numBloques =
        (N + THREADS - 1) / THREADS;

    // Memoria CPU para parciales
    float *h_parciales =
        (float*)malloc(numBloques * sizeof(float));

    // Memoria GPU
    float *d_A;
    float *d_B;
    float *d_parciales;

    cudaMalloc((void**)&d_A,
               N * sizeof(float));

    cudaMalloc((void**)&d_B,
               N * sizeof(float));

    cudaMalloc((void**)&d_parciales,
               numBloques * sizeof(float));

    // Copiar CPU -> GPU
    cudaMemcpy(d_A,
               h_A,
               N * sizeof(float),
               cudaMemcpyHostToDevice);

    cudaMemcpy(d_B,
               h_B,
               N * sizeof(float),
               cudaMemcpyHostToDevice);

    // Shared memory
    int sharedBytes =
        THREADS * sizeof(float);

    // Lanzar kernel
    productoPunto<<<numBloques,
                     THREADS,
                     sharedBytes>>>(
        d_A,
        d_B,
        d_parciales,
        N
    );

    cudaDeviceSynchronize();

    // Recuperar parciales
    cudaMemcpy(h_parciales,
               d_parciales,
               numBloques * sizeof(float),
               cudaMemcpyDeviceToHost);

    // Suma final en CPU
    float resultado_gpu = 0.0f;

    for (int i = 0; i < numBloques; i++) {
        resultado_gpu += h_parciales[i];
    }

    // Mostrar resultados
    printf("Producto punto GPU = %.4f\n",
           resultado_gpu);

    printf("Producto punto CPU = %.4f\n",
           resultado_cpu);

    // Comparar resultados
    if (fabs(resultado_gpu - resultado_cpu) < 1e-3f)
        printf("[OK] Resultados correctos\n");
    else
        printf("[ERROR] Resultados diferentes\n");

    // Liberar memoria
    cudaFree(d_A);
    cudaFree(d_B);
    cudaFree(d_parciales);

    free(h_A);
    free(h_B);
    free(h_parciales);

    return 0;
}

// Compilar: nvcc ejercicio9_producto_punto.cu -o ejercicio9