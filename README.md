# Gazebo World Builder

> 快速创建 Gazebo 仿真环境的 AI Agent Skill，支持 WSL、Ubuntu 22.04/24.04、ROS 2 Jazzy/Humble、Gazebo Harmonic。

[![validate-skill](https://github.com/Bonham433/gazebo-world-builder/actions/workflows/validate-skill.yml/badge.svg)](https://github.com/Bonham433/gazebo-world-builder/actions/workflows/validate-skill.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)

`gazebo-world-builder` 是一个只做一件事的 Agent Skill：让 AI 助手帮你**从零搭建可运行的 Gazebo 世界**——
环境检测、依赖安装、SDF 世界编写、URDF 导入、传感器配置，以及与 ROS 2 的 launch 集成。

## 特性

- 兼容 **WSL** / **Ubuntu 22.04 (jammy)** / **Ubuntu 24.04 (noble)**
- 支持 **ROS 2 Jazzy** / **ROS 2 Humble** 与 **Gazebo Harmonic**
- **非破坏性安装**：已装则跳过、不卸载 Gazebo Classic、不改 `~/.bashrc`
- WSL 图形栈自动适配（WSLg / 软件渲染回退）
- 覆盖 SDF 世界结构、程序化生成、URDF 导入、传感器与 ROS 2 launch

## 安装

```bash
git clone https://github.com/<your-github-username>/gazebo-world-builder.git
cd gazebo-world-builder
Bonham433
# 默认模式 (link): 在当前仓库与技能目录之间建立符号链接
./install.sh

# 复制模式 (copy): 将技能文件复制到目标目录
./install.sh copy

# 自定义技能目录
AGENT_SKILLS_DIR="$HOME/.config/agents/skills" ./install.sh
```

安装目标默认为 `~/.agents/skills/gazebo-world-builder`。

## 使用

在支持 Agent Skill 的 AI 工具中直接说出触发词，例如：

- 创建 Gazebo 世界
- 生成仿真环境
- 写一个 SDF world
- 搭建 Gazebo 场景
- 导入 URDF 到 Gazebo
- 用 Fuel 模型建场景
- 程序化生成 Gazebo 世界
- WSL 中安装 Gazebo

也可以运行 `/skills` 查看已安装技能。

## 兼容性

| 组件 | 支持范围 |
| --- | --- |
| 操作系统 | WSL2、Ubuntu 22.04 LTS、Ubuntu 24.04 LTS |
| ROS 2 | Humble (jammy)、Jazzy (noble) |
| Gazebo | Gazebo Harmonic（`gz sim`） |
| Gazebo Classic | 检测但不卸载，支持 side-by-side |

## 目录结构

```text
gazebo-world-builder/
├── SKILL.md                      # 技能定义 (frontmatter + 正文)
├── scripts/
│   ├── detect_env.sh             # 环境检测
│   ├── install_gazebo.sh         # 非破坏性安装
│   └── launch_wsl.sh             # WSL 图形栈适配 + 启动
├── README.md
├── LICENSE
├── .gitignore
├── .gitattributes
├── install.sh                    # 安装技能 (link / copy)
├── uninstall.sh                  # 卸载技能
└── .github/
    └── workflows/
        └── validate-skill.yml    # CI: 校验技能结构与脚本
```

## 卸载

```bash
./uninstall.sh
```

只会移除 `~/.agents/skills/gazebo-world-builder`，不会触碰其他文件。

## License

本项目基于 [MIT License](./LICENSE) 开源。
