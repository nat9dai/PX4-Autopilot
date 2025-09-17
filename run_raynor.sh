#!/usr/bin/env bash
set -euo pipefail

# 1. Figure out where we are
PX4_ROOT="$(cd "$(dirname "$0")" && pwd)"
MODEL_DIR="${PX4_ROOT}/Tools/simulation/gazebo-classic/models/raynor"

# 2. Tell Gazebo where to find your model
export GAZEBO_MODEL_PATH="${MODEL_DIR}:${GAZEBO_MODEL_PATH:-}"

# 3. Start PX4 SITL + Gazebo-classic
#    SYS_AUTOSTART=22000_raynor picks up your custom param file
make px4_sitl gazebo-classic \
     SYS_AUTOSTART=22000_raynor &

SITL_PID=$!

# 4. Give Gazebo a few seconds to load
sleep 8

# 5. Spawn the raynor model using gz CLI
#    assumes model.sdf (or model.config → model.sdf) in MODEL_DIR
if [ -f "${MODEL_DIR}/model.sdf" ]; then
  gz sdf -p "${MODEL_DIR}/model.sdf" \
    | gz model --spawn-file - --model-name raynor
else
  echo "ERROR: ${MODEL_DIR}/model.sdf not found!"
  kill $SITL_PID
  exit 1
fi

# 6. Wait for PX4+Gazebo to exit
wait $SITL_PID

