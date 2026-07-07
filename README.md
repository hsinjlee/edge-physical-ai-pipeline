# Edge Physical AI Pipeline

End-to-end miniature Physical AI stack:
**ESP32/STM32 (micro-ROS) → Jetson Orin Nano (TensorRT INT8) → ROS 2 → learned policy → real actuators**,
with an Isaac Sim / OpenUSD digital twin.

> Status: setting up. See BUILD_PLAN.md.

## Phases
1. micro-ROS sensor node → Jetson TensorRT inference → ROS 2 topics
2. Camera + quantized perception (detection, monocular depth), INT8/FP16 benchmark report
3. Learned policy on Orin driving physical servos; Isaac Lab sim-to-real via OpenUSD

## Hardware
Jetson Orin Nano · STM32F429ZI · ESP32 · USB camera · hobby servos · RTX 4060 (training)
