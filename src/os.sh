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

export OS_TYPE=""
export OS_DISTRO=""
export OS_VERSION=""
export OS_ARCH=""
export OS_CODENAME=""

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