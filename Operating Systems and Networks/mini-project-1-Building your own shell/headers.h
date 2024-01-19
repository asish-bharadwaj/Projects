#ifndef HEADERS_H_
#define HEADERS_H_

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <pwd.h>
#include <grp.h>
#include <time.h>
#include <dirent.h>
#include <sys/wait.h>
#include <sys/time.h>
#include <signal.h>
#include <stdint.h>

#include "prompt.h"
#include "warp.h"
#include "peek.h"
#include "proclore.h"
#include "seek.h"
#include "execute.h"
#include "pastevents.h"

typedef struct Queue{
    char** msg;
    int front;
    int rear;
    int capacity;
    int cur_size;
}Queue;
typedef Queue* Q;

Q initQ();
void enqueue(Q q, char* str);
void clear(Q q);
void sigchld_handler(int signum);
#endif