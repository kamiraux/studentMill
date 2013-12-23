/*
 * * Simple Echo pseudo-device KLD
 *  *
 *   * Murray Stokely
 *    * Søren (Xride) Straarup
 *     * Eitan Adler
 *      */

#include <sys/types.h>
#include <sys/module.h>
#include <sys/systm.h>  /* uprintf */
#include <sys/param.h>  /* defines used in kernel.h */
#include <sys/kernel.h> /* types used in module initialization */
#include <sys/conf.h>   /* cdevsw struct */
#include <sys/uio.h>    /* uio struct */
#include <sys/malloc.h>

#define BUFFERSIZE 4096

/* Function prototypes */
static d_open_t      echo_open;
static d_close_t     echo_close;
static d_read_t      echo_read;
static d_write_t     echo_write;
static d_open_t      nb_read_open;
static d_close_t     nb_read_close;
static d_read_t      nb_read_read;
static d_open_t      nb_write_open;
static d_close_t     nb_write_close;
static d_read_t      nb_write_read;
static d_write_t     nb_write;

/* Character device entry points */
static struct cdevsw const_cdevsw = {
  .d_version = D_VERSION,
  .d_open = echo_open,
  .d_close = echo_close,
  .d_read = echo_read,
  .d_write = echo_write,
  .d_name = "const",
};
static struct cdevsw nb_read_cdevsw = {
  .d_version = D_VERSION,
  .d_open = nb_read_open,
  .d_close = nb_read_close,
  .d_read = nb_read_read,
  .d_write = nb_write,
  .d_name = "nb_read_dev",
};
static struct cdevsw nb_write_cdevsw = {
  .d_version = D_VERSION,
  .d_open = nb_write_open,
  .d_close = nb_write_close,
  .d_read = nb_write_read,
  .d_write = nb_write,
  .d_name = "nb_write_dev",
};

struct s_echo {
    char msg[BUFFERSIZE + 1];
    int len;
};

/* vars */
static struct cdev *const_dev;
static struct cdev *nb_read_dev;
static struct cdev *nb_write_dev;
static struct s_echo *echomsg;
static int nb_read_call;
static int nb_write_call;
MALLOC_DECLARE(M_ECHOBUF);
MALLOC_DEFINE(M_ECHOBUF, "echobuffer", "buffer for echo module");

/*
 * * This function is called by the kld[un]load(2) system calls to
 *  * determine what actions to take when a module is loaded or unloaded.
 *   */
static int
echo_loader(struct module *m __unused, int what, void *arg __unused)
{
  int error = 0;
  int i=0;
  switch (what) {
    case MOD_LOAD:                /* kldload */
      error = make_dev_p(MAKEDEV_CHECKNAME | MAKEDEV_WAITOK,
                         &const_dev,
                         &const_cdevsw,
                         0,
                         UID_ROOT,
                         GID_WHEEL,
                         0666,
                         "my_const");
      if (error != 0)
        break;
      error = make_dev_p(MAKEDEV_CHECKNAME | MAKEDEV_WAITOK,
                         &nb_read_dev,
                         &nb_read_cdevsw,
                         0,
                         UID_ROOT,
                         GID_WHEEL,
                         0600,
                         "my_nb_read");
      if (error != 0)
        break;
      error = make_dev_p(MAKEDEV_CHECKNAME | MAKEDEV_WAITOK,
                         &nb_write_dev,
                         &nb_write_cdevsw,
                         0,
                         UID_ROOT,
                         GID_WHEEL,
                         0600,
                         "my_nb_write");
      if (error != 0)
        break;

      echomsg = malloc(sizeof(*echomsg), M_ECHOBUF, M_WAITOK |
                       M_ZERO);
      for (i = 0; i <= BUFFERSIZE; ++i)
        echomsg->msg[i] = 'a';
      printf("Echo device loaded.\n");
      break;
      case MOD_UNLOAD:
        destroy_dev(const_dev);
        destroy_dev(nb_read_dev);
        destroy_dev(nb_write_dev);
        free(echomsg, M_ECHOBUF);
        printf("Echo device unloaded.\n");
        break;
        default:
          error = EOPNOTSUPP;
          break;
  }
  return (error);
}

static int
nb_read_open(struct cdev *dev __unused, int oflags __unused, int devtype __unused,
          struct thread *td __unused)
{
  int error = 0;
//  nb_read_call = 0;
  //uprintf("Opened device \"echo\" successfully.\n");
  return (error);
}
static int
nb_write_open(struct cdev *dev __unused, int oflags __unused, int devtype __unused,
          struct thread *td __unused)
{
  int error = 0;
//  nb_write_call = 0;
  //uprintf("Opened device \"echo\" successfully.\n");
  return (error);
}
static int
echo_open(struct cdev *dev __unused, int oflags __unused, int devtype __unused,
          struct thread *td __unused)
{
  int error = 0;
//  uprintf("Opened device \"echo\" successfully.\n");
  return (error);
}

static int
echo_close(struct cdev *dev __unused, int fflag __unused, int devtype __unused,
           struct thread *td __unused)
{

//  uprintf("Closing device \"echo\".\n");
  return (0);
}
static int
nb_read_close(struct cdev *dev __unused, int fflag __unused, int devtype __unused,
           struct thread *td __unused)
{

//  uprintf("Closing device \"echo\".\n");
  return (0);
}
static int
nb_write_close(struct cdev *dev __unused, int fflag __unused, int devtype __unused,
           struct thread *td __unused)
{

//  uprintf("Closing device \"echo\".\n");
  return (0);
}

/*
 * * The read function just takes the buf that was saved via
 *  * echo_write() and returns it to userland for accessing.
 *   * uio(9)
 *    */
static int
echo_read(struct cdev *dev __unused, struct uio *uio, int ioflag __unused)
{
  size_t amt;
  int error;

  /*
   * * How big is this read operation?  Either as big as the user wants,
   *  * or as big as the remaining data.  Note that the 'len' does not
   *   * include the trailing null character.
      */
  amt = MIN(uio->uio_resid, BUFFERSIZE);
  if (uio->uio_offset >= BUFFERSIZE)
    return EINVAL;
  nb_read_call++;
  if ((error = uiomove(echomsg->msg, amt, uio)) != 0)
    uprintf("uiomove failed!\n");

  return (error);
}
static int
nb_read_read(struct cdev *dev __unused, struct uio *uio, int ioflag __unused)
{
  size_t amt;
  int error;

  /*
   * * How big is this read operation?  Either as big as the user wants,
   *  * or as big as the remaining data.  Note that the 'len' does not
   *   * include the trailing null character.
      */
  amt = 4;
  if ((error = uiomove(&nb_read_call, amt, uio)) != 0)
    uprintf("uiomove failed!\n");

  return (error);
}
static int
nb_write_read(struct cdev *dev __unused, struct uio *uio, int ioflag __unused)
{
  size_t amt;
  int error;

  /*
   * * How big is this read operation?  Either as big as the user wants,
   *  * or as big as the remaining data.  Note that the 'len' does not
   *   * include the trailing null character.
      */
  amt = 4;
  if ((error = uiomove(&nb_write_call, amt, uio)) != 0)
    uprintf("uiomove failed!\n");

  return (error);
}

/*
 * * echo_write takes in a character string and saves it
 *  * to buf for later accessing.
 *   */
static int
echo_write(struct cdev *dev __unused, struct uio *uio, int ioflag __unused)
{
  size_t amt;
  int error;

  /*
   * * We either write from the beginning or are appending -- do
   *  * not allow random access.
   *   */
  nb_write_call++;
//  if (uio->uio_offset != 0 && (uio->uio_offset != echomsg->len))
//    return (EINVAL);

  /* This is a new message, reset length */

  /* Copy the string in from user memory to kernel memory */
  if (uio->uio_offset >= BUFFERSIZE)
    return EINVAL;
  amt = MIN(uio->uio_resid, BUFFERSIZE - uio->uio_offset);

  error = uiomove(echomsg->msg, amt, uio);

  /* Now we need to null terminate and record the length */

  if (error != 0)
    uprintf("Write failed: bad address!\n");
  return (error);
}
static int
nb_write(struct cdev *dev __unused, struct uio *uio, int ioflag __unused)
{
  size_t amt =0;
  int error;

  /*
   * * We either write from the beginning or are appending -- do
   *  * not allow random access.
   *   */

  char tab[400];
  amt = uio->uio_resid;

  error = uiomove(tab, amt, uio);
  nb_read_call = 0;
  nb_write_call = 0;
  /* Now we need to null terminate and record the length */

  if (error != 0)
    uprintf("Write failed: bad address!\n");
  return (error);
}

DEV_MODULE(echo, echo_loader, NULL);
