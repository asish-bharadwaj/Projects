#include "main.h"

int main(int argc, char** argv) {

    /*
    When fork creates a child process B as a copy of A
    the return value of fork is set as 0 in B where as
    it is set to the process ID of B in parent process A.

    You can use this return value to differentiate between the child and parent process.

    **INPUT**
    String will be given as input from command line.
    */
    // Write your code here
    
    int len = strlen(argv[1]), u = 0, l = 0;

    //  in => input string, upper => uppercase, lower => lowercase
    char in[len], upper[len], lower[len];
    strcpy(in, argv[1]);
    for(int i = 0; i < len; i++){
        if(in[i] <= 'Z'){
            upper[u++] = in[i];
            lower[l++] = in[i]+32;
        }
        else{
            lower[l++] = in[i];
            upper[u++] = in[i]-32;
        }
    }

    int t = fork();
    if(t == 0){
        printf("=== Child Process ===\n");
        printf("%s\n", upper);
    }
    else{
        printf("=== Parent Process ===\n");
        printf("%s\n", lower);
    }
    
    return 0;
}