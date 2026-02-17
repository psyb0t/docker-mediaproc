#!/bin/bash
set -e

IMAGE="psyb0t/mediaproc:latest-test"
CONTAINER="mediaproc-test-$$"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMPDIR="$SCRIPT_DIR/.test-tmp-$$"
mkdir -p "$TMPDIR"
KEY="$TMPDIR/id_test"
AUTHKEYS="$TMPDIR/authorized_keys"
PASSED=0
FAILED=0
TOTAL=0

cleanup() {
    echo ""
    echo "Cleaning up..."
    docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
    rm -rf "$TMPDIR"
}

trap cleanup EXIT

fail() {
    echo "  FAIL: $1"
    if [ -n "$2" ]; then
        echo "        got: $(echo "$2" | head -1)"
    fi
    FAILED=$((FAILED + 1))
    TOTAL=$((TOTAL + 1))
}

pass() {
    echo "  PASS: $1"
    PASSED=$((PASSED + 1))
    TOTAL=$((TOTAL + 1))
}

ssh_cmd() {
    ssh -p 22 \
        -i "$KEY" \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -o LogLevel=ERROR \
        -o ConnectTimeout=5 \
        "mediaproc@$CONTAINER_IP" "$1" 2>&1 || true
}

# run_test <test_name> <ssh_command> <grep_pattern> [case_insensitive]
run_test() {
    local name="$1"
    local cmd="$2"
    local pattern="$3"
    local case_insensitive="${4:-}"

    local output
    output=$(ssh_cmd "$cmd")

    local grep_flags="-q"
    if [ "$case_insensitive" = "i" ]; then
        grep_flags="-qi"
    fi

    if echo "$output" | grep $grep_flags "$pattern"; then
        pass "$name"
        return
    fi

    fail "$name" "$output"
}

echo "=== Building test image ==="
make build-test

echo ""
echo "=== Generating test SSH key ==="
ssh-keygen -t ed25519 -f "$KEY" -N "" -q
cp "$KEY.pub" "$AUTHKEYS"

echo ""
echo "=== Starting container ==="
docker run -d \
    --name "$CONTAINER" \
    -e "LOCKBOX_UID=$(id -u)" \
    -e "LOCKBOX_GID=$(id -g)" \
    "$IMAGE" >/dev/null

# Inject authorized_keys via docker cp (works in Docker-in-Docker environments
# where bind mounts resolve paths on the host, not in the client container)
docker cp "$AUTHKEYS" "$CONTAINER:/etc/lockbox/authorized_keys"
docker exec "$CONTAINER" chmod 644 /etc/lockbox/authorized_keys

CONTAINER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$CONTAINER")
echo "Container IP: $CONTAINER_IP"

echo "Waiting for sshd..."
for i in $(seq 1 30); do
    if docker exec "$CONTAINER" pgrep sshd >/dev/null 2>&1; then
        break
    fi
    sleep 0.5
done

# Give sshd a moment to be ready for connections
sleep 1

echo ""
echo "=== Container debug info ==="
docker exec "$CONTAINER" id mediaproc
docker exec "$CONTAINER" ls -la /home/mediaproc/
docker exec "$CONTAINER" cat /etc/lockbox/authorized_keys
echo "--- sshd logs ---"
docker logs "$CONTAINER" 2>&1 | tail -20

echo ""
echo "=== Testing media commands ==="

#                  name        command               pattern           flags
run_test           "ffmpeg"    "ffmpeg -version"     "ffmpeg version"
run_test           "ffprobe"   "ffprobe -version"    "ffprobe version"
run_test           "sox"       "sox --version"       "sox"             "i"
run_test           "soxi"      "soxi --version"      "sox"             "i"
run_test           "convert"   "convert --version"   "imagemagick"     "i"
run_test           "identify"  "identify --version"  "imagemagick"     "i"

echo ""
echo "=== Testing LOCKBOX_USER rename ==="

# The container sets LOCKBOX_USER=mediaproc, verify the user was renamed
run_test "usage shows mediaproc" "" "mediaproc@"
docker exec "$CONTAINER" touch /work/test-owner
docker exec "$CONTAINER" chown mediaproc:mediaproc /work/test-owner
run_test "list-files shows mediaproc owner" "list-files --json" "mediaproc"

echo ""
echo "=== Testing fonts ==="

font_output=$(docker exec "$CONTAINER" fc-list : family 2>&1)

if echo "$font_output" | grep -qi "noto color emoji"; then
    pass "emoji fonts installed"
else
    fail "emoji fonts installed" "$font_output"
fi

if echo "$font_output" | grep -qi "noto sans cjk"; then
    pass "CJK fonts installed"
else
    fail "CJK fonts installed" "$font_output"
fi

echo ""
echo "=== Testing frei0r plugins ==="

run_test "frei0r plugins available" "ffmpeg -filters" "frei0r"

echo ""
echo "================================"
echo "Results: $PASSED passed, $FAILED failed, $TOTAL total"
echo "================================"

if [ "$FAILED" -gt 0 ]; then
    exit 1
fi
