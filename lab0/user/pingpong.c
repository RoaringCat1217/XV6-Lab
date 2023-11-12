#include "kernel/types.h"
#include "user/user.h"

int main(int argc, char *argv[])
{
    if(argc != 1)
    {
        fprintf(2, "usage: pingpong\n");
        exit(1);
    }   
    int pipe1[2], pipe2[2], pid;
    char byte = 0x7f;
    pipe(pipe1);
    pipe(pipe2);
    if((pid = fork()) < 0)
    {
        fprintf(2, "pingpong: fork error!\n");
        exit(1);
    }
    else if(pid == 0)
    {
        close(pipe1[1]);
        close(pipe2[0]);
        char rec;
        read(pipe1[0], &rec, 1);
        pid = getpid();
        fprintf(1, "<%d>: received ping\n", pid);
        write(pipe2[1], &rec, 1);
        close(pipe1[0]);
        close(pipe2[1]);
        exit(0);
    }
    else
    {
        char rec;
        close(pipe1[0]);
        close(pipe2[1]);
        write(pipe1[1], &byte, 1);
        read(pipe2[0], &rec, 1);
        pid = getpid();
        fprintf(1, "<%d>: received pong\n", pid);
        close(pipe1[1]);
        close(pipe2[0]);
        exit(0);
    }
}