# HANDOFF — current state & next steps

> Update this file at the end of every work session (stand-up rule: commit + push).
> Last updated: 2026-08-05 (WSL)

## Where we are

**Phase 1, Week 1** (see BUILD_PLAN.md) — container verified, node code not yet written.

Done:
- Repo skeleton, plans, CLAUDE.md, identity setup on both machines ✅
- `docker/Dockerfile.dev` + `scripts/dev-shell.sh` — **build-tested and working on WSL**: Docker Desktop WSL integration confirmed enabled (`docker run hello-world` succeeds), image `edge-physical-ai-dev` builds clean, `./scripts/dev-shell.sh` drops into the container, and inside it `ros2 topic list` shows exactly `/parameter_events` and `/rosout` as expected.
- `ros2_ws/src/edge_bringup/` package **scaffolded** (`package.xml`, `setup.py`, `setup.cfg`, `resource/edge_bringup` marker, empty `edge_bringup/__init__.py`) — boilerplate only, per the hand-write/delegate split in CLAUDE.md. `setup.py` already declares `console_scripts` entry points for `talker`/`listener` pointing at modules that don't exist yet — that's intentional, it's the next step.

Decisions made:
- ROS distro = **Humble** everywhere in the pipeline (matches JetPack 6 / Ubuntu 22.04 on the Orin). Native ROS installs on host machines are fine for tutorials but stay OUT of the project graph — project nodes always run inside `scripts/dev-shell.sh`.
- Work directly on `main`, no feature branches for now.

## Next steps

### Either machine (container is confirmed working)
1. **HAND-WRITE** (don't delegate) `ros2_ws/src/edge_bringup/edge_bringup/talker.py` and `listener.py` — minimal `rclpy` publisher/subscriber pair, `main()` entry points already wired in `setup.py`.
2. Build with colcon inside the container: `cd /repo/ros2_ws && colcon build --packages-select edge_bringup && source install/setup.bash`.
3. Run `ros2 run edge_bringup talker` / `listener` in separate container shells; inspect with `ros2 topic echo/hz/info`.
4. Week 1 exit test: explain out loud what DDS gives you over raw MQTT — QoS (reliability/history/durability), the single-threaded executor spin loop, and timer callback rate vs achieved rate were covered this session and should be fresh.

### Home Ubuntu (when convenient, not blocking)
- Verify Docker + `./scripts/dev-shell.sh` there too (native X11 path in the script is untested).

## Open items / watch-outs
- **History was rewritten on 2026-07-17** (wording cleanup + force push). On the home machine, before doing anything else: `git fetch origin && git reset --hard origin/main`, then re-run `./scripts/install-hooks.sh` (the hook script changed).
- `dev-shell.sh` GUI passthrough: WSLg path written but untested; native X11 path untested.
- `edge_bringup` colcon build will fail until `talker.py`/`listener.py` exist (entry points reference them) — expected, not a bug.
