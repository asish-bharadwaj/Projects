#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <semaphore.h>
#include <pthread.h>
#include <unistd.h>

typedef struct hash_table_entry{
    char* key;
    int value, ictop;
    struct hash_table_entry* next;
}hash_table_entry;
typedef hash_table_entry* HTE;

typedef struct ice_cream{
    char* flavour;
    int num_of_toppings, done;
    char** toppings;
}ice_cream;

typedef struct cust_details{
  int cust_id, cust_arrival_time, cust_no_of_icecreams;
  ice_cream* cust_icecreams;
}cust_details;

// typedef struct ll{
//     cust_details cust;
//     struct ll* next;
// }ll;
// typedef ll* LL;

typedef struct order{
    int machine_no, icecream_index, customer_index, time, ic_prep_time;
}order;

cust_details* CUSTOMERS, *cust_no_entry;
int cust_in = 0;
int no_entry_ind = 0, **machine_details;
int K, N;
// int cust_token = 1;
int machines_count = 0;
int machines_ended = 0;
// ASSUMPTION:- Ice_creams and Toppings cannot have same names
HTE HT[1024];

sem_t cust_in_sem, no_entry_ind_sem, machine_detials_sem, machines_count_sem, machines_ended_sem, op_sem, hash_table_sem;

int hash_function(char *key) {
  unsigned int hash = 0;
  for (int i = 0; i < strlen(key); i++) {
    hash = hash * 31 + key[i];
  }
  return hash % 1024;
}

void hash_table_insert(char *key, int value, int ictop) {
  int index = hash_function(key);
  HTE entry = (HTE)malloc(sizeof(hash_table_entry));
  entry->key = (char*)malloc(sizeof(char)*100);
  strcpy(entry->key, key);
  entry->ictop = ictop;
  entry->value = value;
  entry->next = HT[index];
  HT[index] = entry;
}

int hash_table_lookup(char *key, int ictop) {
  int index = hash_function(key);
  hash_table_entry *entry = HT[index];
  while (entry != NULL) {
    if (strcmp(entry->key, key) == 0 && entry->ictop == ictop) {
      return entry->value;
    }
    entry = entry->next;
  }
  return -1;
}

void hash_table_update(char* key, int ictop){
    int index = hash_function(key);
    hash_table_entry* entry = HT[index];
    while(entry != NULL){
        if(strcmp(entry->key, key) == 0 && entry->ictop == ictop){
            entry->value--;
        }
        entry = entry->next;
    }
}

void* mach_func(void* arg){
    int index = *((int*)arg);
    index--;
    // printf("in mach - %d\n", index);
    // machine_details lock
    sem_wait(&machine_detials_sem);
    int start = machine_details[index][2];
    int end = machine_details[index][3];
    // machine_details unlock
    sem_post(&machine_detials_sem);

    sleep(start);

    // o/p lock
    sem_wait(&op_sem);
    printf("\e[38;2;255;85;0mMachine %d has started working at %d second(s)\n\e[0;37m", index+1, start);
    // o/p unlock
    sem_post(&op_sem);

    // machine_details lock
    sem_wait(&machine_detials_sem);
    machine_details[index][1] = 0;
    // machine_details unlock
    sem_post(&machine_detials_sem);

    sleep(end-start);

    // o/p lock
    sem_wait(&op_sem);
    printf("\e[38;2;255;85;0mMachine %d has stopped working at %d second(s)\n\e[0;37m", index+1, end);
    // o/p unlock
    sem_post(&op_sem);

    // machine_details lock
    sem_wait(&machine_detials_sem);
    machine_details[index][1] = 2;
    // machine_details unlock
    sem_post(&machine_detials_sem);

    // machines_ended lock
    sem_wait(&machines_ended_sem);
    machines_ended++;
    sem_post(&machines_ended_sem);
}

void* order_func(void* arg){
    order o = *((order*)arg);
    
    printf("\e[0;36mMachine %d starts preparing ice cream %d of customer %d at %d second(s)\n\e[0;37m",o.machine_no+1, o.icecream_index+1, o.customer_index, o.time);
    sleep(o.ic_prep_time);
    printf("\e[0;34mMachine %d completes preparing ice cream %d of customer %d at %d second(s)\n\e[0;37m",o.machine_no+1, o.icecream_index+1, o.customer_index, o.time+ o.ic_prep_time );

    // machine_details lock
    sem_wait(&machine_detials_sem);
    machine_details[o.machine_no][1] = 0;
    // machine_details unlock
    sem_post(&machine_detials_sem);

    //machines_count lock
    sem_wait(&machines_count_sem);
    machines_count++;
    sem_post(&machines_count_sem);
    return NULL;
}

void* cust_func(void* arg){
    cust_details cust = *((cust_details*)arg);
    // what if parlour is full ??
    // If a customer comes when K places are filled, they never enter the parlour, thus you do not need to print anything. 
    // You can keep a track of how many such cases were there and print them after Parlour Closed.
    
    sleep(cust.cust_arrival_time);

    // cust_in lock
    sem_wait(&cust_in_sem);
    if(cust_in == K){
        // no-entry lock
        sem_wait(&no_entry_ind_sem);
        cust_no_entry[no_entry_ind++] = cust;
        // no-entry unlock
        sem_post(&no_entry_ind_sem);
        // cust_in unlock
        sem_post(&cust_in_sem);
        return NULL;
    }
    cust_in++;
    // cust_in unlock
    sem_post(&cust_in_sem);

    // o/p lock
    sem_wait(&op_sem);
    printf("Customer %d enters at %d second(s)\n", cust.cust_id, cust.cust_arrival_time);
    printf("\e[0;33mCustomer %d orders %d icecream(s)\n\e[0;37m", cust.cust_id, cust.cust_no_of_icecreams);
    int flag = 0;
    for(int i = 0; i < cust.cust_no_of_icecreams; i++){
        printf("\e[0;33mIce cream %d: %s \e[0;37m", i+1, cust.cust_icecreams[i].flavour);
        for(int j = 0; j < cust.cust_icecreams[i].num_of_toppings; j++){
            printf("\e[0;33m%s \e[0;37m", cust.cust_icecreams[i].toppings[j]);
            // hash-table lock
            sem_wait(&hash_table_sem);
            if(hash_table_lookup(cust.cust_icecreams[i].toppings[j], 1) == 0)
                flag = 1;
            // hash-table unlock
            sem_post(&hash_table_sem);
        }
        printf("\n");
    }
    if(flag == 1){
        printf("\e[0;31mCustomer %d left at %d second(s) with an unfulfilled order\n\e[0;37m", cust.cust_id, cust.cust_arrival_time);
        // o/p unlock
        sem_post(&op_sem);
        sleep(1);
        //cust_in lock
        sem_wait(&cust_in_sem);
        cust_in--;
        //cust_in unlock
        sem_post(&cust_in_sem);
        return NULL;
    }
    // o/p unlock
    sem_post(&op_sem);
    sleep(1);
    pthread_t order_thread[cust.cust_no_of_icecreams];
    int waiting_time = 1, i, j, k, order_threads_created = 0;
    while(1){
        // // cust-token lock
        // if(cust_token == cust.cust_id){
        //     if(flag){
        //         cust_token++;
        //         // cust-token unlock
        //         return NULL;
        //     }
            // cust-token unlock
            // while(1){
                // machines_ended lock
                sem_wait(&machines_ended_sem);
                if(machines_ended == N){
                    sem_post(&machines_ended_sem);
                    // o/p lock
                    sem_wait(&op_sem);
                    printf("\e[0;31mCustomer %d was not serviced due to unavailability of machines\n\e[0;37m", cust.cust_id);
                    // o/p unlock
                    sem_post(&op_sem);

                    for(int i = 0; i < order_threads_created; i++){
                        if(pthread_join(order_thread[i], NULL) != 0){
                            perror("Error in pthread_join of order_thread");
                            exit(1);
                        }
                    }

                    return NULL;
                }
                sem_post(&machines_ended_sem);
                // machines_count lock
                sem_wait(&machines_count_sem);
                int top = 0, start_flag = 0, start_icecream = 0, alldone = 0, donecount = 0;
                if(machines_count > 0){
                    // hash_table lock
                    sem_wait(&hash_table_sem);
                    sem_wait(&machine_detials_sem);
                    for(i = 0; i < N; i++){
                        top = 0, start_flag = 0;
                        // machine_details lock
                        if(machine_details[i][1] == 0){
                            for(j = 0; j < cust.cust_no_of_icecreams; j++){
                                if(cust.cust_icecreams[j].done == 0){
                                    if(hash_table_lookup(cust.cust_icecreams[j].flavour, 0) + 1 + cust.cust_arrival_time + waiting_time <= machine_details[i][3]){
                                        for(k = 0; k < cust.cust_icecreams[j].num_of_toppings; k++){
                                            if(hash_table_lookup(cust.cust_icecreams[j].toppings[k], 1) != 0){
                                                top++;
                                            }
                                            else{
                                                // o/p lock
                                                sem_wait(&op_sem);
                                                printf("\e[0;31mCustomer %d left at %d second(s) with an unfulfilled order - Edge Case\n\e[0;37", cust.cust_id, cust.cust_arrival_time+waiting_time);
                                                // o/p unlock
                                                sem_post(&op_sem);
                                                sem_post(&machines_count_sem);
                                                sem_post(&machine_detials_sem);
                                                sem_post(&hash_table_sem);
                                                for(int i = 0; i < order_threads_created; i++){
                                                    if(pthread_join(order_thread[i], NULL) != 0){
                                                        perror("Error in pthread_join of order_thread at Edge case");
                                                        exit(1);
                                                    }
                                                }
                                                return NULL;
                                            }
                                        }
                                        if(top == cust.cust_icecreams[j].num_of_toppings){
                                            start_flag = 1;
                                            start_icecream = j;
                                            break;
                                        }
                                    }
                                }
                                else{
                                    donecount++;
                                    if(donecount == cust.cust_no_of_icecreams){
                                        sem_post(&hash_table_sem);
                                        sem_post(&machine_detials_sem);
                                        sem_post(&machines_count_sem);
                                        for(int i = 0; i < order_threads_created; i++){
                                            if(pthread_join(order_thread[i], NULL) != 0){
                                                perror("Error in pthread_join of order_thread at done-count == cust_no_icecreams ");
                                                exit(1);
                                            }
                                        }
                                        printf("\e[0;32mCustomer %d has collected their order(s) and left at %d second(s)\n\e[0;37", cust.cust_id, cust.cust_arrival_time+waiting_time+1);
                                        return NULL;
                                    }
                                }
                            }
                            if(start_flag == 1)
                                break;
                        }
                    }
                    if(start_flag == 1){
                        machines_count--;
                        sem_post(&machines_count_sem);
                        order new;
                        new.customer_index = cust.cust_id;
                        new.icecream_index = start_icecream;
                        new.machine_no = i;
                        new.ic_prep_time = hash_table_lookup(cust.cust_icecreams[start_icecream].flavour, 0);
                        new.time = cust.cust_arrival_time + waiting_time;
                        for(int t = 0; t < cust.cust_icecreams[start_icecream].num_of_toppings; t++)
                            hash_table_update(cust.cust_icecreams[start_icecream].toppings[t], 1);
                        machine_details[i][1] = 1;
                        sem_post(&machine_detials_sem); 
                        sem_post(&hash_table_sem);
                        cust.cust_icecreams[start_icecream].done = 1;
                        // printf("\e[0;36mMachine %d starts preparing ice cream %d of customer %d at %d second(s)\n\e[0;37m",new.machine_no+1, new.icecream_index, new.customer_index, new.time);
                        pthread_create(&order_thread[order_threads_created++], NULL, order_func, &new);
                    }
                    else{
                        waiting_time++;
                        sem_post(&hash_table_sem);
                        sem_post(&machines_count_sem);
                        sem_post(&machine_detials_sem);
                        sleep(1);
                    }
                }
                else{
                    sem_post(&machines_count_sem);
                    sleep(1);
                    waiting_time++;
                }
            // }
        }
    // }

}

int main(){
    if(sem_init(&cust_in_sem, 0, 1) == -1){
      perror("Error initializing cust_in_sem");
      exit(0);
    }
    if(sem_init(&no_entry_ind_sem, 0, 1) == -1){
      perror("Error initializing no_entry_sem");
      exit(0);
    }
    if(sem_init(&machine_detials_sem, 0, 1) == -1){
      perror("Error initializing machine_details_sem");
      exit(0);
    }
    if(sem_init(&machines_count_sem, 0, 1) == -1){
      perror("Error initializing machines_count_sem");
      exit(0);
    }
    if(sem_init(&machines_ended_sem, 0, 1) == -1){
      perror("Error initializing machines_ended_sem");
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


    int F, T, t_f, C = 0;
    CUSTOMERS = (cust_details*)malloc(sizeof(cust_details)*1000);
    // CUSTOMERS->next = NULL;
    // LL temp = CUSTOMERS, ptemp = NULL;
    cust_details temp_cust;
    scanf("%d %d %d %d", &N, &K, &F, &T);
    machines_count = N;
    // int** machines_free = (int**)malloc(sizeof(int*)*N);
    machine_details = (int**)malloc(sizeof(int*)*N);

    for(int i = 0; i < N; i++){
        machine_details[i] = (int*)malloc(sizeof(int)*4);
        // machines_free[i] = (int*)malloc(sizeof(int)*4);
        // machines_free[i][0] = i+1;// index
        // machines_free[i][1] = 1;// free = 0, not free/not started = 1, ended = 2 
        // start-time, end-time
        machine_details[i][0] = i+1;
        machine_details[i][1] = 1;// free = 0, not free/not started = 1, ended = 2 
        // start-time, end-time
        scanf("%d %d", &machine_details[i][2], &machine_details[i][3]);
    }
    // CUSTOMERS->machine_free = machines_free;
    for(int i = 0; i < F; i++){
        char temp[100];
        scanf(" %s %d", temp, &t_f);
        hash_table_insert(temp, t_f, 0);
    }
    for(int i = 0; i < T; i++){
        char temp[100];
        scanf(" %s %d", temp, &t_f);
        hash_table_insert(temp, t_f, 1);
    }
    int cust_id, cust_arr_time, cust_ice_creams;
    char c = getchar();
    char buff[4096], *buffer;
    while(*fgets(buff, 4096, stdin) != '\n'){
        // printf("%c\n", c);
        // C++;
        // ASSUMPTION:- i/p length will not be greater than 4096 per line
        // scanf("%d %d %d", &cust_id, &cust_arr_time, &cust_ice_creams);
        // fgets(buff, 4096, stdin);
        // printf("%s", buff);
        buff[strlen(buff)-1] = '\0';
        if(buff[0] == '\n')
            break;
        buffer = strtok(buff, " ");
        cust_id = atoi(buffer);
        buffer = strtok(NULL, " ");
        cust_arr_time = atoi(buffer);
        buffer = strtok(NULL, " ");
        cust_ice_creams = atoi(buffer);
        temp_cust.cust_arrival_time = cust_arr_time;
        temp_cust.cust_id = cust_id;
        temp_cust.cust_no_of_icecreams = cust_ice_creams;
        temp_cust.cust_icecreams = (ice_cream*)malloc(sizeof(ice_cream)*cust_ice_creams);
        for(int i = 0; i < cust_ice_creams; i++){
            temp_cust.cust_icecreams[i].flavour = (char*)malloc(sizeof(char)*50);
            char ip[4096], dup[4096];
            fgets(ip, 4096, stdin);
            ip[strlen(ip)-1] = '\0';
            strcpy(dup, ip);
            buffer = strtok(dup, " ");
            strcpy(temp_cust.cust_icecreams[i].flavour, buffer);
            int top = 0;
            while((buffer = strtok(NULL, " ")) != NULL)
                top++;
            temp_cust.cust_icecreams[i].toppings = (char**)malloc(sizeof(char*)*top);
            for(int j = 0; j < top; j++)
                temp_cust.cust_icecreams[i].toppings[j] = (char*)malloc(sizeof(char)*50);
            buffer = strtok(ip, " ");   
            int j = 0;
            while((buffer = strtok(NULL, " ")) != NULL)
                strcpy(temp_cust.cust_icecreams[i].toppings[j++], buffer);
                // printf("%s\n", buffer);
            temp_cust.cust_icecreams[i].num_of_toppings = top;
            temp_cust.cust_icecreams[i].done = 0;
        }
        CUSTOMERS[C++] = temp_cust;
        // temp->next = (LL)malloc(sizeof(ll));
        // ptemp = temp;
        // temp = temp->next;
        // temp->machine_free = machines_free;
    }
    // free(temp);
    // temp = NULL;
    // if(ptemp != NULL)
    //     ptemp->next = NULL;
    // temp = CUSTOMERS;
    cust_no_entry = (cust_details*)malloc(sizeof(cust_details)*C);
    pthread_t mach_threads[N];
    pthread_t cust_threads[C];
    for(int z = 0; z < N; z++){
        // printf("sending - %d\n", z);
        // int ti = z;
        if(pthread_create(&mach_threads[z], NULL, mach_func, &machine_details[z][0]) != 0){
            perror("Error in creating customer thread ");
            exit(0);
        }
    }
    // printf("done sending mach\n");
    for(int z = 0; z < C; z++){
        if(pthread_create(&cust_threads[z], NULL, cust_func, &CUSTOMERS[z]) != 0){
            perror("Error in creating customer thread ");
            exit(0);
        }
    }

    for(int z = 0; z < N; z++){
        if(pthread_join(mach_threads[z], NULL) != 0){
            perror("Error in pthread_join as mach_threads ");
            exit(1);
        }
    }
    for(int z = 0; z < C; z++){
        if(pthread_join(cust_threads[z], NULL) != 0){
            perror("Error in pthread_join as cust_threads ");
            exit(1);
        }
    }

    printf("Parlour Closed\n\n");

    for(int z = 0; z < no_entry_ind; z++)
        printf("Customer %d arrived at %d second(s), but never entered the parlour as the parlour was full\n", cust_no_entry[z].cust_id, cust_no_entry[z].cust_arrival_time);
}
