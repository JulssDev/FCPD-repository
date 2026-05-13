// Archivo: ejercicio5_cuadrado.cu
// Objetivo: Kernel que modifica datos in-place en la GPU
#include <stdio.h>
#include <cuda_runtime.h>
 
#define N 20
 
// Kernel: eleva al cuadrado cada elemento del arreglo
__global__ void cuadradoInPlace(int *d_datos, int n) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx < n) {
        d_datos[idx] = d_datos[idx] * d_datos[idx];
    }
}
 
int main() {
    int h_datos[N];
    for (int i = 0; i < N; i++) h_datos[i] = i + 1; // [1, 2, ..., 20]
 
    printf("Datos originales:\n");
    for (int i = 0; i < N; i++) printf("%4d", h_datos[i]);
    printf("\n");
 
    // Reservar y copiar a GPU
    int *d_datos;
    cudaMalloc((void**)&d_datos, N * sizeof(int));
    cudaMemcpy(d_datos, h_datos, N * sizeof(int), cudaMemcpyHostToDevice);
 
    // Lanzar kernel (con 1 solo bloque de N hilos)
    cuadradoInPlace<<<1, N>>>(d_datos, N);
    cudaDeviceSynchronize();
 
    // Recuperar resultado
    cudaMemcpy(h_datos, d_datos, N * sizeof(int), cudaMemcpyDeviceToHost);
 
    printf("Despues de elevar al cuadrado en GPU:\n");
    for (int i = 0; i < N; i++) printf("%4d", h_datos[i]);
    printf("\n");
 
    // TAREA: Verifica que cada elemento es igual a (i+1)^2
    // Imprime si hay algun error
 
    cudaFree(d_datos);
    return 0;
}
 
// Compilar: nvcc ejercicio5_cuadrado.cu -o ejercicio5
