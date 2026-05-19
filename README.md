# ROS2-Gazeebo

> **ROS 2 + Gazebo in Docker with GUI, GPU support, and a persistent
> workspace — no host setup required.**

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)
[![ROS 2 Jazzy](https://img.shields.io/badge/ROS_2-Jazzy-22314E?logo=ros&logoColor=white)](https://docs.ros.org/en/jazzy/)
[![Gazebo Harmonic](https://img.shields.io/badge/Gazebo-Harmonic-FF6B00)](https://gazebosim.org/docs/harmonic/)
[![Ubuntu 24.04](https://img.shields.io/badge/Ubuntu-24.04-E95420?logo=ubuntu&logoColor=white)](https://releases.ubuntu.com/24.04/)
[![Docker](https://img.shields.io/badge/Docker-required-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)

A reproducible **Docker image** and helper scripts for running
[ROS 2](https://docs.ros.org/) with [Gazebo](https://gazebosim.org/) on
Linux — including X11 forwarding for GUI tools (Gazebo, RViz, rqt) and
optional NVIDIA GPU acceleration. A single launcher script (`./ros2gz`)
gives you an interactive menu and shortcut subcommands for everything
without ever typing `docker exec` yourself.

## Features

- 🐳 Single-command Docker image with ROS 2 Jazzy + Gazebo Harmonic
- 🖥️ X11 forwarding pre-wired — Gazebo, RViz, rqt open as regular windows
- 🎮 Auto-detected NVIDIA GPU acceleration (CPU fallback otherwise)
- 📁 Bind-mounted `workspace/` so your code persists; mount extra folders
  on the fly with `./ros2gz --mount ~/my_pkg`
- 🚀 `./ros2gz` launcher: interactive menu **or** scriptable subcommands,
  opens GUIs in new terminal windows automatically
- 🤖 Bundled RViz config + ros_gz bridge launch file for instant sim ↔ ROS
- 🔧 Parameterized Dockerfile — swap to Humble + Fortress with one
  build-arg change

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
git clone https://github.com/umerghafoor/ROS2-Gazeebo.git
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

### One-stop launcher: `./ros2gz`

Tired of typing `docker exec` and remembering script paths? Run
[ros2gz](ros2gz) at the repo root — with no args it shows an interactive
menu; with a subcommand it just does the thing:

```bash
./ros2gz                  # interactive menu
./ros2gz shell            # open bash inside the container
./ros2gz term             # open another shell (existing container)
./ros2gz gazebo           # launch gz sim
./ros2gz rviz             # launch RViz2
./ros2gz gz-rviz          # gazebo + bridge + RViz together
./ros2gz topics           # ros2 topic list (no exec needed)
./ros2gz nodes            # ros2 node list
./ros2gz doctor           # ros2 doctor
./ros2gz build-ws         # rosdep install + colcon build in ~/ros2_ws
./ros2gz ros2 bag record /clock  # forward any ros2 CLI args
./ros2gz exec gz topic -l        # run any command inside the container
./ros2gz status           # is the container up? is the image built?
./ros2gz up               # start a detached container in the background
./ros2gz stop             # stop & remove it
./ros2gz rebuild          # rebuild the image
./ros2gz help             # full subcommand list
```

It auto-detects whether a container is running, starts a detached one if
needed, wires up X11 before launching GUI apps, and reuses the same
container for every command so everything shares one ROS DDS domain.

GUI apps and shells open in a **new terminal window** (gnome-terminal /
konsole / alacritty / xterm — whichever is installed). Pass `--inline`
to keep them in the current terminal instead.

#### Mounting extra host folders

You can bind-mount any host folder into the container without editing
the Dockerfile or compose file:

```bash
./ros2gz --mount ~/my_pkg shell      # prompts for container path, then opens shell
./ros2gz --here gazebo               # shortcut for --mount $PWD
./ros2gz --mount ~/data:/data shell  # explicit container path, no prompt
```

Or interactively: pick "16) Add a folder mount" in the menu. You'll be
asked whether to **save it permanently** — saved mounts go to
`.ros2gz.mounts` (gitignored, per-user) and auto-apply every time the
container starts. Manage them via menu options 16–18 or:

```bash
./ros2gz mounts                       # list saved + ad-hoc mounts
```

Note: Docker can't add mounts to a *running* container. If you add a
mount while one is up, `ros2gz` will warn and transparently restart it
so the new mount takes effect.

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
| [rviz.sh](scripts/rviz.sh)            | Launch RViz2 (attaches to the running container if one exists).  |
| [gz_rviz.sh](scripts/gz_rviz.sh)      | Launch Gazebo + ros_gz bridge + RViz together via a launch file. |
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

## RViz2 integration

RViz2 is preinstalled in the image (`ros-${ROS_DISTRO}-rviz2`) and a default
config ships at [config/default.rviz](config/default.rviz) — it's baked into
the image at `/home/ros/.rviz2/default.rviz` with TF, Grid, RobotModel,
LaserScan, PointCloud2 and Image displays already wired up (the data ones
start disabled — enable them once you publish the matching topics).

### Just RViz

```bash
./scripts/rviz.sh                          # default config
./scripts/rviz.sh -d /path/in/container    # custom config
make rviz
```

If a `ros2-gazebo` container is already running (e.g. you started Gazebo
in another terminal), `rviz.sh` exec's RViz inside it so they share the
same `ROS_DOMAIN_ID` and DDS discovery — no extra setup needed.

### Gazebo + ros_gz bridge + RViz together

```bash
./scripts/gz_rviz.sh                                          # shapes.sdf
./scripts/gz_rviz.sh world:=empty.sdf                         # different world
./scripts/gz_rviz.sh bridge:='/cmd_vel@geometry_msgs/msg/Twist@gz.msgs.Twist'
make gz-rviz
```

This runs the bundled launch file
[config/launch/gz_rviz.launch.py](config/launch/gz_rviz.launch.py), which:

1. Starts `gz sim -r` with the given world
2. Bridges `/clock` (`gz.msgs.Clock` ↔ `rosgraph_msgs/msg/Clock`) so
   `use_sim_time` works
3. Optionally bridges any extra topics you pass via `bridge:=...`
4. Launches RViz2 with `use_sim_time: true` and the default config

To verify it's working, in another terminal:

```bash
./scripts/shell.sh
ros2 topic list                  # should include /clock + your extras
ros2 topic echo /clock --once    # should print a sim time
```

### Customizing the RViz config

The default config is just a starting point. To make your own permanent:

1. Open RViz, add/configure displays.
2. **File → Save Config As…** to a path under
   `~/ros2_ws/...` (host-mounted, persists across container restarts).
3. Next time: `./scripts/rviz.sh -d /home/ros/ros2_ws/your.rviz`.

Or edit [config/default.rviz](config/default.rviz) on the host and
`./scripts/build.sh` to bake it into the image.

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

Add your user to the docker group (logout/login or `newgrp docker` afterwards):
```bash
sudo usermod -aG docker $USER
newgrp docker
```
</details>

<details>
<summary><strong>"BuildKit is enabled but the buildx component is missing or broken"</strong></summary>

Ubuntu's `docker.io` package ships Docker without the `buildx` plugin.
`scripts/build.sh` detects this and falls back to the legacy builder
automatically. If you want BuildKit's speed/cache benefits:

```bash
sudo apt install docker-buildx        # Ubuntu 24.04+
# or, on systems with Docker's own repo:
sudo apt install docker-buildx-plugin
```

Or install Docker from
[Docker's official repository](https://docs.docker.com/engine/install/ubuntu/),
which bundles buildx.
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
│   ├── rviz.sh             # launch RViz2 (attaches to running container)
│   ├── gz_rviz.sh          # Gazebo + bridge + RViz via launch file
│   ├── stop.sh
│   ├── clean.sh
│   └── common.sh
├── config/
│   ├── default.rviz        # default RViz layout (TF, Grid, common displays)
│   └── launch/
│       └── gz_rviz.launch.py
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
