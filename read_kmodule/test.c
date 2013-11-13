#include <unistd.h>
#include <fcntl.h>
#include <stdio.h>
int main()
{
  char toto[50];
  int fd = open("/dev/my_const", O_RDWR);
  int nb = open("/dev/my_nb_read", O_RDWR);
  int res;

//  write(nb, res, 4);

  printf("%d\n", read(fd, toto, 10));
  printf("%d\n", write(fd, toto, 10));
  printf("%ld\n", lseek(fd, 4, SEEK_SET));

  read(nb, &res, 4);
  printf ("%d\n", res);
  close(nb);
  close(fd);
  return 0;
}
