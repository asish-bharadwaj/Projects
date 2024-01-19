#include "headers.h"

//  Comparator function for sorting files in lexicographic order
int compareByName(const void* a, const void* b){
    return strcmp((*((struct dirent**)a))->d_name, (*((struct dirent**)b))->d_name);
}

//  Function to print the permissions of the file/directory
void print_perm(struct stat* f, struct dirent* d){
    char perm[11];
    strcpy(perm, "----------");
    perm[10] = '\0';
    
    if(d->d_type == DT_DIR)
        perm[0] = 'd';

    if(d->d_type == DT_LNK)
        perm[0] = 'l';

    if(f->st_mode & S_IRUSR)
        perm[1] = 'r';

    if(f->st_mode & S_IWUSR)
        perm[2] = 'w';
    
    if(f->st_mode & S_IXUSR)
        perm[3] = 'x';

    if(f->st_mode & S_IRGRP)
        perm[4] = 'r';

    if(f->st_mode & S_IWGRP)
        perm[5] = 'w';

    if(f->st_mode & S_IXGRP)
        perm[6] = 'x';

    if(f->st_mode & S_IROTH)
        perm[7] = 'r';

    if(f->st_mode & S_IWOTH)
        perm[8] = 'w';

    if(f->st_mode & S_IXOTH)
        perm[9] = 'x';
        
    printf("%s ", perm);
}

//  0 => name only, no hidden       peek
//  1 => name only, hidden also     peek -a
//  2 => list, no hidden            peek -l
//  3 => list, hidden also          peek -al/ -la/ -a -l/ -l -a

//  Function to print the file description based on the mode
void print_file_descr(struct stat* f, int mode, struct dirent* d){
    if(mode == 0){
        // name only - with color coding
        if(d->d_name[0] != '.'){
            if(d->d_type == DT_DIR)
                printf("\e[34m%s\e[0m\n", d->d_name);
            else if(d->d_type == DT_LNK)
                printf("\e[36m%s\e[0m\n", d->d_name);
            else{
                if(f->st_mode & S_IXUSR)
                    printf("\e[32m%s\e[0m\n", d->d_name);
                else
                    printf("\e[37m%s\e[0m\n", d->d_name);
            }
        }
    }
    else if(mode == 1){
        if(d->d_type == DT_DIR)
            printf("\e[34m%s\e[0m\n", d->d_name);
        else if(d->d_type == DT_LNK)
            printf("\e[36m%s\e[0m\n", d->d_name);
        else{
            if(f->st_mode & S_IXUSR)
                printf("\e[32m%s\e[0m\n", d->d_name);
            else
                printf("\e[37m%s\e[0m\n", d->d_name);
        }
    }
    else if(mode == 2){
        if(d->d_name[0] != '.'){
            struct passwd* p = getpwuid(f->st_uid);
            struct group* g = getgrgid(f->st_gid);
            print_perm(f, d);
            printf("%ld ", f->st_nlink);
            printf("%s ", p->pw_name);
            printf("%s ", g->gr_name);
            printf("%ld %4s", f->st_size, "");
            struct tm* timeinfo = localtime(&f->st_mtime);
            char formattedTime[50];
            strftime(formattedTime, sizeof(formattedTime), "%b %d %H:%M", timeinfo);
            printf("%s %3s", formattedTime, "");
            if(d->d_type == DT_DIR)
                printf("\e[34m%s\e[0m\n", d->d_name);
            else if(d->d_type == DT_LNK)
                printf("\e[36m%s\e[0m\n", d->d_name);
            else{
                if(f->st_mode & S_IXUSR)
                    printf("\e[32m%s\e[0m\n", d->d_name);
                else
                    printf("\e[37m%s\e[0m\n", d->d_name);
            }
        }
    }
    else if(mode == 3){
        struct passwd* p = getpwuid(f->st_uid);
        struct group* g = getgrgid(f->st_gid);
        print_perm(f, d);
        printf("%ld ", f->st_nlink);
        printf("%s ", p->pw_name);
        printf("%s ", g->gr_name);
        printf("%ld %4s", f->st_size, "");
        struct tm* timeinfo = localtime(&f->st_mtime);
        char formattedTime[50];
        strftime(formattedTime, sizeof(formattedTime), "%b %d %H:%M", timeinfo);
        printf("%s %3s", formattedTime, "");
        if(d->d_type == DT_DIR)
            printf("\e[34m%s\e[0m\n", d->d_name);
        else if(d->d_type == DT_LNK)
            printf("\e[36m%s\e[0m\n", d->d_name);
        else{
            if(f->st_mode & S_IXUSR)
                printf("\e[32m%s\e[0m\n", d->d_name);
            else
                printf("\e[37m%s\e[0m\n", d->d_name);
        }
    }
}

//  Function to sort the directory
int proc(char* token, char* home_directory, int mode){
    int hc = home_count(token), count = 0;
    if(hc > 0)
        token = replace_home(token, hc, home_directory);
    DIR* dir = opendir(token);
    if(dir == NULL){
        printf("Invlaid argument!\n");
        return 0;
    }
    struct dirent* s = readdir(dir);
    while(s != NULL){
        count++;
        s = readdir(dir);
    }
    closedir(dir);
    struct dirent** arr = (struct dirent**)malloc(sizeof(struct dirent*)*count);
    count = 0;
    dir = opendir(token);
    s = readdir(dir);
    struct stat* statbuf = (struct stat*)malloc(sizeof(struct stat));
    char* path = (char*)malloc(sizeof(char)*4096);
    intmax_t bloc = 0;
    if(mode == 2){
        while(s != NULL){
            arr[count++] = s;
            if(s->d_name[0] != '.'){
                strcpy(path, token);
                strcat(path, "/");
                strcat(path, s->d_name);
                int t = stat(path, statbuf);
                bloc += statbuf->st_blocks;
            }
            s = readdir(dir);
        }
    }
    else if(mode == 3){
        while(s != NULL){
            arr[count++] = s;
            strcpy(path, token);
            strcat(path, "/");
            strcat(path, s->d_name);
            int t = stat(path, statbuf);
            bloc += statbuf->st_blocks;
            s = readdir(dir);
        }
    }
    else{
        while(s != NULL){
            arr[count++] = s;
            s = readdir(dir);
        }
    }
    qsort(arr, count, sizeof(struct dirent*), compareByName);
    if(mode == 2 || mode == 3){
        printf("total %jd\n", (intmax_t) bloc);
    }
    for(int i = 0; i < count; i++){
        strcpy(path, token);
        strcat(path, "/");
        strcat(path, arr[i]->d_name);
        int t = stat(path, statbuf);
        print_file_descr(statbuf, mode, arr[i]);
    }
    closedir(dir);
    // free(statbuf);
    // statbuf = NULL;
    // for(int i = 0; i < count; i++){
    //     free(arr[i]);
    //     arr[i] = NULL;
    // }
    // free(arr);
    // arr = NULL;
    // free(path);
    // path = NULL;
    return 1;
}

//  Function for peek implementation
int peek(char* input, char* home_directory){
    char* token = strtok(input, " \t");
    token = strtok(NULL, " \t");
    if(token == NULL){
        // current directory
        char* buf = (char*)malloc(4096);
        char* current_directory = getcwd(buf, 4096);

        if(proc(current_directory, home_directory, 0) == 0)
            return 0;
        // free(buf);
        // buf = NULL;
    }
    else{
        if(strcmp(token, "-a") == 0){
            token = strtok(NULL, " \t");
            if(token == NULL){
                char* buf = (char*)malloc(4096);
                char* current_directory = getcwd(buf, 4096);

                if(proc(current_directory, home_directory, 1) == 0)
                    return 0;
                // free(buf);
                // buf = NULL;
            }
            else if(strcmp(token, "-l") == 0){
                token = strtok(NULL, " \t");
                if(token == NULL){
                    char* buf = (char*)malloc(4096);
                    token = getcwd(buf, 4096);
                }
                if(proc(token, home_directory, 3) == 0)
                    return 0;
            }
            else{
                if(proc(token, home_directory, 1) == 0)
                    return 0;
            }
        }
        else if(strcmp(token, "-l") == 0){
            token = strtok(NULL, " \t");
            if(token == NULL){
                char* buf = (char*)malloc(4096);
                token = getcwd(buf, 4096);
                if(proc(token, home_directory, 2) == 0)
                    return 0;
            }
            else if(strcmp(token, "-a") == 0){
                token = strtok(NULL, " \t");
                if(token == NULL){
                    char* buf = (char*)malloc(4096);
                    token = getcwd(buf, 4096);
                }
                if(proc(token, home_directory, 3) == 0)
                    return 0;
            }
            else{
                if(proc(token, home_directory, 2) == 0)
                    return 0;
            }
        }
        else if(strcmp(token, "-al") == 0 || strcmp(token, "-la") == 0){
            token = strtok(NULL, " \t");
            if(token == NULL){
                char* buf = (char*)malloc(4096);
                token = getcwd(buf, 4096);
            }
            if(proc(token, home_directory, 3) == 0)
                return 0;
        }
        else{
            if(proc(token, home_directory, 0) == 0)
                return 0;
        }
   }
   
    return 1;
}