# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Edge Physical AI Pipeline — a miniature Physical AI stack:
ESP32/STM32 (micro-ROS) → Jetson Orin Nano (TensorRT INT8) → ROS 2 → learned policy → real actuators,
with an Isaac Sim / OpenUSD digital twin.

The repo is currently at the skeleton stage (see directory layout below) — no build system, code, or
tests exist yet. Work proceeds according to `BUILD_PLAN.md` (Phase 1: sensor node → edge inference)
and `BUILD_PLAN_PHASE2_PHASE3.md` (Phase 2: perception, Phase 3: learned policy + sim-to-real). Consult
those files for the current week's scope before starting work — do not build ahead of the active phase.

## Repository layout

- `firmware/esp32_sensor/`, `firmware/stm32_actuation/` — MCU firmware (micro-ROS clients)
- `ros2_ws/src/` — ROS 2 workspace (colcon packages)
- `perception/models/`, `perception/benchmarks/` — TensorRT models and benchmark results (Phase 2)
- `policy/lerobot/`, `policy/export/` — policy training (LeRobot) and exported inference artifacts (Phase 3)
- `sim/usd/`, `sim/isaac_lab/` — OpenUSD scene files and Isaac Lab sim-to-real work (Phase 3)
- `docker/` — dev container definitions
- `docs/` — engineering reports and phase writeups (benchmarks, sim-to-real notes, retros)

## Machine split

- **Home Ubuntu**: hardware machine. Flashing MCUs, wiring, camera/servo work, Jetson access. Personal
  git identity only (`hsinjlee <rlee4408@gmail.com>`).
- **WSL**: software-only. No flashing, USB, or camera work here. Repo lives under `~/p/` so git
  identity is scoped automatically via `includeIf` — never suggest `--global` git config changes on this
  machine, since it also holds a separate identity outside `~/p/`.
- `scripts/install-hooks.sh` installs a pre-commit hook that blocks commits made under any git identity
  other than the personal one — this is intentional and should not be bypassed or removed.

## Hand-write vs. delegate

This is a deliberate learning project — some code must be written by hand for interview fluency, the
rest is fair game to delegate:

**Hand-write (do not generate this code):**
- micro-ROS node lifecycle, executor setup, QoS choices
- TensorRT engine/context/bindings code and INT8 calibration logic
- Policy inference loop and safety/watchdog logic
- ROS 2 graph design decisions (topics, rates, QoS)

**Safe to write/generate:**
- CMakeLists.txt / package.xml, colcon workspace scaffolding
- Launch files, URDF/USD boilerplate, Dockerfiles
- Benchmark scripts, plotting, tegrastats parsers
- ONNX export scripts, dataset conversion glue
- README/docs drafting from the user's notes

## Constraints

- Never commit `*.engine`, `datasets/`, or video files (already covered by `.gitignore`).
- Don't add camera, servo, or flashing steps to anything that runs on the WSL machine.
