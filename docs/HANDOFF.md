# HANDOFF — current state & next steps

> Update this file at the end of every work session (stand-up rule: commit + push).
> Last updated: 2026-07-17 (WSL)

## Where we are

**Phase 1, Week 1** (see BUILD_PLAN.md) — just started.

Done:
- Repo skeleton, plans, CLAUDE.md, identity setup on both machines ✅
- `docker/Dockerfile.dev` (ROS 2 Humble desktop, non-root user) + `scripts/dev-shell.sh` — committed as `4d591d0`, **not yet build-tested**

Decisions made:
- ROS distro = **Humble** everywhere in the pipeline (matches JetPack 6 / Ubuntu 22.04 on the Orin). Native ROS installs on host machines (e.g. Lyrical at home) are fine for tutorials but stay OUT of the project graph — project nodes always run inside `scripts/dev-shell.sh`.
- Work directly on `main`, no feature branches for now.

## Next steps

### WSL (blocker to clear first)
1. **Enable Docker Desktop → Settings → Resources → WSL integration** for this Ubuntu distro — `docker` is not usable from WSL until then.
2. Run `./scripts/dev-shell.sh` — first run builds the image (~3 GB pull). Verify inside: `ros2 topic list` shows `/parameter_events` and `/rosout`.

### Either machine (once the container works)
3. Week 1 hands-on (HAND-WRITE, don't delegate): `rclpy` talker/listener pair in `ros2_ws/src/edge_bringup`; build with colcon; inspect with `ros2 topic echo/hz/info`. Claude Code may scaffold `package.xml`/`setup.py` only.
4. Week 1 exit test: explain out loud what DDS gives you over raw MQTT.

### Home Ubuntu (when convenient, not blocking)
- Verify Docker + `./scripts/dev-shell.sh` there too (native X11 path in the script is untested).

## Open items / watch-outs
- `dev-shell.sh` GUI passthrough: WSLg path written but untested; native X11 path untested.
- Nothing else pending — working tree was clean at handoff.
