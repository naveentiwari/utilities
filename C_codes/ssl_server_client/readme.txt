Replace the server.key and server.crt files with actual files.
These file  are currently empty.

To compile client (from ssl_client directory)
gcc ssl_client.c ssl_header.c -o client -lssl -lcrypto

To compile server (from ssl_server directory)
gcc ssl_server.c -o server -lssl -lcrypto
