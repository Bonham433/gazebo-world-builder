#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# launch_wsl.sh — WSL 图形栈适配 + 启动 Gazebo
#
# 作用:
#   在 WSL 下临时注入图形环境变量 (仅当前进程, 不写入 ~/.bashrc),
#   然后执行 `gz sim "$@"`。
#
#   * WSLg 可用:  DISPLAY=:0, LIBGL_ALWAYS_INDIRECT=0, GALLIUM_DRIVER=d3d12,
#                 MESA_D3D12_DEFAULT_ADAPTER_NAME=NVIDIA, QT_X11_NO_MITSHM=1
#   * WSLg 不可用: 回退软件渲染 LIBGL_ALWAYS_SOFTWARE=1, GALLIUM_DRIVER=llvmpipe
#
# 用法:
#   ./launch_wsl.sh                     # 打开空世界 GUI
#   ./launch_wsl.sh my_world.sdf        # 打开指定世界
#   ./launch_wsl.sh my_world.sdf -r     # 参数透传给 gz sim
# ---------------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=detect_env.sh
source "${SCRIPT_DIR}/detect_env.sh"

if [[ "$IS_WSL" -eq 1 ]]; then
  if [[ "$WSLG_AVAILABLE" -eq 1 ]]; then
    export DISPLAY=:0
    export LIBGL_ALWAYS_INDIRECT=0
    export GALLIUM_DRIVER=d3d12
    export MESA_D3D12_DEFAULT_ADAPTER_NAME=NVIDIA
    export QT_X11_NO_MITSHM=1
  else
    # WSLg 不可用: 回退到软件渲染
    export LIBGL_ALWAYS_SOFTWARE=1
    export GALLIUM_DRIVER=llvmpipe
  fi
fi

exec gz sim "$@"
