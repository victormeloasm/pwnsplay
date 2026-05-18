// engine.c
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <openssl/rand.h>
#include <openssl/err.h>

#define RANDOM_SIZE 32

static void print_openssl_error(void) {
    unsigned long err;

    while ((err = ERR_get_error()) != 0) {
        fprintf(stderr, "OpenSSL error: %s\n", ERR_error_string(err, NULL));
    }
}

int main(void) {
    unsigned char buf[RANDOM_SIZE];

    for (;;) {
        if (RAND_bytes(buf, RANDOM_SIZE) != 1) {
            fprintf(stderr, "RAND_bytes failed\n");
            print_openssl_error();
            return EXIT_FAILURE;
        }

        for (int i = 0; i < RANDOM_SIZE; i++) {
            printf("%02x", buf[i]);
        }

        printf("\n");
        fflush(stdout);

        sleep(5);
    }

    return EXIT_SUCCESS;
}