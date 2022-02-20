#!/bin/bash
MACHINE_TYPE=$(uname -m)
S6_VERSION="3.0.0.2"

function set_global_path() {
    echo "/command:/usr/bin:/bin:/usr/local/bin:/usr/sbin" > /etc/s6-overlay/config/global_path
}

if [ "${MACHINE_TYPE}" == "x86_64" ] || [ "${MACHINE_TYPE}" == "aarch64" ] || [ "${MACHINE_TYPE}" == "i486" ] || [ "${MACHINE_TYPE}" == "i686" ]; then
    wget -P /tmp https://github.com/just-containers/s6-overlay/releases/download/v"${S6_VERSION}"/s6-overlay-noarch-"${S6_VERSION}".tar.xz
    wget -P /tmp https://github.com/just-containers/s6-overlay/releases/download/v"${S6_VERSION}"/s6-overlay-"${MACHINE_TYPE}"-"${S6_VERSION}".tar.xz
    tar -C / -Jxpf /tmp/s6-overlay-noarch-"${S6_VERSION}".tar.xz
    tar -C / -Jxpf /tmp/s6-overlay-"${MACHINE_TYPE}"-"${S6_VERSION}".tar.xz
    rm /tmp/s6-overlay-noarch-"${S6_VERSION}".tar.xz /tmp/s6-overlay-"${MACHINE_TYPE}"-"${S6_VERSION}".tar.xz
    set_global_path
elif [ "${MACHINE_TYPE}" == 'armv7l' ]; then
    wget -P /tmp https://github.com/just-containers/s6-overlay/releases/download/v"${S6_VERSION}"/s6-overlay-noarch-"${S6_VERSION}".tar.xz
    wget -P /tmp https://github.com/just-containers/s6-overlay/releases/download/v"${S6_VERSION}"/s6-overlay-armhf-"${S6_VERSION}".tar.xz
    tar -C / -Jxpf /tmp/s6-overlay-noarch-"${S6_VERSION}".tar.xz
    tar -C / -Jxpf /tmp/s6-overlay-armhf-"${S6_VERSION}".tar.xz
    rm /tmp/s6-overlay-noarch-"${S6_VERSION}".tar.xz /tmp/s6-overlay-armhf-"${S6_VERSION}".tar.xz
    set_global_path
else
    echo "Unsupported architecture: ${MACHINE_TYPE}"
    exit 255
fi