#include "headers.h"

//  Function to round-off the time taken by the process
int roundoff(double usec){
    int floor = (int)usec;
    int ceil = floor + 1;

    if(usec - floor == 0.5){
        if(floor % 2 == 0)
            return floor;
        else
            return ceil;
    }

    if(usec - floor < ceil - usec)
        return floor;
    else
        return ceil;
}

//  Funciton to print the prompt
void prompt(char* home_directory) {
    char host[_SC_HOST_NAME_MAX];
    int h = gethostname(host, _SC_HOST_NAME_MAX);
    char* user = getlogin();
    char* buf = (char*)malloc(100000);
    char* current_directory = getcwd(buf, 1000000);

    if(h == 0){
        printf("<\e[1m\e[32m%s@%s\e[0m:\e[1m", user, host);
        char* result = strstr(current_directory, home_directory);
        if(result == NULL)
            printf("\e[1m\e[34m%s\e[0m>", current_directory);
        else
            if(strcmp(result, home_directory) == 0)
                printf("\e[1m\e[34m~\e[0m>");
            else{
                printf("\e[1m\e[34m%s\e[0m>", result+strlen(home_directory));
            }
    }

    // free(buf);
    // buf = NULL;
}

//  Funciton to print prompt along with process that ran for >2 seconds
void prompt_with_proc(char* home_directory, long usec, char* i){
    char* temp = (char*)malloc(sizeof(char)*(strlen(i)));
    strcpy(temp, i);
    char* token = strtok(temp, " \t");
    int time = roundoff((double)usec/1000000);
    char host[_SC_HOST_NAME_MAX];
    int h = gethostname(host, _SC_HOST_NAME_MAX);
    char* user = getlogin();
    char* buf = (char*)malloc(100000);
    char* current_directory = getcwd(buf, 1000000);

    if(h == 0){
        printf("<\e[1m\e[32m%s@%s\e[0m:\e[1m", user, host);
        char* result = strstr(current_directory, home_directory);
        if(result == NULL)
            printf("\e[1m\e[34m%s\e[0m\e[1m %s : %ds\e[0m>", current_directory, token, time);
        else
            if(strcmp(result, home_directory) == 0)
                printf("\e[1m\e[34m~\e[0m\e[1m %s : %ds\e[0m>", token, time);
            else{
                printf("\e[1m\e[34m%s\e[0m\e[1m %s : %ds\e[0m>", result+strlen(home_directory), token, time);
            }
    }

    // free(buf);
    // buf = NULL;
    // free(temp);
    // temp = NULL;
}
