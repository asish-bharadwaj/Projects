#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <semaphore.h>
#include <pthread.h>
#include <unistd.h>

typedef struct hash_table_entry{
    char* key;
    int value;
    struct hash_table_entry* next;
}hash_table_entry;
typedef hash_table_entry* HTE;

typedef struct cust_details{
  char* coffee;
  int cust_id, cust_arrival_time, cust_tolerance_time, baristas_count;
  int* barista_array;
}cust_details;

HTE HT[1024];
int barista_count = 0;
int wasted_coffee = 0;
int cust_token = 1;
sem_t cust_token_sem, barista_count_sem, barista_array_sem, op_sem, hash_table_sem, wasted_coffee_sem;

int hash_function(char *key) {
  unsigned int hash = 0;
  for (int i = 0; i < strlen(key); i++) {
    hash = hash * 31 + key[i];
  }
  return hash % 1024;
}

void hash_table_insert(char *key, int value) {
  int index = hash_function(key);
  HTE entry = (HTE)malloc(sizeof(hash_table_entry));
  entry->key = (char*)malloc(sizeof(char)*100);
  strcpy(entry->key, key);
  entry->value = value;
  entry->next = HT[index];
  HT[index] = entry;
}

int hash_table_lookup(char *key) {
  int index = hash_function(key);
  hash_table_entry *entry = HT[index];
  while (entry != NULL) {
    if (strcmp(entry->key, key) == 0) {
      return entry->value;
    }
    entry = entry->next;
  }
  return -1;
}

void* cust_func(void* arg){
  cust_details cust = *((cust_details*)arg);
  int time = 0, flag = 0;
  while(1){
    // cust-token lock
    sem_wait(&cust_token_sem);
    if(cust_token == cust.cust_id){
      if(flag){
        cust_token++;
        // cust-token unlock
        sem_post(&cust_token_sem);
        return NULL;
      }
      // cust-token unlock
      sem_post(&cust_token_sem);
      while(1){
        // barista_count lock
        sem_wait(&barista_count_sem);
        if(barista_count > 0){
          barista_count--;
          // barista_count unlock
          sem_post(&barista_count_sem);
          int min_barista;

          // barista-array lock
          sem_wait(&barista_array_sem);
          for(int i = 0; i < cust.baristas_count; i++){
            if(cust.barista_array[i] == 0){
              min_barista = i;
              cust.barista_array[i] = 1;
              break;
            }
          }
          // barista-array unlock
          sem_post(&barista_array_sem);

          // cust-token lock
          sem_wait(&cust_token_sem);
          cust_token++;
          // cust-token unlock
          sem_post(&cust_token_sem);

          sleep(1);
          // o/p lock
          sem_wait(&op_sem);
          // cyan color
          printf("\e[0;36mBarista %d begins preparing the order of customer %d at %d second(s)\n\e[0;37m", min_barista+1, cust.cust_id, cust.cust_arrival_time+1+time);
          // o/p unlock
          sem_post(&op_sem);
          // hast-table lock
          sem_wait(&hash_table_sem);
          int time_to_prepare = hash_table_lookup(cust.coffee);
          if(time_to_prepare + 1 +time <= cust.cust_tolerance_time){
            // hash-table unlock
            sem_post(&hash_table_sem);
            sleep(time_to_prepare);

            // o/p lock
            sem_wait(&op_sem);
            // blue
            printf("\e[0;34mBarista %d completes the order of customer %d at %d second(s)\n\e[0;37m", min_barista+1, cust.cust_id, cust.cust_arrival_time+1+time_to_prepare+time);
            // green
            printf("\e[0;32mCustomer %d leaves with their order at %d second(s)\n\e[0;37m", cust.cust_id, cust.cust_arrival_time+1+time_to_prepare+time);
            // o/p unlock
            sem_post(&op_sem);
            // barista-array lock
            sem_wait(&barista_array_sem);
            cust.barista_array[min_barista] = 0;
            // barista-array unlock
            sem_post(&barista_array_sem);
            // barista_count lock
            sem_wait(&barista_count_sem);
            barista_count++;
            // barista_count unlock
            sem_post(&barista_count_sem);
          }
          else{
            // hash-table unlock
            sem_post(&hash_table_sem);
            sleep(cust.cust_tolerance_time - time);

            // o/p lock
            sem_wait(&op_sem);
            // red
            printf("\e[0;31mCustomer %d leaves without their order at %d second(s)\n\e[0;37m", cust.cust_id, cust.cust_tolerance_time+cust.cust_arrival_time+1);
            // o/p unlock
            sem_post(&op_sem);

            sleep(time_to_prepare - cust.cust_tolerance_time + time);
            // o/p lock
            sem_wait(&op_sem);
            // blue
            printf("\e[0;34mBarista %d completes the order of customer %d at % d second(s)\n\e[0;37m", min_barista+1, cust.cust_id, cust.cust_arrival_time+1+time_to_prepare+time);
            // o/p unlock
            sem_post(&op_sem);

            // barista-array lock
            sem_wait(&barista_array_sem);
            cust.barista_array[min_barista] = 0;
            // barista-array unlock
            sem_post(&barista_array_sem);
            // barista_count lock
            sem_wait(&barista_count_sem);
            barista_count++;
            // barista_count unlock
            sem_post(&barista_count_sem);
            // wasted_coffee lock
            sem_wait(&wasted_coffee_sem);
            wasted_coffee++;
            // wasted_coffee unlock
            sem_post(&wasted_coffee_sem);
          }
          return NULL;
        }
        else{
          // barista_count unlock
          sem_post(&barista_count_sem);
          sleep(1);
          time++;
        }
        if(time > cust.cust_tolerance_time){
          // o/p lock
          sem_wait(&op_sem);
          // red
          printf("\e[0;31mCustomer %d leaves without their order at %d second(s)\n\e[0;37m", cust.cust_id, cust.cust_tolerance_time+cust.cust_arrival_time+1);
          // o/p unlock
          sem_post(&op_sem);

          // cust-token lock
          sem_wait(&cust_token_sem);
          cust_token++;
          // cust-token unlock
          sem_post(&cust_token_sem);
          return NULL;
        }
      }
    }
    else{
      // cust-token unlock
      sem_post(&cust_token_sem);
      sleep(1);
      time++;
    }
    if(time > cust.cust_tolerance_time){
      // o/p lock
      sem_wait(&op_sem);
      // red
      printf("\e[0;31mCustomer %d leaves without their order at %d second(s)\n\e[0;37m", cust.cust_id, cust.cust_tolerance_time+cust.cust_arrival_time+1);
      // o/p unlock
      sem_post(&op_sem);
      flag = 1;
    }
  }
}

int main(){
    int N, B, K;
    if(sem_init(&cust_token_sem, 0, 1) == -1){
      perror("Error initializing cust_token_sem");
      exit(0);
    }
    if(sem_init(&barista_count_sem, 0, 1) == -1){
      perror("Error initializing barista_count_sem");
      exit(0);
    }
    if(sem_init(&barista_array_sem, 0, 1) == -1){
      perror("Error initializing barista_array_sem");
      exit(0);
    }
    if(sem_init(&op_sem, 0, 1) == -1){
      perror("Error initializing op_sem");
      exit(0);
    }
    if(sem_init(&hash_table_sem, 0, 1) == -1){
      perror("Error initializing hash_table_sem");
      exit(0);
    }
    if(sem_init(&wasted_coffee_sem, 0, 1) == -1){
      perror("Error initializing wasted_coffee_sem");
      exit(0);
    }
    scanf("%d %d %d", &B, &K, &N);
    barista_count = B;
    int t_c;
    int* baristas_array = (int*)malloc(sizeof(int)*B);
    for(int i = 0; i < B; i++)
      baristas_array[i] = 0;
    cust_details CUSTOMERS[N];
    for(int i = 0; i < K; i++){
        char temp[100];
        scanf(" %s %d", temp, &t_c);
        hash_table_insert(temp, t_c);
    }
    for(int i = 0; i < N; i++){
      CUSTOMERS[i].coffee = (char*)malloc(sizeof(char)*100);
      scanf(" %d %s %d %d", &CUSTOMERS[i].cust_id, CUSTOMERS[i].coffee, &CUSTOMERS[i].cust_arrival_time, &CUSTOMERS[i].cust_tolerance_time);
      CUSTOMERS[i].barista_array = baristas_array;
      CUSTOMERS[i].baristas_count = B;
    }

    int j = 0;
    pthread_t cust_threads[N];
    for(int i = 0; i < N; i++){
      // o/p lock
      sem_wait(&op_sem);
      printf("Customer %d arrives at %d second(s)\n", CUSTOMERS[i].cust_id, CUSTOMERS[i].cust_arrival_time);
      // yellow color
      printf("\e[0;33mCustomer %d orders a %s\n\e[0;37m", CUSTOMERS[i].cust_id, CUSTOMERS[i].coffee);
      // o/p unlock
      sem_post(&op_sem);
      if(i < N-1 && CUSTOMERS[i+1].cust_arrival_time - CUSTOMERS[i].cust_arrival_time > 0){
        for( ; j <= i; j++){
          if(pthread_create(&cust_threads[j], NULL, cust_func, &CUSTOMERS[j]) != 0){
            perror("Error in creating customer thread ");
            exit(0);
          }
        }
        sleep(CUSTOMERS[i+1].cust_arrival_time - CUSTOMERS[i].cust_arrival_time);
      }
    }
    for( ; j < N; j++){
      if(pthread_create(&cust_threads[j], NULL, cust_func, &CUSTOMERS[j]) != 0){
        perror("Error in creating customer thread ");
        exit(0);
      }
    }
    for(int i = 0; i < N; i++){
      if(pthread_join(cust_threads[i], NULL) != 0){
        perror("Error in pthread_join ");
        exit(0);
      }
    }
    printf("\n%d coffee(s) wasted\n", wasted_coffee);
}