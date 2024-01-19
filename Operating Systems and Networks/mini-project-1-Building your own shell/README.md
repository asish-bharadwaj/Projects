[Project Description](https://karthikv1392.github.io/cs3301_osn/mini-projects/mp1)
# Description

1. execute.c	-	to execute system commands [specification 6]
2. pastevents.c	-	to execute pastevents [specification 5]
3. peek.c	-	to execute peek [specification 4]
4. warp.c	-	to execute warp [specification 3]
5. proclore.c	-	to execute proclore [specification 7]
6. seek.c	-	to execute seek [specification 8]

Implementation is mentioned as comments in respective files

# Assumptions

 1. If the previous warp command was warp .. ..
    then when we execute warp - 
    it corresponds to the parent directory only, not the grandparent
    For example, if from A/B/C/D, we do warp .. ..
    we first go to A/B/C, and then to A/B
    Now if we enter warp -
    we go to A/B/C [because this is the previous directory before entering into A/B,as warp command was intended to be executed as such]
   
2. Certain files, such as bg_proc.txt [which stores list of background processes], pastevents.txt [which stores list of pastevents], other dummy textfiles have been used for the implementation of  
   certain functions. Ideally, these functions should have permissions to read, write and execute only for the shell. But, for better understanding, these files can be read and it is assumed that the user 
   does not tamper these files. If tampered, it leads to unfavourable results.
     
3. When the shell is terminated, "exit" is NOT stored in the pastevents.

4. In case seek -e | -ed | -de finds a single directory matching with the input given, it just changes to that directory.
   It does not print the absolute path, as in the case of warp command [because the sample input cases given in the course website are implemented as such]  
  
5. When invalid commands are entered which are to be executed as background processes (example - slepe 2), the pid of the process if printed, but since it is not a valid command, the pid of the background
   process is printed, and then "Invalid command!" is printed. Assuming such test cases will not be considered, the message (slepe exited normally) is not printed.
   
6. Regarding specification 6, "Time taken by the foreground process and the name of the process should be printed in the next prompt if process takes > 2 seconds to run.", this is implemented only for system
   commands and not for commands implemented by me (peek, seek, warp, proclore, etc.), assuming these commands will finish their execution in <2 seconds.
   
7. In case of multiple commands (A ;B ;C .....), the time and process name to be printed in the prompt, if it takes >2 seconds, corresponds to the last executed foreground process.
   For example,
   sleep 5; sleep 10	-	In this case, sleep 10s is printed in the prompt
   sleep 5; sleep 1	-	In this case, nothing is printed, as sleep 1 is executed in <2 seconds
   sleep 5; sleep 10 &	-	In this case, sleep 5s is printed in the prompt
   
8. peek - is considered an invalid command, as ls - is an invalid command

9. In proclore <pid> command, the executable path is the absolute path

10. pastevents execute <index> & is assumed not be given as an input. If given, it may lead to undesired results.

11. For invalid commands given as input to be executed in background, the pid is printed and then "Invalid command!" is printed in the next line (immediately). When Enter key is pressed/ an input is given, the
    message ( <command> exited normally (<pid>) ) is printed.
    
