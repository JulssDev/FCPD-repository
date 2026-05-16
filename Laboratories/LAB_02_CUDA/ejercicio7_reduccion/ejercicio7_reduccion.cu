// Archivo: ejercicio7_reduccion.cu
// Objetivo: Suma de arreglo con reducción paralela y shared memory

#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>

#define N 1024
#define THREADS 256

// Kernel de reducción usando shared memory
__global__ void reduccionSuma(int *d_entrada, int *d_salida, int n) {
    // Declarar shared memory: cada bloque tiene su propio espacio
    // El tamaño se especifica en el lanzamiento del kernel
    extern __shared__ int s_datos[];

    int tid = threadIdx.x; // Índice local dentro del bloque
    int idx = blockIdx.x * blockDim.x + threadIdx.x; // Índice global

    // Cargar datos de memoria global a shared memory
    s_datos[tid] = (idx < n) ? d_entrada[idx] : 0;

    __syncthreads(); // Esperar a que todos los hilos carguen sus datos

    // Reducción paralela
    for (int stride = blockDim.x / 2; stride > 0; stride /= 2) {
        if (tid < stride) {
            s_datos[tid] += s_datos[tid + stride];
        }

        __syncthreads(); // Sincronizar antes del siguiente paso
    }

    // El hilo 0 guarda la suma parcial del bloque
    if (tid == 0) {
        d_salida[blockIdx.x] = s_datos[0];
    }
}

int main() {
    int h_datos[N];
    int suma_cpu = 0;

    // Inicializar arreglo
    for (int i = 0; i < N; i++) {
        h_datos[i] = 1;
        suma_cpu += h_datos[i];
    }

    printf("Suma esperada (CPU): %d\n", suma_cpu);

    // Calcular cantidad de bloques
    int numBloques = (N + THREADS - 1) / THREADS;

    // Reservar memoria dinámica en CPU
    int *h_parciales = (int*)malloc(numBloques * sizeof(int));

    // Punteros GPU
    int *d_datos, *d_parciales;

    cudaMalloc((void**)&d_datos, N * sizeof(int));
    cudaMalloc((void**)&d_parciales, numBloques * sizeof(int));

    // Copiar datos CPU -> GPU
    cudaMemcpy(d_datos,
               h_datos,
               N * sizeof(int),
               cudaMemcpyHostToDevice);

    // Shared memory por bloque
    int sharedBytes = THREADS * sizeof(int);

    // Lanzar kernel
    reduccionSuma<<<numBloques, THREADS, sharedBytes>>>(
        d_datos,
        d_parciales,
        N
    );

    cudaDeviceSynchronize();

    // Recuperar sumas parciales
    cudaMemcpy(h_parciales,
               d_parciales,
               numBloques * sizeof(int),
               cudaMemcpyDeviceToHost);

    // Sumar resultados parciales en CPU
    int suma_gpu = 0;

    for (int i = 0; i < numBloques; i++)
        suma_gpu += h_parciales[i];

    printf("Suma calculada (GPU): %d\n", suma_gpu);

    printf("%s\n",
           (suma_cpu == suma_gpu)
           ? "[OK] Resultados identicos!"
           : "[ERROR] No coinciden.");

    // Liberar memoria
    cudaFree(d_datos);
    cudaFree(d_parciales);

    free(h_parciales);

    return 0;
}

// Compilar: nvcc ejercicio7_reduccion.cu -o ejercicio7
// Nota: __syncthreads() es CRUCIAL.
// Sin él, los hilos leerían datos incorrectos.