#include "kernel/types.h"
#include "user/user.h"
# define N_PRIMES 3

void work_fn(int prime, int upstream, int downstream);

void setup_fn(int *primes, int idx, int upstream)
{
    int prime = primes[idx], p[2], downstream = -1;
    if (idx < N_PRIMES - 1)
    {
        pipe(p);
        if (fork() == 0)
        {
            close(p[1]);
            setup_fn(primes, idx + 1, p[0]);
        }
        close(p[0]);
        downstream = p[1];
    }
    work_fn(prime, upstream, downstream);
}

void work_fn(int prime, int upstream, int downstream)
{
    int buf;
    while (read(upstream, &buf, sizeof(buf)) != 0)
    {
        if (buf % prime != 0 || buf == prime)
        {
            if (downstream == -1)
                fprintf(1, "prime %d\n", buf);
            else
                write(downstream, &buf, sizeof(buf));
        }
    }
    close(upstream);
    close(downstream);
    wait(0);
    exit(0);
}

int main(int argc, char *argv[])
{
    int primes[] = {2, 3, 5}, p[2], i;
    pipe(p);
    if (fork() == 0)
    {
        close(p[1]);
        setup_fn(primes, 0, p[0]);
    }
    else
    {
        close(p[0]);
        for (i = 2; i <= 35; i++)
            write(p[1], &i, sizeof(i));
    }
    close(p[1]);
    wait(0);
    exit(0);
}