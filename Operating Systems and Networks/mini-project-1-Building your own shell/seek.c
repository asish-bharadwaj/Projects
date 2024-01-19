#include "headers.h"

//  To store the path of the only_one file or directory
char only_one[64];
//  mode 0 => both
//  mode 1 => only files
//  mode 2 => only directories

int print_match(struct stat* f, int mode, struct dirent* d, char* short_path, char* search, char* long_path){
    int t = 0;
    if(mode == 0){
            if(d->d_type == DT_DIR){
                printf("\e[34m%s%s\e[0m\n", short_path, d->d_name);
                char current_directory[4096];
                char temp[4096], temp2[4096];
                strcpy(temp, short_path);
                strcpy(current_directory, long_path);
                strcat(current_directory, "/");
                strcat(current_directory, d->d_name);
                strcpy(only_one, current_directory);
            }
            else{    
                printf("\e[37m%s%s\e[0m\n", short_path, d->d_name);
                strcpy(only_one, long_path);
                strcat(only_one, "/");
                strcat(only_one, d->d_name);
            }
            t++;
        }
    
    else if(mode == 1){
        if(d->d_type != DT_DIR){
            printf("\e[37m%s%s\e[0m\n", short_path, d->d_name);
            strcpy(only_one, long_path);
            strcat(only_one, "/");
            strcat(only_one, d->d_name);
            t++;
        }
    }
    else{
        if(d->d_type == DT_DIR){
            t++;
            printf("\e[34m%s%s\e[0m\n", short_path, d->d_name);
            char current_directory[4096];
            char temp[4096], temp2[4096];
            strcpy(temp, short_path);
            strcpy(current_directory, long_path);
            strcat(current_directory, "/");
            strcat(current_directory, d->d_name);
            strcpy(only_one, current_directory);
        }
    }
    return t;
}

//  Recursive-function
//  Iterates through each file/directory and sub-directories
int seek_proc(char* token, char* search, int mode, char* path){
    char temp[4096];
    int t = 0;
    DIR* dir = opendir(token);
    if(dir == NULL){
        perror("ERROR: ");
        return -1;
    }
    struct dirent* s = readdir(dir);
    struct stat* statbuf = (struct stat*)malloc(sizeof(struct stat));
    while(s != NULL){
        if(strstr(s->d_name, search)){
            strcpy(temp, token);
            strcat(temp , "/");
            strcat(temp, s->d_name);
            int p = stat(temp, statbuf);
            t += print_match(statbuf, mode, s, path, search, token);
        }
        if(s->d_type == DT_DIR && strcmp(".", s->d_name) && strcmp("..", s->d_name)){
            char new_path[4096];
            strcpy(new_path, path);
            strcat(new_path, s->d_name);
            strcat(new_path, "/");
            strcpy(temp, token);
            strcat(temp , "/");
            strcat(temp, s->d_name);
            t += seek_proc(temp, search, mode, new_path);
        }
        s = readdir(dir);
    }
    closedir(dir);
    // free(statbuf);
    // statbuf = NULL;
    return t;
}

//  Handling the arguments
int seek(char* ip, char* home_directory){
    int hc = home_count(ip), count = 0;
    if(hc > 0)
        ip = replace_home(ip, hc, home_directory);
    char* token = strtok(ip, " \t");
    token = strtok(NULL, " \t");
    
    if(strcmp(token, "-d") == 0){
        token = strtok(NULL, " \t");
        if(strcmp(token, "-e") == 0){
            //  -d -e
            token = strtok(NULL, " \t");
            //  token is search
            char* search = (char*)malloc(sizeof(char)*(strlen(token)));
            strcpy(search, token);
            token = strtok(NULL, " \t");
            //  token is target
            if(token == NULL){
                char* buf = (char*)malloc(4096);
                char* current_directory = getcwd(buf, 4096);
                int t = seek_proc(current_directory, search, 2, "./");
                if(t == 1){
                    char wip[5000];
                    strcpy(wip, "warp ");
                    struct stat fileStat;
                    stat(only_one, &fileStat);
                    mode_t mode = fileStat.st_mode;
                    int perm = (mode&S_IXGRP) | (mode&S_IXOTH) | (mode&S_IXUSR); 
                    strcat(wip, only_one);
                    if(perm) 
                        warpi(wip, home_directory);
                    else
                        printf("Missing permissions for task!\n");
                }
                else if(t == 0)
                    printf("No match found!\n");
                else if(t == -1)
                    return 0;
                // free(buf);
                // buf = NULL;
            }
            else{
                int t = seek_proc(token, search, 2, "./");
                if(t == 1){
                    char wip[5000];
                    strcpy(wip, "warp ");
                    struct stat fileStat;
                    stat(only_one, &fileStat);
                    mode_t mode = fileStat.st_mode;
                    int perm = (mode&S_IXGRP) | (mode&S_IXOTH) | (mode&S_IXUSR); 
                    strcat(wip, only_one);
                    if(perm) 
                        warpi(wip, home_directory);
                    else
                        printf("Missing permissions for task!\n");
                }
                else if(t == 0)
                    printf("No match found!\n");
                else if(t == -1)
                    return 0;
            }
            // free(search);
            // search = NULL;
        }        
        else if(strcmp(token, "-f") == 0 || strcmp(token, "-fe") == 0 || strcmp(token, "-ef") == 0){
            // ERROR
            //  -d -f
            printf("ERROR: Invalid flags!\n");
            return 0;
        }
        else{
            //  -d
            //token is search
            char* search = (char*)malloc(sizeof(char)*(strlen(token)));
            strcpy(search, token);
            token = strtok(NULL, " \t");
            //  token is target
            if(token == NULL){
                char* buf = (char*)malloc(4096);
                char* current_directory = getcwd(buf, 4096);
                int t = seek_proc(current_directory, search, 2, "./");
                if(t == 0)
                    printf("No match found!\n");
                else if(t == -1)
                    return 0;
                // free(buf);
                // buf = NULL;
            }
            else{
                int t = seek_proc(token, search, 2, "./");
                if(t == 0)
                    printf("No match found!\n");
                else if(t == -1)    
                    return 0;
            }
            // free(search);
            // search = NULL;
        }
    }
    else if(strcmp(token, "-e") == 0){
        token = strtok(NULL, " \t");
        if(strcmp(token, "-d") == 0){
            //  -e -d
            token = strtok(NULL, " \t");
            //  token is search
            char* search = (char*)malloc(sizeof(char)*(strlen(token)));
            strcpy(search, token);
            token = strtok(NULL, " \t");
            //  token is target
            if(token == NULL){
                char* buf = (char*)malloc(4096);
                char* current_directory = getcwd(buf, 4096);
                int t = seek_proc(current_directory, search, 2, "./");
                if(t == 1){
                    char wip[5000];
                    strcpy(wip, "warp ");
                    struct stat fileStat;
                    stat(only_one, &fileStat);
                    mode_t mode = fileStat.st_mode;
                    int perm = (mode&S_IXGRP) | (mode&S_IXOTH) | (mode&S_IXUSR); 
                    strcat(wip, only_one);
                    if(perm) 
                        warpi(wip, home_directory);
                    else
                        printf("Missing permissions for task!\n");
                }
                else if(t == 0)
                    printf("No match found!\n");
                else if(t == -1)
                    return 0;
                // free(buf);
                // buf = NULL;
            }
            else{
                int t = seek_proc(token, search, 2, "./");
                if(t == 1){
                    char wip[5000];
                    strcpy(wip, "warp ");
                    struct stat fileStat;
                    stat(only_one, &fileStat);
                    mode_t mode = fileStat.st_mode;
                    int perm = (mode&S_IXGRP) | (mode&S_IXOTH) | (mode&S_IXUSR); 
                    strcat(wip, only_one);
                    if(perm) 
                        warpi(wip, home_directory);
                    else
                        printf("Missing permissions for task!\n");
                }
                else if(t == 0)
                    printf("No match found!\n");
                else if(t == -1)
                    return 0;
            }
            // free(search);
            // search = NULL;
        }
        else if(strcmp(token, "-f") == 0){
            //  -e -f
            token = strtok(NULL, " \t");
            //  token is search
            char* search = (char*)malloc(sizeof(char)*(strlen(token)));
            strcpy(search, token);
            token = strtok(NULL, " \t");
            //  token is target
            if(token == NULL){
                char* buf = (char*)malloc(4096);
                char* current_directory = getcwd(buf, 4096);
                int t = seek_proc(current_directory, search, 1, "./");
                if(t == 1){
                    char wip[5000];
                    struct stat fileStat;
                    stat(only_one, &fileStat);
                    mode_t mode = fileStat.st_mode;
                    int perm = (mode&S_IXGRP) | (mode&S_IXOTH) | (mode&S_IXUSR); 
                    strcat(wip, only_one);
                    if(perm){
                        FILE* fptr = fopen(only_one, "r");
                        char buffer[1000];
                        while(fgets(buffer, 1000, fptr) != NULL){
                            printf("%s", buf);
                        }
                        fclose(fptr);
                    }
                    else
                        printf("Missing permissions for task!\n");
                }
                else if(t == 0)
                    printf("No match found!\n");
                else if(t == -1)
                    return 0;
                // free(buf);
                // buf = NULL;
            }
            else{
                int t = seek_proc(token, search, 1, "./");
                if(t == 1){
                    struct stat fileStat;
                    stat(only_one, &fileStat);
                    mode_t mode = fileStat.st_mode;
                    int perm = (mode&S_IXGRP) | (mode&S_IXOTH) | (mode&S_IXUSR); 
                    if(perm){
                        FILE* fptr = fopen(only_one, "r");
                        char buffer[1000];
                        while(fgets(buffer, 1000, fptr) != NULL){
                            printf("%s", buffer);
                        }
                        fclose(fptr);
                    }
                    else
                        printf("Missing permissions for task!\n");
                }
                else if(t == 0)
                    printf("No match found!\n");
                else if(t == -1)
                    return 0;
            }
            // free(search);
            // search = NULL;
        }
        else if(strcmp(token, "-fd") == 0 || strcmp(token, "-df") == 0){
            // ERROR
            //  -e -fd | -e -df
            printf("ERROR: Invalid flags!\n");
            return 0;
        }   
        else{
            //  -e
            //  token is search
            char* search = (char*)malloc(sizeof(char)*(strlen(token)));
            strcpy(search, token);
            token = strtok(NULL, " \t");
            //  token is target
            if(token == NULL){
                char* buf = (char*)malloc(4096);
                char* current_directory = getcwd(buf, 4096);
                int t = seek_proc(current_directory, search, 0, "./");
                if(t == 1){
                    struct stat str;
                    int p = stat(only_one, &str);
                    // printf("%d\n", str.st_mode&S_IFMT - S_IFDIR);
                    if(((str.st_mode&S_IFMT) ^ S_IFDIR) == 0){
                        char wip[5000];
                        strcpy(wip, "warp ");
                        struct stat fileStat;
                        stat(only_one, &fileStat);
                        mode_t mode = fileStat.st_mode;
                        int perm = (mode&S_IXGRP) | (mode&S_IXOTH) | (mode&S_IXUSR); 
                        strcat(wip, only_one);
                        if(perm) 
                            warpi(wip, home_directory);
                        else
                            printf("Missing permissions for task!\n");
                    }
                    else{
                        struct stat fileStat;
                        stat(only_one, &fileStat);
                        mode_t mode = fileStat.st_mode;
                        int perm = (mode&S_IXGRP) | (mode&S_IXOTH) | (mode&S_IXUSR); 
                        if(perm){
                            FILE* fptr = fopen(only_one, "r");
                            char buffer[1000];
                            while(fgets(buffer, 1000, fptr) != NULL){
                                printf("%s", buffer);
                            }
                            fclose(fptr);
                        }
                        else
                            printf("Missing permissions for task!\n");
                    }
                }
                else if(t == 0)
                    printf("No match found!\n");
                else if(t == -1)
                    return 0;
                // free(buf);
                // buf = NULL;
            }
            else{
                int t = seek_proc(token, search, 0, "./");
                if(t == 1){
                    struct stat str;
                    int p = stat(only_one, &str);
                    if(str.st_mode & S_IFMT == S_IFDIR){
                        char wip[1000];
                        strcpy(wip, "warp ");
                        struct stat fileStat;
                        stat(only_one, &fileStat);
                        mode_t mode = fileStat.st_mode;
                        int perm = (mode&S_IXGRP) | (mode&S_IXOTH) | (mode&S_IXUSR); 
                        strcat(wip, only_one);
                        if(perm) 
                            warpi(wip, home_directory);
                        else
                            printf("Missing permissions for task!\n");
                    }
                    else{
                        struct stat fileStat;
                        stat(only_one, &fileStat);
                        mode_t mode = fileStat.st_mode;
                        int perm = (mode&S_IXGRP) | (mode&S_IXOTH) | (mode&S_IXUSR); 
                        if(perm){
                            FILE* fptr = fopen(only_one, "r");
                            char buffer[1000];
                            while(fgets(buffer, 1000, fptr) != NULL){
                                printf("%s", buffer);
                            }
                            fclose(fptr);
                        }
                        else
                            printf("Missing permissions for task!\n");
                    }
                }
                else if(t == 0)
                    printf("No match found!\n");
                else if(t == -1)
                    return 0;
            }
            // free(search);
            // search = NULL;
        }
    }
    else if(strcmp(token, "-f") == 0){
        token = strtok(NULL, " \t");
        if(strcmp(token, "-e") == 0){
            //  -f -e
            token = strtok(NULL, " \t");
            //  token is search
            char* search = (char*)malloc(sizeof(char)*(strlen(token)));
            strcpy(search, token);
            token = strtok(NULL, " \t");
            //  token is target
            if(token == NULL){
                char* buf = (char*)malloc(4096);
                char* current_directory = getcwd(buf, 4096);
                int t = seek_proc(current_directory, search, 1, "./");
                if(t == 1){
                    char wip[5000];
                    struct stat fileStat;
                    stat(only_one, &fileStat);
                    mode_t mode = fileStat.st_mode;
                    int perm = (mode&S_IXGRP) | (mode&S_IXOTH) | (mode&S_IXUSR); 
                    strcat(wip, only_one);
                    if(perm){
                        FILE* fptr = fopen(only_one, "r");
                        char buffer[1000];
                        while(fgets(buffer, 1000, fptr) != NULL){
                            printf("%s", buf);
                        }
                        fclose(fptr);
                    }
                    else
                        printf("Missing permissions for task!\n");
                }
                else if(t == 0)
                    printf("No match found!\n");
                else if(t == -1)
                    return 0;
                // free(buf);
                // buf = NULL;
            }
            else{
                int t = seek_proc(token, search, 1, "./");
                if(t == 1){
                    char wip[5000];
                    struct stat fileStat;
                    stat(only_one, &fileStat);
                    mode_t mode = fileStat.st_mode;
                    int perm = (mode&S_IXGRP) | (mode&S_IXOTH) | (mode&S_IXUSR); 
                    strcat(wip, only_one);
                    if(perm){
                        FILE* fptr = fopen(only_one, "r");
                        char buffer[1000];
                        while(fgets(buffer, 1000, fptr) != NULL){
                            printf("%s", buffer);
                        }
                        fclose(fptr);
                    }
                    else
                        printf("Missing permissions for task!\n");
                }
                else if(t == 0)
                    printf("No match found!\n");
                else if(t == -1)
                    return 0;
            }
            // free(search);
            // search = NULL;
        }
        else if(strcmp(token, "-d") == 0 || strcmp(token, "-de") == 0 || strcmp(token, "-ed") == 0){
            // ERROR
            //  -f -d
            printf("ERROR: Invalid flags!\n");
            return 0;
        }
        else{
            //  -f
            //  token is search
            char* search = (char*)malloc(sizeof(char)*(strlen(token)));
            strcpy(search, token);
            token = strtok(NULL, " \t");
            //  token is target
            if(token == NULL){
                char* buf = (char*)malloc(4096);
                char* current_directory = getcwd(buf, 4096);
                int t = seek_proc(current_directory, search, 1, "./");
                if(t == 0)
                    printf("No match found!\n");
                else if(t == -1)
                    return 0;
            }
            else{
                int t = seek_proc(token, search, 1, "./");
                if(t == 0)
                    printf("No match found!\n");
                else if(t == -1)
                    return 0;
            }
            // free(search);
            // search = NULL;
        }
    }
    else if(strcmp(token, "-de") == 0 || strcmp(token, "-ed") == 0){
        token = strtok(NULL, " \t");
        if(strcmp(token, "-f") == 0){
            //  -de -f | -ed -f
            //ERROR
            printf("ERROR: Invalid flags!\n");
            return 0;
        }
        else{
            //  -ed | -de
            //  token is search
            char* search = (char*)malloc(sizeof(char)*(strlen(token)));
            strcpy(search, token);
            token = strtok(NULL, " \t");
            //  token is target
            if(token == NULL){
                char* buf = (char*)malloc(4096);
                char* current_directory = getcwd(buf, 4096);
                int t = seek_proc(current_directory, search, 2, "./");
                if(t == 1){
                    char wip[5000];
                    strcpy(wip, "warp ");
                    struct stat fileStat;
                    stat(only_one, &fileStat);
                    mode_t mode = fileStat.st_mode;
                    int perm = (mode&S_IXGRP) | (mode&S_IXOTH) | (mode&S_IXUSR); 
                    strcat(wip, only_one);
                    if(perm) 
                        warpi(wip, home_directory);
                    else
                        printf("Missing permissions for task!\n");
                }
                else if(t == 0)
                    printf("No match found!\n");
                else if(t == -1)
                    return 0;
                // free(buf);
                // buf = NULL;
            }
            else{
                int t = seek_proc(token, search, 2, "./");
                if(t == 1){
                    char wip[5000];
                    strcpy(wip, "warp ");
                    struct stat fileStat;
                    stat(only_one, &fileStat);
                    mode_t mode = fileStat.st_mode;
                    int perm = (mode&S_IXGRP) | (mode&S_IXOTH) | (mode&S_IXUSR); 
                    strcat(wip, only_one);
                    if(perm) 
                        warpi(wip, home_directory);
                    else
                        printf("Missing permissions for task!\n");
                }
                else if(t == 0)
                    printf("No match found!\n");
                else if(t == -1)
                    return 0;
            }
            // free(search);
            // search = NULL;
        }
    }
    else if(strcmp(token, "-ef") == 0 || strcmp(token, "-fe") == 0){
        token = strtok(NULL, " \t");
        if(strcmp(token, "-d") == 0){
            //  -ef -d | -fe -d 
            //ERROR
            printf("ERROR:Invalid flags!\n");
            return 0;
        }
        else{
            //  -ef | -fe
            //  token is search
            char* search = (char*)malloc(sizeof(char)*(strlen(token)));
            strcpy(search, token);
            token = strtok(NULL, " \t");
            //  token is target
            if(token == NULL){
                char* buf = (char*)malloc(4096);
                char* current_directory = getcwd(buf, 4096);
                int t = seek_proc(current_directory, search, 1, "./");
                if(t == 1){
                    struct stat fileStat;
                    stat(only_one, &fileStat);
                    mode_t mode = fileStat.st_mode;
                    int perm = (mode&S_IXGRP) | (mode&S_IXOTH) | (mode&S_IXUSR); 
                    if(perm){
                        FILE* fptr = fopen(only_one, "r");
                        char buffer[1000];
                        while(fgets(buffer, 1000, fptr) != NULL){
                            printf("%s", buf);
                        }
                        fclose(fptr);
                    }
                    else
                        printf("Missing permissions for task!\n");
                }
                else if(t == 0)
                    printf("No match found!\n");
                else if(t == -1)
                    return 0;
                // free(buf);
                // buf = NULL;
            }
            else{
                int t = seek_proc(token, search, 1, "./");
                if(t == 1){
                    struct stat fileStat;
                    stat(only_one, &fileStat);
                    mode_t mode = fileStat.st_mode;
                    int perm = (mode&S_IXGRP) | (mode&S_IXOTH) | (mode&S_IXUSR); 
                    if(perm){
                        FILE* fptr = fopen(only_one, "r");
                        char buffer[1000];
                        while(fgets(buffer, 1000, fptr) != NULL){
                            printf("%s", buffer);
                        }
                        fclose(fptr);
                    }
                    else
                        printf("Missing permissions for task!\n");
                }
                else if(t == 0)
                    printf("No match found!\n");
                else if(t == -1)
                    return 0;
            }
            // free(search);
            // search = NULL;
        }
    }
    else if(strcmp(token, "-fd") == 0 || strcmp(token, "-df") == 0 || strcmp(token, "-fde") == 0 || strcmp(token, "-fed") == 0 || strcmp(token, "-edf") == 0 || strcmp(token, "-efd") == 0 || strcmp(token, "-def") == 0 || strcmp(token, "-dfe") == 0){
        //ERROR
        //  -fd | -df | -fed | -fde | -edf | -efd | -def | -dfe
        printf("ERROR: Invalid flags!\n");
        return 0;
    }
    else{
        //  no args
        //  token is search
        char* search = (char*)malloc(sizeof(char)*(strlen(token)));
        strcpy(search, token);
        token = strtok(NULL, " \t");
        //  token is target
        if(token == NULL){
            char* buf = (char*)malloc(4096);
            char* current_directory = getcwd(buf, 4096);
            int t = seek_proc(current_directory, search, 0, "./");
            if(t == 0)
                printf("No match found!\n");
            else if(t == -1)
                return 0;
            // free(buf);
            // buf = NULL;
        }
        else{
            int t = seek_proc(token, search, 0, "./");
            if(t == 0)
                printf("No match found!\n");
            else if(t == -1)
                return 0;
        }
        // free(search);
        // search = NULL;
    }
    return 1;
}