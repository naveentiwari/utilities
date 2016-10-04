gcc ssl_server.c -o server -I/usr/local/ssl/include/ -ldl -L/usr/local/ssl/lib/ -lssl -lcrypto
