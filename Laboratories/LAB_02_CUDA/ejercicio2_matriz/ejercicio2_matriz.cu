// Archivo: ejercicio2_matriz.cu
// Objetivo: Transferir una matriz 2D (plana) entre CPU y GPU
#include <stdio.h>
#include <cuda_runtime.h>
 
#define FILAS 3
#define COLS 4
#define N (FILAS * COLS)
 
void imprimirMatriz(float *m, int filas, int cols) {
    for (int i = 0; i < filas; i++) {
        for (int j = 0; j < cols; j++)
            printf("%6.1f ", m[i * cols + j]);
        printf("\n");
    }
}
 
int main() {
    // Matrices en CPU (representadas como arreglos 1D)
    float h_original[N], h_recuperada[N];
    for (int i = 0; i < N; i++) h_original[i] = (float)(i + 1) * 1.5f;
 
    printf("Matriz original (CPU):\n");
    imprimirMatriz(h_original, FILAS, COLS);
 
    // Reservar en GPU
    float *d_matriz;
    cudaMalloc((void**)&d_matriz, N * sizeof(float));
 
    // Copiar CPU → GPU
    cudaMemcpy(d_matriz, h_original, N * sizeof(float), cudaMemcpyHostToDevice);
    printf("\n[OK] Datos enviados a la GPU\n");
 
    // Copiar GPU → CPU
    cudaMemcpy(h_recuperada, d_matriz, N * sizeof(float), cudaMemcpyDeviceToHost);
    printf("\nMatriz recuperada desde GPU:\n");
    imprimirMatriz(h_recuperada, FILAS, COLS);
 
    // TAREA: Modifica el programa para verificar automáticamente
    // que cada elemento de h_original == h_recuperada
    // Pista: usa un bucle y compara con fabsf(a - b) < 1e-5f
 
    cudaFree(d_matriz);
    return 0;
}
 
// Compilar: nvcc ejercicio2_matriz.cu -o ejercicio2
