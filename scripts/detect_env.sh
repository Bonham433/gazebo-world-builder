#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# detect_env.sh — 运行环境检测 (Ubuntu / WSL / WSLg / Gazebo / ROS 2)
#
# 用法:
#   source scripts/detect_env.sh    # 推荐: 导入变量供其他脚本使用
#   bash   scripts/detect_env.sh    # 直接运行: 打印检测摘要
#
# 导出变量:
#   UBUNTU_VERSION      22.04 / 24.04 / unknown
#   UBUNTU_CODENAME     jammy / noble / unknown
#   IS_WSL              0 | 1
#   WSL_DISTRO_NAME     WSL 发行版名 (非 WSL 时为空)
#   WSLG_AVAILABLE      0 | 1
#   GAZEBO_KIND         gazebo-harmonic | gazebo-classic | none
#   GZ_VERSION          已装 Gazebo (Harmonic 等) 版本 (未装为空)
#   GAZEBO_CLASSIC_VER  已装 Gazebo Classic 版本 (未装为空)
#   ROS_DISTRO          已装 ROS 2 发行版, 如 jazzy / humble (未装为空)
#   ROS_AVAILABLE       0 | 1
#   APT_AVAILABLE       0 | 1
# ---------------------------------------------------------------------------
set -euo pipefail

# ----------------------------- 工具函数 -----------------------------------
detect__has() { command -v "$1" >/dev/null 2>&1; }

# ----------------------------- Ubuntu 版本 --------------------------------
UBUNTU_VERSION="unknown"
UBUNTU_CODENAME="unknown"
if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  UBUNTU_VERSION="${VERSION_ID:-unknown}"
  UBUNTU_CODENAME="${VERSION_CODENAME:-unknown}"
fi

# ----------------------------- WSL 检测 -----------------------------------
IS_WSL=0
if [[ -n "${WSL_DISTRO_NAME:-}" ]] || grep -qiE '(microsoft|wsl)' /proc/version 2>/dev/null; then
  IS_WSL=1
fi
WSL_DISTRO_NAME="${WSL_DISTRO_NAME:-}"

# ----------------------------- WSLg 检测 ----------------------------------
WSLG_AVAILABLE=0
if [[ "$IS_WSL" -eq 1 ]]; then
  if [[ -d /mnt/wslg ]] \
     || [[ -n "${WAYLAND_DISPLAY:-}" ]] \
     || { [[ -n "${DISPLAY:-}" ]] && [[ -e /tmp/.X11-unix/X0 ]]; }; then
    WSLG_AVAILABLE=1
  fi
fi

# ----------------------------- Gazebo (Harmonic 系列) ---------------------
GZ_VERSION=""
if detect__has gz; then
  GZ_VERSION="$(timeout 10 gz sim --version 2>/dev/null | head -n1 || true)"
  [[ -z "$GZ_VERSION" ]] && GZ_VERSION="installed"
fi

# ----------------------------- Gazebo Classic -----------------------------
GAZEBO_CLASSIC_VER=""
if detect__has gazebo; then
  GAZEBO_CLASSIC_VER="$(timeout 10 gazebo --version 2>/dev/null \
    | sed -n 's/^Gazebo multi-robot simulator, version //p' | head -n1 || true)"
  [[ -z "$GAZEBO_CLASSIC_VER" ]] && GAZEBO_CLASSIC_VER="installed"
fi

# ----------------------------- 综合判定 -----------------------------------
if [[ -n "$GZ_VERSION" ]]; then
  GAZEBO_KIND="gazebo-harmonic"
elif [[ -n "$GAZEBO_CLASSIC_VER" ]]; then
  GAZEBO_KIND="gazebo-classic"
else
  GAZEBO_KIND="none"
fi

# ----------------------------- ROS 2 --------------------------------------
ROS_DISTRO="${ROS_DISTRO:-}"
ROS_AVAILABLE=0
if [[ -n "$ROS_DISTRO" && -d "/opt/ros/$ROS_DISTRO" ]]; then
  ROS_AVAILABLE=1
elif [[ -d /opt/ros ]]; then
  for _d in /opt/ros/*/; do
    [[ -d "$_d" ]] || continue
    ROS_DISTRO="$(basename "$_d")"
    ROS_AVAILABLE=1
    break
  done
fi

# ----------------------------- apt ----------------------------------------
APT_AVAILABLE=0
detect__has apt-get && APT_AVAILABLE=1

# ----------------------------- 摘要输出 -----------------------------------
detect__summary() {
  local wsl_txt wslg_txt apt_txt
  [[ "$IS_WSL" -eq 1 ]] && wsl_txt="yes (${WSL_DISTRO_NAME:-unknown})" || wsl_txt="no"
  [[ "$WSLG_AVAILABLE" -eq 1 ]] && wslg_txt="available" || wslg_txt="not available"
  [[ "$APT_AVAILABLE" -eq 1 ]] && apt_txt="yes" || apt_txt="no"

  cat <<EOF
=== 环境检测摘要 ===
Ubuntu   : ${UBUNTU_VERSION} (${UBUNTU_CODENAME})
WSL      : ${wsl_txt}
WSLg     : ${wslg_txt}
Gazebo   : ${GAZEBO_KIND} ${GZ_VERSION:+(${GZ_VERSION})}${GAZEBO_CLASSIC_VER:+ (classic ${GAZEBO_CLASSIC_VER})}
ROS 2    : ${ROS_DISTRO:-none}
apt-get  : ${apt_txt}
EOF
}

# 直接运行时输出摘要; 被 source 时仅导入变量
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  detect__summary
fi
