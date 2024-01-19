#include "headers.h"

//  Function for proclore implementation
int proclore(char* ip) {
    char* token = strtok(ip, " \t");
    token = strtok(NULL, " \t");
    if (token == NULL) {
        // current pid
        pid_t pid = getpid();
        token = (char*)malloc(sizeof(char) * 20);
        sprintf(token, "%d", pid);
    }
    FILE* fptr;
    char path[256];
    sprintf(path, "/proc/%s/stat", token);
    char exe[256];
    sprintf(exe, "/proc/%s/exe", token);
    fptr = fopen(path, "r");
    if(fptr == NULL){
        perror("Error:");
        return 0;
    }
    char comm[20], state, pid[20], pgrp[20], tpgid[20], vsize[20], temp[20];
    int i = 2;
    //  pid   
    fscanf(fptr, "%s", temp);
    strcpy(pid, temp);
    while (i < 24) {
        fscanf(fptr, "%s", temp);
        if (i == 3)     //  process status
            state = temp[0];
        else if (i == 5)    //  process group
            strcpy(pgrp, temp);
        else if (i == 8)    //  ID of the foreground process group of the controlling terminal of the process.
            strcpy(tpgid, temp);
        else if (i == 23)   //  Virtual memory
            strcpy(vsize, temp);
        i++;
    }
    printf("pid : %s\n", pid);
    printf("process Status : ");
    //  If pgrp and tpgid are the same => Foreground process
    //  Else, background process
    switch (state) {
        case 'R':
            if (strcmp(pgrp, tpgid) != 0)
                printf("R\n");
            else
                printf("R+\n");
            break;
        case 'S':
            if (strcmp(pgrp, tpgid) != 0)
                printf("S\n");
            else
                printf("S+\n");
            break;
        case 'Z':
            printf("Z\n");
            break;
        default:
            break;
    }
    printf("Process Group : %s\n", pgrp);
    printf("Virtual memory : %s\n", vsize);
    printf("executable Path : ");
    char exe_path[512];
    //  exe is a symlink
    ssize_t exe_length = readlink(exe, exe_path, sizeof(exe_path));
    if (exe_length != -1)
        exe_path[exe_length] = '\0';
    else
        strcpy(exe_path, "Unknown");
    printf("%s\n", exe_path);
    return 1;
}

