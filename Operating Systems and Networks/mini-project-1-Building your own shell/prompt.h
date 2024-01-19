#ifndef __PROMPT_H
#define __PROMPT_H

int roundoff(double usec);
void prompt(char* home_directory);
void prompt_with_proc(char* home_directory, long usec, char* i);

#endif