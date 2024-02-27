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

NGINX_DIRECTORY="/etc/nginx"
CACHE_DIRECTORY="/var/cache/nginx"

# Create a directory for cache
# $1: The domain
function doCreateCacheDirectory() {
    local domain="$1"

    domain=$(doDomainToUnderDomain "$domain")

    if isDirExists "$CACHE_DIRECTORY/$domain"; then
        return 0
    fi

    if ! doCreateDirectory "$CACHE_DIRECTORY/$domain" "www-data" "www-data" "0700"; then
        return 1
    fi

    return 0
}

# Create a site server
# $1: The domain
function doCreateServer() {
    local domain="$1"
}

# Enable a site server
# $1: The domain
function doEnableServer() {
    local domain="$1"
}

# Create a reverse proxy
# $1: The domain
# $2: The name
function doCreateReserveProxy() {
    local domain="$1"
    local name="$2"
}

# Enable a site server
# $1: Reverse Proxy ID
function doEnableReserveProxy() {
    local reverse_proxy_id="$1"
}

# Create load balancer
# $1: The domain
# $2: The name
# $3: The servers
function doCreateLoadBalancer() {
    local domain="$1"
    local name="$2"
    local servers="$3"

    if isEmpty "$domain"; then
        sendErrorMessage "The domain is required."
        return 1
    fi

    if isEmpty "$name"; then
        sendErrorMessage "The load balancer name is required."
        return 1
    fi

    if isEmpty "$servers"; then
        sendErrorMessage "The servers is required."
        return 1
    fi

    if isFileExists "$file"; then
        local data=$(cat "$file")
        # Check upstream_name already exists
        echo "$data"
    fi

    domain=$(doDomainToUnderDomain "$domain")
    name=$(doStringSlug "$name" "_")

    local load_balancer_id=$(doGenerateUUIDv4)
    local file="$NGINX_DIRECTORY/upstream-available/$load_balancer_id.conf"
    local load_balancer=$(printf "%s\n" \
        "# Load Balancer ID: $load_balancer_id, Name: $name" \
        "upstream lb_${domain}_${name} {")
    servers=$(echo "$servers" | tr "," "\n")

    for server in $servers; do
        local server_address=""
        local server_port=""
        # Check server is ipv6 with port [ipv6]:port
        if [[ "$server" =~ ^\[.*\]:[0-9]+$ ]]; then
            server_address=$(echo "$server" | cut -d "]" -f 1 | cut -d "[" -f 2)
            server_port=$(echo "$server" | cut -d "]" -f 2 | cut -d ":" -f 2)

            if ! isValidIPv6 "$server_address"; then
                sendErrorMessage "The server ipv6 '$server_address' is not valid."
                return 1
            fi

            if ! isValidPort "$server_port"; then
                sendErrorMessage "The server port '$server_port' is not valid."
                return 1
            fi
        else
            if strContains "$server" ":"; then
                server_address=$(echo "$server" | cut -d ":" -f 1)
                server_port=$(echo "$server" | cut -d ":" -f 2)
            else
                server_address="$server"
                server_port="80"
            fi

            if ! isValidIPv4 "$server_address" && ! isValidHostname "$server_address"; then
                sendErrorMessage "The server ipv4 or hostname '$server_address' is not valid, if you want to use a ipv6, use [ipv6]:port."
                return 1
            fi

            if ! isValidPort "$server_port"; then
                sendErrorMessage "The server port '$server_port' is not valid."
                return 1
            fi
        fi

        load_balancer=$(printf "%s\n" "$load_balancer" \
            "    # Server ID: $(doGenerateUUIDv4)" \
            "    server $server;")
    done

    load_balancer=$(printf "%s\n" "$load_balancer" "}")
    echo "$load_balancer" >"$file"
    if $? -ne 0; then
        sendErrorMessage "Failed to create load balancer."
        return 1
    fi

    echo "$load_balancer_id"
    return 0
}

# Enable load balancer
# $1: The load balancer ID
function doEnableLoadBalancer() {
    local load_balancer_id="$1"

    if isEmpty "$load_balancer_id"; then
        sendErrorMessage "The load balancer ID is required."
        return 1
    fi

    if isValidUUIDv4 "$load_balancer_id"; then
        sendErrorMessage "The load balancer ID '$load_balancer_id' is not valid."
        return 1
    fi

    local file="$NGINX_DIRECTORY/upstream-available/$load_balancer_id.conf"
    if ! isFileExists "$file"; then
        sendErrorMessage "The load balancer '$load_balancer_id' not exists."
        return 1
    fi

    local file_link="$NGINX_DIRECTORY/upstream-enabled/$load_balancer_id.conf"
    if isFileExists "$file_link"; then
        sendErrorMessage "The load balancer '$load_balancer_id' already enabled."
        return 1
    fi

    if ! doCreateSymlink "$file" "$file_link"; then
        sendErrorMessage "Failed to enable load balancer '$load_balancer_id'."
        return 1
    fi

    return 0
}

# Disable load balancer
# $1: The load balancer ID
function doDisableLoadBalancer() {
    local load_balancer_id="$1"

    if isEmpty "$load_balancer_id"; then
        sendErrorMessage "The load balancer ID is required."
        return 1
    fi

    if isValidUUIDv4 "$load_balancer_id"; then
        sendErrorMessage "The load balancer ID '$load_balancer_id' is not valid."
        return 1
    fi

    local file_link="$NGINX_DIRECTORY/upstream-enabled/$load_balancer_id.conf"
    if ! isFileExists "$file_link"; then
        sendErrorMessage "The load balancer '$load_balancer_id' not enabled."
        return 1
    fi

    if ! doRemoveSymlink "$file_link"; then
        sendErrorMessage "Failed to disable load balancer '$load_balancer_id'."
        return 1
    fi

    return 0
}

# Add a server to load balancer
# $1: The load balancer ID
# $2: The server
function addServerToLoadBalancer() {
    local load_balancer_id="$1"
    local server="$2"

    if isEmpty "$load_balancer_id"; then
        sendErrorMessage "The load balancer ID is required."
        return 1
    fi

    if isValidUUIDv4 "$load_balancer_id"; then
        sendErrorMessage "The load balancer ID '$load_balancer_id' is not valid."
        return 1
    fi

    local file="$NGINX_DIRECTORY/upstream-available/$load_balancer_id.conf"
    if ! isFileExists "$file"; then
        sendErrorMessage "The load balancer '$load_balancer_id' not exists."
        return 1
    fi
}

