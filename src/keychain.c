#include "keychain.h"

const char *get_error_message(OSStatus status)
{
	if (status != 0)
	{
		CFStringRef error = SecCopyErrorMessageString(status, NULL);
		CFIndex length = CFStringGetLength(error);
		CFIndex maxSize = CFStringGetMaximumSizeForEncoding(length, kCFStringEncodingUTF8);
		// TODO: memory leak??
		char *errStr = (char *)malloc(maxSize);
		CFStringGetCString(error, errStr, maxSize, kCFStringEncodingUTF8);
		// CFRelease(error);
		return errStr;
	}
	else
	{
		return NULL;
	}
}

void print_error_message(OSStatus status)
{
	if (status == 0)
		return;
	printf("Error: %s", get_error_message(status));
}

const char *save_api_key(const char *api_key)
{
	// CFStringRef password = CFStringCreateWithCString(NULL, api_key, kCFStringEncodingUTF8);
	// CFDataRef passwordData = CFDataCreate(NULL, (UInt8 *)CFStringGetCStringPtr(password, kCFStringEncodingUTF8), CFStringGetLength(password));
	CFDataRef passwordData = CFDataCreate(NULL, (UInt8 *)api_key, strlen(api_key));
	CFMutableDictionaryRef keychainItem = CFDictionaryCreateMutable(NULL, 0, NULL, NULL);
	CFDictionaryAddValue(keychainItem, kSecClass, kSecClassInternetPassword);
	CFDictionaryAddValue(keychainItem, kSecAttrServer, CFSTR("api.groq.com"));
	CFDictionaryAddValue(keychainItem, kSecAttrDescription, CFSTR("Groq API Key"));
	CFDictionaryAddValue(keychainItem, kSecValueData, passwordData);

	OSStatus status = SecItemAdd(keychainItem, NULL);

	CFRelease(passwordData);
	CFRelease(keychainItem);
	// CFRelease(password);

	return get_error_message(status);
}

const char *get_api_key()
{
	// CFDictionaryRef query = NULL;
	CFDictionaryRef result = NULL;

	CFMutableDictionaryRef query = CFDictionaryCreateMutable(NULL, 0, NULL, NULL);
	CFDictionaryAddValue(query, kSecClass, kSecClassInternetPassword);
	CFDictionaryAddValue(query, kSecAttrServer, CFSTR("api.groq.com"));
	CFDictionaryAddValue(query, kSecReturnAttributes, kCFBooleanTrue);
	CFDictionaryAddValue(query, kSecReturnData, kCFBooleanTrue);

	OSStatus status = SecItemCopyMatching(query, &result);

	if (status == errSecSuccess && result != NULL)
	{
		// the data was retrieved successfully
		CFDataRef passwordData = CFDictionaryGetValue(result, kSecValueData);
		if (passwordData != NULL)
		{
			// convert the CFData to a C string
			CFIndex dataLength = CFDataGetLength(passwordData);
			const UInt8 *dataBytes = CFDataGetBytePtr(passwordData);
			// char password[dataLength + 1];
			char *password = (char *)malloc(dataLength + 1);
			memcpy(password, dataBytes, dataLength);
			password[dataLength] = '\0';

			// printf("The password is %s\n", password);
			return password;
		}
	}
	else
	{
		print_error_message(status);
	}

	// return get_error_message(status);
	return NULL;
}
