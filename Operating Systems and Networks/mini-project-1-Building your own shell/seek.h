#ifndef __SEEK_H
#define __SEEK_H

int print_match(struct stat* f, int mode, struct dirent* d, char* short_path, char* search, char* long_path);
int seek_proc(char* token, char* search, int mode, char* path);
int seek(char* ip, char* home_directory);

#endif