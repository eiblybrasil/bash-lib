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

function doGenerateDHParam() {
  local bits="$1"
  local output="$2"
  local fast="$3"
  local overwrite="$4"

  if [ -z "$bits" ]; then
    bits="2048"
  fi

  if [ -z "$output" ]; then
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

