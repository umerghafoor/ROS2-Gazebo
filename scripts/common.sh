#!/usr/bin/env bash
# Shared helpers sourced by the other scripts.

set -euo pipefail

# Resolve project root regardless of where the script is called from.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

IMAGE_NAME="${IMAGE_NAME:-ros2-gazebo}"
IMAGE_TAG="${IMAGE_TAG:-jazzy-harmonic}"
CONTAINER_NAME="${CONTAINER_NAME:-ros2-gazebo}"
# Remote (Docker Hub) image. `./ros2gz pull` fetches this and re-tags it
# locally as ${IMAGE_NAME}:${IMAGE_TAG} so the rest of the scripts find it.
REMOTE_IMAGE="${REMOTE_IMAGE:-umerghafoor/ros2-gazebo:jazzy-harmonic}"
ROS_DISTRO="${ROS_DISTRO:-jazzy}"
GZ_DISTRO="${GZ_DISTRO:-harmonic}"
UBUNTU_VERSION="${UBUNTU_VERSION:-24.04}"

# Colors (only when stdout is a TTY).
if [ -t 1 ]; then
    C_RED='\033[0;31m'
    C_GREEN='\033[0;32m'
    C_YELLOW='\033[0;33m'
    C_BLUE='\033[0;34m'
    C_RESET='\033[0m'
else
    C_RED='' C_GREEN='' C_YELLOW='' C_BLUE='' C_RESET=''
fi

log()   { printf "${C_BLUE}[ros2-gz]${C_RESET} %s\n" "$*"; }
ok()    { printf "${C_GREEN}[ros2-gz]${C_RESET} %s\n" "$*"; }
warn()  { printf "${C_YELLOW}[ros2-gz]${C_RESET} %s\n" "$*" >&2; }
err()   { printf "${C_RED}[ros2-gz]${C_RESET} %s\n" "$*" >&2; }

require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        err "Required command not found: $1"
        return 1
    fi
}

check_docker_access() {
    # Verify the user (or sudo'd root) can actually talk to the Docker daemon.
    # If not, print a clear, actionable hint and exit — better than letting
    # every subsequent command spew "permission denied" against docker.sock.
    if docker info >/dev/null 2>&1; then
        return 0
    fi
    err "Cannot connect to the Docker daemon."
    if [ "$(id -u)" != "0" ] && ! groups | grep -qw docker; then
        warn "You are not in the 'docker' group. Pick one:"
        warn "  1) Run with sudo:   sudo $(basename "$0" 2>/dev/null) ..."
        warn "  2) Add to group:    sudo usermod -aG docker \$USER && newgrp docker"
    else
        warn "Is the Docker daemon running?  sudo systemctl status docker"
    fi
    exit 1
}

detect_nvidia() {
    # Returns 0 if an NVIDIA GPU + container runtime appear usable.
    if ! command -v nvidia-smi >/dev/null 2>&1; then
        return 1
    fi
    if ! nvidia-smi >/dev/null 2>&1; then
        return 1
    fi
    # Check docker info for nvidia runtime registration.
    if docker info 2>/dev/null | grep -qi 'Runtimes:.*nvidia\|nvidia-container-runtime'; then
        return 0
    fi
    # Newer setups expose it as the default runtime or as a CDI device — try a dry-run.
    if docker run --rm --gpus all hello-world >/dev/null 2>&1; then
        return 0
    fi
    return 1
}
