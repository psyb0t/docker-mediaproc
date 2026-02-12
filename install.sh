#!/bin/bash
set -e

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

mkdir -p "$MEDIAPROC_HOME/work"
touch "$MEDIAPROC_HOME/authorized_keys"

if [ ! -f "$MEDIAPROC_HOME/.env" ]; then
    echo "MEDIAPROC_PORT=2222" > "$MEDIAPROC_HOME/.env"
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
      - ./work:/work
      - ./fonts:/usr/share/fonts/custom:ro
    restart: unless-stopped
EOF

cat > "$INSTALL_PATH" << 'SCRIPT'
#!/bin/bash
set -e

MEDIAPROC_HOME="__MEDIAPROC_HOME__"
ENV_FILE="$MEDIAPROC_HOME/.env"

compose() {
    docker compose --env-file "$ENV_FILE" -f "$MEDIAPROC_HOME/docker-compose.yml" "$@"
}

usage() {
    echo "Usage: mediaproc <command>"
    echo ""
    echo "Commands:"
    echo "  start [-d] [-p PORT]  Start mediaproc (-d for detached, -p to set port, default 2222)"
    echo "  stop                  Stop mediaproc"
    echo "  upgrade               Pull latest image and restart if needed"
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
            esac
            shift
        done

        if compose ps --status running 2>/dev/null | grep -q mediaproc; then
            read -rp "mediaproc is already running. Recreate? [y/N] " answer
            if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
                exit 0
            fi
        fi

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
            echo -n "Stopping mediaproc... "
            compose down --quiet-pull >/dev/null 2>&1
            echo "done"
        fi

        echo -n "Pulling latest image... "
        docker pull psyb0t/mediaproc >/dev/null 2>&1
        echo "done"

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

docker pull "$IMAGE" >/dev/null 2>&1

echo ""
echo "mediaproc installed!"
echo ""
echo "  Command:         $INSTALL_PATH"
echo "  Authorized keys: $MEDIAPROC_HOME/authorized_keys"
echo "  Work directory:  $MEDIAPROC_HOME/work"
echo "  Custom fonts:    $MEDIAPROC_HOME/fonts/"
echo ""
echo "Add your SSH public key(s) to the authorized_keys file and run:"
echo ""
echo "  mediaproc start -d"
echo ""
