#!/usr/bin/env bash
# Build (if needed) and enter the ROS 2 Humble dev container.
# The repo is mounted at /repo, so edits made inside persist on the host.
# Usage: scripts/dev-shell.sh          — enter the container
#        REBUILD=1 scripts/dev-shell.sh — force an image rebuild
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE=edge-physical-ai-dev

if ! docker image inspect "$IMAGE" >/dev/null 2>&1 || [ "${REBUILD:-0}" = "1" ]; then
    docker build \
        --build-arg UID="$(id -u)" \
        --build-arg GID="$(id -g)" \
        -t "$IMAGE" \
        -f "$REPO_ROOT/docker/Dockerfile.dev" \
        "$REPO_ROOT/docker"
fi

# GUI passthrough for rqt/rviz: WSLg exposes sockets under /mnt/wslg,
# native Ubuntu (home) only has the X11 socket — mount whichever exists.
GUI_ARGS=(-e DISPLAY="${DISPLAY:-:0}")
[ -d /tmp/.X11-unix ] && GUI_ARGS+=(-v /tmp/.X11-unix:/tmp/.X11-unix)
if [ -d /mnt/wslg ]; then
    GUI_ARGS+=(
        -v /mnt/wslg:/mnt/wslg
        -e WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-}"
        -e XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-}"
        -e PULSE_SERVER="${PULSE_SERVER:-}"
    )
fi

# --network host + --ipc host: DDS discovery (and later the micro-ROS agent)
# need real UDP multicast and shared memory, which bridged networking breaks.
exec docker run --rm -it \
    --network host \
    --ipc host \
    -v "$REPO_ROOT":/repo \
    "${GUI_ARGS[@]}" \
    --name edge-dev \
    "$IMAGE"
