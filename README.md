# ROS2-Gazeebo

A reproducible **Docker image** and helper scripts for running
[ROS 2](https://docs.ros.org/) with [Gazebo](https://gazebosim.org/) on
Linux — including X11 forwarding for GUI tools (Gazebo, RViz, rqt) and
optional NVIDIA GPU acceleration.

Default stack:

| Component  | Version                          |
|------------|----------------------------------|
| Ubuntu     | 24.04 (Noble)                    |
| ROS 2      | Jazzy Jalisco (`ros-jazzy-desktop`) |
| Gazebo     | Harmonic (`gz-harmonic`)         |
| Bridge     | `ros-jazzy-ros-gz`               |

Other combos (Humble + Fortress, etc.) are supported via build args — see
[Switching ROS / Gazebo versions](#switching-ros--gazebo-versions).

---

## Why?

Setting up ROS 2 + Gazebo cleanly on a workstation usually means
disturbing your host system with several apt repos, ROS keyrings,
Gazebo keyrings, and Python overrides. This project keeps all of that
inside a container, while still letting you:

- Run Gazebo / RViz GUIs on your host display via X11
- Use your NVIDIA GPU for rendering (when available)
- Persist your `ros2_ws/` across container restarts
- Edit code on the host with your editor of choice

---

## Quick start

```bash
git clone https://github.com/<you>/ROS2-Gazeebo.git
cd ROS2-Gazeebo

# 1. Build the image (~10–15 min the first time, mostly downloads)
./scripts/build.sh

# 2. Launch an interactive shell (sets up X11, GPU automatically)
./scripts/run.sh

# 3. Inside the container — verify everything works
ros2 doctor
gz sim shapes.sdf
```

Or use the `Makefile`:

```bash
make build
make run
make demo    # opens Gazebo with the shapes world
```

---

## What the scripts do

All scripts live in [scripts/](scripts/) and are safe to inspect / hack on.

| Script                                | Purpose                                                          |
|---------------------------------------|------------------------------------------------------------------|
| [build.sh](scripts/build.sh)          | Build the image. Forwards extra flags to `docker build` (e.g. `--no-cache`). |
| [run.sh](scripts/run.sh)              | Start (or exec into) a container with X11 + GPU wired up.        |
| [setup_x11.sh](scripts/setup_x11.sh)  | Configure X11 forwarding (xhost + xauth cookie). Called by `run.sh`, but you can run it standalone too. |
| [shell.sh](scripts/shell.sh)          | Open another bash session in the running container.              |
| [demo.sh](scripts/demo.sh)            | End-to-end sanity check — launches Gazebo with `shapes.sdf`.     |
| [stop.sh](scripts/stop.sh)            | Stop & remove the container.                                     |
| [clean.sh](scripts/clean.sh)          | Stop the container and delete the image.                         |
| [common.sh](scripts/common.sh)        | Shared variables and helpers sourced by the others.              |

### Environment overrides

Every script reads these from the environment, so you can mix and match
without editing files:

```bash
IMAGE_NAME=ros2-gazebo        # docker image name
IMAGE_TAG=jazzy-harmonic      # docker image tag
CONTAINER_NAME=ros2-gazebo    # docker container name
ROS_DISTRO=jazzy              # ros 2 distro
GZ_DISTRO=harmonic            # gazebo flavor
UBUNTU_VERSION=24.04          # base image
ROS_DOMAIN_ID=0               # ROS 2 DDS domain
```

---

## X11 / GUI forwarding

The most common Docker + GUI failure is:

```
Authorization required, but no authorization protocol specified
qt.qpa.xcb: could not connect to display :0
```

`setup_x11.sh` fixes this by:

1. Running `xhost +local:docker` so containers on the same host may connect.
2. Generating an xauth cookie at `/tmp/.docker.xauth` with the `FamilyWild`
   byte set, so the cookie is accepted regardless of the container's UID
   or hostname.
3. Bind-mounting `/tmp/.X11-unix` and `/tmp/.docker.xauth` into the
   container and exporting `DISPLAY` + `XAUTHORITY`.

You usually don't need to call it directly — `run.sh` invokes it for you.
If GUI apps still fail, run it on its own to see what's wrong:

```bash
./scripts/setup_x11.sh
```

### Wayland users

X11 forwarding works under Wayland through `Xwayland` (default on Ubuntu
24.04, Fedora, Arch). No extra setup needed. If you use a tiling
compositor without Xwayland, install it first.

---

## NVIDIA GPU support

If you have an NVIDIA GPU and the
[NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)
installed, `run.sh` will auto-detect it and pass `--gpus all` to Docker.

To verify inside the container:

```bash
nvidia-smi          # should show your GPU
glxinfo | grep -i "OpenGL renderer"
```

To force CPU / software rendering (useful for debugging):

```bash
./scripts/run.sh --no-gpu
```

If you're on AMD or Intel graphics, the script falls back to
`--device /dev/dri:/dev/dri`, which is enough for Mesa-based OpenGL.

---

## Workspace persistence

The host folder [workspace/](workspace/) is bind-mounted to
`/home/ros/ros2_ws/` inside the container. Put your ROS packages under
`workspace/src/`:

```
workspace/
├── src/
│   └── my_package/
├── build/      # generated by colcon (gitignored)
├── install/    # generated by colcon (gitignored)
└── log/        # generated by colcon (gitignored)
```

Inside the container:

```bash
cd ~/ros2_ws
rosdep install --from-paths src --ignore-src -r -y
colcon build --symlink-install
source install/setup.bash
```

The container's `~/.bashrc` already sources `/opt/ros/jazzy/setup.bash`
and, if it exists, `~/ros2_ws/install/setup.bash`.

---

## Switching ROS / Gazebo versions

The Dockerfile is parameterized — just override the build args:

```bash
# Humble + Fortress on Ubuntu 22.04
ROS_DISTRO=humble GZ_DISTRO=fortress UBUNTU_VERSION=22.04 \
    IMAGE_TAG=humble-fortress \
    ./scripts/build.sh

ROS_DISTRO=humble GZ_DISTRO=fortress IMAGE_TAG=humble-fortress \
    ./scripts/run.sh
```

Verified combinations:

| ROS 2 Distro | Gazebo  | Ubuntu | Status      |
|--------------|---------|--------|-------------|
| Jazzy        | Harmonic | 24.04 | ✅ default  |
| Humble       | Fortress | 22.04 | ✅ via args |
| Rolling      | Harmonic | 24.04 | ⚠️ untested |

---

## Docker Compose

A [docker-compose.yml](docker-compose.yml) is provided as an alternative
to the shell scripts:

```bash
./scripts/setup_x11.sh        # still needed for the xauth cookie
docker compose up -d
docker compose exec ros2-gazebo bash
```

---

## Troubleshooting

<details>
<summary><strong>GUI apps say "cannot open display"</strong></summary>

1. On the host: `echo $DISPLAY` — should be `:0` or `:1`. If empty,
   you're probably in an SSH session without `-Y`.
2. Run `./scripts/setup_x11.sh` and look for warnings.
3. Inside the container: `echo $DISPLAY $XAUTHORITY` — both should be set.
4. Test the socket: `ls /tmp/.X11-unix` should show `X0` (or similar).
</details>

<details>
<summary><strong>Gazebo opens but is black / corrupt</strong></summary>

Usually a GPU driver mismatch. Try `./scripts/run.sh --no-gpu` to confirm
it works with software rendering — if it does, your NVIDIA Container
Toolkit needs updating or doesn't match your host driver version.
</details>

<details>
<summary><strong>"Got permission denied while trying to connect to the Docker daemon"</strong></summary>

Add your user to the docker group (logout/login afterwards):
```bash
sudo usermod -aG docker $USER
```
</details>

<details>
<summary><strong>colcon build fails with "No space left on device"</strong></summary>

Docker images can grow large. Run `docker system prune -a` to reclaim,
or move Docker's data-root to a larger disk via `/etc/docker/daemon.json`.
</details>

<details>
<summary><strong>I want to install extra apt packages</strong></summary>

Either bake them into the Dockerfile and rebuild, or install inside the
running container with `sudo apt update && sudo apt install <pkg>` —
the `ros` user has passwordless sudo. Note the changes are lost when the
container is removed; persistent changes belong in the Dockerfile.
</details>

---

## Project layout

```
ROS2-Gazeebo/
├── docker/
│   ├── Dockerfile          # ROS 2 + Gazebo image definition
│   ├── entrypoint.sh       # sources ROS setup before exec
│   └── .dockerignore
├── scripts/
│   ├── build.sh
│   ├── run.sh
│   ├── setup_x11.sh
│   ├── shell.sh
│   ├── demo.sh
│   ├── stop.sh
│   ├── clean.sh
│   └── common.sh
├── workspace/              # bind-mounted into the container as ~/ros2_ws
├── docker-compose.yml
├── Makefile
├── CONTRIBUTING.md
├── LICENSE                 # Apache 2.0
└── README.md
```

---

## Contributing

Issues and PRs are very welcome — see [CONTRIBUTING.md](CONTRIBUTING.md).

## License

Apache 2.0 — see [LICENSE](LICENSE).

This project bundles ROS 2 and Gazebo at runtime; those projects are
licensed by their respective maintainers (mostly Apache 2.0 / BSD).
