#!/bin/bash

SOURCE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" >/dev/null 2>&1 && pwd)"

###
#
# Imports
#
###
source "$SOURCE_PATH/utils.sh"
source "$SOURCE_PATH/ssl.sh"
source "$SOURCE_PATH/os.sh"

###
#
# Functions
#
###

SNAPSHOT_DIRECTORY="/var/snapshots"
TMP_DIRECTORY="/tmp"

# Create a snapshot
# $1: The domain
# $2: The name of the snapshot (optional, default: the current date)
# $3: Compress the snapshot (optional, default: false)
# $4: Compress type of the snapshot (optional, default: zstd) - gzip, bzip2, lzma, lzop, xz, zstd, zip, rar or 7z ()
function doCreateSnapshot() {
    local domain="$1"

    domain=$(doDomainToUnderDomain "$domain")

    if isDirExists "$SNAPSHOT_DIRECTORY/$domain"; then
        return 0
    fi

    if ! doCreateDirectory "$SNAPSHOT_DIRECTORY/$domain" "root" "root" "0700"; then
        return 1
    fi

    return 0
}