---
name: gazebo-world-builder
description: >-
  快速创建 Gazebo 仿真环境的 AI Agent Skill。触发场景包括：创建 Gazebo 世界、
  生成仿真环境、写 SDF world、搭建 Gazebo 场景、导入 URDF 到 Gazebo、
  用 Fuel 模型建场景、程序化生成 Gazebo 世界、WSL 中安装 Gazebo。
  兼容 WSL / Ubuntu 22.04 / Ubuntu 24.04 / ROS 2 Jazzy / ROS 2 Humble / Gazebo Harmonic。
---

# Gazebo World Builder

一个用于**快速创建 Gazebo 仿真环境**的 AI Agent Skill。目标：让 Agent 能够从零搭建可运行的
Gazebo 世界（SDF），完成环境检测、依赖安装、URDF 导入、传感器配置以及与 ROS 2 的 launch 集成，
并覆盖 WSL / Ubuntu 22.04 / Ubuntu 24.04 / ROS 2 Jazzy / ROS 2 Humble / Gazebo Harmonic。

<!-- TODO: 如果你已有原始 SKILL.md 正文，请把自己的经验、约定与示例合并到本文档对应章节中。 -->

---

## 1. 环境检测与依赖安装

在动手写世界文件之前，**先检测、再安装**，避免破坏用户现有环境。

```bash
# 导入环境变量（推荐，供其他脚本 source）
source scripts/detect_env.sh

# 或直接查看检测摘要
bash scripts/detect_env.sh
```

检测脚本会导出以下变量：`UBUNTU_VERSION`、`UBUNTU_CODENAME`、`IS_WSL`、
`WSL_DISTRO_NAME`、`WSLG_AVAILABLE`、`GAZEBO_KIND`、`GZ_VERSION`、
`GAZEBO_CLASSIC_VER`、`ROS_DISTRO`、`ROS_AVAILABLE`、`APT_AVAILABLE`。

安装 Gazebo（非破坏性）：

```bash
./scripts/install_gazebo.sh            # 自动选择安装方式
./scripts/install_gazebo.sh --dry-run  # 只打印将要执行的命令
```

决策顺序：

1. 已安装 Gazebo（Harmonic 系列）→ **跳过**，不重装。
2. 检测到 Gazebo Classic 11 → **不自动卸载**，提示 side-by-side 方案（见第 4 节）。
3. 有 ROS 2 → 优先安装 `ros-${ROS_DISTRO}-ros-gz`。
4. 无 ROS 2 → 从 OSRF 源安装 `gz-harmonic`。

## 2. Ubuntu 22.04 / 24.04 与 Gazebo Harmonic 兼容性

| Ubuntu | 代号 | 推荐 ROS 2 | Gazebo | 状态 |
| --- | --- | --- | --- | --- |
| 22.04 LTS | jammy | Humble | Harmonic | 支持 |
| 24.04 LTS | noble | Jazzy | Harmonic | 支持 |

- **Gazebo Harmonic**（`gz-sim8`）同时提供 jammy 与 noble 的软件包，是当前主推版本。
- 安装来源二选一：OSRF apt 源（`packages.osrfoundation.org`）或 ROS 2 的 `ros-gz` 元包。
- 不要混装不同大版本的 Gazebo（如 Fortress `gz-sim6` 与 Harmonic `gz-sim8`）到同一前缀。

## 3. ROS 2 Jazzy / Humble 集成

- Jazzy 对应 `ros-jazzy-ros-gz`，Humble 对应 `ros-humble-ros-gz`。
- 使用 `ros_gz_sim` 的 launch 文件启动仿真，用 `ros_gz_bridge` 桥接话题：

```bash
ros2 launch ros_gz_sim gz_sim.launch.py
ros2 run ros_gz_bridge parameter_bridge /clock@rosgraph_msgs/msg/Clock[gz.msgs.Clock
```

- 世界文件中通过 `<plugin>` 引用 `gz-sim-*` 系统插件（物理、传感器、GUI 等）。
- 在 launch 中通过 `GZ_SIM_RESOURCE_PATH` 暴露模型目录：

```python
os.environ["GZ_SIM_RESOURCE_PATH"] = os.pathsep.join(model_dirs)
```

## 4. 非破坏性安装原则

- **不覆盖** `/etc/apt/sources.list`，只向 `/etc/apt/sources.list.d/` 追加 `.list` 文件。
- **不修改**用户 `~/.bashrc`；需要 source 环境时给出显式提示而非自动改写。
- 已存在的 Gazebo 一律跳过；检测到 Gazebo Classic **不自动卸载**，改为提示：
  - classic 用 `gazebo`，harmonic 用 `gz sim`，二者命令不冲突；
  - 如确认不再需要，用户可显式执行 `sudo apt-get remove 'gazebo*' 'libgazebo*'`。
- 安装前尽量提供 `--dry-run`，让用户先审查将执行的命令。

## 5. WSL 图形栈适配

WSL 下 GUI 依赖 WSLg，需临时注入图形环境变量（不写入 shell 配置）：

```bash
./scripts/launch_wsl.sh world.sdf   # 会设置环境变量后 exec gz sim
```

- **WSLg 可用**：`DISPLAY=:0`、`LIBGL_ALWAYS_INDIRECT=0`、`GALLIUM_DRIVER=d3d12`、
  `MESA_D3D12_DEFAULT_ADAPTER_NAME=NVIDIA`、`QT_X11_NO_MITSHM=1`。
- **WSLg 不可用**：回退软件渲染 `LIBGL_ALWAYS_SOFTWARE=1`、`GALLIUM_DRIVER=llvmpipe`。
- 变量仅在本次进程内生效，脚本最后 `exec gz sim "$@"`。

## 6. SDF 世界文件结构

```xml
<?xml version="1.0" ?>
<sdf version="1.10">
  <world name="default">
    <physics name="1ms" type="dartsim">
      <max_step_size>0.001</max_step_size>
      <real_time_factor>1.0</real_time_factor>
    </physics>

    <light type="directional" name="sun">
      <cast_shadows>true</cast_shadows>
      <pose>0 0 10 0 0 0</pose>
    </light>

    <include>
      <uri>https://fuel.gazebosim.org/1.0/OpenRobotics/models/Ground Plane</uri>
    </include>

    <model name="box">
      <static>false</static>
      <link name="link">
        <collision name="collision">
          <geometry><box><size>1 1 1</size></box></geometry>
        </collision>
        <visual name="visual">
          <geometry><box><size>1 1 1</size></box></geometry>
        </visual>
      </link>
    </model>
  </world>
</sdf>
```

要点：`<world>` → `<physics>` / `<light>` / `<include>` / `<model>`；模型由
`<link>`（`<collision>` + `<visual>` + `<inertial>`）和 `<joint>` 组成。

## 7. 程序化生成、URDF 导入、传感器配置

- **程序化生成**：用 Python（`xml.etree.ElementTree`）或模板批量生成 `<model>`，
  例如随机摆放障碍物、生成网格化仓库货架。
- **URDF → Gazebo**：URDF 需补充 Gazebo 标签（`<gazebo>`）或经 `sdformat` 转换；
  机器人用 `ros_gz_sim` 的 `create` 服务或无 `<include>` 直接引入。
- **传感器**：在 `<link>` 内添加 `<sensor>`：
  - 相机：`<sensor type="camera">` + `<plugin filename="gz-sim-camera-system">`
  - 激光雷达：`<sensor type="lidar">`（或 `gpu_lidar`）+ `gz-sim-sensors-system`
  - IMU：`<sensor type="imu">`
  - 别忘了在 world 中启用 `gz-sim-sensors-system` / `gz-sim-physics-system` 插件。

## 8. ROS 2 launch 集成

以 `ros_gz_sim` 为桥梁，典型 launch 结构：

```python
from launch import LaunchDescription
from launch.actions import IncludeLaunchDescription
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch_ros.substitutions import FindPackageShare

def generate_launch_description():
    return LaunchDescription([
        IncludeLaunchDescription(
            PythonLaunchDescriptionSource([
                FindPackageShare("ros_gz_sim"), "/launch/gz_sim.launch.py"
            ]),
            launch_arguments={"gz_args": "-r world.sdf"}.items(),
        ),
    ])
```

## 9. 异常处理与验证清单

常见异常与处理：

- `gz sim` 无法打开窗口 → 检查 `DISPLAY` / WSLg / 软件渲染回退。
- 模型下载失败 → 检查网络或改用本地 `GZ_SIM_RESOURCE_PATH`。
- URDF 无 `<inertial>` → 物理不稳定，补齐质量与惯量。
- 传感器无数据 → 确认 world 中启用了对应 system 插件。

验证清单：

- [ ] `gz sim --version` 能输出版本号。
- [ ] `gz sim world.sdf` 能加载世界且无报错。
- [ ] WSL 下图形窗口正常显示（或已回退软件渲染）。
- [ ] ROS 2 场景下 `ros2 topic list` 能看到 `/clock` 等话题。
- [ ] 传感器话题有数据（`ros2 topic echo`）。
- [ ] 未修改 `/etc/apt/sources.list` 与 `~/.bashrc`。
