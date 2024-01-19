#ifndef __WARP_H
#define __WARP_H

int home_count(char* input);
char* replace_home(char* input, int hc, char* home_directory) ;
int warp(char* input, char* home_directory, char* parent_dir);
int warpi(char* input, char* home_directory);

#endif