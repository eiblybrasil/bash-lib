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
# Variables
#
###
mysql_connection=""

###
#
# Functions
#
###

# Open a connection to the MySQL server
# $1: The database name
# $2: The user name
# $3: The password
# $4: The host
# $5: The port
# $6: The socket
# $7: The connection name
function openMysqlConnection() {
  local databaseName="$1"
  local userName="$2"
  local password="$3"
  local host="$4"
  local port="$5"
  local socket="$6"
  local connectionName="$7"

  if [ -z "$connectionName" ]; then
    connectionName="default"
  fi

  if [ -z "$databaseName" ]; then
    databaseName="mysql"
  fi

  if [ -z "$userName" ]; then
    userName="root"
  fi

  if [ -z "$password" ]; then
    password=""
  fi

  if [ -z "$host" ]; then
    host="localhost"
  fi

  if [ -z "$port" ]; then
    port="3306"
  fi

  if [ -z "$socket" ]; then
    socket="/var/run/mysqld/mysqld.sock"
  fi

  mysql_connection="$connectionName"
  mysql_connection+="|"
  mysql_connection+="$databaseName"
  mysql_connection+="|"
  mysql_connection+="$userName"
  mysql_connection+="|"
  mysql_connection+="$password"
  mysql_connection+="|"
  mysql_connection+="$host"
  mysql_connection+="|"
  mysql_connection+="$port"
  mysql_connection+="|"
  mysql_connection+="$socket"
}

# Close the connection to the MySQL server
function closeMysqlConnection() {
  mysql_connection=""
}
