# HANDOFF — current state & next steps

> Update this file at the end of every work session (stand-up rule: commit + push).
> Last updated: 2026-10-19 evening (Home Ubuntu)

## Where we are

**Phase 1, Week 1** (see BUILD_PLAN.md) — `talker.py` hand-written, built, and validated with a clean 6-minute soak on Home Ubuntu (no stalls, so the stalls only happen on WSL). Next up: hand-write the `rclpy.ok()` shutdown fix in `talker.py`, then `listener.py`.

Done:
- Repo skeleton, plans, CLAUDE.md, identity setup on both machines ✅
- `docker/Dockerfile.dev` + `scripts/dev-shell.sh` — build-tested and working on WSL (carried over from prior sessions).
- `ros2_ws/src/edge_bringup/` package scaffolded — `package.xml` already declares `<depend>rclpy</depend>` / `<depend>std_msgs</depend>`; `setup.py` entry points for `talker`/`listener` in place.
- **`talker.py` hand-written this session** (`ros2_ws/src/edge_bringup/edge_bringup/talker.py`): `Talker(Node)` with explicit `QoSProfile` (RELIABLE / KEEP_LAST depth=10 / VOLATILE, reasoned through rather than defaulted), `create_publisher(String, 'chatter', qos)`, `create_timer(1.0, self.on_timer)` for 1 Hz, `on_timer` builds/publishes/logs a `hello world: N` message. `main()` does `rclpy.init` → construct → `try: rclpy.spin(node) finally: destroy_node(); rclpy.shutdown()`.
- **Build + run verified**: `colcon build --packages-select edge_bringup` succeeds (only harmless setuptools dash-vs-underscore deprecation warnings). `ros2 run edge_bringup talker` runs; `ros2 topic list` shows `/chatter` alongside `/parameter_events`/`/rosout`; `ros2 topic hz /chatter` measured a clean `average rate: 1.000` (std dev <1.3ms) for the first several samples — **this is the real proof the node logic is correct.**
- `talker.py` is committed and pushed (pulled onto Home Ubuntu 2026-10-19). The `rclpy.ok()` shutdown fix is still not applied.
- **Home Ubuntu Docker install done (2026-10-19).** Docker Engine 29.9.1 from Docker's official apt repo, service `active`, user `casa` added to the `docker` group. Host is Ubuntu **26.04 "resolute"**, which Docker's repo doesn't ship yet, so `/etc/apt/sources.list.d/docker.list` is pinned to **`noble`**. The packages installed and the service runs fine on that pin.
- **Home Ubuntu dev environment verified (2026-10-19 evening).** After relogin, the `docker` group is active and `docker run hello-world` works without sudo. Dev image `edge-physical-ai-dev` built (4.93 GB). `colcon build --packages-select edge_bringup` succeeds inside the container.
- **6-minute native soak: clean.** `ros2 topic hz /chatter` gave `average rate: 1.000` in all 225 readings over 357 messages, with min 0.999 s / max 1.001 s and std dev 0.32 ms. No stalls. On WSL the same code stalled for ~148 s within a few minutes, so the stall is a WSL2/Docker Desktop issue, not a code bug. (This soak ran in a detached container via `docker exec`, not through `dev-shell.sh`.)

Bugs found this session:
1. **Known, not yet fixed — `rclpy.shutdown()` double-call on Ctrl+C.** `main()`'s `finally` block unconditionally calls `rclpy.shutdown()`, but `rclpy.init()` installs its own SIGINT handler that shuts the context down *before* the `KeyboardInterrupt` from the interrupted `spin()` wait call reaches your `finally`. Result: `RCLError: failed to shutdown: rcl_shutdown already called on the given context`. Fix (per CLAUDE.md hand-write policy, this is node-lifecycle code — write it yourself, don't delegate):
   ```python
   finally:
       node.destroy_node()
       if rclpy.ok():
           rclpy.shutdown()
   ```
2. **Environment issue, confirmed WSL-only — periodic multi-minute publish stalls.** (The 6-minute native soak on Home Ubuntu was clean, so this happens only on WSL. WSL `.wslconfig` fix below is still unverified.) `ros2 topic hz /chatter` showed the rate suddenly crater from `1.000` to `~0.03–0.07` with `max` gaps of ~147.9s and ~294.9s (a clean 2x multiple) recurring throughout a run. Not a code bug — the *first* several samples were clean 1 Hz, and a `create_timer` callback has no mechanism to silently skip 147 seconds. Diagnosed as the WSL2 VM / Docker Desktop backend being paused during idle periods.
   - Disabled Docker Desktop's **Resource Saver** setting (Settings → General) — did **not** fully fix it; stall pattern recurred identically afterward.
   - Created `C:\Users\F042\.wslconfig` (didn't exist before) with:
     ```ini
     [wsl2]
     vmIdleTimeout=-1
     ```
     to also disable WSL2's own VM idle-suspend timeout.
   - **Not yet verified.** Applying this requires `wsl --shutdown` run from an actual **Windows PowerShell/cmd window** (not a WSL bash shell — bash can't shut down the VM it's running inside of). First attempt at retesting found the old `edge-dev` container still `Up` with the `talker` process (PIDs 38/39) still alive inside it, which means the WSL shutdown either wasn't run yet or didn't reach Docker Desktop's backend — so this fix is unconfirmed as of this handoff.

Decisions made:
- ROS distro = **Humble** everywhere in the pipeline (matches JetPack 6 / Ubuntu 22.04 on the Orin). Native ROS installs on host machines are fine for tutorials but stay OUT of the project graph — project nodes always run inside `scripts/dev-shell.sh`.
- Work directly on `main`, no feature branches for now.
- QoS reasoning for `chatter`: RELIABLE (every message matters for now, revisit for high-rate sensor topics later), KEEP_LAST depth=10 (no replay-everything requirement), VOLATILE (late subscribers don't need history replayed — that's for something like a static config/URDF topic instead).

## Next steps

### WSL — pick this up next
1. **Confirm the WSL2/Docker idle-throttle fix**, from a real Windows PowerShell/cmd window (not this WSL bash):
   - Close all WSL terminal windows first.
   - Run `wsl --shutdown` in PowerShell.
   - Reopen a WSL terminal, then `docker ps -a --filter "name=edge-dev"` should come back empty (confirms the VM actually restarted and the old `--rm` container is gone).
2. Redo the full flow: `./scripts/dev-shell.sh` → `cd ros2_ws` → `source install/setup.bash` → `ros2 run edge_bringup talker`; second shell via `docker exec -it edge-dev bash` → `source install/setup.bash` → `ros2 topic hz /chatter`, soaked for **5+ minutes** this time (the stall didn't appear until well past the first minute previously).
3. Once the rate stays a clean `1.000` throughout — **hand-write** the `if rclpy.ok():` guard fix into `talker.py`'s `main()` (see bug #1 above), rebuild, and verify Ctrl+C now exits cleanly with no traceback.
4. Commit `talker.py` (plus this handoff update).
5. **HAND-WRITE** `listener.py` next, mirroring `talker.py`'s structure with `create_subscription` instead of `create_publisher`/`create_timer` — QoS must be **compatible** with the talker's (same reliability/durability, or subscriber's must be a subset) or messages silently drop with no error, no exception.
6. Build (`colcon build --packages-select edge_bringup`), run talker + listener in separate shells, confirm messages flow end to end.
7. Week 1 exit test: explain out loud what DDS gives you over raw MQTT — QoS (reliability/history/durability), the single-threaded executor spin loop, and timer callback rate vs achieved rate (now with a real example of *why* achieved rate can lie to you — the idle-throttle stall — as a bonus talking point).

### Home Ubuntu — pick this up next (tomorrow)
Steps 1–4 from last time (relogin, hello-world, image build, native soak) are ✅ done. Resume here, going one step at a time:
1. **Reproduce the bug first.** `./scripts/dev-shell.sh` → prompt becomes `dev@casa-G5-KF5:/repo$` → `cd ros2_ws && source install/setup.bash && ros2 run edge_bringup talker` → let it print 3–4 lines → **Ctrl+C**. Expect a traceback ending in `RCLError: failed to shutdown: rcl_shutdown already called on the given context`. (This is also the first interactive `dev-shell.sh` run on Home Ubuntu.)
2. **Hand-write** the `if rclpy.ok():` guard into `main()`'s `finally` block in `talker.py` (lines 38–40; see bug #1 above).
3. Rebuild (`colcon build --packages-select edge_bringup`, re-`source install/setup.bash`), run talker, Ctrl+C → should exit with no traceback.
4. Commit the fix.
5. Continue with WSL steps 5–7 above (`listener.py`, end-to-end test, Week 1 exit test). Don't do the same step on both machines.
- The WSL `.wslconfig` check (WSL step 1) is now lower priority, since the code is proven fine. Do it the next time you're on WSL.
- Still untested: X11 GUI passthrough (`rqt`/`rviz`) via `dev-shell.sh` on Home Ubuntu.

## Open items / watch-outs
- **WSL2/Docker Desktop idle-throttling** — root cause of the multi-minute publish stalls; Resource Saver disabled, `.wslconfig` `vmIdleTimeout=-1` added but **unconfirmed**. If the stall recurs even after a real `wsl --shutdown`, the next thing to check is Windows' own USB/PCIe selective-suspend or sleep settings, or whether Docker Desktop has a separate "pause idle containers" toggle beyond Resource Saver.
- **`rclpy.shutdown()` double-call bug** in `talker.py` — identified, fix known, not yet applied (see bug #1 above). Don't let this slip into `listener.py` too — same guard needed there.
- **Home Ubuntu Docker repo is pinned to `noble`** because the host runs 26.04 "resolute". Once Docker publishes a `resolute` suite, switch `/etc/apt/sources.list.d/docker.list` over to it.
- **Claude Code can't run `sudo` on Home Ubuntu** because it has no TTY for the password prompt. Run sudo steps yourself in a terminal and paste the output back.
- `dev-shell.sh` GUI passthrough: WSLg path written but untested; native X11 path untested on Home Ubuntu.
- Common gotcha, recurred this session: running `ros2`/`colcon` commands on the raw WSL **host** shell instead of inside the container. Always check the prompt (`dev@docker-desktop` = inside container, `f042@...` = host).
- `edge_bringup` colcon build will fail until `listener.py` exists if you try `ros2 run edge_bringup listener` (entry point references it) — expected, not a bug, until step 5 above is done.
