#ifndef __PEEK_H
#define __PEEK_H

int compareByName(const void* a, const void* b);
void print_perm(struct stat* f, struct dirent* d);
void print_file_descr(struct stat* f, int mode, struct dirent* d);
int proc(char* token, char* home_directory, int mode);
int peek(char* input, char* home_directory);

#endif