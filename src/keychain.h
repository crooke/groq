#ifndef KEYCHAIN_C
#define KEYCHAIN_C

#include <Security/Security.h>

const char *get_error_message(OSStatus status);
const char *save_api_key(const char *api_key);
const char *get_api_key();

#endif
