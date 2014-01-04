#ifndef PARALLEL_H_
# define PARALLEL_H_

#include <sys/types.h>

typedef struct args
{
    char *conf;
    char *log;
} s_args;

pid_t   launch_worker(s_args* args, char* work, char id);
char*   is_work_remaining();

#endif /* !PARALLEL_H_ */
