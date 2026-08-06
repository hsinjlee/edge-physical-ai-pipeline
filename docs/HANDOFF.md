# HANDOFF — current state & next steps

> Update this file at the end of every work session (stand-up rule: commit + push).
> Last updated: 2026-08-06 (WSL)

## Where we are

**Phase 1, Week 1** (see BUILD_PLAN.md) — container verified on both machines' relevant sides, `talker.py` in progress (not yet written).

Done:
- Repo skeleton, plans, CLAUDE.md, identity setup on both machines ✅
- `docker/Dockerfile.dev` + `scripts/dev-shell.sh` — **build-tested and working on WSL**: Docker Desktop WSL integration confirmed enabled (`docker run hello-world` succeeds), image `edge-physical-ai-dev` builds clean, `./scripts/dev-shell.sh` drops into the container, and inside it `ros2 topic list` shows exactly `/parameter_events` and `/rosout` as expected. Re-confirmed working again this session (image still present, no rebuild needed).
- `ros2_ws/src/edge_bringup/` package **scaffolded** (`package.xml`, `setup.py`, `setup.cfg`, `resource/edge_bringup` marker, empty `edge_bringup/__init__.py`) — boilerplate only, per the hand-write/delegate split in CLAUDE.md. `setup.py` already declares `console_scripts` entry points for `talker`/`listener` pointing at modules that don't exist yet.
- **Home Ubuntu synced up to the rewritten history**: `git reset --hard origin/main` done, `./scripts/install-hooks.sh` re-run and verified (blocks commits unless `user.email` is `rlee4408@gmail.com`).
- This session (WSL): worked through `rclpy` doc-lookup approach (`help()` on `Node.create_publisher`/`create_timer`, `QoSProfile`, and the `demo_nodes_py` reference location) and started hand-writing `talker.py` — **no file written yet**, still at the lookup/planning stage inside the container.

Decisions made:
- ROS distro = **Humble** everywhere in the pipeline (matches JetPack 6 / Ubuntu 22.04 on the Orin). Native ROS installs on host machines are fine for tutorials but stay OUT of the project graph — project nodes always run inside `scripts/dev-shell.sh`.
- Work directly on `main`, no feature branches for now.

## Next steps

### WSL — pick this up next
1. **HAND-WRITE** (don't delegate) `ros2_ws/src/edge_bringup/edge_bringup/talker.py`, then `listener.py` — still not started as of this handoff. Enter the container with `./scripts/dev-shell.sh`, `cd ros2_ws/src/edge_bringup/edge_bringup`, and write `talker.py` there.
   - Doc lookups run **inside the container** only (`rclpy` isn't installed on the host) — `python3 -c "import rclpy.node; help(rclpy.node.Node.create_publisher)"` etc., or a second shell into the same running container via `docker exec -it edge-dev bash`.
   - Shape: `Node` subclass, explicit `QoSProfile` (reliability/history/durability — don't take the bare-int default without being able to justify it), `create_publisher(String, 'chatter', qos)`, `create_timer(period, cb)`, publish + log in the callback, `rclpy.spin()` in `main()`.
   - `listener.py` mirrors it with `create_subscription` — QoS must be **compatible** with the talker's or messages silently drop with no error.
2. Build with colcon inside the container: `cd /repo/ros2_ws && colcon build --packages-select edge_bringup && source install/setup.bash`.
3. Run `ros2 run edge_bringup talker` / `listener` in separate container shells; inspect with `ros2 topic echo/hz/info`.
4. Week 1 exit test: explain out loud what DDS gives you over raw MQTT — QoS (reliability/history/durability), the single-threaded executor spin loop, and timer callback rate vs achieved rate.

### Home Ubuntu — still pending from before
1. **Install Docker first — attempted this session, did NOT complete.** Ran `apt-get update` without `sudo` → `Permission denied` on the apt lock file, so nothing was actually installed (`docker-ce` absent from `dpkg -l`, `/usr/bin/docker` doesn't exist). Redo the full block with `sudo` on **every** `apt-get`/`install`/`tee` line:
   ```bash
   sudo apt-get update
   sudo apt-get install -y ca-certificates curl
   sudo install -m 0755 -d /etc/apt/keyrings
   sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
   sudo chmod a+r /etc/apt/keyrings/docker.asc
   echo \
     "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
     $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
     sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
   sudo apt-get update
   sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
   sudo usermod -aG docker $USER
   ```
   OS is Ubuntu 26.04 (`resolute`) — confirmed Docker's apt repo already lists `resolute`, no codename fallback needed. After `usermod`, log out/in (or `newgrp docker`) before `docker run hello-world` will work without `sudo`.
2. Once Docker's up there, same talker/listener task as the WSL section above — whichever machine gets there first, don't duplicate.

## Open items / watch-outs
- **Docker install incomplete on Home Ubuntu** — first attempt failed on a missing `sudo`, see Home Ubuntu step 1 above.
- `dev-shell.sh` GUI passthrough: WSLg path written but untested; native X11 path untested on Home Ubuntu.
- `edge_bringup` colcon build will fail until `talker.py`/`listener.py` exist (entry points reference them) — expected, not a bug.
- Common gotcha hit this session: running `rclpy`/`ros2`/`colcon` commands on the raw WSL **host** shell instead of inside the container — `rclpy` only exists inside `edge-physical-ai-dev`. Always check the prompt (`dev@docker-desktop` = inside container, `f042@...` = host).
