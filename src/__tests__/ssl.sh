#!/bin/bash

SOURCE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$SOURCE_PATH/../ssl.sh"

# Test Create a DHParam
doGenerateDHParam "4096" "/tmp/ssl/dhparam.pem" "true" "true"
# Test Create a CA
doGenerateCA "sha512" "9150" "rsa" "4096" "/tmp/ssl/ca-key.pem" "/tmp/ssl/ca-cert.pem" "BR" "Sao Paulo" "Sorocaba" "Eibly LTDA" "IT" "Eibly Global Root CA" "ssl@eibly.com" "true"
