# Contributing to ROS2-Gazeebo

Thanks for your interest in contributing! This project is fully open source
under the Apache 2.0 license, and contributions of any size are welcome.

## Ways to help

- **Bug reports** — open a GitHub issue with reproduction steps, host OS,
  Docker version, GPU (if any), and the exact command that failed.
- **Pull requests** — bug fixes, new ROS distro / Gazebo combos, doc
  improvements, additional helper scripts.
- **Examples** — add minimal example packages under `workspace/src/` and a
  short note in the README.

## Development workflow

1. Fork the repo and create a feature branch:

   ```bash
   git checkout -b feat/short-description
   ```

2. Make your changes. Keep commits focused and write clear messages.
3. Test locally — at minimum:

   ```bash
   ./scripts/build.sh
   ./scripts/demo.sh
   ```

4. Run shellcheck on any modified scripts:

   ```bash
   shellcheck scripts/*.sh docker/entrypoint.sh
   ```

5. Open a pull request against `main` and describe what you changed and why.

## Style

- Bash: `set -euo pipefail`, quote variables, `shellcheck`-clean.
- Dockerfile: pin distro versions via `ARG`, clean up apt lists in the same
  `RUN`, group related installs to limit layers.
- Keep helper scripts idempotent — running them twice should be a no-op.

## Adding a new ROS / Gazebo combination

The Dockerfile is parameterized via build args. To add a new combination:

1. Verify the upstream pairing on the ROS docs
   (https://docs.ros.org/en/rolling/Releases.html) and on the Gazebo
   compatibility matrix (https://gazebosim.org/docs/).
2. Build with overrides:

   ```bash
   ROS_DISTRO=humble GZ_DISTRO=fortress UBUNTU_VERSION=22.04 ./scripts/build.sh
   ```

3. If it works, add a note to the README's compatibility table and open a PR.

## Code of conduct

Be kind. Assume good faith. We follow the
[Contributor Covenant](https://www.contributor-covenant.org/version/2/1/code_of_conduct/).
