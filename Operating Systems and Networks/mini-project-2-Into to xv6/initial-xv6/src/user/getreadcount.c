#include "kernel/types.h"
#include "kernel/stat.h"
#include "user.h"
#include "kernel/fcntl.h"

int main(){
    printf("%d\n",  getreadcount());
    exit(0);
}