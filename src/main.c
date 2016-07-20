#include <err.h>
#include <inttypes.h>
#include <signal.h>
#include <stdio.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/select.h>

#include <nfc/nfc.h>
#include <nfc/nfc-types.h>
#include <ei.h>

static nfc_device *pnd = NULL;
static nfc_context *context;


int is_ready(int fd) {
    fd_set fdset;
    struct timeval timeout;
    FD_ZERO(&fdset);
    FD_SET(fd, &fdset);
    timeout.tv_sec = 0;
    timeout.tv_usec = 1;
    return select(fd+1, &fdset, NULL, NULL, &timeout) == 1 ? 1 : 0;
}


static void stop_polling(int sig)
{
    (void) sig;
    if (pnd != NULL)
        nfc_abort_command(pnd);
    else {
        nfc_exit(context);
        exit(EXIT_FAILURE);
    }
}


/**
 * @brief Synchronously send a response back to Erlang
 *
 * @param response what to send back
 */
void erlcmd_send(char *response, size_t len)
{
    uint16_t be_len = htons(len - sizeof(uint16_t));
    memcpy(response, &be_len, sizeof(be_len));

    size_t wrote = 0;
    do {
        ssize_t amount_written = write(STDOUT_FILENO, response + wrote, len - wrote);
        if (amount_written < 0) {
            if (errno == EINTR)
                continue;

            //err(EXIT_FAILURE, "write");
            exit(0);
        }

        wrote += amount_written;
    } while (wrote < len);
}


void send_tag(const char *uid, size_t len) {
    char resp[1024];
    int resp_index = sizeof(uint16_t); // Space for payload size
    ei_encode_version(resp, &resp_index);

    ei_encode_tuple_header(resp, &resp_index, 2);
    ei_encode_atom(resp, &resp_index, "tag");
    ei_encode_binary(resp, &resp_index, uid, len);

    erlcmd_send(resp, resp_index);
}


int
main(int argc, const char *argv[])
{
    signal(SIGINT, stop_polling);

    // Display libnfc version
    const char *acLibnfcVersion = nfc_version();

    fprintf(stderr, "%s uses libnfc %s\n", argv[0], acLibnfcVersion);

    static const nfc_modulation nmMifare = {
        .nmt = NMT_ISO14443A,
        .nbr = NBR_106,
    };

    nfc_target nt;

    nfc_init(&context);
    if (context == NULL) {
        fprintf(stderr, "Unable to init libnfc (malloc)\n");
        exit(EXIT_FAILURE);
    }

    pnd = nfc_open(context, NULL);

    if (pnd == NULL) {
        fprintf(stderr, "Unable to open NFC device.\n");
        nfc_exit(context);
        exit(EXIT_FAILURE);
    }

    if (nfc_initiator_init(pnd) < 0) {
        nfc_perror(pnd, "nfc_initiator_init");
        nfc_close(pnd);
        nfc_exit(context);
        exit(EXIT_FAILURE);
    }


    // Let the device only try once to find a tag
    if (nfc_device_set_property_bool(pnd, NP_INFINITE_SELECT, false) < 0) {
        nfc_perror(pnd, "nfc_device_set_property_bool");
        nfc_close(pnd);
        nfc_exit(context);
        exit(EXIT_FAILURE);
    }

    printf("NFC reader: %s opened\n", nfc_device_get_name(pnd));
    char buffer[10];
	char *p;
	char sn_str[23];

    for (;;) {

        while (is_ready(fileno(stdin))) {
            if (!read(fileno(stdin), buffer, sizeof(buffer))) {
                fprintf(stderr, "Done.\n");
                nfc_abort_command(pnd);
                nfc_exit(context);
                exit(0);
            } else {
                fprintf(stderr, "data.. %s\n", buffer);
            }
        }


        // Try to find a MIFARE Ultralight tag
        if (nfc_initiator_select_passive_target(pnd, nmMifare, NULL, 0, &nt) <= 0) {
            usleep(100 * 1000);
            continue;
        }

        // Get the info from the current tag
        size_t  szPos;
        p = sn_str;
        for (szPos = 0; szPos < nt.nti.nai.szUidLen; szPos++) {
            sprintf(p, "%02X", nt.nti.nai.abtUid[szPos]);
            p += 2;
        }
        *p = 0;
        fprintf(stderr,"Serial: %s\n",&sn_str[1]);
        send_tag(sn_str, 2 * nt.nti.nai.szUidLen);

        while (0 == nfc_initiator_target_is_present(pnd, NULL)) {}

        usleep(200 * 1000);

    }

    nfc_close(pnd);
    nfc_exit(context);
    exit(EXIT_SUCCESS);
}
