#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fs.h"
#include "kernel/fcntl.h"

void find(char *path, char *file)
{
    int fd;
    struct stat st;
    fd = open(path, O_RDONLY);
    fstat(fd, &st);
    
}