#!/bin/bash

# Supported OS types
# 1. CentOS
# 2. Oracle Linux
# 3. Fedora
# 4. Amazon Linux
# 5. Arch Linux
# 6. Debian
# 7. Ubuntu
# 8. Alpine Linux
# 9. Gentoo
# 10. openSUSE

###
#
# Variables
#
###
export OS_TYPE=""
export OS_DISTRO=""
export OS_VERSION=""
export OS_ARCH=""
export OS_CODENAME=""
export SERVICE_CMD=""

SOURCE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# Check OS Type (Linux or Windows)
if [ "$(uname -s)" == "Linux" ]; then
    OS_TYPE="linux"
else
    OS_TYPE="Unknown"
fi

# Check OS Distro
if [ -f /etc/redhat-release ]; then
    if [ -f /etc/oracle-release ]; then
        OS_DISTRO="oracle"
    elif [ -f /etc/fedora-release ]; then
        OS_DISTRO="fedora"
    elif [ -f /etc/amzn-release ]; then
        OS_DISTRO="amazon"
    else
        OS_DISTRO="centos"
    fi
elif [ -f /etc/arch-release ]; then
    OS_DISTRO="arch"
elif [ -f /etc/alpine-release ]; then
    OS_DISTRO="alpine"
elif grep -qi "debian" /etc/issue; then
    OS_DISTRO="debian"
elif grep -qi "ubuntu" /etc/issue; then
    OS_DISTRO="ubuntu"
elif [ -f /etc/gentoo-release ]; then
    OS_DISTRO="gentoo"
elif [ -f /etc/SuSE-release ] || [ -f /etc/os-release ] && grep -qi "opensuse" /etc/os-release; then
    OS_DISTRO="opensuse"
fi

# Check OS version
if [ "$OS_DISTRO" == "arch" ]; then
    OS_VERSION="arch"
elif [ -f /etc/os-release ]; then
    OS_VERSION=$(grep -oP '(?<=VERSION_ID=").*(?=")' /etc/os-release)
elif [ -f /etc/debian_version ]; then
    OS_VERSION=$(cat /etc/debian_version)
elif [ -f /etc/alpine-release ]; then
    OS_VERSION=$(cat /etc/alpine-release)
elif [ -f /etc/gentoo-release ]; then
    OS_VERSION=$(cat /etc/gentoo-release)
elif [ -f /etc/SuSE-release ]; then
    OS_VERSION=$(grep -oP '(?<=VERSION = ).*' /etc/SuSE-release)
fi

# Check Architecture
OS_ARCH=$(uname -m)
case "$OS_ARCH" in
x86_64)
    OS_ARCH="x64"
    ;;
i[3456]86)
    OS_ARCH="x86"
    ;;
esac

# Check OS Codename
if [ "$OS_DISTRO" == "debian" ] || [ "$OS_DISTRO" == "ubuntu" ]; then
    if [ -f /etc/os-release ]; then
        OS_CODENAME=$(grep -oP '(?<=VERSION_CODENAME=").*(?=")' /etc/os-release)
        if [ "$OS_CODENAME" == "" ] && [ -f /etc/lsb-release ]; then
            OS_CODENAME=$(grep -oP '(?<=DISTRIB_CODENAME=).+' /etc/lsb-release)
        fi
    elif [ -f /etc/lsb-release ]; then
        OS_CODENAME=$(grep -oP '(?<=DISTRIB_CODENAME=).+' /etc/lsb-release)
    fi
elif [ "$OS_DISTRO" == "alpine" ]; then
    OS_CODENAME="N/A"
elif [ "$OS_DISTRO" == "gentoo" ]; then
    OS_CODENAME="N/A"
elif [ "$OS_DISTRO" == "opensuse" ]; then
    OS_CODENAME=$(grep -oP '(?<=VERSION = ).*' /etc/SuSE-release)
fi

# Check available service command
if command -v systemctl >/dev/null 2>&1; then
    SERVICE_CMD="systemctl"
elif command -v service >/dev/null 2>&1; then
    SERVICE_CMD="service"
fi

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

function isCommandExists() {
    local command="$1"

    if command -v "$command" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

function isFolderExists() {
    local folder="$1"

    if [ -d "$folder" ]; then
        return 0
    else
        return 1
    fi
}

function isFileExists() {
    local file="$1"

    if [ -f "$file" ]; then
        return 0
    else
        return 1
    fi
}

function isPackageInstalled() {
    local package="$1"

    case "$OS_TYPE" in
    linux)
        case "$OS_DISTRO" in
        centos | oracle | fedora | amazon)
            rpm -q "$package" &>/dev/null && return 0 || return 1
            ;;
        debian | ubuntu)
            dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q "install ok installed" && return 0 || return 1
            ;;
        arch)
            pacman -Qs "$package" &>/dev/null && return 0 || return 1
            ;;
        alpine)
            apk -q info "$package" >/dev/null 2>&1 && return 0 || return 1
            ;;
        gentoo)
            equery -q list "$package" >/dev/null 2>&1 && return 0 || return 1
            ;;
        opensuse)
            zypper search -i "$package" >/dev/null 2>&1 && return 0 || return 1
            ;;
        *)
            sendMessage "Distribution not supported: $OS_DISTRO" "ERROR"
            return 1
            ;;
        esac
        ;;
    *)
        sendMessage "OS not supported: $OS_TYPE" "ERROR"
        return 1
        ;;
    esac
}

function isServiceEnabled() {
    local service="$1"

    if [ "$SERVICE_CMD" = "systemctl" ]; then
        if systemctl is-enabled "$service" &>/dev/null; then
            return 0
        else
            return 1
        fi
    elif [ "$SERVICE_CMD" = "service" ]; then
        for i in $(find /etc/rc*.d -name S*); do
            local service_name=$(basename "$i" | sed 's/^S[0-9]\{1,2\}//')
            if [ "$service_name" = "$service" ]; then
                return 0
            fi
        done
    else
        sendMessage "Not supported service command!" "ERROR"
        return 1
    fi

    return 1
}

function isServiceRunning() {
    local service="$1"

    if [ "$SERVICE_CMD" = "systemctl" ]; then
        if systemctl is-active "$service" &>/dev/null; then
            return 0
        fi
    elif [ "$SERVICE_CMD" = "service" ]; then
        if service "$service" status &>/dev/null; then
            return 0
        fi
    else
        sendMessage "Not supported service command!" "ERROR"
        return 1
    fi

    return 1
}

function isServiceExists() {
    local service="$1"

    if [ "$SERVICE_CMD" = "systemctl" ]; then
        if systemctl status "$service" &>/dev/null; then
            return 0
        else
            return 1
        fi
    elif [ "$SERVICE_CMD" = "service" ]; then
        if service "$service" status &>/dev/null; then
            return 0
        else
            return 1
        fi
    else
        sendMessage "Not supported service command!" "ERROR"
        return 1
    fi
}

# "DO" Functions

function doEnableServiceOnStartup() {
    local service="$1"
    local isEnabled=$(isServiceEnabled "$service")

    if [[ "$isEnabled" == "enabled" ]]; then
        sendMessage "$service already enabled on system startup." "OK"
        return 0
    fi

    if [ "$SERVICE_CMD" = "systemctl" ]; then
        sendMessage "Trying to enable $service on system startup..." "INFO"
        systemctl enable "$service" &>/dev/null

        isEnabled=$(isServiceEnabled "$service")

        if [[ "$isEnabled" == "enabled" ]]; then
            sendMessage "$service enabled successfully on system startup." "OK"
            return 0
        else
            sendMessage "Unable to enable $service on system startup." "WARNING"
            return 1
        fi
    elif [ "$SERVICE_CMD" = "service" ]; then
        sendMessage "Trying to enable $service on system startup..." "INFO"
        update-rc.d "$service" defaults &>/dev/null

        isEnabled=$(isServiceEnabled "$service")

        if [[ "$isEnabled" == "enabled" ]]; then
            sendMessage "$service enabled successfully on system startup." "OK"
            return 0
        else
            sendMessage "Unable to enable $service on system startup." "WARNING"
            return 1
        fi
    else
        sendMessage "Not supported service command!" "ERROR"
        return 1
    fi
}

function doStartPackage() {
    local service="$1"
    local isActive=$(isServiceRunning "$service")

    if [[ "$isActive" == "active" ]]; then
        sendMessage "$service already running." "OK"
        return 0
    fi

    if [ "$SERVICE_CMD" = "systemctl" ]; then
        systemctl start "$service" &>/dev/null
    elif [ "$SERVICE_CMD" = "service" ]; then
        service "$service" start &>/dev/null
    else
        sendMessage "Not supported service command!" "ERROR"
        return 1
    fi

    return 0
}

function doRestartPackage() {
    local service="$1"
    local isActive=$(isServiceRunning "$service")

    if [[ "$isActive" == "active" ]]; then
        sendMessage "Trying to restart $service..." "INFO"
        if [ "$SERVICE_CMD" = "systemctl" ]; then
            systemctl restart "$service" &>/dev/null
        elif [ "$SERVICE_CMD" = "service" ]; then
            service "$service" restart &>/dev/null
        else
            sendMessage "Not supported service command!" "ERROR"
            return 1
        fi

        isActive=$(isServiceRunning "$service")

        if [[ "$isActive" == "active" ]]; then
            sendMessage "$service restarted successfully." "OK"
            return 0
        else
            sendMessage "Unable to restart $service." "WARNING"
            return 1
        fi
    else
        sendMessage "$service is not running." "WARNING"
        return 1
    fi
}

function doStartAndEnablePackage() {
    local service="$1"
    local isActive=$(isServiceRunning "$service")
    local isEnabled$(isServiceEnabled "$service")

    if [[ "$isActive" == "active" ]]; then
        sendMessage "$service already running." "OK"

        if [[ "$isEnabled" == "enabled" ]]; then
            sendMessage "$service already enabled on system startup." "OK"
            return 0
        else
            doEnableServiceOnStartup "$service"
        fi
    else
        doStartPackage "$service"

        if [[ "$isEnabled" == "enabled" ]]; then
            sendMessage "$service already enabled on system startup." "OK"
            return 0
        else
            doEnableServiceOnStartup "$service"
        fi
    fi
}

function doDisableAndStopPackage() {
    local service="$1"
    local isEnabled=$(isServiceEnabled "$service")
    local isActive=$(isServiceRunning "$service")

    if [[ "$isEnabled" == "disabled" ]]; then
        sendMessage "$service already disabled on system startup." "OK"

        if [[ "$isActive" == "inactive" ]]; then
            sendMessage "$service already stopped." "OK"
            return 0
        else
            doStopPackage "$service"
        fi
    else
        doDisableServiceOnStartup "$service"

        if [[ "$isActive" == "inactive" ]]; then
            sendMessage "$service already stopped." "OK"
            return 0
        else
            doStopPackage "$service"
        fi
    fi

    return 0
}

function doInstallPackage() {
    local package="$1"
    local DEBUG

    case "$OS_TYPE" in
    linux)
        case "$OS_DISTRO" in
        debian | ubuntu)
            DEBUG=$(apt-get install -y "$package" 2>&1 | grep 'E:' | awk -F 'E:' 'NR==1{print $2}' | xargs echo -n)
            if isPackageInstalled "$package"; then
                return 0
            fi
            ;;
        centos | oracle | fedora | amazon)
            DEBUG=$(yum install -y "$package" 2>&1 | grep 'Error:' | awk -F 'Error:' 'NR==1{print $2}' | xargs echo -n)
            if isPackageInstalled "$package"; then
                return 0
            fi
            ;;
        arch)
            DEBUG=$(pacman -S --noconfirm "$package" 2>&1 | grep 'error:' | awk -F 'error:' 'NR==1{print $2}' | xargs echo -n)
            if isPackageInstalled "$package"; then
                return 0
            fi
            ;;
        alpine)
            DEBUG=$(apk add "$package" 2>&1 | grep 'ERROR:' | awk -F 'ERROR:' 'NR==1{print $2}' | xargs echo -n)
            if isPackageInstalled "$package"; then
                return 0
            fi
            ;;
        gentoo)
            DEBUG=$(emerge "$package" 2>&1 | grep '!!!' | awk -F '!!!' 'NR==1{print $2}' | xargs echo -n)
            if isPackageInstalled "$package"; then
                return 0
            fi
            ;;
        opensuse)
            DEBUG=$(zypper install -y "$package" 2>&1 | grep 'Error:' | awk -F 'Error:' 'NR==1{print $2}' | xargs echo -n)
            if isPackageInstalled "$package"; then
                return 0
            fi
            ;;
        *)
            sendMessage "Distribution not supported: $distro" "ERROR"
            return 1
            ;;
        esac
        ;;
    *)
        sendMessage "OS not supported: $OS_TYPE" "ERROR"
        return 1
        ;;
    esac

    sendMessage "Unable to install $package." "WARNING"
    sendMessage "$DEBUG" "ERROR"
    return 1
}

function doInstallPackages() {
    local packages=("$@")
    local packagesCount="${#packages[@]}"
    local packagesInstalled=0
    local packagesFailed=0

    for package in "${packages[@]}"; do
        if doInstallPackage "$package"; then
            packagesInstalled=$((packagesInstalled + 1))
        else
            packagesFailed=$((packagesFailed + 1))
        fi
    done

    if ((packagesInstalled > 0)); then
        sendMessage "$packagesInstalled/$packagesCount packages have been successfully installed." "SUCCESS"
    fi

    if ((packagesFailed > 0)); then
        sendMessage "$packagesFailed/$packagesCount packages cannot be installed." "WARNING"
    fi

    if ((packagesInstalled > 0)) && ((packagesFailed == 0)); then
        return 0
    else
        return 1
    fi
}

function doUpdatePackages() {
    sendMessage "Trying to update packages..." "INFO"

    case "$OS_TYPE" in
    linux)
        case "$OS_DISTRO" in
        debian | ubuntu)
            if apt-get -y update &>/dev/null; then
                sendMessage "The packages have been successfully updated." "SUCCESS"
                return 0
            fi
            ;;
        centos | oracle | fedora | amzn)
            if dnf -y update &>/dev/null; then
                sendMessage "The packages have been successfully updated." "SUCCESS"
                return 0
            fi
            ;;
        arch)
            if pacman -Sy --noconfirm &>/dev/null; then
                sendMessage "The packages have been successfully updated." "SUCCESS"
                return 0
            fi
            ;;
        alpine)
            if apk update --no-cache &>/dev/null; then
                sendMessage "The packages have been successfully updated." "SUCCESS"
                return 0
            fi
            ;;
        *)
            sendMessage "Distribution not supported: $distro" "ERROR"
            return 1
            ;;
        esac
        ;;
    *)
        sendMessage "OS not supported: $OS_TYPE" "ERROR"
        return 1
        ;;
    esac

    sendMessage "The packages cannot be updated." "WARNING"
    return 1
}

function doUpgradePackages() {
    case "$OS_TYPE" in
    linux)
        case "$OS_DISTRO" in
        debian | ubuntu)
            if apt-get -y dist-upgrade &>/dev/null; then
                sendMessage "The packages have been successfully upgraded." "SUCCESS"
                return 0
            fi
            ;;
        centos | oracle | fedora | amzn)
            if dnf -y upgrade &>/dev/null; then
                sendMessage "The packages have been successfully upgraded." "SUCCESS"
                return 0
            fi
            ;;
        arch)
            if pacman -Syu --noconfirm &>/dev/null; then
                sendMessage "The packages have been successfully upgraded." "SUCCESS"
                return 0
            fi
            ;;
        alpine)
            if apk upgrade --no-cache &>/dev/null; then
                sendMessage "The packages have been successfully upgraded." "SUCCESS"
                return 0
            fi
            ;;
        *)
            sendMessage "Distribution not supported: $distro" "ERROR"
            return 1
            ;;
        esac
        ;;
    *)
        sendMessage "OS not supported: $OS_TYPE" "ERROR"
        return 1
        ;;
    esac

    sendMessage "The packages cannot be upgraded." "WARNING"
    return 1
}

function doCleanPackages() {
    sendMessage "Trying to clean packages..." "INFO"

    case "$OS_TYPE" in
    linux)
        case "$OS_DISTRO" in
        debian | ubuntu)
            if apt-get -y autoremove &>/dev/null; then
                sendMessage "The packages have been successfully cleaned." "SUCCESS"
                return 0
            fi
            ;;
        centos | oracle | fedora | amzn)
            if dnf -y autoremove &>/dev/null; then
                sendMessage "The packages have been successfully cleaned." "SUCCESS"
                return 0
            fi
            ;;
        arch)
            if pacman -Rns --noconfirm $(pacman -Qtdq) &>/dev/null; then
                sendMessage "The packages have been successfully cleaned." "SUCCESS"
                return 0
            fi
            ;;
        alpine)
            if apk autoremove --no-cache &>/dev/null; then
                sendMessage "The packages have been successfully cleaned." "SUCCESS"
                return 0
            fi
            ;;
        *)
            sendMessage "Distribution not supported: $distro" "ERROR"
            return 1
            ;;
        esac
        ;;
    *)
        sendMessage "OS not supported: $OS_TYPE" "ERROR"
        return 1
        ;;
    esac

    sendMessage "The packages cannot be cleaned." "WARNING"
    return 1
}

function doRunScreen() {
    local userName="$1"
    local command="$2"

    if [ -z "$userName" ]; then
        sendMessage "No user name provided." "ERROR"
        return 1
    fi

    if [ -z "$command" ]; then
        sendMessage "No command provided." "ERROR"
        return 1
    fi

    if ! isCommandExists "screen"; then
        sendMessage "Screen is not installed." "ERROR"
        return 1
    fi

    if ! isUserExists "$userName"; then
        sendMessage "User $userName does not exist." "ERROR"
        return 1
    fi
}

# "GET" Functions

function getTimezone() {
    if ! isCommandExists "timedatectl"; then
        sendMessage "Timedatectl is not installed." "ERROR"
        return 1
    fi

    local timezone=$(timedatectl | grep "Time zone" | awk '{print $3}')
    if [[ -z "$timezone" ]]; then
        sendMessage "Unable to get timezone." "ERROR"
        return 1
    fi

    echo "$timezone"
}

# "SET" Functions

function setTimezone() {
    local timezone="$1"

    if [[ -z "$timezone" ]]; then
        sendMessage "No timezone provided." "ERROR"
        return 1
    fi

    if ! isCommandExists "timedatectl"; then
        sendMessage "Timedatectl is not installed." "ERROR"
        return 1
    fi

    sendMessage "Trying to set timezone to $timezone..." "INFO"
    if timedatectl set-timezone "$timezone" &>/dev/null; then
        sendMessage "Timezone set to $timezone." "OK"
        return 0
    else
        sendMessage "Unable to set timezone to $timezone." "ERROR"
        return 1
    fi
}

function setAptArchiveUrl() {
    local url="$1"

    if [[ -z "$url" ]]; then
        sendMessage "No URL provided." "ERROR"
        return 1
    fi

    if ! isCommandExists "sed"; then
        sendMessage "Sed is not installed." "ERROR"
        return 1
    fi

    sendMessage "Trying to set APT archive URL to $url..." "INFO"
    if sed -i "s|http://archive.ubuntu.com/ubuntu/|$url|g" /etc/apt/sources.list &>/dev/null; then
        sendMessage "APT archive URL set to $url." "OK"
        return 0
    else
        sendMessage "Unable to set APT archive URL to $url." "ERROR"
        return 1
    fi
}

function setAptSecurityUrl() {
    local url="$1"

    if [[ -z "$url" ]]; then
        sendMessage "No URL provided." "ERROR"
        return 1
    fi

    sendMessage "Trying to set APT security URL to $url..." "INFO"
    if sed -i "s|http://security.ubuntu.com/ubuntu/|$url|g" /etc/apt/sources.list &>/dev/null; then
        sendMessage "APT security URL set to $url." "OK"
        return 0
    else
        sendMessage "Unable to set APT security URL to $url." "ERROR"
        return 1
    fi
}
