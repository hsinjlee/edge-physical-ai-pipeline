# BUILD_PLAN — Phase 1: Sensor Node → Edge Inference (Weeks 1–8)

Goal: a working micro-ROS sensor pipeline — **ESP32/STM32 nodes publishing real sensor data → Jetson Orin Nano running TensorRT inference → results on ROS 2 topics** — with everything reproducible from this repo.

Weekly rhythm: wsl (WSL) = write code with Claude Code; home (Ubuntu) = flash, wire, test on hardware. Morning blocks only after the job-hunt minimum is met.

---

## Week 1 — ROS 2 fundamentals (software only, no hardware needed)
- [ ] Docker dev environment working on both machines (`docker/Dockerfile.dev`, `scripts/dev-shell.sh`)
- [ ] Core concepts hands-on (type these yourself, don't delegate): nodes, topics, publishers/subscribers with `rclpy`; services vs topics; QoS basics (reliability, depth)
- [ ] Write a minimal talker/listener pair in `ros2_ws/src/edge_bringup`; build with colcon; inspect with `ros2 topic echo/hz/info`
- [ ] Exit test: explain out loud (interview practice) what DDS gives you over raw MQTT

## Week 2 — micro-ROS concepts + ESP32 first node
- [ ] micro-ROS architecture: client on MCU ↔ agent on host; transports (serial/UDP); executor model
- [ ] Follow the official micro-ROS ESP32 tutorial: publish a counter over Wi-Fi/UDP to the micro-ROS agent
- [ ] Home: flash ESP32, see the topic in `ros2 topic echo` on Ubuntu
- [ ] Exit test: draw the client/agent split from memory; explain why the agent exists

## Week 3 — Real sensor on ESP32
- [ ] Wire a real sensor (whatever is on hand — IMU over I2C is ideal; temperature works)
- [ ] Publish typed messages (`sensor_msgs/Imu` or similar) at a fixed rate; measure achieved rate with `ros2 topic hz`
- [ ] Handle Wi-Fi drop/reconnect gracefully (agent reconnection)
- [ ] Delegate to Claude Code: launch file that starts the agent + a logger node

## Week 4 — STM32F429ZI micro-ROS node (the differentiator)
- [ ] micro-ROS on STM32 with FreeRTOS; serial transport first (simplest), Ethernet/UDP as stretch
- [ ] Port one sensor (or synthetic data at fixed rate) to the STM32 node
- [ ] Hand-write the node lifecycle and executor setup — this is interview-critical
- [ ] Exit test: both MCU nodes visible in one `ros2 node list`; explain serial vs UDP transport tradeoffs

## Week 5 — Jetson Orin Nano bring-up + TensorRT basics
- [ ] JetPack verified: `trtexec` runs; clone repo on Orin
- [ ] Take a small pretrained model (ResNet18 or YOLOv8n) → ONNX → TensorRT FP16 engine ON THE ORIN
- [ ] Benchmark with `trtexec`: latency, throughput; record numbers in `perception/benchmarks/`
- [ ] Understand (hands-on): why engines are built per-GPU; workspace size; FP16 vs FP32

## Week 6 — Inference node on the Orin
- [ ] ROS 2 node on Orin (`edge_perception` package): subscribe to input, run TensorRT engine, publish results
- [ ] For now input can be synthetic/file-based (camera arrives in Phase 2) — the point is the ROS 2 ↔ TensorRT plumbing
- [ ] Hand-write the inference loop (context, bindings, streams); delegate the packaging/launch files
- [ ] Measure end-to-end: MCU sensor topic → Orin node reaction latency

## Week 7 — Integration: the full graph
- [ ] One launch file brings up: micro-ROS agent + ESP32 node + STM32 node + Orin inference node
- [ ] `ros2 topic hz`/`ros2 doctor` health check across the graph; document the topology
- [ ] Failure-mode notes in docs/: what happens when each node dies; restart behavior
- [ ] rqt_graph screenshot for the README

## Week 8 — Documentation + packaging (this is portfolio week, don't skip it)
- [ ] README: architecture diagram, quickstart, measured numbers table
- [ ] `docs/phase1_report.md`: what was built, rates achieved, latencies, lessons (write like an engineering report)
- [ ] Short demo video/GIF of the live graph
- [ ] Tag release `v0.1-phase1`; update repo description
- [ ] Retro: what to carry into Phase 2 (see BUILD_PLAN_PHASE2_PHASE3.md)

---

## Hand-write vs delegate (standing rule, also in CLAUDE.md)
- **You type:** micro-ROS node lifecycle, executor, QoS choices, TensorRT engine/context/bindings code
- **Claude Code:** CMakeLists/package.xml, Dockerfiles, launch files, benchmark scripts, plotting, docs drafts

## Exit criteria for Phase 1
Two MCU nodes (one wireless, one wired/serial) publishing real data into a ROS 2 graph where a Jetson TensorRT node consumes and republishes inference results — all launched from one command, all documented with measured numbers.
