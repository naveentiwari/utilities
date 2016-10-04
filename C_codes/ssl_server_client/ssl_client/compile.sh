gcc ssl_header.c ssl_client.c -o client -I/usr/local/ssl/include/ -ldl -L/usr/local/ssl/lib -lssl -lcrypto
