#include <mpi.h>
#include <omp.h>
#include <stdio.h>
 
int main(int argc, char** argv) {
    // MPI_THREAD_FUNNELED: solo el hilo master llama a MPI
    int provided;
    MPI_Init_thread(&argc, &argv, MPI_THREAD_FUNNELED, &provided);
 
    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
 
    int num_threads = 4;
 
    // TODO 1: Región paralela con OpenMP
    #pragma omp parallel num_threads(num_threads)
    {
        int thread_id = omp_get_thread_num();
        int total_threads = omp_get_num_threads();
 
        printf("  Proceso MPI %d | Hilo OpenMP %d de %d\n",
               rank, thread_id, total_threads);
    }
 
    // TODO 2: Solo el maestro imprime el total
    if (rank == 0) {
        printf("Total unidades: %d x %d = %d\n",
               size, num_threads, size * num_threads);
    }
 
    MPI_Finalize();
    return 0;
}