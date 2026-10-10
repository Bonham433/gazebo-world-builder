#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# install_gazebo.sh — 非破坏性安装 Gazebo Harmonic / ros-gz
#
# 设计原则:
#   * 已安装 Gazebo 则跳过, 绝不移除/降级已有版本
#   * 检测到 Gazebo Classic 11 不自动卸载, 提示 side-by-side 方案
#   * 有 ROS 2 则优先安装 ros-<distro>-ros-gz
#   * 无 ROS 2 则从 OSRF 源安装 gz-harmonic
#   * 不覆盖 /etc/apt/sources.list, 只追加 /etc/apt/sources.list.d/*.list
#   * 不修改用户 ~/.bashrc
#
# 用法:
#   ./install_gazebo.sh              # 自动选择安装方式
#   ./install_gazebo.sh --dry-run    # 只打印将要执行的命令
#   ./install_gazebo.sh --help
# ---------------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=detect_env.sh
source "${SCRIPT_DIR}/detect_env.sh"

DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help)
      sed -n 's/^# \{0,1\}//p' "$0"
      exit 0
      ;;
    *)
      echo "未知参数: $arg" >&2
      exit 2
      ;;
  esac
done

log()  { printf '\033[1;34m[install]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*"; }
err()  { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; }

run() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '\033[1;35m[dry-run]\033[0m %s\n' "$*"
  else
    "$@"
  fi
}

# --------------------------------------------------------------------------
# 1) 已装 Gazebo (Harmonic 系列) -> 跳过
# --------------------------------------------------------------------------
if [[ "$GAZEBO_KIND" == "gazebo-harmonic" ]]; then
  log "已检测到 Gazebo (${GZ_VERSION}), 跳过安装。"
  log "查看版本: gz sim --version"
  exit 0
fi

# --------------------------------------------------------------------------
# 2) 检测到 Gazebo Classic -> 不卸载, 提示 side-by-side
# --------------------------------------------------------------------------
if [[ "$GAZEBO_KIND" == "gazebo-classic" ]]; then
  warn "检测到 Gazebo Classic (${GAZEBO_CLASSIC_VER})。"
  warn "本脚本不会卸载 Gazebo Classic, 以免破坏现有工程。"
  warn "Gazebo Harmonic 可与 Gazebo Classic 并存 (side-by-side):"
  warn "  * 命令不同: classic 用 'gazebo', harmonic 用 'gz sim'"
  warn "  * 二者资源/端口不冲突; 注意 QT / OGRE 依赖版本差异"
  warn "  * 如确认不再需要 classic, 请手动执行:"
  warn "      sudo apt-get remove 'gazebo*' 'libgazebo*'"
fi

if [[ "$APT_AVAILABLE" -ne 1 ]]; then
  err "未检测到 apt-get, 无法自动安装。请在 Debian/Ubuntu 环境运行。"
  exit 1
fi

# --------------------------------------------------------------------------
# 3) 有 ROS 2 -> 优先安装 ros-<distro>-ros-gz
# --------------------------------------------------------------------------
if [[ "$ROS_AVAILABLE" -eq 1 ]]; then
  PKG="ros-${ROS_DISTRO}-ros-gz"
  log "检测到 ROS 2 (${ROS_DISTRO}), 优先安装 ${PKG} ..."
  run sudo apt-get update
  run sudo apt-get install -y "$PKG"
  log "完成。验证: ros2 launch ros_gz_sim gz_sim.launch.py"
  exit 0
fi

# --------------------------------------------------------------------------
# 4) 无 ROS 2 -> 从 OSRF 源安装 gz-harmonic
# --------------------------------------------------------------------------
if [[ "$UBUNTU_CODENAME" != "jammy" && "$UBUNTU_CODENAME" != "noble" ]]; then
  warn "Ubuntu 代号 '${UBUNTU_CODENAME}' 未经测试 (支持 jammy/noble)。best-effort 继续。"
fi

OSRF_KEYRING="/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg"
OSRF_LIST="/etc/apt/sources.list.d/gazebo-stable.list"

log "未检测到 ROS 2, 从 OSRF 源安装 gz-harmonic ..."
run sudo apt-get update
run sudo apt-get install -y curl gnupg lsb-release ca-certificates

# 导入 OSRF 签名密钥
run bash -c "curl -fsSL https://packages.osrfoundation.org/gazebo.gpg | sudo tee '${OSRF_KEYRING}' >/dev/null"

# 仅追加 .list 文件, 不触碰 /etc/apt/sources.list
ARCH="$(dpkg --print-architecture)"
CODENAME="$(lsb_release -cs 2>/dev/null || echo "${UBUNTU_CODENAME}")"
run bash -c "echo 'deb [arch=${ARCH} signed-by=${OSRF_KEYRING}] http://packages.osrfoundation.org/gazebo/ubuntu-stable ${CODENAME} main' | sudo tee '${OSRF_LIST}' >/dev/null"

run sudo apt-get update
run sudo apt-get install -y gz-harmonic

log "完成。验证: gz sim --version"
log "提示: 本脚本未修改 ~/.bashrc; 如需 source 请自行处理。"
