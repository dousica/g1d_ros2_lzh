# 我的工作空间 g1d_ros2_lzh

- 主人：lzh（我）
- 创建：2026-10-23
- 目的：**独立学习/开发**，与师兄的 `~/g1d_ros2_ws` 完全隔离

---

## 一、隔离机制（两层，缺一不可）

### 第 1 层：目录隔离 —— 一个终端只 source 一个工作空间

```bash
# 正确开终端
source /opt/ros/humble/setup.bash          # 系统 ROS2
source ~/g1d_ros2_lzh/install/setup.bash   # 我的空间（只此一个）
```

**绝对禁止**在同一个终端里 source 两个工作空间。ROS 2 靠环境变量（`AMENT_PREFIX_PATH` 等）找包，
后 source 的会**覆盖**前一个的同名包，症状是"我改了代码但跑起来还是老版本"。

### 第 2 层：网络隔离 —— `ROS_DOMAIN_ID`

同一台机器上所有 ROS 2 节点默认都在 domain 0 上，会互相看到对方的 topic。

```bash
export ROS_DOMAIN_ID=42     # 我的频道
```

| 项目 | ROS_DOMAIN_ID | 说明 |
|---|---|---|
| `g1d_ros2_lzh`（我的） | `42` | 学习、离线开发 |
| `g1d_ros2_ws`（师兄的） | `0` | 实机，要和机器人本体通信 |

> **重要**：改 `ROS_DOMAIN_ID` 只隔离 ROS 2 之间，**不影响 Unitree SDK2**。
> SDK2 自带独立 DDS（domain 写死在代码里），所以实机通信依然正常。

---

## 二、命名规范（防撞名）

师兄项目的包名（**不要用**）：
`g1d_description` / `g1d_moveit_config` / `g1d_sdk_bridge` / `g1d_camera_bridge` / `g1d_bringup` / `g1d_motion_demo`

我的包名规则：`lzh_<主题>`，例如 `lzh_urdf_demo`、`lzh_motion_planner`

节点名、topic 名、action 名、service 名一律加 `lzh_` 前缀：
`lzh_planner` / `lzh_joint_states` / `~/lzh_cmd_vel` 等

参数、frame 名如果必须沿用 URDF 里的（如 `AGV_link`），保持一致即可 —— frame 是 URDF 内部约定，
只要我不加载师兄的 URDF 就不冲突。

---

## 三、复制师兄代码的正确方式

**只复制，绝不原地修改。**

```bash
cp -r ~/g1d_ros2_ws/src/g1d_description ~/g1d_ros2_lzh/src/
# 然后立刻改包名，避免撞名
#   package.xml:  <name>lzh_description</name>
#   CMakeLists.txt: project(lzh_description)
#   所有 package://g1d_description/  ->  package://lzh_description/
```

复制后用 `sed` 批量替换包名：

```bash
cd ~/g1d_ros2_lzh/src/lzh_description
grep -rl "g1d_description" . | xargs sed -i 's/g1d_description/lzh_description/g'
```

改完记得 `colcon build` 一次验证。

---

## 四、绝不碰的东西

- `~/g1d_ros2_ws/` 整个目录（师兄的正式项目，有 git、能驱动真机）
- `~/unitree_ros_official`、`~/unitree_sdk2`（上游官方库，git 仓库）
- `~/dex1_1_service`（夹爪独立工程）

只读借鉴，不写入。

---

## 五、日常流程

```bash
cd ~/g1d_ros2_lzh
colcon build --symlink-install     # 编译
source install/setup.bash           # 进入
source /opt/ros/humble/setup.bash   # 如果发现环境变量脏了，先跑这句重置
```

`--symlink-install` 好处：Python 文件改动**不用重新编译**直接生效，适合快速迭代。

---

## 六、我的 git 仓库

- 本地仓库已 `git init`，分支 `main`
- 远端：**暂不配置**。这是属于我自己的独立仓库，不与任何其他工作空间共用远端。
- 提交信息用中文/英文随意，但格式建议：`feat: xxx` / `fix: xxx` / `docs: xxx`
