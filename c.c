#include <stdio.h>
#include <pthread.h>
#include <semaphore.h>
#include <unistd.h>

sem_t semaphore;

// Arrival times for 5 threads
int arrival[5] = {1, 3, 4, 6, 7};

int currentTime = 0;
pthread_mutex_t timeLock;

void* process(void* arg) {
    int id = *(int*)arg;
    int at = arrival[id];

    sleep(at);   // simulate arrival at different times

    printf("P%d arrived at time %d\n", id + 1, at);

    // -------- wait(semaphore) --------
    sem_wait(&semaphore);

    // lock for shared time management
    pthread_mutex_lock(&timeLock);

    int start = currentTime < at ? at : currentTime;
    currentTime = start;

    printf("P%d START at time %d\n", id + 1, start);

    sleep(2);  // critical section (burst time = 2)

    currentTime += 2;
    int completion = currentTime;

    printf("P%d COMPLETE at time %d\n", id + 1, completion);

    pthread_mutex_unlock(&timeLock);
    // -------- signal(semaphore) --------
    sem_post(&semaphore);

    return NULL;
}

int main() {
    pthread_t th[5];
    int id[5];

    sem_init(&semaphore, 0, 1); // binary semaphore
    pthread_mutex_init(&timeLock, NULL);

    for (int i = 0; i < 5; i++) {
        id[i] = i;
        pthread_create(&th[i], NULL, process, &id[i]);
    }

    for (int i = 0; i < 5; i++)
        pthread_join(th[i], NULL);

    sem_destroy(&semaphore);
    pthread_mutex_destroy(&timeLock);

    return 0;
}
