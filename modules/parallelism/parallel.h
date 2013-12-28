#ifndef PARALLEL_H_
# define PARALLEL_H_

typedef struct args
{
    char *conf;
    char *log;
} s_args;

void    launch_worker(s_args* args, char* work, char id);
char*   is_work_remaining();

#endif /* !PARALLEL_H_ */
