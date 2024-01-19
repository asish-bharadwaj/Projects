#include "headers.h"

//  Funciton to count the no. of occurrences of '~'
int home_count(char* input){
    int l = strlen(input), c = 0;
    for(int i = 0; i < l ; i++){
        if(input[i] == '~')
            c++;
    }
    return c;
}

//  Funciton to replace '~' with home_directory (absolute address)
char* replace_home(char* input, int hc, char* home_directory) {
    int ip_size = strlen(input);
    int hd_size = strlen(home_directory);
    int l = hd_size * hc + ip_size - hc + 1;
    char* ip = (char*)malloc(sizeof(char) * l);
    int ip_pos = 0; 

    for (int j = 0; j < ip_size - hc + 1; j++) {
        if (input[j] != '~')
            ip[ip_pos++] = input[j];
        else {
            for (int k = 0; k < hd_size; k++)
                ip[ip_pos++] = home_directory[k];
        }
    }
    ip[ip_pos] = '\0';

    return ip;
}

//  warp function
int warp(char* input, char* home_directory, char* parent_dir){
    //  Replace all occurrences of '~' with home_directory
    int hc = home_count(input);
    if(hc > 0)
        input = replace_home(input, hc, home_directory);
    //  Tokenize the input
    char* token = strtok(input, " \t");
    
    token = strtok(NULL, " \t");

    //  If no arguments are passed, change directory to the home directory
    if(token == NULL){
        char* buf = (char*)malloc(4096);
        char* current_directory = getcwd(buf, 4096);
        strcpy(parent_dir, buf);
        int t = chdir(home_directory);
        printf("%s\n", home_directory);
        // free(buf);
        // buf = NULL;
    }
    //  Else if argument is - (previous directory)
    else if(*token == '-'){
        //  If the directory was not changed before, print error message
        if(strcmp("-1", parent_dir) == 0){
                printf("OLDPWD not set\n");
        }
        //  Else, change directory to the previous directory
        else{
            char* buf = (char*)malloc(4096);
            char temp[4096];
            char* current_directory = getcwd(buf, 4096);
            //  temporarily store the cwd
            strcpy(temp, current_directory);
            //  change to the previous directory
            int t = chdir(parent_dir);
            //  store the temp stored directory to the parent_dir
            strcpy(parent_dir, temp);
            current_directory = getcwd(buf, 4096);
            printf("%s\n", buf);
            // free(buf);
            // buf = NULL;
        }
    }
    //  Else, change to the directory mentioned in the argument
    else{
        while(token != NULL){
            char* buf = (char*)malloc(4096);
            char* current_directory = getcwd(buf, 4096);
            strcpy(parent_dir, buf);
            int t = chdir(token);
            if(t == -1){
                perror("Error: ");
                return 0;
            }
            current_directory = getcwd(buf, 4096);
            printf("%s\n", current_directory);
            token = strtok(NULL, " \t");
            // free(buf);
            // buf = NULL;
        }
    }
    
    return 1;
}


//  Function to change directory in case of seek -e
//  Same implementation as warp. Here we do not print the directory name
int warpi(char* input, char* home_directory){
    int hc = home_count(input);
    if(hc > 0)
        input = replace_home(input, hc, home_directory);
    char* token = strtok(input, " \t");
    
    token = strtok(NULL, " \t");
    if(token == NULL){
        char* buf = (char*)malloc(4096);
        char* current_directory = getcwd(buf, 4096);
        int t = chdir(home_directory);
        // free(buf);
        // buf = NULL;
    }
    else{
        while(token != NULL){
            char* buf = (char*)malloc(4096);
            char* current_directory = getcwd(buf, 4096);
            int t = chdir(token);
            if(t == -1){
                perror("Error: ");
                return 0;
            }
            current_directory = getcwd(buf, 4096);
            token = strtok(NULL, " \t");
            // free(buf);
            // buf = NULL;
        }
    }

    return 1;
}
