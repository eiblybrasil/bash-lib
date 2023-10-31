#!/bin/bash

SOURCE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

###
#
# Functions
#
###

function sendMessage() {
    PREFIX="\033[1m\033[0;97m[$(date +%H:%M:%S.%N | cut -b 1-10)]\033[0m "

    case $2 in
    INFO | info)
        echo -e "$PREFIX\033[0;94m[INFO]:\033[0m $1"
        ;;
    WARNING | warning)
        echo -e "$PREFIX\033[0;93m[WARNING]:\033[0m $1"
        ;;
    ERROR | error)
        echo -e "$PREFIX\033[0;91m[ERROR]:\033[0m $1"
        ;;
    SUCCESS | success)
        echo -e "$PREFIX\033[0;92m[SUCCESS]:\033[0m $1"
        ;;
    OK | ok)
        echo -e "$PREFIX\033[0;36m[OK]:\033[0m $1"
        ;;
    DEBUG | debug)
        echo -e "$PREFIX\033[0;33m[DEBUG]:\033[0m $1"
        ;;
    NONE | none)
        echo -e "$PREFIX$31"
        ;;
    *)
        echo -e "$PREFIX$1"
        ;;
    esac
}

# "DO" Functions

function doRandomPassword() {
    local length="${1:-22}"
    tr -dc 'A-Za-z0-9-._@' </dev/urandom | head -c "$length"
    echo
}

function doRandomString() {
    local length="${1:-22}"
    tr -dc 'A-Za-z' </dev/urandom | head -c "$length"
    echo
}

function doRandomNumber() {
    local length="${1:-22}"
    tr -dc '0-9' </dev/urandom | head -c "$length"
    echo
}

function doTrim() {
    local var="${*}"
    var="${var#"${var%%[![:space:]]*}"}"
    var="${var%"${var##*[![:space:]]}"}"
    printf '%s' "$var"
}

function doHumanBytes() {
    local bytes="$1"
    local precision=2
    local units=("B" "KB" "MB" "GB" "TB" "PB" "EB" "ZB" "YB")
    local unit=0

    while ((bytes >= 1024)) && ((unit < 8)); do
        bytes=$((bytes / 1024))
        unit=$((unit + 1))
    done

    if ((unit == 0)); then
        precision=0
    fi

    printf "%.${precision}f %s" "$bytes" "${units[$unit]}"
}

# "GET" Functions

function getDuration() {
    local start="$1"
    local end="$2"
    local start_s=$(date -d "${start//./:}" +%s)
    local end_s=$(date -d "${end//./:}" +%s)
    local duration=$((end_s - start_s))
    local days=$((duration / 86400))
    local hours=$((duration % 86400 / 3600))
    local minutes=$((duration % 3600 / 60))
    local seconds=$((duration % 60))
    printf '%s' "$days days, $hours hours, $minutes minutes, $seconds seconds"
}
