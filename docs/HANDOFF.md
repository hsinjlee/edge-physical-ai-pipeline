# HANDOFF — current state & next steps

> Update this file at the end of every work session (stand-up rule: commit + push).
> Last updated: 2026-10-21 (WSL) — synced with commit `22953df` (listener.py + CLAUDE.md now committed)

## Where we are

**Phase 1, Week 1** (see BUILD_PLAN.md) — `talker.py` hand-written, validated with a clean 6-minute soak on Home Ubuntu (stalls are WSL-only), and the `rclpy.ok()` shutdown fix is **committed** (`a9f2e77`, rebased from WSL's `c70c385`). `listener.py`'s two known bugs are **fixed** (hand-written by the user) and **committed** (`22953df`), but it is **not build-verified yet** — pick that up first (preferably on Home Ubuntu, since WSL has idle-throttle stalls).

Done:
- Repo skeleton, plans, CLAUDE.md, identity setup on both machines ✅
- `docker/Dockerfile.dev` + `scripts/dev-shell.sh` — build-tested and working on WSL and Home Ubuntu.
- `ros2_ws/src/edge_bringup/` package scaffolded — `package.xml` declares `<depend>rclpy</depend>` / `<depend>std_msgs</depend>`; `setup.py` entry points for `talker`/`listener` in place.
- **`talker.py` hand-written** (`ros2_ws/src/edge_bringup/edge_bringup/talker.py`): `Talker(Node)` with explicit `QoSProfile` (RELIABLE / KEEP_LAST depth=10 / VOLATILE), `create_publisher(String, 'chatter', qos)`, `create_timer(1.0, self.on_timer)` for 1 Hz. `main()` does `rclpy.init` → construct → `try: rclpy.spin(node) finally: destroy_node(); if rclpy.ok(): rclpy.shutdown()`.
- **Shutdown fix committed** (WSL): `rclpy.init()` installs a SIGINT handler that shuts the context down before the `KeyboardInterrupt` reaches `finally`, so the unconditional `rclpy.shutdown()` raised `RCLError: rcl_shutdown already called`. Guarded with `rclpy.ok()`.
- **Build + run verified** on WSL: `ros2 topic hz /chatter` measured `average rate: 1.000` (std dev <1.3ms) for the first several samples.
- **Home Ubuntu Docker install done (2026-10-19).** Docker Engine 29.9.1 from Docker's official apt repo, user `casa` in the `docker` group. Host is Ubuntu **26.04 "resolute"**, so `/etc/apt/sources.list.d/docker.list` is pinned to **`noble`**.
- **Home Ubuntu dev environment verified (2026-10-19 evening).** `docker run hello-world` works without sudo, dev image `edge-physical-ai-dev` built (4.93 GB), `colcon build --packages-select edge_bringup` succeeds inside the container.
- **6-minute native soak: clean.** `average rate: 1.000` in all 225 readings over 357 messages, min 0.999 s / max 1.001 s, std dev 0.32 ms. So the stall is a WSL2/Docker Desktop issue, not a code bug. (Ran in a detached container via `docker exec`, not through `dev-shell.sh`.)
- **`listener.py` bugs fixed** (WSL, `ros2_ws/src/edge_bringup/edge_bringup/listener.py`, committed in `22953df`):
  - Deleted the leftover `on_timer` method copy-pasted from talker.
  - Fixed `main()` to instantiate `Listener()` instead of the stale `Talker()`.
  - QoS (matching talker), `create_subscription`, and the `if rclpy.ok():` guard were already correct.
- **CLAUDE.md updated** (committed in `22953df`): for hand-write-list code, walk the user through what the code means and why instead of handing over a fix. Also fixed two markdownlint blanks-around-lists warnings.

Decisions made:
- ROS distro = **Humble** everywhere in the pipeline (matches JetPack 6 / Ubuntu 22.04 on the Orin). Native ROS installs on host machines stay OUT of the project graph — project nodes always run inside `scripts/dev-shell.sh`.
- Work directly on `main`, no feature branches for now.
- QoS for `chatter`: RELIABLE, KEEP_LAST depth=10, VOLATILE.
- CLAUDE.md hand-write policy clarified (see above).
- WSL2/Docker idle-throttle investigation deprioritized — native soak proves the code is fine.

## Next steps

Prefer Home Ubuntu for steps 2–3 (WSL has idle-throttle stalls). Don't duplicate steps across machines.

1. **Enter the dev container** (never run `colcon`/`ros2` on the raw host shell): `scripts/dev-shell.sh` from the repo root. Confirm the prompt (`dev@docker-desktop:/repo$` on WSL, `dev@casa-G5-KF5:/repo$` on Home Ubuntu).
2. Inside the container: `cd ros2_ws && source /opt/ros/humble/setup.bash && colcon build --packages-select edge_bringup` — first real build of the fixed `listener.py`.
3. `source install/setup.bash`, run talker + listener in **separate shells** (second shell: `docker exec -it edge-dev bash`) — confirm `Received: "hello world: N"` matches the talker's sequence. Also Ctrl+C the talker and confirm it exits with no traceback (verifies the shutdown fix).
4. Record the build/run result in this handoff, commit + push.
5. Week 1 exit test: explain out loud what DDS gives you over raw MQTT — QoS (reliability/history/durability), the single-threaded executor spin loop, and timer callback rate vs achieved rate (the WSL idle-throttle stall is good bonus material).

## Open items / watch-outs
- **`listener.py` is committed but not build-verified** — first `colcon build` + talker/listener run still pending.
- **WSL2/Docker Desktop idle-throttling — deprioritized, unresolved, confirmed WSL-only.** Multi-minute publish stalls (~150s, ~300s, one ~597s) persisted through: Resource Saver off, `.wslconfig` `vmIdleTimeout=-1` + verified `wsl --shutdown`, full Docker Desktop restart, Windows USB selective-suspend off, PCIe Link State Power Management off, sleep/screen timeout Never. Next unexplored lead if ever needed: `%APPDATA%\Docker\settings-store.json` for an `autoPauseTimeoutSeconds`-type key.
- **Home Ubuntu Docker repo is pinned to `noble`** because the host runs 26.04 "resolute". Switch to `resolute` once Docker publishes it.
- **Claude Code can't run `sudo` on Home Ubuntu** (no TTY for the password prompt). Run sudo steps yourself and paste the output back.
- `dev-shell.sh` GUI passthrough: WSLg path untested; native X11 path untested on Home Ubuntu.
- Common gotcha: running `ros2`/`colcon` on the raw **host** shell instead of inside the container. Always check the prompt (`f042@...` = WSL host).
