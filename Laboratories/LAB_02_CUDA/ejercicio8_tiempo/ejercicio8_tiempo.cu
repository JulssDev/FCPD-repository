// Archivo: ejercicio8_tiempo.cu
// Objetivo: Medir rendimiento con CUDA Events y calcular bandwidth

#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <cuda_runtime.h>

#define N 10000000
#define THREADS 256

// Kernel: multiplica cada elemento por un escalar
__global__ void escalarMult(float *d_vec, float escalar, int n) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;

    if (idx < n)
        d_vec[idx] *= escalar;
}

int main() {

    float escalar = 2.5f;

    size_t bytes = N * sizeof(float);

    // Vector CPU
    float *h_vec = (float*)malloc(bytes);

    // Vector para prueba CPU
    float *h_vec_cpu = (float*)malloc(bytes);

    for (int i = 0; i < N; i++) {
        h_vec[i] = 1.0f;
        h_vec_cpu[i] = 1.0f;
    }

    // Reservar GPU
    float *d_vec;

    cudaMalloc((void**)&d_vec, bytes);

    // Copiar CPU -> GPU
    cudaMemcpy(d_vec,
               h_vec,
               bytes,
               cudaMemcpyHostToDevice);

    // =========================
    // MEDIR GPU
    // =========================

    cudaEvent_t inicio, fin;

    cudaEventCreate(&inicio);
    cudaEventCreate(&fin);

    int numBloques =
        (N + THREADS - 1) / THREADS;

    cudaEventRecord(inicio);

    escalarMult<<<numBloques, THREADS>>>(
        d_vec,
        escalar,
        N
    );

    cudaEventRecord(fin);

    cudaEventSynchronize(fin);

    float ms = 0;

    cudaEventElapsedTime(
        &ms,
        inicio,
        fin
    );

    printf("Tiempo GPU: %.4f ms\n", ms);

    // Calcular bandwidth
    float gb =
        (2.0f * bytes) /
        (1024.0f * 1024.0f * 1024.0f);

    float bandwidth =
        gb / (ms / 1000.0f);

    printf("Bandwidth efectivo: %.2f GB/s\n",
           bandwidth);

    // =========================
    // MEDIR CPU
    // =========================

    clock_t inicio_cpu = clock();

    for (int i = 0; i < N; i++) {
        h_vec_cpu[i] *= escalar;
    }

    clock_t fin_cpu = clock();

    double tiempo_cpu_ms =
        ((double)(fin_cpu - inicio_cpu) * 1000.0)
        / CLOCKS_PER_SEC;

    printf("Tiempo CPU: %.4f ms\n",
           tiempo_cpu_ms);

    // =========================
    // VERIFICAR RESULTADO
    // =========================

    cudaMemcpy(h_vec,
               d_vec,
               sizeof(float),
               cudaMemcpyDeviceToHost);

    printf("h_vec[0] = %.1f (esperado %.1f)\n",
           h_vec[0],
           escalar);

    // Comparación simple
    if (ms < tiempo_cpu_ms)
        printf("GPU mas rapida que CPU\n");
    else
        printf("CPU mas rapida que GPU\n");

    // Liberar recursos
    cudaEventDestroy(inicio);
    cudaEventDestroy(fin);

    cudaFree(d_vec);

    free(h_vec);
    free(h_vec_cpu);

    return 0;
}

// Compilar: nvcc ejercicio8_tiempo.cu -o ejercicio8