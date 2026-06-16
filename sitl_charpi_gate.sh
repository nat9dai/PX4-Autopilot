#!/usr/bin/env bash
# sitl_charpi_gate.sh — launch PX4 SITL + Gazebo for the Charpi gate task with the
# CG-recentred model. After the 2026-06-16 sim2real restructure, the gz model's body
# geometry sits 0.0635 m BELOW the model frame (so the reported pose = the box centre /
# CG, body-frame). That REQUIRES spawning 6.4 cm higher, else the box bottom spawns in
# the ground and EKF2 stalls. This wrapper bakes that spawn z so you don't have to
# remember it. See dva-quad-jax/envs/GATE_SIM2REAL.md §9.
#
# Usage:
#   ./sitl_charpi_gate.sh [GATE_ROLL_DEG] [headless]
#     GATE_ROLL_DEG : gz gate roll, default 45
#     headless      : pass "headless" or "1" for NO gz GUI; omit for the GUI (default)
# Examples:
#   ./sitl_charpi_gate.sh 45            # gz GUI shown, gate rolled 45
#   ./sitl_charpi_gate.sh 0 headless    # headless, upright gate
#
# NOTE: PX4's px4-rc.gzsim shows the gz GUI only when HEADLESS is UNSET ([ -z ]). So we
# must NOT export HEADLESS at all for the GUI case (HEADLESS=0 would still hide it).
#
# Then, in separate shells (unchanged):
#   MicroXRCEAgent udp4 -p 8888
#   ros2 launch offboard_state_machine interactive_test.launch.py \
#       task:=gate enable_rl:=true rviz:=true dummy_gate:=true gate_angle:=<same roll>
#   # then type: ttt<roll>  then  ggg
set -eu

ROLL="${1:-45}"
HL="${2:-}"   # empty = GUI; "1"/"headless" = headless

# Drone spawn pose (ENU): x y z roll pitch yaw. z=0.0635 lifts the box bottom onto the
# ground for the CG-recentred model (DO NOT set z=0 — drone spawns in the ground).
SPAWN_Z="0.0635"
MODEL_POSE="0,-1.5,${SPAWN_Z},0,0,1.5708"

cd "$(dirname "$(readlink -f "$0")")"   # PX4-Autopilot root

# Build the env. Only export HEADLESS when headless is requested (else GUI is hidden).
ENVV=(GATE_ROLL_DEG="${ROLL}" PX4_GZ_MODEL_POSE="${MODEL_POSE}" PX4_GZ_WORLD="charpi_gate")
if [ "${HL}" = "1" ] || [ "${HL}" = "headless" ]; then
  ENVV+=(HEADLESS=1)
  MODE="headless"
else
  MODE="gz GUI"
fi

echo "[sitl_charpi_gate] gate roll=${ROLL} deg, spawn=${MODEL_POSE}, ${MODE}"
echo "[sitl_charpi_gate] (CG-recentred model: reported pose = box centre; spawn z=${SPAWN_Z})"

exec env "${ENVV[@]}" make px4_sitl gz_charpi_vision
