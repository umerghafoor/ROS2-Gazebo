# syntax=docker/dockerfile:1.6
ARG UBUNTU_VERSION=24.04
FROM ubuntu:${UBUNTU_VERSION}

ARG ROS_DISTRO=jazzy
ARG GZ_DISTRO=harmonic
ARG USERNAME=ros
ARG USER_UID=1000
ARG USER_GID=1000

ENV ROS_DISTRO=${ROS_DISTRO} \
    GZ_DISTRO=${GZ_DISTRO} \
    DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    TZ=Etc/UTC \
    NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=all

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && apt-get install -y --no-install-recommends \
        locales \
        curl \
        gnupg2 \
        lsb-release \
        ca-certificates \
        software-properties-common \
        sudo \
        tzdata \
    && locale-gen en_US en_US.UTF-8 \
    && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 \
    && ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime \
    && dpkg-reconfigure -f noninteractive tzdata \
    && rm -rf /var/lib/apt/lists/*

RUN add-apt-repository universe \
    && export ROS_APT_SOURCE_VERSION=$(curl -s https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest \
        | grep -F '"tag_name"' | cut -d'"' -f4) \
    && curl -fsSL -o /tmp/ros2-apt-source.deb \
        "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.$(. /etc/os-release && echo $VERSION_CODENAME)_all.deb" \
    && apt-get update \
    && apt-get install -y /tmp/ros2-apt-source.deb \
    && rm /tmp/ros2-apt-source.deb

RUN curl -fsSL https://packages.osrfoundation.org/gazebo.gpg \
        -o /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" \
        > /etc/apt/sources.list.d/gazebo-stable.list

RUN apt-get update && apt-get install -y --no-install-recommends \
        ros-${ROS_DISTRO}-desktop \
        ros-dev-tools \
        ros-${ROS_DISTRO}-ros-gz \
        ros-${ROS_DISTRO}-ros-gz-bridge \
        ros-${ROS_DISTRO}-ros-gz-sim \
        ros-${ROS_DISTRO}-ros-gz-image \
        ros-${ROS_DISTRO}-rviz2 \
        gz-${GZ_DISTRO} \
        python3-colcon-common-extensions \
        python3-rosdep \
        python3-vcstool \
        python3-argcomplete \
        build-essential \
        cmake \
        git \
        nano \
        vim \
        less \
        wget \
        bash-completion \
        mesa-utils \
        libgl1-mesa-dri \
        x11-apps \
        x11-utils \
    && rosdep init \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid ${USER_GID} ${USERNAME} \
    && useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} -s /bin/bash \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

USER ${USERNAME}
WORKDIR /home/${USERNAME}

RUN rosdep update \
    && mkdir -p /home/${USERNAME}/ros2_ws/src \
    && echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> /home/${USERNAME}/.bashrc \
    && echo "[ -f /home/${USERNAME}/ros2_ws/install/setup.bash ] && source /home/${USERNAME}/ros2_ws/install/setup.bash" >> /home/${USERNAME}/.bashrc \
    && echo "export GZ_VERSION=${GZ_DISTRO}" >> /home/${USERNAME}/.bashrc

COPY --chown=${USERNAME}:${USERNAME} config/default.rviz /home/${USERNAME}/.rviz2/default.rviz
COPY --chown=${USERNAME}:${USERNAME} config/launch/ /home/${USERNAME}/.config/ros2-gazeebo/launch/

COPY --chown=${USERNAME}:${USERNAME} docker/entrypoint.sh /usr/local/bin/entrypoint.sh
USER root
RUN chmod +x /usr/local/bin/entrypoint.sh
USER ${USERNAME}

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash"]
