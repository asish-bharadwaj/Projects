#include "main.h"

int main(int argc, char** argv) {

    /*
    You are expected to make use of File Management
    syscalls for this part.
    
    **INPUT**
    Filename will be given as input from the command line.
    */

    // Write your code here

    int read_size = 1000000, i;
    char buffer[read_size], t;

    //  Getting the file permissions of the input txt file, using stat() function
    struct stat* buf = (struct stat*)malloc(sizeof(struct stat));
    int temp = stat(argv[1], buf);
    mode_t mode = buf->st_mode;

    //  Setting the user, group and other permissions
    //  Used symbolic constants for formality
    mode_t usr = ((mode&S_IRUSR)?S_IRUSR:0)|((mode&S_IWUSR)?S_IWUSR:0)|((mode&S_IXUSR)?S_IXUSR:0);
    mode_t grp = ((mode&S_IRGRP)?S_IRGRP:0)|((mode&S_IWGRP)?S_IWGRP:0)|((mode&S_IXGRP)?S_IXGRP:0);
    mode_t oth = ((mode&S_IROTH)?S_IROTH:0)|((mode&S_IWOTH)?S_IWOTH:0)|((mode&S_IXOTH)?S_IXOTH:0);

    //  Opening the input file
    int old_file = open(argv[1], O_RDONLY);
    
    //  Setting the newfile name from the given input file name
    int file_name_len = strlen(argv[1]);
    argv[1][file_name_len-4] = '\0';
    char* newfile_name = (char*)malloc(sizeof(char)*(file_name_len+8));
    strcpy(newfile_name, argv[1]);
    strcat(newfile_name, "_reverse.txt");   

    //  Defining relative location of the new file from present directory
    char* newfile_location = (char*)malloc(sizeof(char)*(strlen(newfile_name)+7));
    strcpy(newfile_location, "Copies/");
    strcat(newfile_location, newfile_name);    

    //  Making the directory [if it does not exist] with the required permissions (777)
    int copies_dir = mkdir("Copies", S_IRUSR | S_IWUSR | S_IXUSR | S_IRGRP | S_IWGRP |S_IXGRP | S_IROTH | S_IWOTH | S_IXOTH);
    temp = chmod("Copies", S_IRUSR | S_IWUSR | S_IXUSR | S_IRGRP | S_IWGRP |S_IXGRP | S_IROTH | S_IWOTH | S_IXOTH);

    //  Opening/Creating the new file in the designated location and setting its permissions accordingly
    int new_file = open(newfile_location, O_CREAT | O_WRONLY);
    temp = chmod(newfile_location, usr+grp+oth);

    //  Repositions the file offset of the open file description associated with the file descriptor of the input file to the end of file 
    off_t pos = lseek(old_file, 0, SEEK_END);

    //  At any point of time, pos represents the file offset from the beginning of the file
    //  Iterating in a loop, while there is a scope of completely reading "read_size" bytes into the buffer array
    while(pos-read_size >= 0){
        //  Reposition the file descriptor by -read_size from the current position
        pos = lseek(old_file, -1*read_size, SEEK_CUR);

        //  Read read_size bytes into the buffer
        ssize_t r = read(old_file, buffer, read_size);

        //  Reverse the buffer
        for(i = 0; i < r/2; i++){
            t = buffer[i];
            buffer[i] = buffer[r-i-1];
            buffer[r-i-1] = t;
        }

        //  Write the reversed buffer into the new_file
        ssize_t w = write(new_file, buffer, r);

        //  Since we repositioned by read_size bytes while reading into the buffer, 
        //  we again reposition the file descriptor by -read_size from the current position
        pos = lseek(old_file, -1*r, SEEK_CUR);
    }
    //  Storing the current offset from beginning of the file [which is less than the read_size] in a temporary variable
    temp = pos;

    //  Repositioning the file descriptor to the beginning of the file
    pos = lseek(old_file, 0, SEEK_SET);

    //  Reading the remaining [temp] bytes into the buffer
    ssize_t r = read(old_file, buffer, temp);

    //  Reverse the buffer
    for(i = 0; i < r/2; i++){
        t = buffer[i];
        buffer[i] = buffer[r-i-1];
        buffer[r-i-1] = t;
    }

    //  Write the reversed buffer into the new_file
    ssize_t w = write(new_file, buffer, r);

    // Done with the Task, Close both the files (descriptors)
    temp = close(old_file);
    temp = close(new_file);

    // Freeing the allocated memory
    free(newfile_name);
    free(buf);
    free(newfile_location);
    buf = NULL;
    newfile_location = NULL;
    newfile_name = NULL;
    return 0;
}