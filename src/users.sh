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

# "IS" Functions

function isUserExists() {
	local user="$1"

	if id -u "$user" >/dev/null 2>&1; then
		return 0
	else
		return 1
	fi
}

function isGroupExists() {
	local group="$1"

	if getent group "$group" >/dev/null 2>&1; then
		return 0
	else
		return 1
	fi
}

function isUserInGroup() {
	local user="$1"
	local group="$2"

	if id -nG "$user" | grep -qw "$group"; then
		return 0
	else
		return 1
	fi
}

function isUserInSudoers() {
	local user="$1"

	if grep -q "^$user" /etc/sudoers /etc/sudoers.d/*; then
		return 0
	else
		return 1
	fi
}

# "DO" Functions

function doChangeUserPassword() {
	local userName="$1"
	local password="$2"

	if [ -z "$userName" ]; then
		userName="root"
	fi

	if [ -z "$password" ]; then
		sendErrorMessage "You must specify a password"
		exit 1
	fi

	passwd "$userName" <<EOF
$password
$password
EOF
}

# "GET" Functions

function getUserEx() {
    awk -F: -v user="$1" '$1 == user {print length($1)}' /etc/passwd
}

function getGroupEx() {
    if getent group "$1" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

function getUserMaxInotifyWatches() {
	local userName="$1"

	if [ -z "$userName" ]; then
		sendErrorMessage "You must specify a user name"
		exit 1
	fi

	local maxWatches=$(su "$userName" -c "cat /proc/sys/fs/inotify/max_user_watches")

	echo "$maxWatches"
}

function getUserMaxInotifyInstances() {
	local userName="$1"

	if [ -z "$userName" ]; then
		sendErrorMessage "You must specify a user name"
		exit 1
	fi

	local maxInstances=$(su "$userName" -c "cat /proc/sys/fs/inotify/max_user_instances")

	echo "$maxInstances"
}

# "SET" Functions
function setUserToGroup() {
	local userName="$1"
	local groupName="$2"

	if [ -z "$userName" ]; then
		sendErrorMessage "You must specify a user name"
		exit 1
	fi

	if [ -z "$groupName" ]; then
		sendErrorMessage "You must specify a group name"
		exit 1
	fi

	usermod -a -G "$groupName" "$userName"
}

function setUserMaxInotifyWatches() {
	local userName="$1"
	local maxWatches="$2"

	if [ -z "$userName" ]; then
		sendErrorMessage "You must specify a user name"
		exit 1
	fi

	if [ -z "$maxWatches" ]; then
		sendErrorMessage "You must specify a max watches value"
		exit 1
	fi

	# Defaukt value is 65536

	su "$userName" -c "echo $maxWatches > /proc/sys/fs/inotify/max_user_watches"
}

function setUserMaxInotifyInstances() {
	local userName="$1"
	local maxInstances="$2"

	if [ -z "$userName" ]; then
		sendErrorMessage "You must specify a user name"
		exit 1
	fi

	if [ -z "$maxInstances" ]; then
		sendErrorMessage "You must specify a max instances value"
		exit 1
	fi

	# Default value is 128

	su "$userName" -c "echo $maxInstances > /proc/sys/fs/inotify/max_user_instances"
}

# "REMOVE" Functions

function removeUserFromGroup() {
	local userName="$1"
	local groupName="$2"

	if [ -z "$userName" ]; then
		sendErrorMessage "You must specify a user name"
		exit 1
	fi

	if [ -z "$groupName" ]; then
		sendErrorMessage "You must specify a group name"
		exit 1
	fi

	gpasswd -d "$userName" "$groupName"
}
