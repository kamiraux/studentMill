#include <fcntl.h>
#include <unistd.h>

int main(void)
{
  char some_test = 1;
  int fd;

  some_test = some_test;


  fd = open("some_dir/some_file", O_RDWR);

  // do something that reads the standard input and write to the file

  write(fd, "test\n", 5);

  close(fd);

  if (some_test)
    return 0; // Correct return value
  else
    return 1; // Wrong return value
}
