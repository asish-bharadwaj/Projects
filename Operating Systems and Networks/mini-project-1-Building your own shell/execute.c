#include "headers.h"

//  Function for executing system funcitons
int execute(char* ip, long* usec, int bg, char* bg_address){
    char** arr = NULL;
    int argc = 0;
    FILE* fptr = fopen(bg_address, "a");
    char* token = strtok(ip, " \t");
    //  If it is a backgroud process, print name of the process to the bg_proc.txt file
    if(bg)
        fprintf(fptr, "%s ", token);
    //  storing the command and arguments in an array
    while(token != NULL && *token != '&'){
        arr = (char**)realloc(arr, (argc+1)*sizeof(char*));
        arr[argc] = token;
        argc++;
        token = strtok(NULL, " \t");
    }
    arr = (char**)realloc(arr, (argc+1)*sizeof(char*));
    arr[argc] = NULL;

    //  If it is a foreground process, directly use execvp()
    //  Calculate time taken by the process finding difference between the time instant at which the process began and ended
    if(bg == 0){
        struct timeval start_time, end_time;
        gettimeofday(&start_time, NULL);
        pid_t t = fork();
        if(t == 0){
            int p = execvp(arr[0], arr);
            if(p == -1){
                printf("ERROR: %s is an invalid command!\n", arr[0]);
                exit(0);
            }
        }
        else{
            wait(NULL);
            gettimeofday(&end_time, NULL);
        }
        (*usec) = (end_time.tv_sec - start_time.tv_sec)*1000000 + (end_time.tv_usec - start_time.tv_usec);
    }
    //  Else, fork and execute the background process in the child process
    //  Print the pid of the child (background process) in the shell
    else{
        // pid_t original_fd = tcgetpgrp(STDIN_FILENO);
        pid_t pid = fork();
        if(pid == 0){
            setpgid(0, 0);
            int p = execvp(arr[0], arr);
            if(p == -1){
                strcpy(arr[1], arr[0]);
                strcat(arr[1], " is not a valid command");
                strcpy(arr[0], "echo");
                int p = execvp(arr[0], arr);
            }
        }
        else{
            // tcsetpgrp(STDIN_FILENO, pid);
            fprintf(fptr, "%d\n", pid);
            printf("%d\n", pid);
        }
    }
    fclose(fptr);
    return 1;
}