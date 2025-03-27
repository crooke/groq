build:
# Use openssl due to timeouts with mbedtls (https://github.com/vlang/v/issues/23717)
	v -prod -d use_openssl .

install: build
	cp groq $$HOME/.local/bin
