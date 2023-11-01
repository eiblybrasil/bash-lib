#!/bin/bash

SOURCE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

###
## "SEND" Functions
###

# Send a message to the console
# $1: The message
# $2: The message type (info, warning, error, success, ok, debug, none)
function sendMessage() {
    local message="$1"
    local type="$2"
    local date=$(date +%H:%M:%S.%N | cut -b 1-12)
    local prefix="\033[1m\033[0;97m[$date]\033[0m "

    case $type in
    INFO | info)
        echo -e "$prefix\033[0;94m[INFO]:\033[0m $message"
        ;;
    WARNING | warning)
        echo -e "$prefix\033[0;93m[WARNING]:\033[0m $message"
        ;;
    ERROR | error)
        echo -e "$prefix\033[0;91m[ERROR]:\033[0m $message"
        ;;
    SUCCESS | success)
        echo -e "$prefix\033[0;92m[SUCCESS]:\033[0m $message"
        ;;
    OK | ok)
        echo -e "$prefix\033[0;36m[OK]:\033[0m $message"
        ;;
    DEBUG | debug)
        echo -e "$prefix\033[0;33m[DEBUG]:\033[0m $message"
        ;;
    NONE | none)
        echo -e "$prefix$31"
        ;;
    *)
        echo -e "$prefix$message"
        ;;
    esac
}

# Send a error message to the console
# $1: The message
function sendErrorMessage() {
    sendMessage "$1" "error"
}

# Send a warning message to the console
# $1: The message
function sendWarningMessage() {
    sendMessage "$1" "warning"
}

# Send a info message to the console
# $1: The message
function sendInfoMessage() {
    sendMessage "$1" "info"
}

# Send a success message to the console
# $1: The message
function sendSuccessMessage() {
    sendMessage "$1" "success"
}

# Send a ok message to the console
# $1: The message
function sendOkMessage() {
    sendMessage "$1" "ok"
}

# Send a debug message to the console
# $1: The message
function sendDebugMessage() {
    sendMessage "$1" "debug"
}

###
## "IS" Functions
###

# Check if a string is empty
# $1: The string
function isEmpty() {
    local value="$1"

    if [ -z "$value" ]; then
        return 0
    fi

    return 1
}

# Check if a command exists
# $1: The command
function isCommandExists() {
    local command="$1"

    if command -v "$command" &>/dev/null; then
        return 0
    fi

    return 1
}

# Check if a folder exists
# $1: The folder
function isFolderExists() {
    local folder="$1"

    if [ -d "$folder" ]; then
        return 0
    fi

    return 1
}

# Check if a file exists
# $1: The file
function isFileExists() {
    local file="$1"

    if [ -f "$file" ]; then
        return 0
    fi

    return 1
}

# Check if a string is a valid UUIDv4
# $1: The string
function isValidUUIDv4() {
    local uuid="$1"
    local regex="^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$"

    if [[ "$uuid" =~ $regex ]]; then
        return 0
    fi

    return 1
}

# Check if a string is a valid alpha
# $1: The string
function isStringAlpha() {
    local string="$1"
    local regex="^[a-zA-Z]+$"

    if [[ "$string" =~ $regex ]]; then
        return 0
    fi

    return 1
}

# Check if a number is a valid numeric
# $1: The number
function isNumeric() {
    local string="$1"
    local regex="^[0-9]+$"

    if [[ "$string" =~ $regex ]]; then
        return 0
    fi

    return 1
}

# Check if a string is a valid alpha numeric
# $1: The string
function isStringAlphaNumeric() {
    local string="$1"
    local regex="^[a-zA-Z0-9]+$"

    if [[ "$string" =~ $regex ]]; then
        return 0
    fi

    return 1

}

# Check if a string is a valid alpha numeric with spaces
# $1: The string
function isStringAlphaNumericWithSpaces() {
    local string="$1"
    local regex="^[a-zA-Z0-9 ]+$"

    if [[ "$string" =~ $regex ]]; then
        return 0
    fi

    return 1
}

# Check if a string is a valid alpha numeric with spaces and special characters
# $1: The string
function isStringAlphaNumericWithSpacesAndSpecialCharacters() {
    local string="$1"
    local regex="^[a-zA-Z0-9 _.,!@#$%^&*()+=]+$"

    if [[ "$string" =~ $regex ]]; then
        return 0
    fi

    return 1
}

# Check if is a valid domain
# $1: The domain
function isValidDomain() {
    local domain="$1"

    if [[ "$domain" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$ ]]; then
        return 0
    fi

    return 1
}

# Check if is a valid hostname
# $1: The hostname
function isValidHostname() {
    local hostname="$1"

    if [[ "$hostname" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]$ ]]; then
        return 0
    fi

    return 1
}

# Check if is a valid email
# $1: The email
function isValidEmail() {
    local email="$1"

    if [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 0
    fi

    return 1
}

# Check if is a valid IPv4
# $1: The IPv4
function isValidIPv4() {
    local ipv4="$1"

    if [[ "$ipv4" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        return 0
    fi

    return 1
}

# Check if is a valid IPv6
# $1: The IPv6
function isValidIPv6() {
    local ipv6="$1"

    # Regex from: https://stackoverflow.com/questions/53497/regular-expression-that-matches-valid-ipv6-addresses
    if [[ "$ipv6" =~ ^(([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){6}(:[0-9a-fA-F]{1,4})|([0-9a-fA-F]{1,4}:){5}((:[0-9a-fA-F]{1,4}){1,2})|([0-9a-fA-F]{1,4}:){4}((:[0-9a-fA-F]{1,4}){1,3})|([0-9a-fA-F]{1,4}:){3}((:[0-9a-fA-F]{1,4}){1,4})|([0-9a-fA-F]{1,4}:){2}((:[0-9a-fA-F]{1,4}){1,5})|([0-9a-fA-F]{1,4}:){1}((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:) ]]; then
        return 0
    fi

    return 1
}

# Check if is a valid IPv4 or IPv6
# $1: The IP
function isValidIP() {
    local ip="$1"

    if isValidIPv4 "$ip" || isValidIPv6 "$ip"; then
        return 0
    fi

    return 1
}

# Check if is a valid URL
# $1: The URL
function isValidURL() {
    local url="$1"

    if [[ "$url" =~ ^https?://[^/]+/.+$ ]]; then
        return 0
    fi

    return 1
}

# Check if is a valid port
# $1: The port
function isValidPort() {
    local port="$1"

    if [[ "$port" =~ ^[0-9]+$ ]] && [ "$port" -ge 1 ] && [ "$port" -le 65535 ]; then
        return 0
    fi

    return 1
}

###
## "IN" Functions
###

# Check if a value is in an array
# $1: The value to search for
# $2: The array (space separated)
function inArray() {
    local needle="$1"
    shift
    local haystack=("$@")
    local i
    for i in "${haystack[@]}"; do
        if [[ "$i" == "$needle" ]]; then
            return 0
        fi
    done
    return 1
}

# Check if a value is in an array (case insensitive)
# $1: The value to search for
# $2: The array (space separated)
function inArrayCaseInsensitive() {
    local needle="$1"
    shift
    local haystack=("$@")
    local i
    for i in "${haystack[@]}"; do
        if [[ "${i,,}" == "${needle,,}" ]]; then
            return 0
        fi
    done
    return 1
}

###
## "DO" Functions
###

# Generate a random password
# $1: The length of the password
function doRandomPassword() {
    local length="${1:-22}"
    tr -dc 'A-Za-z0-9-._@' </dev/urandom | head -c "$length"
    echo
}

# Generate a random string (only letters)
# $1: The length of the string
function doRandomString() {
    local length="${1:-22}"
    tr -dc 'A-Za-z' </dev/urandom | head -c "$length"
    echo
}

# Generate a random numbers
# $1: The length of the number
function doRandomNumber() {
    local length="${1:-22}"
    tr -dc '0-9' </dev/urandom | head -c "$length"
    echo
}

# Create a directory
# $1 The path of the directory
# $2: Create the parent directory (true, false)
# $3: The owner (optional, default: current user)
# $4: The group (optional, default: current user)
# $5: The permissions (optional, default: 0755)
function doCreateDirectory() {
    local path="$1"
    local createParentDirectory="$2"
    local owner="$3"
    local group="$4"
    local permissions="$5"

    if [ -z "$path" ]; then
        sendErrorMessage "You must specify a path"
        return 1
    fi

    if [ -z "$createParentDirectory" ]; then
        createParentDirectory="false"
    fi

    if [ "$createParentDirectory" == "true" ]; then
        mkdir -p "$path"
    else
        mkdir "$path"
    fi

    if [ $? -ne 0 ]; then
        sendErrorMessage "The directory '$path' could not be created"
        return 1
    fi

    if [ ! -z "$owner" ]; then
        chown "$owner" "$path"
    fi

    if [ ! -z "$group" ]; then
        chgrp "$group" "$path"
    fi

    if [ ! -z "$permissions" ]; then
        chmod "$permissions" "$path"
    fi

    return 0
}

# Create a symlink
# $1: The source
# $2: The destination
# $3: The owner (optional, default: current user)
# $4: The group (optional, default: current user)
# $5: The permissions (optional, default: 0755)
function doCreateSymlink() {
    local source="$1"
    local destination="$2"
    local owner="$3"
    local group="$4"
    local permissions="$5"

    if [ -z "$source" ]; then
        sendErrorMessage "You must specify a source"
        return 1
    fi

    if [ -z "$destination" ]; then
        sendErrorMessage "You must specify a destination"
        return 1
    fi

    if [ ! -f "$source" ]; then
        sendErrorMessage "The source '$source' does not exist"
        return 1
    fi

    if [ -f "$destination" ]; then
        sendErrorMessage "The destination '$destination' already exists"
        return 1
    fi

    ln -s "$source" "$destination"

    if [ $? -ne 0 ]; then
        sendErrorMessage "The symlink '$destination' could not be created"
        return 1
    fi

    if [ ! -z "$owner" ]; then
        chown "$owner" "$destination"
    fi

    if [ ! -z "$group" ]; then
        chgrp "$group" "$destination"
    fi

    if [ ! -z "$permissions" ]; then
        chmod "$permissions" "$destination"
    fi

    return 0
}

# Delete a file
# $1: The file
function doDeleteFile() {
    local file="$1"

    if [ -z "$file" ]; then
        sendErrorMessage "You must specify a file"
        return 1
    fi

    if [ ! -f "$file" ]; then
        sendErrorMessage "The file '$file' does not exist"
        return 1
    fi

    rm -f "$file"
}

# Delete symlink (only the symlink)
# $1: The symlink
function doRemoveSymlink() {
    local symlink="$1"

    if [ -z "$symlink" ]; then
        sendErrorMessage "You must specify a symlink"
        return 1
    fi

    if [ ! -L "$symlink" ]; then
        sendErrorMessage "The symlink '$symlink' does not exist"
        return 1
    fi

    rm -f "$symlink"
}

# String to lowercase
# $1: The string
function doStringToLower() {
    local string="$1"
    echo "${string,,}"
}

# String to uppercase
# $1: The string
function doStringToUpper() {
    local string="$1"
    echo "${string^^}"
}

# Trim a string
# $1: The string
function doTrim() {
    local var="${*}"
    var="${var#"${var%%[![:space:]]*}"}"
    var="${var%"${var##*[![:space:]]}"}"
    printf '%s' "$var"
}

# Human readable bytes (B, KB, MB, GB, TB, PB, EB, ZB, YB)
# $1: The bytes
# $2: The precision
function doHumanBytes() {
    local bytes="$1"
    local precision="${2:-2}"
    local units=("B" "KB" "MB" "GB" "TB" "PB" "EB" "ZB" "YB")
    local unit=0

    if ((bytes == 0)); then
        echo "0 ${units[0]}"
        return 0
    fi

    if ((precision < 0)); then
        precision=0
    fi

    if ((precision > 8)); then
        precision=8
    fi

    while ((bytes >= 1024)) && ((unit < 8)); do
        bytes=$((bytes / 1024))
        unit=$((unit + 1))
    done

    if ((unit == 0)); then
        precision=0
    fi

    printf "%.${precision}f %s" "$bytes" "${units[$unit]}"
}

# Generate a UUIDv4
function doGenerateUUIDv4() {
    local N B C='89ab'

    for ((N = 0; N < 16; ++N)); do
        B=$((RANDOM % 256))

        case "$N" in
        6)
            printf '4%x' "$((B % 16))"
            ;;
        8)
            printf '%c%x' "${C:$RANDOM%${#C}:1}" "$((B % 16))"
            ;;
        3 | 5 | 7 | 9)
            printf '%02x-' "$B"
            ;;
        *)
            printf '%02x' "$B"
            ;;
        esac
    done

    echo ""

    return 0
}

# Generate a UUIDv5
# $1: The namespace
# $2: The name
function doGenerateUUIDv5() {
    local namespace="$1"
    local name="$2"

    # Common namespace UUIDs
    # DNS: 6ba7b810-9dad-11d1-80b4-00c04fd430c8
    # URL: 6ba7b811-9dad-11d1-80b4-00c04fd430c8
    # OID: 6ba7b812-9dad-11d1-80b4-00c04fd430c8
    # X500: 6ba7b814-9dad-11d1-80b4-00c04fd430c8
    # nil: 00000000-0000-0000-0000-000000000000

    if [ -z "$namespace" ]; then
        sendErrorMessage "You must specify a namespace"
        return 1
    fi

    if [ -z "$name" ]; then
        sendErrorMessage "You must specify a name"
        return 1
    fi

    local uuidv4=$(doGenerateUUIDv4)
    local uuidv5=$(echo -n "$namespace$name" | sha1sum | sed 's/\(..\)/\1-/g; s/-$//')

    uuidv5="${uuidv5:0:14}5${uuidv5:15:19}8${uuidv5:20}"

    echo "$uuidv5"
    return 0
}

# Normalize path permissions (0755 for directories and 0644 for files)
# $1: The path
# $2: The directory permissions
# $3: The file permissions
function doNormalizePathPermissions() {
    local path="$1"
    local directoryPermissions="$2"
    local filePermissions="$3"

    if [ -z "$path" ]; then
        sendErrorMessage "You must specify a path"
        return 1
    fi

    if [ ! -z "$directoryPermissions" ]; then
        directoryPermissions="0755"
    fi

    if [ ! -z "$filePermissions" ]; then
        filePermissions="0644"
    fi

    if [ ! -d "$path" ] || [ ! -f "$path" ]; then
        sendErrorMessage "The path '$path' does not exist"
        return 1
    fi

    find "$path" -type d -exec chmod "$directoryPermissions" {} \;
    find "$path" -type f -exec chmod "$filePermissions" {} \;

    return 0
}

# Run a command
# $1: The command
# $2: Print the error message (true, false)
function doRunCommand() {
    local command="$1"
    local print="$2"

    if [ -z "$command" ]; then
        sendErrorMessage "You must specify a command"
        return 1
    fi

    if [ -z "$print" ]; then
        print="false"
    fi

    $command
    if [ $? -ne 0 ]; then
        if [ "$print" == "true" ]; then
            sendErrorMessage "The command '$command' failed"
        fi
        return 1
    fi

    return 0
}

# Run a command (silent)
# $1: The command
# $2: Print the error message (true, false)
function doRunCommandSilent() {
    local command="$1"
    local print="$2"

    if [ -z "$command" ]; then
        sendErrorMessage "You must specify a command"
        return 1
    fi

    if [ -z "$print" ]; then
        print="false"
    fi

    $command >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        if [ "$print" == "true" ]; then
            sendErrorMessage "The command '$command' failed"
        fi
        return 1
    fi

    return 0
}

# Replace a string (Domain Type) removing special characters, spaces and converting to lowercase
# $1: The domain
function doDomainToUnderDomain() {
    local domain="$1"

    if [ -z "$domain" ]; then
        sendErrorMessage "You must specify a domain"
        return 1
    fi

    if ! isValidDomain "$domain"; then
        sendErrorMessage "The domain '$domain' is not valid"
        return 1
    fi

    local underDomain=$(echo "$domain" | sed 's/\./_/g' | sed 's/-/_/g' | tr A-Z a-z)

    echo "$underDomain"
    return 0
}

# Transform a string to slug
# $1: The string
# $2: The separator (optional, default: '-')
function doStringSlug() {
    local string="$1"
    local separator="$2"

    if [ -z "$string" ]; then
        sendErrorMessage "You must specify a string"
        return 1
    fi

    if [ -z "$separator" ]; then
        separator="-"
    fi

    local slug=$(echo "$string" | iconv -t ascii//TRANSLIT | sed -E 's/[~\^]+//g' | sed -E 's/[^a-zA-Z0-9]+/-/g' | sed -E 's/^-+\|-+$//g' | sed -E 's/^-+//g' | sed -E 's/-+$//g' | tr A-Z a-z)
    slug=$(echo "$slug" | sed -E "s/-/$separator/g")

    echo "$slug"
    return 0
}

###
## "GET" Functions
###

# Get the current date and time
function getCurrentDateTime() {
    date +"%Y-%m-%d %H:%M:%S"
}

# Format a date
# $1: The date
# $2: The format
function doFormatDate() {
    local date="$1"
    local format="$2"

    if [ -z "$date" ]; then
        sendErrorMessage "You must specify a date"
        return 1
    fi

    if [ -z "$format" ]; then
        sendErrorMessage "You must specify a format"
        return 1
    fi

    local formatedDate=$(date -d "$date" +"$format")

    echo "$formatedDate"
    return 0
}

# Get the difference between two dates
# $1: The start date
# $2: The end date
function getDiffDate() {
    local start="$1"
    local end="$2"
    local start_s=$(date -d "${start//./:}" +%s)
    local end_s=$(date -d "${end//./:}" +%s)
    local duration=$((end_s - start_s))
    echo "$duration"
    return 0
}

# Get the difference between two dates (Formated)
# $1: The start date
# $2: The end date
function getDiffDateFormated() {
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

# Get file size
# $1: The file
# $2: The format (human, bytes)
function getFileSize() {
    local file="$1"
    local format="$2"

    if [ -z "$file" ]; then
        sendErrorMessage "You must specify a file"
        return 1
    fi

    if ! isFileExists "$file"; then
        sendErrorMessage "The file '$file' does not exist"
        return 1
    fi

    if [ -z "$format" ]; then
        format="bytes"
    fi

    local size=$(wc -c <"$file" | tr -d ' ')
    if [ "$format" == "human" ]; then
        size=$(doHumanBytes "$size")
    fi

    echo "$size"
    return 0
}

# Get directory size
# $1: The directory
# $2: The format (human, bytes)
function getDirectorySize() {
    local directory="$1"

    if [ -z "$directory" ]; then
        sendErrorMessage "You must specify a directory"
        return 1
    fi

    if [ ! -d "$directory" ]; then
        sendErrorMessage "The directory '$directory' does not exist"
        return 1
    fi

    if [ -z "$format" ]; then
        format="bytes"
    fi

    local size=$(du -sb "$directory" | awk '{print $1}')
    if [ "$format" == "human" ]; then
        size=$(doHumanBytes "$size")
    fi

    echo "$size"
    return 0
}

# Get files in a directory
# $1: The directory
function getDirectoryFiles() {
    local directory="$1"

    if [ -z "$directory" ]; then
        sendErrorMessage "You must specify a directory"
        return 1
    fi

    if [ ! -d "$directory" ]; then
        sendErrorMessage "The directory '$directory' does not exist"
        return 1
    fi

    local files=()

    while IFS= read -r -d '' file; do
        files+=("$file")
    done < <(find "$directory" -type f -print0)

    echo "${files[@]}"
    return 0
}

# Get the number of files in a directory
# $1: The directory
function getDirectoryFilesCount() {
    local directory="$1"

    if [ -z "$directory" ]; then
        sendErrorMessage "You must specify a directory"
        return 1
    fi

    if [ ! -d "$directory" ]; then
        sendErrorMessage "The directory '$directory' does not exist"
        return 1
    fi

    local filesCount=$(find "$directory" -type f | wc -l)

    echo "$filesCount"
    return 0
}

# Get file checksum
# $1: The file
# $2: The algorithm (md5, sha1, sha256, sha512)
function getFileChecksum() {
    local file="$1"
    local algorithm="$2"

    if [ -z "$file" ]; then
        sendErrorMessage "You must specify a file"
        return 1
    fi

    if ! isFileExists "$file"; then
        sendErrorMessage "The file '$file' does not exist"
        return 1
    fi

    if [ -z "$algorithm" ]; then
        algorithm="sha256"
    fi

    if [! inArrayCaseInsensitive "$algorithm" "md5" "sha1" "sha256" "sha512"]; then
        sendErrorMessage "The algorithm '$algorithm' is not valid"
        return 1
    fi

    local checksum=$(openssl dgst -"$algorithm" "$file" | awk '{print $2}')

    echo "$checksum"
    return 0
}

# Get file extension
# $1: The file
function getFileExtension() {
    local file="$1"

    if [ -z "$file" ]; then
        sendErrorMessage "You must specify a file"
        return 1
    fi

    if ! isFileExists "$file"; then
        sendErrorMessage "The file '$file' does not exist"
        return 1
    fi

    local extension="${file##*.}"

    echo "$extension"
    return 0
}

# Get file name
# $1: The file (complete path)
function getFileName() {
    local file="$1"

    if [ -z "$file" ]; then
        sendErrorMessage "You must specify a file"
        return 1
    fi

    if ! isFileExists "$file"; then
        sendErrorMessage "The file '$file' does not exist"
        return 1
    fi

    local name="${file##*/}"

    echo "$name"
    return 0
}

# Get file name without extension
# $1: The file (complete path)
function getFileNameWithoutExtension() {
    local file="$1"

    if [ -z "$file" ]; then
        sendErrorMessage "You must specify a file"
        return 1
    fi

    if ! isFileExists "$file"; then
        sendErrorMessage "The file '$file' does not exist"
        return 1
    fi

    local name="${file##*/}"
    local nameWithoutExtension="${name%.*}"

    echo "$nameWithoutExtension"
    return 0
}

# Get file owner
# $1: The file
function getFileOwner() {
    local file="$1"

    if [ -z "$file" ]; then
        sendErrorMessage "You must specify a file"
        return 1
    fi

    if ! isFileExists "$file"; then
        sendErrorMessage "The file '$file' does not exist"
        return 1
    fi

    local owner=$(stat -c '%U' "$file")

    echo "$owner"
    return 0
}

# Get file group
# $1: The file
function getFileGroup() {
    local file="$1"

    if [ -z "$file" ]; then
        sendErrorMessage "You must specify a file"
        return 1
    fi

    if ! isFileExists "$file"; then
        sendErrorMessage "The file '$file' does not exist"
        return 1
    fi

    local group=$(stat -c '%G' "$file")

    echo "$group"
    return 0
}

# Get file permissions
# $1: The file
function getFilePermissions() {
    local file="$1"

    if [ -z "$file" ]; then
        sendErrorMessage "You must specify a file"
        return 1
    fi

    if ! isFileExists "$file"; then
        sendErrorMessage "The file '$file' does not exist"
        return 1
    fi

    local permissions=$(stat -c '%a' "$file")

    echo "$permissions"
    return 0
}

# Get file access time
# $1: The file
function getFileAccessTime() {
    local file="$1"

    if [ -z "$file" ]; then
        sendErrorMessage "You must specify a file"
        return 1
    fi

    if ! isFileExists "$file"; then
        sendErrorMessage "The file '$file' does not exist"
        return 1
    fi

    local accessTime=$(stat -c '%x' "$file")

    echo "$accessTime"
    return 0
}

# Get file modification time
# $1: The file
function getFileModificationTime() {
    local file="$1"

    if [ -z "$file" ]; then
        sendErrorMessage "You must specify a file"
        return 1
    fi

    if ! isFileExists "$file"; then
        sendErrorMessage "The file '$file' does not exist"
        return 1
    fi

    local modificationTime=$(stat -c '%y' "$file")

    echo "$modificationTime"
    return 0
}

# Get file change time
# $1: The file
function getFileChangeTime() {
    local file="$1"

    if [ -z "$file" ]; then
        sendErrorMessage "You must specify a file"
        return 1
    fi

    if ! isFileExists "$file"; then
        sendErrorMessage "The file '$file' does not exist"
        return 1
    fi

    local changeTime=$(stat -c '%z' "$file")

    echo "$changeTime"
    return 0
}

# Get file type
# $1: The file
function getFileType() {
    local file="$1"

    if [ -z "$file" ]; then
        sendErrorMessage "You must specify a file"
        return 1
    fi
    if ! isFileExists "$file"; then
        sendErrorMessage "The file '$file' does not exist"
        return 1
    fi
    local type=$(stat -c '%F' "$file")

    echo "$type"
    return 0
}

# Get file MIME type
# $1: The file
function getFileMimeType() {
    local file="$1"

    if [ -z "$file" ]; then
        sendErrorMessage "You must specify a file"
        return 1
    fi
    if ! isFileExists "$file"; then
        sendErrorMessage "The file '$file' does not exist"
        return 1
    fi
    local mimeType=$(file --mime-type -b "$file")

    echo "$mimeType"
    return 0
}

###
## "SET" Functions
###

# Set file owner
# $1: The file
# $2: The owner
function setFileOwner() {
    local file="$1"
    local owner="$2"

    if [ -z "$file" ]; then
        sendErrorMessage "You must specify a file"
        return 1
    fi
    if ! isFileExists "$file"; then
        sendErrorMessage "The file '$file' does not exist"
        return 1
    fi
    if [ -z "$owner" ]; then
        sendErrorMessage "You must specify a owner"
        return 1
    fi

    chown "$owner" "$file"
    return 0
}

# Set file group
# $1: The file
# $2: The group
function setFileGroup() {
    local file="$1"
    local group="$2"

    if [ -z "$file" ]; then
        sendErrorMessage "You must specify a file"
        return 1
    fi
    if ! isFileExists "$file"; then
        sendErrorMessage "The file '$file' does not exist"
        return 1
    fi
    if [ -z "$group" ]; then
        sendErrorMessage "You must specify a group"
        return 1
    fi

    chgrp "$group" "$file"
    return 0
}

# Set file permissions
# $1: The file
# $2: The permissions
function setFilePermissions() {
    local file="$1"
    local permissions="$2"

    if [ -z "$file" ]; then
        sendErrorMessage "You must specify a file"
        return 1
    fi
    if ! isFileExists "$file"; then
        sendErrorMessage "The file '$file' does not exist"
        return 1
    fi
    if [ -z "$permissions" ]; then
        sendErrorMessage "You must specify a permissions"
        return 1
    fi

    chmod "$permissions" "$file"
    return 0
}

# Set file access time
# $1: The file
# $2: The access time
function setFileAccessTime() {
    local file="$1"
    local accessTime="$2"

    if [ -z "$file" ]; then
        sendErrorMessage "You must specify a file"
        return 1
    fi
    if ! isFileExists "$file"; then
        sendErrorMessage "The file '$file' does not exist"
        return 1
    fi
    if [ -z "$accessTime" ]; then
        sendErrorMessage "You must specify a access time"
        return 1
    fi

    touch -a -m -t "$accessTime" "$file"
    return 0
}

# Set file modification time
# $1: The file
# $2: The modification time
function setFileModificationTime() {
    local file="$1"
    local modificationTime="$2"

    if [ -z "$file" ]; then
        sendErrorMessage "You must specify a file"
        return 1
    fi
    if ! isFileExists "$file"; then
        sendErrorMessage "The file '$file' does not exist"
        return 1
    fi
    if [ -z "$modificationTime" ]; then
        sendErrorMessage "You must specify a modification time"
        return 1
    fi

    touch -m -t "$modificationTime" "$file"
    return 0
}

# Set file change time
# $1: The file
# $2: The change time
function setFileChangeTime() {
    local file="$1"
    local changeTime="$2"

    if [ -z "$file" ]; then
        sendErrorMessage "You must specify a file"
        return 1
    fi
    if ! isFileExists "$file"; then
        sendErrorMessage "The file '$file' does not exist"
        return 1
    fi
    if [ -z "$changeTime" ]; then
        sendErrorMessage "You must specify a change time"
        return 1
    fi

    touch -c -m -t "$changeTime" "$file"
    return 0
}

###
## Others Functions
###

# Check string start with
# $1: The string
# $2: The haystack
function startsWith() {
    local string="$1"
    local haystack="$2"

    if [ -z "$string" ]; then
        sendErrorMessage "You must specify a string"
        return 1
    fi

    if [ -z "$haystack" ]; then
        sendErrorMessage "You must specify a haystack"
        return 1
    fi

    case "$haystack" in
    "$string"*) return 0 ;;
    *) return 1 ;;
    esac
}

# Check string end with
# $1: The string
# $2: The haystack
function endsWith() {
    local string="$1"
    local haystack="$2"

    if [ -z "$string" ]; then
        sendErrorMessage "You must specify a string"
        return 1
    fi

    if [ -z "$haystack" ]; then
        sendErrorMessage "You must specify a haystack"
        return 1
    fi

    case "$haystack" in
    *"$string") return 0 ;;
    *) return 1 ;;
    esac
}

# Check string contains
# $1: The string
# $2: The substring
function strContains() {
    local string="$1"
    local substring="$2"

    if [ -z "$string" ]; then
        sendErrorMessage "You must specify a string"
        return 1
    fi

    if [ -z "$substring" ]; then
        sendErrorMessage "You must specify a substring"
        return 1
    fi

    if [ "${string#*$substring}" != "$string" ]; then
        return 0
    fi

    return 1
}

# declare -A TRANSLATIONS

# # List all files in directory translate
# for file in $(ls -1 "$SOURCE_PATH/translate"); do
#     filePath="$SOURCE_PATH/translate/$file"
#     language=$(getFileNameWithoutExtension "$filePath")
# done

# # Translate a string
# # $1: The string
# # $2: The language (optional, default: en-US)
# function __() {
#     local string="$1"
#     local language="$2"

#     if [ -z "$string" ]; then
#         sendErrorMessage "You must specify a string"
#         return 1
#     fi

#     if [ -z "$language" ]; then
#         language="en-US"
#     fi

#     if [ "$language" == "en-US" ]; then
#         echo "$string"
#         return 0
#     fi

#     local availableLanguages=("en-US" "pt-BR")
#     if ! inArrayCaseInsensitive "$language" "${availableLanguages[@]}"; then
#         sendErrorMessage "The language '$language' is not available"
#         return 1
#     fi

#     local translation="${TRANSLATIONS[$language]}"
#     # local key=$(echo "$string" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
#     # local value=$(echo "$translation" | grep "$key=" | cut -d '=' -f2)

#     # if [ -z "$value" ]; then
#     #     echo "$string"
#     #     return 0
#     # fi

#     return 0
# }
