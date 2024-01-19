#include "headers.h"

//  Global variables
//  bg_address -> file that stores all the background process
//  commands and process id, which are currently running in background
//  qlock -> as a lock for the completed background processes queue, so that we do not enqueu and clear at the same time
char bg_address[4096];
int qlock = 0;

//  Function to initialize the queue
Q initQ(){
    Q q = (Q)malloc(sizeof(Queue));
    q->front = 0;
    q->rear = -1;
    q->capacity = 4096;
    q->cur_size = 0;
    q->msg = (char**)malloc(sizeof(char*)*4096);
    for(int i = 0; i < 4096; i++){
        q->msg[i] = (char*)malloc(sizeof(char)*100);
    }
    return q;
}

//  Function to enqueue a string (message that a background process completed) to the queue
void enqueue(Q q, char* str){
    if(q->cur_size < q->capacity){
        q->rear++;
        q->rear %= q->capacity;
        q->cur_size++;
        strcpy(q->msg[q->rear], str);
    }
}

//  Function to clear the queue
void clear(Q q){
    q->rear = -1;
    q->front = 0;
    q->cur_size = 0;
}

Q q;

//  Signal handler to keep checking for signals sent from completed background processes
void sigchld_handler(int signum) {
    int status;
    pid_t pid;
    char childpath[64];
    
    //  Continuously check for completed background processes (=> pid > 0)
    while ((pid = waitpid(-1, &status, WNOHANG)) > 0) {
        int succ = 0;
        
        //  Set succ bit to 1 if the background process exited normally
        //  Else set to 0 (=> exited abnormally)
        if (WIFEXITED(status))
            succ = 1;
            
        char* message = (char*)malloc(sizeof(char)*100);
        char* buf = (char*)malloc(sizeof(char) * 4096);
        char cpid[20];
        int l = 0;
        
        sprintf(cpid, "%d", pid);
        FILE* fptr = fopen(bg_address, "r");  
        
        //  Read the file that stores all the background process (bg_proc.txt)
        //  Find the line that matches with the pid of the completed process
        while (fgets(buf, 4096, fptr) != NULL) {
            if (strlen(buf)) {
                l++;
                
                if (strstr(buf, cpid)) {
                    //  Store the message (<command> exited <normally/abnormally> (<pid>))
                    char* temp = (char*)malloc(sizeof(char)*strlen(buf));
                    strcpy(temp, buf);
                    char* token = strtok(temp, " \t");
                    strcpy(message, token);
                    strcat(message, " exited ");
                    
                    if (succ)
                        strcat(message, "normally ");
                    else
                        strcat(message, " abnormally ");
                        
                    strcat(message, "(");
                    strcat(message, cpid);
                    strcat(message, ")\n");
                    
                    //  If queue is locked, wait until it is unlocked
                    while (qlock) { }  
                    //  Lock the queue
                    qlock = 1;
                    //  Enqueue the message
                    enqueue(q, message);  
                    //  Unlock the queue
                    qlock = 0;
                    // free(temp);
                    // temp = NULL;
                    break;
                }
            }
        }
        fclose(fptr);
        
        //  In order to remove the completed process from the bg_proc.txt
        //  Write all the lines except the one that mathces with pid into a temporary dummy file
        fptr = fopen(bg_address, "r");
        FILE* d = fopen("dum.txt", "w");
        
        while (fgets(buf, 4000, fptr) != NULL) {
            if (strlen(buf)) {
                l--;
                if (l == 0)
                    continue;
                    
                fwrite(buf, sizeof(char), strlen(buf), d);
            }
        }
        
        fclose(fptr);
        fclose(d);
        
        //  Now read from the dummy file and write to the bg_proc.txt file
        d = fopen("dum.txt", "r");
        fptr = fopen(bg_address, "w");
        
        while (fgets(buf, 4000, d) != NULL) {
            if (strlen(buf))
                fwrite(buf, sizeof(char), strlen(buf), fptr);
        }
        
        fclose(fptr);
        fclose(d);
        // free(message);
        // free(buf);
        // buf = NULL;
        // message = NULL;
    }
}

int main(){   
    char parent_dir[4096];
    strcpy(parent_dir, "-1");
    //  Initiating the signal handler
    signal(SIGCHLD, sigchld_handler);
    //  Initiating the message queue
    q = initQ();
    char* buf = (char*)malloc(4096);
    char* home_directory = getcwd(buf, 4096);
    char buffer[4096], prev_ip[4096], pe_address[4096], dum_address[4096];
    int cnt = 0, flag = 1;
    long usec;
    //  We will be using these text files - pastevents, dummy, bg_proc
    //  If they already exist, do not do anything
    //  Else create these files using write mode
    FILE* fptr = fopen("pastevents.txt", "r"), *dum = fopen("dummy.txt", "r"), *bg_proc = fopen("bg_proc.txt", "r");
    if(fptr == NULL)
        fptr = fopen("pastevents.txt", "w");
    if(dum == NULL)
        dum = fopen("dummy.txt", "w");
    if(bg_proc == NULL)
        bg_proc = fopen("bg_proc.txt", "w");
    fclose(bg_proc);
    fclose(fptr);
    fclose(dum);
    //  Store the corresponding addresses in pe_address, dum_address, bg_address
    fptr = fopen("pastevents.txt", "r");
    strcpy(pe_address, home_directory);
    strcpy(dum_address, home_directory);
    strcpy(bg_address, home_directory);
    strcat(pe_address, "/pastevents.txt");
    strcat(dum_address, "/dummy.txt");
    strcat(bg_address, "/bg_proc.txt");
    //  From the pastevents.txt file, get the latest command executed before the shell was terminated
    while(fgets(buffer, 4096, fptr) != NULL){
        cnt++;
        strcpy(prev_ip, buffer);
    }
    if(prev_ip[strlen(prev_ip)-1] == '\n');
        prev_ip[strlen(prev_ip)-1] = '\0';
    fclose(fptr);

    // Keep accepting commands
    while (1)
    {
        // Print appropriate prompt with username, systemname and directory before accepting input
        if(flag)
            prompt(home_directory);
        else
            prompt_with_proc(home_directory, usec, prev_ip);
        char input[4096], ip[4096], i[4096];
        fgets(input, 4096, stdin);
        //  After scanning the input, wait until the queue is unlocked
        while(qlock){}
        //  If the queue is non empty (=> There are some messages to be printed)
        if(q->cur_size){
            //  Lock the queue
            qlock = 1;
            //  Print the messages
            for(int i = q->front; i != q->rear + 1; i = (i+1)%(q->capacity))
                printf("%s\n", q->msg[i]);
            clear(q);
            //  Lock the queue
            qlock = 0;
        }
        if(input[strlen(input)-1] == '\n')
            input[strlen(input)-1] = '\0';
        char* mod_input = (char*)malloc(sizeof(char)*4096);
        strcpy(mod_input, input);
        strcpy(ip, input);
        strcpy(i, input);
        int t = 1;
        int ptr = 0;
        while(ptr < strlen(input) && t){
            char* broken_input = (char*)malloc(sizeof(char)*4096);
            int ini = 0;
            for(;ptr < strlen(input); ptr++){
                if(input[ptr] == ';'){
                    ptr++;
                    break;
                }
                else if(input[ptr] == '&'){
                    broken_input[ini++] = ' ';
                    broken_input[ini++] = '&';
                    ptr++;
                    break;
                }
                else if((input[ptr] == '<' && input[ptr+1] == '<') || ( input[ptr] == '>' && input[ptr+1] == '>')){
                    broken_input[ini++] = ' ';
                    broken_input[ini++] = input[ptr];
                    broken_input[ini++] = input[ptr];
                    broken_input[ini++] = ' ';
                }
                else if(input[ptr] == '>' || input[ptr] == '<' || input[ptr] == '|'){
                    broken_input[ini++] = ' ';
                    broken_input[ini++] = input[ptr];
                    broken_input[ini++] = ' ';
                }
                else
                    broken_input[ini++] = input[ptr];
            }
            broken_input[ini++] = '\0';
            //  Tokenize the input
            char temp_buf[4096];
            strcpy(temp_buf, broken_input);
            char* token = strtok(broken_input, " \t");
            while(token != NULL && t){
                flag = 1;
                //  warp command
                if(strcmp(token, "warp") == 0)
                    t = warp(temp_buf, home_directory, parent_dir) & t;
                //  peek command
                else if(strcmp(token, "peek") == 0)
                    t = peek(temp_buf, home_directory) & t;
                //  pastevents command
                else if(strcmp(token, "pastevents") == 0){
                    char* v = pastevents(temp_buf, &cnt, prev_ip, ip, i, home_directory, pe_address, dum_address, parent_dir, bg_address);
                    if(v == NULL)
                        t = 0;
                    else{
                        char* x = strstr(mod_input, "pastevents");
                        int ind = x - mod_input;
                        char* tempo = (char*)malloc(sizeof(char)*4096);
                        int j = 0;
                        for(int i = 0; i < ind; i++)
                            tempo[j++] = mod_input[i];
                        for(int i = 0; i < strlen(v); i++)
                            tempo[j++] = v[i];
                        int i;
                        for(i = ind + strlen(broken_input); i < strlen(mod_input) && input[i] != ';' ; i++){}
                        for(; i < strlen(mod_input); i++)
                            tempo[j++] = mod_input[i];
                        tempo[j++] = '\0';
                        strcpy(mod_input, tempo);
                        // free(tempo);
                        // tempo = NULL;
                    }
                }
                //  proclore command
                else if(strcmp(token, "proclore") == 0){
                    t = proclore(temp_buf) & t;
                }
                //  seek command
                else if(strcmp(token, "seek") == 0)
                    t = seek(temp_buf, home_directory) & t;
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
                // broken_input = NULL;
                // free(broken_input);
        }
        //  If the command executed successfully
        if(t && strlen(mod_input)){
            //  If the command is different from the last successfully command, write it to the pastevents.txt file
            if(strcmp(mod_input, prev_ip)){
                //  If already 15 commands are stored, remove the oldest command executed
                if(cnt == 15){
                    fptr = fopen(pe_address, "r");
                    dum = fopen(dum_address, "w");
                    fgets(buffer, 4096, fptr);
                    while(fgets(buffer, 4096, fptr) != NULL){
                        fprintf(dum, "%s", buffer);
                    }
                    fclose(dum);
                    fclose(fptr);
                    fptr = fopen(pe_address, "w");
                    dum = fopen(dum_address, "r");
                    while(fgets(buffer, 4096, dum) != NULL){
                        fprintf(fptr, "%s", buffer);
                    }
                    fprintf(fptr, "%s\n", mod_input);
                    fclose(dum);
                    fclose(fptr);
                }
                else{
                    fptr = fopen(pe_address, "a");
                    fprintf(fptr, "%s\n", mod_input);
                    fclose(fptr);
                    cnt++;
                }
                strcpy(prev_ip, mod_input);
            }
        }
        // free(mod_input);
        // mod_input = NULL;
    }
}
