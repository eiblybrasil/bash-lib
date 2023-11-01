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

# Check if the current user is root
function isRoot() {
	if [ "$EUID" -ne 0 ]; then
		return 1
	fi

	return 0
}

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
# $2: The user password (if 0, the user will not be able to login, if null, the random password will be generated)
# $3: The user id (optional, if 0, the next available id will be used)
# $4: The user shell (optional)
# $5: The user home directory (optional)
# $6: The user group (optional)
# $7: The user group id (optional, if 0, the next available id will be used)
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
	user=$(doStringToLower "$user")

	if [ -z "$password" ]; then
		password=$(doGeneratePassword)
	elif [ "$password" == "0" ]; then
		password=0
	fi

	if [ -z "$userId" ]; then
		userId=0
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
		userGroupId=0
	fi

	if isUserExists "$user"; then
		sendWarningMessage "The user '$user' already exists"
		return 1
	fi

	if isGroupExists "$userGroup"; then
		sendWarningMessage "The group '$userGroup' already exists"
		return 1
	fi
	local command="groupadd"
	if [ "$userGroupId" -ne 0 ]; then
		command="$command --gid $userGroupId"
	fi
	command="$command $userGroup"

	if ! doRunCommandSilent "$command"; then
		sendErrorMessage "Failed to create group '$userGroup'"
		return 1
	fi

	command="useradd --create-home --shell $userShell --home-dir $userHomeDir"
	if [ "$userId" -ne 0 ]; then
		command="$command --uid $userId"
	fi
	if [ "$userGroupId" -ne 0 ]; then
		command="$command --gid $userGroupId"
	fi
	if [ "$password" != "0" ]; then
		command="$command --password $password"
	fi
	command="$command $user"

	if ! doRunCommandSilent "$command"; then
		sendErrorMessage "Failed to create user '$user'"
		return 1
	fi
}

# Change user password
# $1: The user name
# $2: The user password
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

###
## "GET" Functions
###

# Get current username
function getCurrentUsername() {
	if ! isCommandExists "whoami"; then
		sendErrorMessage "The command 'whoami' is required"
		return 1
	fi

	whoami
}

# Get current user id
function getCurrentUserId() {
	if ! isCommandExists "id"; then
		sendErrorMessage "The command 'id' is required"
		return 1
	fi

	id -u
}

# Get User ID by name
# $1: The user name
function getUserEx() {
	local userName="$1"

	if [ -z "$userName" ]; then
		sendErrorMessage "You must specify a user name"
		return 1
	fi

	if ! isCommandExists "awk"; then
		sendErrorMessage "The command 'awk' is required"
		return 1
	fi

	awk -F: -v user="$userName" '$1 == user {print length($1)}' /etc/passwd
	return 0
}

# Get Group ID by name
# $1: The group name
function getGroupEx() {
	local groupName="$1"

	if [ -z "$userName" ]; then
		sendErrorMessage "You must specify a user name"
		return 1
	fi

	if ! isCommandExists "getent"; then
		sendErrorMessage "The command 'getent' is required"
		return 1
	fi

	if getent group "$groupName" >/dev/null 2>&1; then
		return 0
	fi

	return 1
}

# Get User max inotify watches
# $1: The user name
function getUserMaxInotifyWatches() {
	local userName="$1"

	if [ -z "$userName" ]; then
		sendErrorMessage "You must specify a user name"
		return 1
	fi

	local maxWatches=$(su "$userName" -c "cat /proc/sys/fs/inotify/max_user_watches")

	echo "$maxWatches"
}

# Get User max inotify instances
# $1: The user name
function getUserMaxInotifyInstances() {
	local userName="$1"

	if [ -z "$userName" ]; then
		sendErrorMessage "You must specify a user name"
		return 1
	fi

	local maxInstances=$(su "$userName" -c "cat /proc/sys/fs/inotify/max_user_instances")

	echo "$maxInstances"
}

###
## "SET" Functions
###

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

###
## "REMOVE" Functions
###

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
