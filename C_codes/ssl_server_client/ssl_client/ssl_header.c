#include "ssl_header.h"

static void InitSSLLib ()
{
    /* Initialize SSL */
    /* OpenSSL_add_ssl_algorithms - This would get called by the function below. */
    SSL_library_init ();

    /* Load error strings for SSL */
    /* ERR_load_crypto_strings - This would get called by the function below. */
    SSL_load_error_strings ();

    OPENSSL_config (NULL);
}

static void ExitOnFailure (SSL * ssl)
{
    printf ("Error!!\n");
    if (ssl)
        fprintf (stderr, "ssl state = %s\n", SSL_state_string_long(ssl));
    exit (0);
}

// TODO: get trusted chain and provide flag to control verification
static void SetupSSLCtx (SSL_CTX * ctx)
{
    // const long flags = SSL_OP_NO_SSLv2 | SSL_OP_NO_SSLv3 | SSL_OP_NO_COMPRESSION;
    const long flags = SSL_OP_ALL | SSL_OP_NO_SSLv2 | SSL_OP_NO_SSLv3 | SSL_OP_NO_COMPRESSION;
    //  long      res   = 1;

    /* SSL_CTX_set_verify(ctx, SSL_VERIFY_PEER, verify_callback); */
    SSL_CTX_set_verify_depth(ctx, 4);
    //SSL_CTX_set_options(ctx, flags);

    /* res = SSL_CTX_load_verify_locations(ctx, "random-org-chain.pem", NULL);
    if(!(1 == res)) ExitOnFailure(); */
}

static SSL_CTX * SetupSSL (uint64_t flags)
{
    SSL_CTX * ctx   = NULL;

    const SSL_METHOD * method;

    InitSSLLib ();

    // method = TLSv1_2_method ();// SSLv23_method ();
    method = SSLv23_method ();

    if (method == NULL) ExitOnFailure (NULL);

    ctx = SSL_CTX_new (method);

    if (ctx == NULL) ExitOnFailure (NULL);

    if (flags == OPENSSL_SEC_CONN_H2) {
	//SSL_CTX_set_alpn_protos(ctx, (const unsigned char *)"\x02h2", 3);
	}

    SetupSSLCtx (ctx);

    return ctx;
}

void ReleaseConnContext (sslConnContext * connCtx)
{
    if (!connCtx) return;

    if (connCtx->outputFile)    BIO_free(connCtx->outputFile);
    if (connCtx->socket)        BIO_free_all(connCtx->socket);
    if (connCtx->ctx)           SSL_CTX_free(connCtx->ctx);
}

void SetOutputChannel (sslConnContext * connCtx, FILE * fp)
{
    if (!connCtx || !fp)
        return;

    connCtx->outputFile = BIO_new_fp(fp, BIO_NOCLOSE);
    if(!(NULL != connCtx->outputFile)) ExitOnFailure(connCtx->ssl);
}

sslConnContext * SetupSecureConnection (char * host, uint64_t flags)
{
    sslConnContext  *   ctx;
    long      res   = 1;

    ctx = (sslConnContext *) malloc (sizeof(sslConnContext));

    if (!ctx)
        return NULL;

    ctx->ctx = SetupSSL(flags);

    if (!ctx->ctx)  return NULL;

    ctx->socket = BIO_new_ssl_connect(ctx->ctx);
    if(!(ctx->socket != NULL)) ExitOnFailure (ctx->ssl);

    res = BIO_set_conn_hostname(ctx->socket, host);
    if(!(1 == res)) ExitOnFailure (ctx->ssl);

    BIO_get_ssl(ctx->socket, &ctx->ssl);
    if(!(ctx->ssl != NULL)) ExitOnFailure (ctx->ssl);

    const char* const PREFERRED_CIPHERS = "HIGH:!aNULL:!kRSA:!PSK:!SRP:!MD5:!RC4";
    res = SSL_set_cipher_list(ctx->ssl, PREFERRED_CIPHERS);
    if(!(1 == res)) ExitOnFailure (ctx->ssl);

    res = SSL_set_tlsext_host_name(ctx->ssl, host);
    if(!(1 == res)) ExitOnFailure (ctx->ssl);

    res = BIO_do_connect(ctx->socket);
    if(!(1 == res)) ExitOnFailure(ctx->ssl);

    res = BIO_do_handshake(ctx->socket);
    if(!(1 == res)) ExitOnFailure(ctx->ssl);

    /* Step 1: verify a server certificate was presented during the negotiation */
    X509* cert = SSL_get_peer_certificate(ctx->ssl);
    if(cert) { X509_free(cert); } /* Free immediately */
    if(NULL == cert) ExitOnFailure(ctx->ssl);

    /* Step 2: verify the result of chain verification */
    /* In our case the verification would not succeed
       it is self signed certificate */
    /* res = SSL_get_verify_result(ssl);
    if(!(X509_V_OK == res)) ExitOnFailure(); */

    /* Step 3: hostname verification */
    /* get hostnname from the certificate and compare it with the
       host name passed */
    /* We do not have to do this, we do not have any security
       concerns */

    return ctx;
}

int SocketWrite (sslConnContext * connCtx, void * data, uint32_t len)
{
    if (!data || !connCtx || !connCtx->socket)
        return 0;

    return BIO_write (connCtx->socket, data, len);
}

int SocketRead (sslConnContext * connCtx)
{
    int32_t     len     = 0;
    int32_t     totsz   = 0;
    char        buf[MAX_TXT_BUF_SIZE];

    if (!connCtx || !connCtx->socket || !connCtx->outputFile)
        return 0;

    do {
        memset (buf, 0, MAX_TXT_BUF_SIZE);
        len = BIO_read(connCtx->socket, buf, MAX_TXT_BUF_SIZE);

        totsz += len;

        if (len > 0)
            BIO_write(connCtx->outputFile, buf, len);

    } while (len > 0 || BIO_should_retry(connCtx->socket));

    return totsz;
}
