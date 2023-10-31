#!/bin/bash

SOURCE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

###
#
# Imports
#
###
source "$SOURCE_PATH/utils.sh"

# Constants
DEFAULT_USER_SHELL="/bin/bash"
DEFAULT_USER=$(getent passwd 1000 | cut -d: -f1)
DEFAULT_GROUP=$(getent group 1000 | cut -d: -f1)

###
## "IS" Functions
###

# Check if a user exists
# $1: The user name
function isUserExists() {
	local user="$1"

	if id -u "$user" >/dev/null 2>&1; then
		return 0
	fi

	return 1
}

# Check if a group exists
# $1: The group name
function isGroupExists() {
	local group="$1"

	if getent group "$group" >/dev/null 2>&1; then
		return 0
	fi

	return 1
}

# Check if a user is in a group
# $1: The user name
# $2: The group name
function isUserInGroup() {
	local user="$1"
	local group="$2"

	if id -nG "$user" | grep -qw "$group"; then
		return 0
	fi

	return 1
}

# Check if a user is in sudoers
# $1: The user name
function isUserInSudoers() {
	local user="$1"

	if grep -q "^$user" /etc/sudoers /etc/sudoers.d/*; then
		return 0
	fi

	return 1
}

###
## "DO" Functions
###

# Create a user
# $1: The user name
# $2: The user password
# $3: The user id (optional)
# $4: The user shell (optional)
# $5: The user home directory (optional)
# $6: The user group (optional)
# $7: The user group id (optional)
function doCreateUser() {
	local user="$1"
	local password="$2"
	local userId="$3"
	local userShell="$4"
	local userHomeDir="$5"
	local userGroup="$6"
	local userGroupId="$7"

	if [ -z "$user" ]; then
		sendErrorMessage "You must specify a user name"
		return 1
	fi

	if [ -z "$password" ]; then
		sendErrorMessage "You must specify a password"
		return 1
	fi

	if [ -z "$userId" ]; then
		userId=null
	fi

	if [ -z "$userShell" ]; then
		userShell="$DEFAULT_USER_SHELL"
	fi

	if [ -z "$userHomeDir" ]; then
		userHomeDir="/home/$user"
	fi

	if [ -z "$userGroup" ]; then
		userGroup="$DEFAULT_GROUP"
	fi

	if [ -z "$userGroupId" ]; then
		userGroupId=null
	fi

	if isUserExists "$user"; then
		sendErrorMessage "The user '$user' already exists"
		return 1
	fi

	if isGroupExists "$userGroup"; then
		sendErrorMessage "The group '$userGroup' already exists"
		return 1
	fi

	groupadd -g "$userGroupId" "$userGroup"
	useradd -u "$userId" -g "$userGroup" -d "$userHomeDir" -s "$userShell" -m "$user"
	echo "$user:$password" | chpasswd
}

function doChangeUserPassword() {
	local userName="$1"
	local password="$2"

	if [ -z "$userName" ]; then
		userName="root"
	fi

	if [ -z "$password" ]; then
		sendErrorMessage "You must specify a password"
		return 1
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
		return 1
	fi

	local maxWatches=$(su "$userName" -c "cat /proc/sys/fs/inotify/max_user_watches")

	echo "$maxWatches"
}

function getUserMaxInotifyInstances() {
	local userName="$1"

	if [ -z "$userName" ]; then
		sendErrorMessage "You must specify a user name"
		return 1
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
		return 1
	fi

	if [ -z "$groupName" ]; then
		sendErrorMessage "You must specify a group name"
		return 1
	fi

	usermod -a -G "$groupName" "$userName"
}

function setUserMaxInotifyWatches() {
	local userName="$1"
	local maxWatches="$2"

	if [ -z "$userName" ]; then
		sendErrorMessage "You must specify a user name"
		return 1
	fi

	if [ -z "$maxWatches" ]; then
		sendErrorMessage "You must specify a max watches value"
		return 1
	fi

	# Defaukt value is 65536

	su "$userName" -c "echo $maxWatches > /proc/sys/fs/inotify/max_user_watches"
}

function setUserMaxInotifyInstances() {
	local userName="$1"
	local maxInstances="$2"

	if [ -z "$userName" ]; then
		sendErrorMessage "You must specify a user name"
		return 1
	fi

	if [ -z "$maxInstances" ]; then
		sendErrorMessage "You must specify a max instances value"
		return 1
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
		return 1
	fi

	if [ -z "$groupName" ]; then
		sendErrorMessage "You must specify a group name"
		return 1
	fi

	gpasswd -d "$userName" "$groupName"
}
