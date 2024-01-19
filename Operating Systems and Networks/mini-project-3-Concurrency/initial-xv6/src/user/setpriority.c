#include "kernel/types.h"
#include "kernel/stat.h"
#include "user.h"
#include "kernel/fcntl.h"

int main(int argc, char** argv){
    if(argc < 3 || argc > 3){
        printf("Incorrect input format. Expected format -  setpriority pid priority\n");
        exit(1);
    }
    int pid = atoi(argv[1]);
    int priority = atoi(argv[2]);
    printf("%d\n",  setpriority(pid, priority));
    exit(0);
}