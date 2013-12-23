#include "parallel.h"

#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/wait.h>

static int nb_child = 0;

int main(int argc, char **argv)
{
  int           nb_worker = 1;
  s_args        args = { 0, 0 };
  char*         work = 0;
  int           status = 0;
  if (argc < 3)
  {
    printf("Usage: %s NB_WORKER CONF_ABS LOG\n", argv[0]);
    return 1;
  }

  // get params
  nb_worker = atoi(argv[1]);
  args.conf = argv[2];
  args.log = argv[3];

  while ((work = is_work_remaining()))
  {
    // Wait for a free slot
    while (nb_child >= nb_worker)
      // wait for a child to end
      if (wait(&status) > 0 && (WIFEXITED(status) || WIFSIGNALED(status)))
        nb_child--;

    // Launch new worker
    launch_worker(&args, work);
  }

  // Wait for remaining child processes
  while (nb_child > 0)
    // wait for a child to end
    if (wait(&status) > 0 && (WIFEXITED(status) || WIFSIGNALED(status)))
      nb_child--;

  return 0;
}

char*   is_work_remaining()
{
  static char*  work = NULL;
  static FILE*  file = NULL;
  size_t        linecap = 0;
  ssize_t       size = 0;

  if (!file)
    file = fdopen(STDIN_FILENO, "r");

  size = getline(&work, &linecap, file);
  if (work && size && work[size - 1] == '\n')
    work[size - 1] = 0;

  if (size == -1)
  {
    fclose(file);
    free(work);
    work = NULL;
  }

  return work;
}

void launch_worker(s_args* args, char* work)
{
  pid_t pid = 0;

  // if fork fails kill the process and all children
  if ((pid = fork()) == -1)
    kill(-getpid(), SIGKILL);

  if (pid)
  {//father
    nb_child++;
    printf("%s\n", work);
  }
  else
  {//son
    char *aargs[5] =
      {
        "modules/parallelism/launch_student_redir_wrapper.sh",
        args->log,
        args->conf,
        work,
        NULL
      };
    execv(aargs[0], aargs);
  }
}
