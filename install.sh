#!/bin/bash
IMAGE="psyb0t/mediaproc"
INSTALL_PATH="/usr/local/bin/mediaproc"

# Resolve the real user when running under sudo
if [ -n "$SUDO_USER" ]; then
    REAL_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    REAL_UID="$SUDO_UID"
    REAL_GID="$SUDO_GID"
else
    REAL_HOME="$HOME"
    REAL_UID=$(id -u)
    REAL_GID=$(id -g)
fi

MEDIAPROC_HOME="$REAL_HOME/.mediaproc"

mkdir -p "$MEDIAPROC_HOME/work" "$MEDIAPROC_HOME/host_keys" "$MEDIAPROC_HOME/fonts"
touch "$MEDIAPROC_HOME/authorized_keys"

if [ ! -f "$MEDIAPROC_HOME/.env" ]; then
    cat > "$MEDIAPROC_HOME/.env" << ENVEOF
MEDIAPROC_PORT=2222
MEDIAPROC_FONTS_DIR=$MEDIAPROC_HOME/fonts
MEDIAPROC_CPUS=0
MEDIAPROC_MEMORY=0
MEDIAPROC_SWAP=0
ENVEOF
fi

cat > "$MEDIAPROC_HOME/docker-compose.yml" << EOF
services:
  mediaproc:
    image: ${IMAGE}
    ports:
      - "\${MEDIAPROC_PORT:-2222}:22"
    environment:
      - LOCKBOX_UID=${REAL_UID}
      - LOCKBOX_GID=${REAL_GID}
    volumes:
      - ./authorized_keys:/etc/lockbox/authorized_keys:ro
      - ./host_keys:/etc/lockbox/host_keys
      - ./work:/work
      - \${MEDIAPROC_FONTS_DIR:-./fonts}:/usr/share/fonts/custom:ro
    cpus: \${MEDIAPROC_CPUS:-0}
    mem_limit: \${MEDIAPROC_MEMORY:-0}
    memswap_limit: \${MEDIAPROC_MEMSWAP:-0}
    restart: unless-stopped
EOF

cat > "$INSTALL_PATH" << 'SCRIPT'
#!/bin/bash

MEDIAPROC_HOME="__MEDIAPROC_HOME__"
ENV_FILE="$MEDIAPROC_HOME/.env"

compose() {
    docker compose --env-file "$ENV_FILE" -f "$MEDIAPROC_HOME/docker-compose.yml" "$@"
}

# Convert size string (e.g. 4g, 512m) to bytes
to_bytes() {
    local val="$1"
    if [ "$val" = "0" ]; then echo 0; return; fi
    local num="${val%[bBkKmMgG]*}"
    local unit="${val##*[0-9.]}"
    case "${unit,,}" in
        g) echo $(( ${num%.*} * 1073741824 )) ;;
        m) echo $(( ${num%.*} * 1048576 )) ;;
        k) echo $(( ${num%.*} * 1024 )) ;;
        *) echo "$num" ;;
    esac
}

# Compute memswap (Docker's memswap_limit = ram + swap)
compute_memswap() {
    . "$ENV_FILE"
    local mem="$MEDIAPROC_MEMORY"
    local swap="$MEDIAPROC_SWAP"

    if [ "$mem" = "0" ] || [ -z "$mem" ]; then
        sed -i '/^MEDIAPROC_MEMSWAP=/d' "$ENV_FILE"
        echo "MEDIAPROC_MEMSWAP=0" >> "$ENV_FILE"
        return
    fi

    if [ "$swap" = "0" ] || [ -z "$swap" ]; then
        sed -i '/^MEDIAPROC_MEMSWAP=/d' "$ENV_FILE"
        echo "MEDIAPROC_MEMSWAP=$mem" >> "$ENV_FILE"
        return
    fi

    local mem_bytes swap_bytes total
    mem_bytes=$(to_bytes "$mem")
    swap_bytes=$(to_bytes "$swap")
    total=$(( mem_bytes + swap_bytes ))

    sed -i '/^MEDIAPROC_MEMSWAP=/d' "$ENV_FILE"
    echo "MEDIAPROC_MEMSWAP=$total" >> "$ENV_FILE"
}

usage() {
    echo "Usage: mediaproc <command>"
    echo ""
    echo "Commands:"
    echo "  start [-d] [-p PORT] [-f FONTS_DIR] [-c CPUS] [-r MEMORY] [-s SWAP]"
    echo "                        Start mediaproc (-d for detached)"
    echo "                        -f  Custom fonts directory"
    echo "                        -c  CPU limit (e.g. 4, 0.5) - 0 = unlimited"
    echo "                        -r  RAM limit (e.g. 4g, 512m) - 0 = unlimited"
    echo "                        -s  Swap limit (e.g. 2g, 512m) - 0 = no swap"
    echo "  stop                  Stop mediaproc"
    echo "  upgrade               Pull latest image and restart if needed"
    echo "  uninstall             Stop mediaproc and remove everything"
    echo "  status                Show container status"
    echo "  logs                  Show container logs (pass extra args to docker compose logs)"
}

case "${1:-}" in
    start)
        shift
        DETACHED=false
        while [ $# -gt 0 ]; do
            case "$1" in
                -d) DETACHED=true ;;
                -p) shift; sed -i "s/^MEDIAPROC_PORT=.*/MEDIAPROC_PORT=$1/" "$ENV_FILE" ;;
                -f) shift; sed -i "s|^MEDIAPROC_FONTS_DIR=.*|MEDIAPROC_FONTS_DIR=$1|" "$ENV_FILE" ;;
                -c) shift; sed -i "s/^MEDIAPROC_CPUS=.*/MEDIAPROC_CPUS=$1/" "$ENV_FILE" ;;
                -r) shift; sed -i "s/^MEDIAPROC_MEMORY=.*/MEDIAPROC_MEMORY=$1/" "$ENV_FILE" ;;
                -s) shift; sed -i "s/^MEDIAPROC_SWAP=.*/MEDIAPROC_SWAP=$1/" "$ENV_FILE" ;;
            esac
            shift
        done

        if compose ps --status running 2>/dev/null | grep -q mediaproc; then
            read -rp "mediaproc is already running. Recreate? [y/N] " answer
            if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
                exit 0
            fi
        fi

        compute_memswap

        COMPOSE_ARGS="up --force-recreate"
        if [ "$DETACHED" = true ]; then
            COMPOSE_ARGS="up --force-recreate -d"
        fi

        compose $COMPOSE_ARGS
        ;;
    stop)
        compose down
        ;;
    upgrade)
        WAS_RUNNING=false
        if compose ps --status running 2>/dev/null | grep -q mediaproc; then
            WAS_RUNNING=true
            read -rp "mediaproc is running. Stop it to upgrade? [y/N] " answer
            if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
                echo "Upgrade cancelled"
                exit 0
            fi
            compose down
        fi

        docker pull psyb0t/mediaproc
        sudo -v
        echo "Updating mediaproc..."
        curl -fsSL https://raw.githubusercontent.com/psyb0t/docker-mediaproc/main/install.sh | sudo bash
        echo "Upgrade complete"

        if [ "$WAS_RUNNING" = true ]; then
            read -rp "Start mediaproc again? [y/N] " answer
            if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
                exit 0
            fi
            compose up -d
        fi
        ;;
    uninstall)
        read -rp "Uninstall mediaproc? [y/N] " answer
        if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
            exit 0
        fi

        compose down 2>/dev/null
        rm -f "$0"

        read -rp "Remove $MEDIAPROC_HOME? This deletes all data including work files. [y/N] " answer
        if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
            rm -rf "$MEDIAPROC_HOME"
        fi

        echo "mediaproc uninstalled"
        ;;

    status)
        compose ps
        ;;
    logs)
        shift
        compose logs "$@"
        ;;
    *)
        usage
        ;;
esac
SCRIPT

sed -i "s|__MEDIAPROC_HOME__|$MEDIAPROC_HOME|g" "$INSTALL_PATH"
chmod +x "$INSTALL_PATH"

chown -R "$REAL_UID:$REAL_GID" "$MEDIAPROC_HOME"

docker pull "$IMAGE"

echo ""
echo "mediaproc installed!"
echo ""
echo "  Command:         $INSTALL_PATH"
echo "  Authorized keys: $MEDIAPROC_HOME/authorized_keys"
echo "  Work directory:  $MEDIAPROC_HOME/work"
echo "  Custom fonts directory: $MEDIAPROC_HOME/fonts/"
echo ""
echo "Add your SSH public key(s) to the authorized_keys file and run:"
echo ""
echo "  mediaproc start -d"
echo ""
