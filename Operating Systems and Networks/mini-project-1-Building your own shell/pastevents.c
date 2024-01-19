#include "headers.h"

//  Function to execute pastevents command
char* pastevents(char* input, int* cnt, char* prev_ip, char* ip, char* i, char* home_directory, char* pe_address, char* dum_address, char* parent_dir, char* bg_address){
    char* token = strtok(input, " \t");
    token = strtok(NULL, " \t");
    char buffer[4096];
    FILE* fptr, *dum;

    //  if command is pastevents, read the pastevents.txt file, and print all the past events
    if(token == NULL){
        fptr = fopen(pe_address, "r");
        while(fgets(buffer, 1000, fptr) != NULL){
            printf("%s", buffer);
        }
        fclose(fptr);
    }
    //  if command is pastevents purge, clear the pastevents.txt file
    else if(strcmp(token, "purge") == 0){
        fptr = fopen(pe_address, "w");
        fprintf(fptr, " ");
    }
    //  if command is pastevents execute <index>, execute the command in the index-th line from end
    else if(strcmp(token, "execute") == 0){
        token = strtok(NULL, " \t");
        int line;
        if(strcmp(token, "1") == 0) line = 1;
        else if(strcmp(token, "2") == 0) line = 2;
        else if(strcmp(token, "3") == 0) line = 3;
        else if(strcmp(token, "4") == 0) line = 4;
        else if(strcmp(token, "5") == 0) line = 5;
        else if(strcmp(token, "6") == 0) line = 6;
        else if(strcmp(token, "7") == 0) line = 7;
        else if(strcmp(token, "8") == 0) line = 8;
        else if(strcmp(token, "9") == 0) line = 9;
        else if(strcmp(token, "10") == 0) line = 10;
        else if(strcmp(token, "11") == 0) line = 11;
        else if(strcmp(token, "12") == 0) line = 12;
        else if(strcmp(token, "13") == 0) line = 13;
        else if(strcmp(token, "14") == 0) line = 14;
        else if(strcmp(token, "15") == 0) line = 15;
        else{
            printf("ERROR: Invalid index\n");
            return 0;
        }
        if(line > (*cnt)){
            printf("ERROR: Invalid index\n");
            return 0;
        }
        char buf[4096], ip[4096], i[4096];
        fptr = fopen(pe_address, "r");
        int t = 1;

        for(int i = 1; i <= (*cnt) - line; i++)
            fgets(buf, 4096, fptr);
        //  store the command in buf
        fgets(buf, 4096, fptr);
        buf[strlen(buf)-1] = '\0';
        
        //  execute the command, same way as we did in main.c
        int flag = 1;
        long usec;
        char* in = (char*)malloc(sizeof(char)*4096);
        char* inp = (char*)malloc(sizeof(char)*4096);
        strcpy(in, buf);
        in[strlen(buf)] = '\0';
        strcpy(inp, buf);
        int ptr = 0;
        while(ptr < strlen(buf) && t){
            char* broken_input = (char*)malloc(sizeof(char)*4096);
            int ini = 0;
            for(;ptr < strlen(buf); ptr++){
                if(buf[ptr] == ';'){
                    ptr++;
                    break;
                }
                else if(buf[ptr] == '&'){
                    broken_input[ini++] = ' ';
                    broken_input[ini++] = '&';
                    ptr++;
                    break;
                }
                else if((buf[ptr] == '<' && buf[ptr+1] == '<') || ( buf[ptr] == '>' && buf[ptr+1] == '>')){
                    broken_input[ini++] = ' ';
                    broken_input[ini++] = buf[ptr];
                    broken_input[ini++] = buf[ptr];
                    broken_input[ini++] = ' ';
                }
                else if(buf[ptr] == '>' || buf[ptr] == '<' || buf[ptr] == '|'){
                    broken_input[ini++] = ' ';
                    broken_input[ini++] = buf[ptr];
                    broken_input[ini++] = ' ';
                }
                else
                    broken_input[ini++] = buf[ptr];
            }
            broken_input[ini++] = '\0';
            //  Tokenize the input
            char temp_buf[4096];
            strcpy(temp_buf, broken_input);
            char* token = strtok(broken_input, " \t");
            while(token != NULL){
                flag = 1;
                //  warp command
                if(strcmp(token, "warp") == 0)
                    t = warp(temp_buf, home_directory, parent_dir) & t;
                //  peek command
                else if(strcmp(token, "peek") == 0)
                    t = peek(temp_buf, home_directory) & t;
                //  proclore command
                else if(strcmp(token, "proclore") == 0){
                    proclore(temp_buf);
                }
                //  seek command
                else if(strcmp(token, "seek") == 0)
                    seek(temp_buf, home_directory);
                //  system commands
                else{
                    char temp[4096];
                    int bg = 0;
                    strcpy(temp, temp_buf);
                    if(temp[strlen(temp)-1] == '&'){
                        bg = 1;
                        temp[strlen(temp)-1] = '\0';
                    }
                    t = execute(temp, &usec, bg, bg_address) & t;
                    if(usec > 2000000)
                        flag = 0;
                }
                token = strtok(NULL, " \t");
            }
                // free(broken_input);
                // broken_input = NULL;
        
        }
        // free(in);
        // free(input);
        // in = NULL;
        // input = NULL;
        return in;
    }
    else{
        printf("ERROR: Invalid argument!\n");
    }
    return NULL;
}