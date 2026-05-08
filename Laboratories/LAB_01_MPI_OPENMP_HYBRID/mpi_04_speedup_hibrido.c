#include <mpi.h>
#include <omp.h>
#include <stdio.h>
#include <stdlib.h>
 
#define N 1000000
 
int main(int argc, char** argv) {

    int provided;
    MPI_Init_thread(&argc, &argv, MPI_THREAD_FUNNELED, &provided);
 
    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
 
    int chunk = N / size;
    long long *arr = NULL;

    // En rank 0 inicia medición paralela
    double t_inicio;

    if (rank == 0) {
        t_inicio = MPI_Wtime();

        arr = (long long*) malloc(N * sizeof(long long));

        for (int i = 0; i < N; i++) {
            arr[i] = i;
        }
    }
 
    // Buffer local
    long long *local = (long long*) malloc(chunk * sizeof(long long));
 
    // Repartir datos
    MPI_Scatter(
        arr,
        chunk,
        MPI_LONG_LONG,
        local,
        chunk,
        MPI_LONG_LONG,
        0,
        MPI_COMM_WORLD
    );
 
    // Suma paralela con OpenMP
    long long suma_local = 0;

    #pragma omp parallel for reduction(+:suma_local)
    for (int i = 0; i < chunk; i++) {
        suma_local += local[i];
    }
 
    // Reducir resultados
    long long suma_total = 0;

    MPI_Reduce(
        &suma_local,
        &suma_total,
        1,
        MPI_LONG_LONG,
        MPI_SUM,
        0,
        MPI_COMM_WORLD
    );
 
    // Finaliza medición paralela
    double t_fin;

    if (rank == 0) {

        t_fin = MPI_Wtime();

        printf("Suma total paralela = %lld\n", suma_total);
        printf("Esperado            = %lld\n",
               (long long)N*(N-1)/2);

        printf("Tiempo paralelo: %.6f segundos\n",
               t_fin - t_inicio);

        // ─── Versión secuencial ───────────────────────

        long long suma_seq = 0;

        double ts = MPI_Wtime();

        // For secuencial normal
        for (int i = 0; i < N; i++) {
            suma_seq += i;
        }

        double te = MPI_Wtime();

        printf("\nSuma secuencial = %lld\n", suma_seq);

        printf("Tiempo secuencial: %.6f segundos\n",
               te - ts);

        printf("Speedup: %.2fx\n",
               (te - ts) / (t_fin - t_inicio));

        free(arr);
    }
 
    free(local);

    MPI_Finalize();

    return 0;
}