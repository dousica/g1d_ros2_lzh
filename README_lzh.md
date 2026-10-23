# 我的工作空间 g1d_ros2_lzh

- 主人：lzh（我）
- 创建：2026-10-23
- 目的：**独立学习/开发**，与师兄的 `~/g1d_ros2_ws` 完全隔离
- 远端：https://github.com/dousica/g1d_ros2_lzh

## 快捷脚本

| 脚本 | 作用 |
|---|---|
| `source ~/g1d_ros2_lzh/setup_env.sh` | 一键进入环境（domain 42 + 系统ROS + 我的overlay + 隔离自检） |
| `bash ~/g1d_ros2_lzh/check_isolation.sh` | 隔离自检，6 项全过才算完好 |
| `bash ~/g1d_ros2_lzh/copy_pkg.sh g1d_xxx` | 安全复制师兄的包并自动改名（源只读） |

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

**最省事的做法**：直接用现成脚本，一条命令搞定环境：

```bash
source ~/g1d_ros2_lzh/setup_env.sh
```

它会自动做三件事：设 `ROS_DOMAIN_ID=42` → source 系统 ROS → source 我的 overlay（顺序已固定，不会搞反）。

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

**只复制，绝不原地修改。** 用现成脚本，一条命令搞定（源包只读，绝不碰师兄的目录）：

```bash
bash ~/g1d_ros2_lzh/copy_pkg.sh g1d_description
# → 生成 ~/g1d_ros2_lzh/src/lzh_description, 并自动把 g1d_xxx 替换成 lzh_xxx
# → 打印残留的 g1d_ 字样供人工确认(机器人型号名 G1_D / frame 名属于正常, 不需要改)
```

脚本会:
1. 复制包到我的 `src/`, 顺带清掉 `build/ install/ log/ .git`
2. 批量把包名 `g1d_xxx` → `lzh_xxx`（含 `package://g1d_xxx/` 路径引用）
3. 打印**残留的 `g1d_` 字样**, 让你人工判断哪些该改（模型名/frame 名不用改）
4. 自动 `git add`, 方便 `git diff --cached` review 后再 commit

手工等价做法：

```bash
cp -r ~/g1d_ros2_ws/src/g1d_description ~/g1d_ros2_lzh/src/
cd ~/g1d_ros2_lzh/src/g1d_description
grep -rl "g1d_description" . | xargs sed -i 's/g1d_description/lzh_description/g'
```

### 可复制的 6 个包清单

| 师兄的包 | 类型 | 复制后 | 用途 |
|---|---|---|---|
| `g1d_description` | cmake | `lzh_description` | URDF 模型 + mesh（62MB，含 59MB mesh） |
| `g1d_moveit_config` | cmake | `lzh_moveit_config` | MoveIt 规划配置 |
| `g1d_sdk_bridge` | cmake | `lzh_sdk_bridge` | Unitree SDK2 ↔ ROS 2 桥接 |
| `g1d_bringup` | cmake | `lzh_bringup` | 启动文件汇总 |
| `g1d_camera_bridge` | python | `lzh_camera_bridge` | 相机话题桥接 |
| `g1d_motion_demo` | python | `lzh_motion_demo` | 动作示例 |

> ⚠️ `lzh_description` 含 **59MB mesh**，推 GitHub 虽可行但仓库会很快变大。建议后续改用
> Git LFS，或在 README 里注明只保留 URDF 不含 mesh。

复制后用 `colcon build` 一次验证。

---

## 三·五、隔离自检（每次怀疑出问题就跑）

```bash
bash ~/g1d_ros2_lzh/check_isolation.sh
```

检查 6 项：`ROS_DOMAIN_ID` / `AMENT_PREFIX_PATH` 污染 / 包名前缀 / git 身份 /
credential helper / 师兄工作空间是否被污染。全部 ✅ 才算隔离完好。

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

**推荐用一条命令代替上面三步：**

```bash
source ~/g1d_ros2_lzh/setup_env.sh
```

它会按固定顺序设 `ROS_DOMAIN_ID=42` → source 系统 ROS → source 我的 overlay，
并在最后做一次隔离自检（发现污染立即报错）。

---

## 六、我的 git 仓库

- 远端：**`https://github.com/dousica/g1d_ros2_lzh`**（public）
- 提交身份：仓库级 `dousica` / `dousica@users.noreply.github.com`（隐私邮箱，不暴露真实邮箱）
- 与师兄的 `JaminJin58/g1d_control` **完全隔离**：独立的 gh 配置目录 + 仓库级 credential helper
- 提交信息格式：`feat: xxx` / `fix: xxx` / `docs: xxx`

日常推送（自动使用 dousica 的 token，无需手动切换）：

```bash
cd ~/g1d_ros2_lzh
git add .
git commit -m "feat: xxx"
git push
```

---

## 七、学习路线（按顺序推进，每步一个 commit）

### 步骤 1 — 自定义消息包 `lzh_msgs` ✅ 待做

学 pub/sub、service、action、参数、tf 的载体。

```bash
cd ~/g1d_ros2_lzh/src
ros2 pkg create lzh_msgs --build-type ament_cmake
# 加 msg/ 目录, 定义消息, 然后在 CMakeLists 里加 rosidl_generate_interfaces
```

### 步骤 2 — 模型 `lzh_description` ✅ 待做

```bash
bash ~/g1d_ros2_lzh/copy_pkg.sh g1d_description
cd ~/g1d_ros2_lzh && colcon build --symlink-install
```

产出：能在 RViz 里看到 G1-D 模型。**这一步做完才和步骤 1 有意义**——
不然没有模型，消息发了也看不到效果。

### 步骤 3 — 桥接 `lzh_sdk_bridge` ✅ 待做

```bash
bash ~/g1d_ros2_lzh/copy_pkg.sh g1d_sdk_bridge
```

让 ROS 2 节点读到实机关节状态 → 发布成 `sensor_msgs/JointState`。

> ⚠️ **关键认知**：Unitree SDK2 自带**独立 DDS**（domain 写死在代码里），
> 所以 `ROS_DOMAIN_ID=42` **不影响**与实机的通信。
> 改 domain 只隔离「ROS 2 节点之间」，不会断开机器人。
> 这是最容易误解的地方，别被"改 domain 就连不上真机"的错觉带偏。

### 步骤 4 — 规划 `lzh_moveit_config` ✅ 待做

```bash
bash ~/g1d_ros2_lzh/copy_pkg.sh g1d_moveit_config
```

依赖步骤 2（URDF）+ 步骤 3（关节状态），缺一不可。

### 步骤 5 — 其余

`lzh_bringup` / `lzh_camera_bridge` / `lzh_motion_demo` 按需复制。

---

## 八、常见坑速查

| 症状 | 原因 | 解法 |
|---|---|---|
| 改了代码跑起来还是老版本 | 同一个终端 source 了两个工作空间 | 开新终端，只 source 我的 |
| 看不到师兄的 topic | domain 不同 | 正常，隔离生效；临时 `export ROS_DOMAIN_ID=0` |
| 改 domain 后连不上真机 | 误解 | SDK2 独立 DDS，**不受 ROS_DOMAIN_ID 影响**，正常连 |
| `colcon build` 报找不到包 | 没 source 对环境 | `source ~/g1d_ros2_lzh/setup_env.sh` |
| `git push` 要密码 | credential helper 没生效 | 跑 `check_isolation.sh` 看第 5 项 |
