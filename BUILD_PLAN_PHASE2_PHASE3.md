# BUILD_PLAN — Phase 2 & 3 Extension: Perception + Policy Deployment

Extends the existing 8-week plan (Phase 1: ESP32/STM32 micro-ROS → Jetson Orin Nano TensorRT → ROS 2).
Goal: evolve the repo from "edge AI pipeline" into a miniature Physical AI stack —
**perception → learned policy → real-time actuation**, with a sim-to-real link via Isaac Sim/OpenUSD.

---

## Phase 2 — Perception Layer (Weeks 9–14)

**Narrative for recruiters:** "I added a camera to my edge node and run quantized perception models on Orin, publishing structured ROS 2 outputs, with INT8/FP16 benchmark analysis."

### Week 9–10: Camera bring-up + baseline detection
- [ ] Connect camera (USB webcam is fine to start; CSI camera optional later)
- [ ] `v4l2` verification → ROS 2 `image_raw` publisher (`v4l2_camera` or `gscam` node)
- [ ] Run YOLOv8n / YOLO11n via TensorRT on Orin; publish `vision_msgs/Detection2DArray`
- [ ] Record baseline: FPS, latency (camera → detection topic), GPU utilization

### Week 11–12: Quantization benchmark report
- [ ] Export ONNX → TensorRT engines: FP16 and INT8 (calibration dataset from own captures)
- [ ] Benchmark table: latency / throughput / mAP delta / power draw (tegrastats)
- [ ] Nsight Systems trace of the full ROS 2 pipeline — identify copy vs compute bottlenecks
- [ ] Write `docs/perception_benchmarks.md` as an engineering report (this is the interview artifact)

### Week 13–14: Depth + spatial output
- [ ] Monocular depth (Depth Anything V2 small, TensorRT-quantized) on the same camera
      — no depth camera required; upgrade to RealSense D435i later only if grasping demos need it
- [ ] Fuse detection + depth → publish 3D object positions (`geometry_msgs/PoseStamped`)
- [ ] Optional stretch: Isaac ROS Visual SLAM (`isaac_ros_visual_slam`) for odometry
- [ ] Close the loop conceptually: STM32 IMU data + camera odometry on the same ROS 2 graph

**Phase 2 exit criteria:** camera → quantized perception → 3D pose topics at ≥15 FPS on Orin Nano, with a written benchmark report and Nsight traces committed to the repo.

---

## Phase 3 — Learned Policy on Real Hardware (Weeks 15–22)

**Narrative for recruiters:** "I deploy vision-language-action / imitation-learning policies on edge GPU and drive real actuators — the same architecture as a humanoid stack, in miniature."

### Week 15–16: Actuation node
- [ ] Minimal actuator rig — pick one:
  - **Budget path:** 2× hobby servos (pan-tilt) driven by STM32F429ZI PWM → object-tracking demo
  - **Standard path:** LeRobot SO-101 arm (community-standard, ~US$100–250 in parts, Feetech servos)
- [ ] STM32 firmware: receive joint commands over micro-ROS, publish joint states at fixed rate
- [ ] Safety layer: command clamping, watchdog timeout, e-stop topic

### Week 17–19: Policy training + deployment
- [ ] LeRobot toolchain: teleoperate (keyboard/leader arm), record 30–50 demo episodes
- [ ] Train ACT or diffusion policy (train on RTX 6000 / DGX Spark at work, or rent cloud GPU)
- [ ] Export policy → ONNX → TensorRT on Orin; benchmark inference latency vs PyTorch
- [ ] Closed loop: camera → policy inference on Orin → joint commands → STM32 → servos

### Week 20–21: Sim-to-real bridge (differentiator)
- [ ] Model the physical rig in OpenUSD; import into Isaac Sim (Omniverse access at work)
- [ ] Simulate the same camera + joints; run the same ROS 2 graph against sim
- [ ] Document the digital-twin workflow in `docs/sim_to_real.md`; cross-link `openUSD-physical-ai-pipeline`
- [ ] Optional stretch: evaluate GR00T N1 / OpenVLA checkpoint inference on Orin (even benchmark-only is portfolio-worthy)

### Week 22: Packaging
- [ ] Demo video (60–90 s): real rig + sim twin side by side
- [ ] Architecture diagram in README: sensor node → perception → policy → actuation
- [ ] Pin repo, write profile README section, prepare 3 interview stories from the build

**Phase 3 exit criteria:** a learned policy running TensorRT-quantized on Orin, controlling physical servos via micro-ROS/STM32, with an Isaac Sim digital twin of the same rig.

---

## Equipment & Budget

| Item | Purpose | Cost (approx.) | Required? |
|---|---|---|---|
| USB webcam (Logitech C270/C920 class) | Phase 2 perception | NT$500–1,500 | Yes (cheapest entry) |
| 2× hobby servos + pan-tilt bracket | Phase 3 budget path | NT$300–800 | Yes (budget path) |
| STM32F429ZI Nucleo | Actuation node | already planned | Yes |
| LeRobot SO-101 arm kit | Phase 3 standard path | ~NT$3,000–8,000 | Optional upgrade |
| Raspberry Pi Camera Module 3 (CSI) | Lower-latency camera | ~NT$1,000 | Optional |
| Intel RealSense D435i | Hardware depth | ~NT$10,000 | No — monocular depth first |

**Minimum viable budget: ~NT$1,000–2,500** (webcam + servos). Everything else uses hardware already owned or available at work (Orin Nano, ESP32, STM32, RTX 6000, Omniverse).

---

## Claude Code Delegation Map

Per established methodology — hands-on for interview-critical concepts, delegate plumbing:

**Type it yourself (interview fluency):**
- micro-ROS node lifecycle, executor, QoS settings
- TensorRT engine building + INT8 calibration logic
- Policy inference loop and safety/watchdog logic
- ROS 2 graph design decisions (topics, rates, QoS)

**Delegate to Claude Code:**
- CMakeLists, package.xml, colcon workspace scaffolding
- Launch files, URDF/USD boilerplate, Dockerfiles
- Benchmark scripts, plotting, tegrastats parsers
- ONNX export scripts, dataset conversion glue
- README/docs drafting from your notes

**Where Claude Code runs:**
- Ubuntu desktop (casa-G5-KF5): main workspace, training scripts, USD work
- SSH into Jetson Orin Nano: deployment, TensorRT builds, on-device debugging
- Physical steps stay manual: flashing STM32/ESP32, wiring, camera mounting, teleop recording
