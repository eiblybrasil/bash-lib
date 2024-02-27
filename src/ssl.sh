#!/bin/bash

SOURCE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

###
#
# Imports
#
###
source "$SOURCE_PATH/utils.sh"

###
#
# Functions
#
###

# "DO" Functions

function doGenerateDHParam() {
    local bits="$1"
    local output="$2"
    local fast="$3"
    local overwrite="$4"

    if isEmpty "$bits"; then
        bits="2048"
    fi

    if isEmpty "$output"; then
        output="/etc/ssl/dhparam.pem"
    fi

    if [ -f "$output" ] && [ "$overwrite" != "true" ]; then
        sendMessage "DHParam file already exists"
        return 1
    fi

    if [ ! -d "$(dirname "$output")" ]; then
        mkdir -p "$(dirname "$output")"
    fi

    if [ "$fast" == "true" ]; then
        openssl dhparam -dsaparam -out "$output" "$bits" 2>/dev/null
    else
        openssl dhparam -out "$output" "$bits" 2>/dev/null
    fi

    if [ $? -ne 0 ]; then
        sendErrorMessage "Failed to generate DHParam file"
        return 1
    fi

    sendMessage "DHParam file generated"

    return 0
}

function doGenerateCA() {
    # openssl req -x509 -sha512 -nodes -days 9132 -newkey rsa:4096 -keyout "/etc/ssl/ca-key.pem" -out "/etc/ssl/ca-cert.pem" -subj "/C=BR/ST=Sao Paulo/L=Sorocaba/O=Eibly LTDA/OU=IT/CN=Eibly Global Root CA" &>/dev/null

    local algorithm="$1"
    local days="$2"
    local keyType="$3"
    local keySize="$4"
    local keyFile="$5"
    local certFile="$6"
    local country="$7"
    local state="$8"
    local city="$9"
    local organization="${10}"
    local organizationalUnit="${11}"
    local commonName="${12}"
    local emailAddress="${13}"
    local overwrite="${14}"

    if isEmpty "$algorithm"; then
        algorithm="sha512"
    fi

    # Validate algorithms
    local validAlgorithms=("sha1" "sha224" "sha256" "sha384" "sha512")
    if ! inArray "$algorithm" "${validAlgorithms[@]}"; then
        sendErrorMessage "Invalid algorithm"
        return 1
    fi

    if isEmpty "$days"; then
        days="9150" # ~25 years
    fi

    # Check days is multiple of 30
    if [ $((days % 30)) -ne 0 ]; then
        sendErrorMessage "Days must be multiple of 30"
        return 1
    fi

    if isEmpty "$keyType"; then
        keyType="rsa"
    fi

    # Validate key types
    local validKeyTypes=("rsa" "dsa" "ec")
    if ! inArray "$keyType" "${validKeyTypes[@]}"; then
        sendErrorMessage "Invalid key type"
        return 1
    fi

    if isEmpty "$keySize"; then
        keySize="4096"
    fi

    # Check key size is multiple of 1024
    if [ $((keySize % 1024)) -ne 0 ]; then
        sendErrorMessage "Key size must be multiple of 1024"
        return 1
    fi

    # Max key size is 10240
    if [ "$keySize" -gt "10240" ]; then
        sendErrorMessage "Key size must be less than 10240 (10K)"
        return 1
    fi

    if isEmpty "$keyFile"; then
        keyFile="/etc/ssl/ca-key.pem"
    fi

    if isEmpty "$certFile"; then
        certFile="/etc/ssl/ca-cert.pem"
    fi

    if isEmpty "$country"; then
        country="BR"
    fi

    if isEmpty "$state"; then
        state="Sao Paulo"
    fi

    if isEmpty "$city"; then
        city="Sorocaba"
    fi

    if isEmpty "$organization"; then
        organization="Eibly LTDA"
    fi

    if isEmpty "$organizationalUnit"; then
        organizationalUnit="IT"
    fi

    if isEmpty "$commonName"; then
        commonName="Eibly Global Root CA"
    fi

    if isEmpty "$emailAddress"; then
        emailAddress="ssl@eibly.com"
    fi

    if [ "$overwrite" != "true" ] && [ -f "$keyFile" ]; then
        sendErrorMessage "Key file already exists"
        return 1
    fi

    if [ "$overwrite" != "true" ] && [ -f "$certFile" ]; then
        sendErrorMessage "Cert file already exists"
        return 1
    fi

    if [ ! -d "$(dirname "$keyFile")" ]; then
        mkdir -p "$(dirname "$keyFile")"
    fi

    if [ ! -d "$(dirname "$certFile")" ]; then
        mkdir -p "$(dirname "$certFile")"
    fi

    openssl req -x509 -"$algorithm" -nodes -days "$days" -newkey "$keyType":"$keySize" -keyout "$keyFile" -out "$certFile" -subj "/C=$country/ST=$state/L=$city/O=$organization/OU=$organizationalUnit/CN=$commonName/emailAddress=$emailAddress" &>/dev/null
    if [ $? -ne 0 ]; then
        sendErrorMessage "Failed to generate CA"
        return 1
    fi

    sendMessage "CA generated"
    return 0
}

# "GET" Functions

function getCertificateDetails() {
    local certFile="$1"

    if isEmpty "$certFile"; then
        certFile="/etc/ssl/ca-cert.pem"
    fi

    if ! isFileExists "$certFile"; then
        sendErrorMessage "Cert file not found"
        return 1
    fi

    local details=$(openssl x509 -text -noout -in "$certFile")
    if [ $? -ne 0 ]; then
        sendErrorMessage "Failed to get cert details"
        return 1
    fi

    echo "$details"
    return 0
}

function getCertificate() {
    local certFile="$1"

    if isEmpty "$certFile"; then
        certFile="/etc/ssl/ca-cert.pem"
    fi

    if ! isFileExists "$certFile"; then
        sendErrorMessage "Cert file not found"
        return 1
    fi

    local certificate=$(openssl x509 -text -noout -in "$certFile")
    if [ $? -ne 0 ]; then
        sendErrorMessage "Failed to get certificate"
        return 1
    fi

    # Map certificate to object
    local certificateObject
    certificateObject=$(echo "$certificate" | awk '
        BEGIN {
            RS = ""
            FS = "\n"
        }
        {
            for (i = 1; i <= NF; i++) {
                if ($i ~ /^ *Serial Number:/) {
                    serialNumber = $i
                    sub(/^ *Serial Number: */, "", serialNumber)
                } else if ($i ~ /^ *Signature Algorithm:/) {
                    signatureAlgorithm = $i
                    sub(/^ *Signature Algorithm: */, "", signatureAlgorithm)
                } else if ($i ~ /^ *Issuer:/) {
                    issuer = $i
                    sub(/^ *Issuer: */, "", issuer)
                } else if ($i ~ /^ *Validity/) {
                    validFrom = $(i + 1)
                    validTo = $(i + 2)
                    sub(/^ *Not Before: */, "", validFrom)
                    sub(/^ *Not After : */, "", validTo)
                } else if ($i ~ /^ *Subject:/) {
                    subject = $i
                    sub(/^ *Subject: */, "", subject)
                } else if ($i ~ /^ *Subject Public Key Info:/) {
                    subjectPublicKeyInfo = $i
                    sub(/^ *Subject Public Key Info: */, "", subjectPublicKeyInfo)
                } else if ($i ~ /^ *X509v3 extensions:/) {
                    x509v3Extensions = $i
                    sub(/^ *X509v3 extensions: */, "", x509v3Extensions)
                }
            }
        }
        END {
            printf "{\"serialNumber\":\"%s\",\"signatureAlgorithm\":\"%s\",\"issuer\":\"%s\",\"validFrom\":\"%s\",\"validTo\":\"%s\",\"subject\":\"%s\",\"subjectPublicKeyInfo\":\"%s\",\"x509v3Extensions\":\"%s\"}", serialNumber, signatureAlgorithm, issuer, validFrom, validTo, subject, subjectPublicKeyInfo, x509v3Extensions
        }
    ')

    if [ $? -ne 0 ]; then
        sendErrorMessage "Failed to map certificate to object"
        return 1
    fi

    echo "$certificateObject"
    return 0
}

function getCertificateValidFrom() {
    local certFile="$1"

    if isEmpty "$certFile"; then
        certFile="/etc/ssl/ca-cert.pem"
    fi

    if ! isFileExists "$certFile"; then
        sendErrorMessage "Cert file not found"
        return 1
    fi

    local validFrom=$(openssl x509 -startdate -noout -in "$certFile" | sed -e 's#notBefore=##')
    if [ $? -ne 0 ]; then
        sendErrorMessage "Failed to get cert valid from"
        return 1
    fi

    echo "$validFrom"
    return 0
}

function getCertificateExpiresAt() {
    local certFile="$1"

    if isEmpty "$certFile"; then
        certFile="/etc/ssl/ca-cert.pem"
    fi

    if ! isFileExists "$certFile"; then
        sendErrorMessage "Cert file not found"
        return 1
    fi

    local expiresAt=$(openssl x509 -enddate -noout -in "$certFile" | sed -e 's#notAfter=##')
    if [ $? -ne 0 ]; then
        sendErrorMessage "Failed to get cert expires at"
        return 1
    fi

    echo "$expiresAt"
    return 0
}

function getCertificateSerialNumber() {
    local certFile="$1"

    if isEmpty "$certFile"; then
        certFile="/etc/ssl/ca-cert.pem"
    fi

    if ! isFileExists "$certFile"; then
        sendErrorMessage "Cert file not found"
        return 1
    fi

    local serialNumber=$(openssl x509 -serial -noout -in "$certFile" | sed -e 's#serial=##')
    if [ $? -ne 0 ]; then
        sendErrorMessage "Failed to get cert serial number"
        return 1
    fi

    echo "$serialNumber"
    return 0
}

function getCertificateIssuer() {
    local certFile="$1"

    if isEmpty "$certFile"; then
        certFile="/etc/ssl/ca-cert.pem"
    fi

    if ! isFileExists "$certFile"; then
        sendErrorMessage "Cert file not found"
        return 1
    fi

    local issuer=$(openssl x509 -issuer -noout -in "$certFile" | sed -e 's#issuer=##')
    if [ $? -ne 0 ]; then
        sendErrorMessage "Failed to get cert issuer"
        return 1
    fi

    echo "$issuer"
    return 0
}

# "ADD" Functions

function addCAToTrust() {
    local certFile="$1"
    local trustFile="$2"
    local overwrite="$3"

    if isEmpty "$certFile"; then
        certFile="/etc/ssl/ca-cert.pem"
    fi

    if isEmpty "$trustFile"; then
        trustFile="/etc/ssl/certs/ca-certificates.crt"
    fi

    # Check CA Cert already exists in trust

    if [ "$overwrite" != "true" ] && grep -q "$(cat "$certFile")" "$trustFile"; then
        sendMessage "CA already added to trust"
        return 0
    fi

    if [ ! -d "$(dirname "$trustFile")" ]; then
        mkdir -p "$(dirname "$trustFile")"
    fi

    cat "$certFile" >>"$trustFile"
    if [ $? -ne 0 ]; then
        sendErrorMessage "Failed to add CA to trust"
        return 1
    fi

    sendMessage "CA added to trust"
    return 0
}

# "REMOVE" Functions

function removeCAFromTrust() {
    local certFile="$1"
    local trustFile="$2"

    if isEmpty "$certFile"; then
        certFile="/etc/ssl/ca-cert.pem"
    fi

    if isEmpty "$trustFile"; then
        trustFile="/etc/ssl/certs/ca-certificates.crt"
    fi

    # Check CA Cert already exists in trust
    if ! grep -q "$(cat "$certFile")" "$trustFile"; then
        sendOkMessage "CA already removed from trust"
        return 0
    fi

    if [ ! -d "$(dirname "$trustFile")" ]; then
        mkdir -p "$(dirname "$trustFile")"
    fi

    if ! isFileExists "$trustFile"; then
        sendOkMessage "CA already removed from trust"
        return 0
    fi

    sed -i "/$(cat "$certFile")/d" "$trustFile"
    if [ $? -ne 0 ]; then
        sendErrorMessage "Failed to remove CA from trust"
        return 1
    fi

    sendMessage "CA removed from trust"
    return 0
}
