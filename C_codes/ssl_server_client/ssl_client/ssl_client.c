#include "ssl_header.h"

#define CLIENT_MSG  "Hello Server!!!"
#define BILLION         1E9

uint64_t client (char * host, uint64_t flags)
{
    sslConnContext  *   ctx;
    struct timespec requestStart, requestEnd;
    uint64_t            nano_sec;
    char                buf[1024];
    int                 len;

    clock_gettime(CLOCK_REALTIME, &requestStart);
    ctx = SetupSecureConnection (host, flags);

    if (!ctx) {
        fprintf (stderr, "Unable to get the secure context!\n");
        return 0;
    }

    SetOutputChannel (ctx, stdout);

    // --------- Client work here ------------
    SocketWrite (ctx, CLIENT_MSG, strlen(CLIENT_MSG));
    len = SSL_read (ctx->ssl, buf, 1024);
    // SocketRead (ctx);
    clock_gettime(CLOCK_REALTIME, &requestEnd);

    // SocketWrite (ctx, <buffer ptr>, <length>
    // SocketRead (ctx, <buffer ptr>, <read Size>
    // ---------------------------------------

    ReleaseConnContext (ctx);

    nano_sec = ((uint64_t)(((uint64_t)(requestEnd.tv_sec - requestStart.tv_sec)) * BILLION)) +
                ((uint64_t)(requestEnd.tv_nsec - requestStart.tv_nsec));

    printf ("%llu\t%s\n", nano_sec, buf);

    return nano_sec;
}

int main (int argc, char ** argv)
{
    uint64_t    t_nano_sec = 0;
    uint32_t    count;
    uint32_t    i = 0;
    double      avg_nano_sec = 0;
    double      avg_sec = 0;

    if (argc < 3) {
        printf ("Usage: %s <IP:port> <request count>\n", argv[0]);
        return 0;
    }

    count = atoi (argv[2]);

    for (; i< count; ++i) {
        t_nano_sec += client (argv[1], 0);
    }

    avg_nano_sec = ((double)t_nano_sec) / count;
    avg_sec      = avg_nano_sec / BILLION;

    printf ("\nTotal elapsed Nano second = %llu Nano Seconds\n", t_nano_sec);
    printf ("Average time per request = %lf Nano Seconds (%lf seconds)\n", avg_nano_sec, avg_sec);

    return 0;
}
