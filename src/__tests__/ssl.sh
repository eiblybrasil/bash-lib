#!/bin/bash

SOURCE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$SOURCE_PATH/../utils.sh"

# Test Create a DHParam
doGenerateDHParam "2048" "/tmp/ssl/dhparam.pem" "false" "true"
# Test Create a CA
doGenerateCA "sha512" "9132" "rsa" "4096" "/tmp/ssl/ca-key.pem" "/tmp/ssl/ca-cert.pem" "BR" "Sao Paulo" "Sorocaba" "Eibly LTDA" "IT" "Eibly Global Root CA" "ssl@eibly.com" "true"
