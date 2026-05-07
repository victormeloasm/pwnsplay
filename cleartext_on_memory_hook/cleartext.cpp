// cleartext_password_toy.cpp
#include <openssl/rand.h>
#include <unistd.h>
#include <string.h>
#include <stdint.h>

static void write_all(const char *s) {
    write(1, s, strlen(s));
}

static char charset[] =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    "abcdefghijklmnopqrstuvwxyz"
    "0123456789"
    "!@#$%^&*";

static void generate_password(char *out, size_t len) {
    unsigned char rnd[64];

    if (len > sizeof(rnd)) {
        _exit(1);
    }

    if (RAND_bytes(rnd, len) != 1) {
        write_all("OpenSSL RAND_bytes failed\n");
        _exit(1);
    }

    size_t charset_len = strlen(charset);

    for (size_t i = 0; i < len; i++) {
        out[i] = charset[rnd[i] % charset_len];
    }

    out[len] = '\0';
}

int main() {
    constexpr size_t PASS_LEN = 20;

    /*
        VULNERABILIDADE DIDTICA:

        A senha secreta  gerada antes da autenticao
        e fica guardada em cleartext na memria do processo.
    */
    char secret_password[PASS_LEN + 1];

    generate_password(secret_password, PASS_LEN);

    write_all("=== Cleartext Password Toy ===\n");
    write_all("A senha foi gerada com OpenSSL.\n");
    write_all("Digite a senha de 20 caracteres:\n> ");

    char input[128];
    memset(input, 0, sizeof(input));

    ssize_t n = read(0, input, sizeof(input) - 1);

    if (n <= 0) {
        write_all("\nErro lendo entrada.\n");
        return 1;
    }

    // Remove newline final, se existir.
    for (ssize_t i = 0; i < n; i++) {
        if (input[i] == '\n' || input[i] == '\r') {
            input[i] = '\0';
            break;
        }
    }

    if (strlen(input) != PASS_LEN) {
        write_all("Senha deve ter exatamente 20 caracteres.\n");
        return 1;
    }

    if (strcmp(input, secret_password) == 0) {
        write_all("Acesso concedido.\n");
    } else {
        write_all("Acesso negado.\n");
    }

    /*
        Outro erro proposital:
        No limpamos secret_password da memria antes de sair.
    */

    return 0;
}