#ifndef SSL_HEADER_H
#define SSL_HEADER_H

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <openssl/conf.h>
#include <openssl/ssl.h>

#define MAX_TXT_BUF_SIZE 2048

/* flags for secure connection */
#define OPENSSL_SEC_CONN_H2		0x1

typedef struct {
    BIO         *   socket;
    BIO         *   outputFile;
    SSL         *   ssl;
    SSL_CTX     *   ctx;
} sslConnContext;

void				SetOutputChannel		(sslConnContext *, FILE *);
sslConnContext	*	SetupSecureConnection	(char *, uint64_t);
int					SocketWrite				(sslConnContext *, void * data, uint32_t len);
int 				SocketRead				(sslConnContext *);
void                ReleaseConnContext      (sslConnContext * connCtx);

#endif // SSL_HEADER_H
