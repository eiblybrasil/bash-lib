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

BACKUP_DIRECTORY="/var/backups"
TMP_DIRECTORY="/tmp"
