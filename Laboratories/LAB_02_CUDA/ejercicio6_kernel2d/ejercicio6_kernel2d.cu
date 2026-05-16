// Archivo: ejercicio6_kernel2d.cu
// Objetivo: Usar indexacion 2D de hilos en un kernel
#include <stdio.h>
#include <cuda_runtime.h>

#define FILAS 4
#define COLS 5

// Kernel 2D: cada hilo procesa una celda de la matriz
__global__ void inicializarMatriz(int *d_mat, int filas, int cols) {
    // Calcular índice de fila y columna para este hilo
    int col = blockIdx.x * blockDim.x + threadIdx.x;
    int fila = blockIdx.y * blockDim.y + threadIdx.y;

    // Guard: verificar límites
    if (fila < filas && col < cols) {
        // Convertir índice 2D a índice lineal 1D
        int idx = fila * cols + col;

        // Guardar i + j
        d_mat[idx] = fila + col;
    }
}

int main() {
    int h_mat[FILAS * COLS];
    int *d_mat;

    cudaMalloc((void**)&d_mat, FILAS * COLS * sizeof(int));

    // Configurar bloques e hilos 2D
    // dim3 permite definir dimensiones en 2D o 3D
    dim3 hilosPorBloque(COLS, FILAS); // un hilo por celda
    dim3 numBloques(1, 1);            // un solo bloque

    inicializarMatriz<<<numBloques, hilosPorBloque>>>(d_mat, FILAS, COLS);

    cudaDeviceSynchronize();

    cudaMemcpy(h_mat,
               d_mat,
               FILAS * COLS * sizeof(int),
               cudaMemcpyDeviceToHost);

    printf("Matriz inicializada por la GPU:\n");

    for (int i = 0; i < FILAS; i++) {
        for (int j = 0; j < COLS; j++)
            printf("%3d ", h_mat[i * COLS + j]);

        printf("\n");
    }

    cudaFree(d_mat);

    return 0;
}
 
// Compilar: nvcc ejercicio6_kernel2d.cu -o ejercicio6
