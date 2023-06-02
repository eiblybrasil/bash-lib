#!/bin/bash

SOURCE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# Imports
source "$SOURCE_PATH/os.sh"
source "$SOURCE_PATH/service_management.sh"

function sendMessage() {
    PREFIX="\033[1m\033[0;97m[$(date +%H:%M:%S.%N | cut -b 1-10)]\033[0m "

    case $2 in
    INFO | info)
        echo -e "$PREFIX\033[0;94m[INFO]:\033[0m $1"
        ;;
    WARNING | warning)
        echo -e "$PREFIX\033[0;93m[WARNING]:\033[0m $1"
        ;;
    ERROR | error)
        echo -e "$PREFIX\033[0;91m[ERROR]:\033[0m $1"
        ;;
    SUCCESS | success)
        echo -e "$PREFIX\033[0;92m[SUCCESS]:\033[0m $1"
        ;;
    OK | ok)
        echo -e "$PREFIX\033[0;36m[OK]:\033[0m $1"
        ;;
    DEBUG | debug)
        echo -e "$PREFIX\033[0;33m[DEBUG]:\033[0m $1"
        ;;
    NONE | none)
        echo -e "$PREFIX$31"
        ;;
    *)
        echo -e "$PREFIX$1"
        ;;
    esac
}

function isPackageInstalled() {
    local package="$1"

    case "$OS_TYPE" in
    linux)
        case "$OS_DISTRO" in
        centos | oracle | fedora | amazon)
            if rpm -q "$package" &>/dev/null; then
                return 0
            else
                return 1
            fi
            ;;
        debian | ubuntu)
            if dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q "install ok installed"; then
                return 0
            else
                return 1
            fi
            ;;
        arch)
            if pacman -Qs "$package" &>/dev/null; then
                return 0
            else
                return 1
            fi
            ;;
        alpine)
            if apk -q info "$package" >/dev/null 2>&1; then
                return 0
            else
                return 1
            fi
            ;;
        gentoo)
            if equery -q list "$package" >/dev/null 2>&1; then
                return 0
            else
                return 1
            fi
            ;;
        opensuse)
            if zypper search -i "$package" >/dev/null 2>&1; then
                return 0
            else
                return 1
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
}

function isServiceEnabled() {
    local service="$1"

    if [ "$SERVICE_CMD" = "systemctl" ]; then
        if systemctl is-enabled "$service" &>/dev/null; then
            return 0
        fi
    elif [ "$SERVICE_CMD" = "service" ]; then
        for i in `find /etc/rc*.d -name S*`; do
            basename $i | sed 's/^S[0-9]\{1,2\}//g' | grep -q "$service"
            return 0
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
    local options="${@:2}"

    case "$OS_TYPE" in
    linux)
        case "$OS_DISTRO" in
        debian | ubuntu)
            if apt-get install -y $options "$package" &>/dev/null; then
                return 0
            fi
            ;;
        centos | oracle | fedora | amazon)
            if yum install -y $options "$package" &>/dev/null; then
                return 0
            fi
            ;;
        arch)
            if pacman -S --noconfirm $options "$package" &>/dev/null; then
                return 0
            fi
            ;;
        alpine)
            if apk add $options "$package" &>/dev/null; then
                return 0
            fi
            ;;
        gentoo)
            if emerge $options "$package" &>/dev/null; then
                return 0
            fi
            ;;
        opensuse)
            if zypper install -y $options "$package" &>/dev/null; then
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
                debian|ubuntu)
                    if apt-get -y update &>/dev/null; then
                        sendMessage "The packages have been successfully updated." "SUCCESS"
                        return 0
                    fi
                    ;;
                centos|oracle|fedora|amzn)
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
                debian|ubuntu)
                    if apt-get -y dist-upgrade &>/dev/null; then
                        sendMessage "The packages have been successfully upgraded." "SUCCESS"
                        return 0
                    fi
                    ;;
                centos|oracle|fedora|amzn)
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
                debian|ubuntu)
                    if apt-get -y autoremove &>/dev/null; then
                        sendMessage "The packages have been successfully cleaned." "SUCCESS"
                        return 0
                    fi
                    ;;
                centos|oracle|fedora|amzn)
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

function doGeneratePassword() {
    local length="${1:-22}"
    tr -dc 'A-Za-z0-9-._@' </dev/urandom | head -c "$length"
    echo
}

function doTrim() {
    local var="${*}"
    var="${var#"${var%%[![:space:]]*}"}"
    var="${var%"${var##*[![:space:]]}"}"
    printf '%s' "$var"
}

function doHumanBytes() {
    local bytes="$1"
    local precision=2
    local units=("B" "KB" "MB" "GB" "TB" "PB" "EB" "ZB" "YB")
    local unit=0

    while ((bytes >= 1024)) && ((unit < 8)); do
        bytes=$((bytes / 1024))
        unit=$((unit + 1))
    done

    if ((unit == 0)); then
        precision=0
    fi

    printf "%.${precision}f %s" "$bytes" "${units[$unit]}"
}

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

function getDuration() {
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

function setTimezone() {
    local timezone="$1"

    if [[ -z "$timezone" ]]; then
        sendMessage "No timezone provided." "ERROR"
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
