#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/wait.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <signal.h>

#ifdef __MACH__
# define GROUP 20
#else
# define GROUP uid
#endif

int main(int argc, char** argv)
{
  pid_t child;
  int file_out;
  int file_err;
  int file_ret;
  int ret = 0;
  int status;
  uid_t uid;
  long time;

  if (argc < 6)
  {
    dprintf(STDERR_FILENO, "Too few arguments\n"
      "usage: ./exec file_out file_err file_ret user timeout command [...]\n");
    return 2;
  }

  // Convert uid
  uid = atoi(argv[4]);
  // Open files
  if ((file_out = open(argv[1], O_WRONLY | O_TRUNC | O_CREAT, S_IRUSR | S_IWUSR)) == -1)
  {
    perror("cannot open out file");
    return 3;
  }
  if ((file_err = open(argv[2], O_WRONLY | O_TRUNC | O_CREAT, S_IRUSR | S_IWUSR)) == -1)
  {
    perror("cannot open err file");
    ret = 4;
    goto lbl_err1;
  }
  if ((file_ret = open(argv[3], O_WRONLY | O_TRUNC | O_CREAT, S_IRUSR | S_IWUSR)) == -1)
  {
    perror("cannot open ret file");
    ret = 5;
    goto lbl_err_ret;
  }


  if ((child = fork()) == -1)
  {
    perror("fork");
    ret = 12;
    goto lbl_err2;
  }
  if (child)
  {//father
    dprintf(STDOUT_FILENO, "%d\n", child);

    if (waitpid(child, &status, 0) == -1)
    {
      perror("waitpid failed");
    }
    else if (WIFEXITED(status))
    {
      dprintf(file_ret, "%d\n", WEXITSTATUS(status));
    }
    else if (WIFSIGNALED(status))
    {
      dprintf(file_ret, "%d\n", 1000 + WTERMSIG(status));
    }
  }
  else
  {//son
    // redirect stdout and stderr to pipes
    dup2(file_out, 1);
    dup2(file_err, 2);
    if (setgid(GROUP) == -1)
    {
      perror("setgid failed");
      ret = 20;
      goto lbl_err2;
    }
    if (setuid(uid) == -1)
    {
      perror("setuid failed");
      ret = 20;
      goto lbl_err2;
    }
    execv(argv[5], argv + 5);
    ret = 42;
  }

  lbl_err2:
  close(file_err);
  lbl_err_ret:
  close(file_ret);
  lbl_err1:
  close(file_out);
  return ret;
}
