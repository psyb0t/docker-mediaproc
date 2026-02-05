#!/bin/bash
set -e

# Adjust mediaproc UID/GID to match host user if env vars provided
TARGET_UID="${MEDIAPROC_UID:-1000}"
TARGET_GID="${MEDIAPROC_GID:-1000}"
CURRENT_UID=$(id -u mediaproc)
CURRENT_GID=$(id -g mediaproc)

if [ "$TARGET_GID" != "$CURRENT_GID" ]; then
    groupmod -g "$TARGET_GID" mediaproc
fi

if [ "$TARGET_UID" != "$CURRENT_UID" ]; then
    usermod -u "$TARGET_UID" -o mediaproc
fi

# Unlock the account so sshd allows pubkey auth
passwd -u mediaproc >/dev/null 2>&1 || usermod -p '*' mediaproc

chown mediaproc:mediaproc /home/mediaproc /work

# Update font cache if extra fonts mounted
if [ -d "/usr/share/fonts/custom" ] && [ "$(ls -A /usr/share/fonts/custom 2>/dev/null)" ]; then
    echo "Updating font cache with custom fonts..."
    fc-cache -f /usr/share/fonts/custom
fi

exec "$@"
