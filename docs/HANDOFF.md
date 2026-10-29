# HANDOFF — current state & next steps

> Update this file at the end of every work session (stand-up rule: commit + push).
> Last updated: 2026-10-29 end of session (Home Ubuntu) — Week 1 build items done; exit-test quiz in progress (resume at Q2)

## Where we are

**Phase 1, Week 1** (see BUILD_PLAN.md) — `talker.py` and `listener.py` are both hand-written, **build-verified and run-verified together on Home Ubuntu** (2026-10-29), and both now exit cleanly on Ctrl+C (no traceback). All Week 1 build/run steps are done, plus `ros2 topic echo/hz/info` inspection and a `~/reset_count` service (services vs topics) — only the Week 1 exit test (explain DDS vs MQTT) remains. It's being run as a 6-question quiz with Claude (teach on gaps); **Q1 done, resume at Q2**.

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
- **talker + listener build + run verified on Home Ubuntu (2026-10-29).** `colcon build --packages-select edge_bringup` clean (only setuptools `script-dir` deprecation warnings). Listener received `hello world: 0`–`5` in order, ~1 ms after each publish. (Ran both nodes in one detached container via `docker exec`, SIGINT sent with `timeout -s INT`.)
- **Clean Ctrl+C exit fix** (hand-written by the user, both nodes): the `rclpy.ok()` guard only removed the *second* error (`RCLError`); the original `KeyboardInterrupt` still escaped `try/finally` (finally runs cleanup but doesn't catch) and printed a traceback. Added `except KeyboardInterrupt: pass` between `try` and `finally` — `except` decides which exits are normal, `finally` still cleans up on *every* exit path. Re-tested: no traceback on either node.
- **Topic inspection verified (2026-10-29):** `ros2 topic info -v /chatter` shows the talker's QoS (RELIABLE / VOLATILE; depth reports UNKNOWN — normal for remote endpoints), `echo` shows the sequence, `hz` = `average rate: 1.000`, std dev ~0.15 ms.
- **Services vs topics: `~/reset_count` service added to the talker** (`std_srvs/Trigger`, `std_srvs` added to package.xml). `ros2 service call /talker/reset_count std_srvs/srv/Trigger` → `success=True, message='count reset from 4 to 0'`; publishing continued from 0. Topic = one-way stream, many subscribers, fire-and-forget; service = request/response with a reply, one server.
- **CLAUDE.md updated** (committed in `22953df`): for hand-write-list code, walk the user through what the code means and why instead of handing over a fix. Also fixed two markdownlint blanks-around-lists warnings. *(Superseded 2026-10-29: hand-write rule removed — see Decisions.)*

Decisions made:
- ROS distro = **Humble** everywhere in the pipeline (matches JetPack 6 / Ubuntu 22.04 on the Orin). Native ROS installs on host machines stay OUT of the project graph — project nodes always run inside `scripts/dev-shell.sh`.
- Work directly on `main`, no feature branches for now.
- QoS for `chatter`: RELIABLE, KEEP_LAST depth=10, VOLATILE.
- **Hand-write rule dropped (2026-10-29):** all remaining code is delegated to Claude Code. Removed from CLAUDE.md and both build plans.
- WSL2/Docker idle-throttle investigation deprioritized — native soak proves the code is fine.

## Next steps

Don't duplicate steps across machines. To build/run: `scripts/dev-shell.sh`, then `cd ros2_ws && source /opt/ros/humble/setup.bash && colcon build --packages-select edge_bringup && source install/setup.bash` (never on the raw host shell).

1. **Resume the Week 1 exit-test quiz at Q2** — ask Claude to "continue the quiz at Q2". Format: one question at a time, user answers in own words; if the user doesn't know, teach the gap, then a quick check question. Plan:
   - ~~Q1 Architecture~~ ✅ (taught — see quiz notes below)
   - **Q2 QoS** (asked, not yet answered): a) what RELIABLE / KEEP_LAST depth=10 / VOLATILE each mean; b) 30 Hz camera stream — keep RELIABLE or switch to BEST_EFFORT, and why. Also: QoS compatibility (why the listener had to match the talker).
   - Q3 Typed messages: DDS/IDL types (`std_msgs/String`) vs MQTT opaque byte payloads.
   - Q4 Topics vs services (+ actions): use the `~/reset_count` service as the example.
   - Q5 Executor: single-threaded `rclpy.spin()` loop, slow callback blocks the rest, timer rate vs achieved rate (WSL stall as the real example). Bonus: `except KeyboardInterrupt` + `finally` vs cleanup in `except`.
   - Q6 When MQTT wins: WAN/cloud, constrained links; DDS multicast discovery doesn't cross subnets → bridge into Week 2 (why micro-ROS needs an agent).
2. After the quiz passes, tick the Week 1 exit-test box in BUILD_PLAN.md.
3. Week 2 (micro-ROS + ESP32): start by adding the micro-ROS agent + ESP-IDF toolchain (to `Dockerfile.dev` or a separate agent container). Flashing happens on Home Ubuntu only.

Quiz notes so far (2026-10-29):
- **Q1 — taught from scratch** (user didn't know). MQTT = central broker, 2 hops, broker is a single point of failure; DDS = no broker, discovery via UDP multicast (why `--network host`), then direct 1-hop peer-to-peer. Check question: user got "broker crash stops everything" and "DDS survives a node crash" right, but **wrongly said an ordinary node crash breaks MQTT** — corrected: a non-broker node crash is equivalent in both; the difference is only the broker. Worth a quick re-check tomorrow.
- **Acronyms (user asked):** DDS = Data Distribution Service (OMG standard; Fast DDS default in Humble, Cyclone, RTI Connext; defense/industrial roots). MQTT = originally MQ Telemetry Transport (IBM 1999, oil-pipeline satellite telemetry; now officially just a name, OASIS standard). Origin explains design: few devices + thin link + central collector → broker; many real-time peers + no central failure → peer-to-peer.

## Open items / watch-outs
- **WSL2/Docker Desktop idle-throttling — deprioritized, unresolved, confirmed WSL-only.** Multi-minute publish stalls (~150s, ~300s, one ~597s) persisted through: Resource Saver off, `.wslconfig` `vmIdleTimeout=-1` + verified `wsl --shutdown`, full Docker Desktop restart, Windows USB selective-suspend off, PCIe Link State Power Management off, sleep/screen timeout Never. Next unexplored lead if ever needed: `%APPDATA%\Docker\settings-store.json` for an `autoPauseTimeoutSeconds`-type key.
- **Home Ubuntu Docker repo is pinned to `noble`** because the host runs 26.04 "resolute". Switch to `resolute` once Docker publishes it.
- **Claude Code can't run `sudo` on Home Ubuntu** (no TTY for the password prompt). Run sudo steps yourself and paste the output back.
- `dev-shell.sh` GUI passthrough: WSLg path untested; native X11 path untested on Home Ubuntu.
- Common gotcha: running `ros2`/`colcon` on the raw **host** shell instead of inside the container. Always check the prompt (`f042@...` = WSL host).
