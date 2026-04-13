# VibeGesture 技术详细方案

## 1. 文档目的

本文件是 `TECH_ARCHITECTURE.md` 的执行级配套文档。

它面向后续 coder agent，作为更细化的实现参考。请将它与以下文档一起阅读：
- `PRD.md`，用于产品需求
- `AGENTS.md`，用于贡献者约束
- `TECH_ARCHITECTURE.md`，用于系统结构

### 文档边界
- `TECH_ARCHITECTURE.md` 定义模块划分和运行边界。
- 本文件定义这些边界内部的具体行为。
- 如果本文件与架构文档不同，则以架构文档的结构为准；而 PRD 和 AGENTS 仍然是产品行为的最高准则。

本文件应足够具体，以便 coder agent 在不凭空补设行为的情况下实现应用，但它不应变成 task card。

---

## 2. 单一推荐实现

V1 的推荐实现是：
- 原生 macOS 应用，使用 Swift
- SwiftUI 用于轻量 UI
- 必要时使用 AppKit 处理菜单栏 / popover 集成
- AVFoundation 摄像头采集
- Vision hand pose detection
- 一个串行的识别 coordinator
- 显式的识别 state machine
- 集中的键盘事件发射器

### 为什么是这套形态
- 它让代码路径更短。
- 它让状态转移更容易审计。
- 它避免线程语义不清。
- 它给后续 coder agent 一个清晰的实现模板。

### 少量可替代点
如果未来需要更细的并发隔离，可以把串行 coordinator 切成小型 actors。V1 不应从这里开始。

---

## 3. 参考运行模型

应用应看作三个正交关注点的组合：

1. `recognition_state`
2. `permission_state`
3. `foreground_app_gate`

### 3.1 Recognition State
可能取值：
- `disabled`
- `idle`
- `recording_active`
- `cooldown`
- `error_permission_missing`

### 3.2 Permission State
可能取值：
- `ready`
- `missing_camera`
- `missing_accessibility`
- `missing_both`

`permission_state` 只是权限原因细分，不是主控制态。  
权限层应决定展示哪种 onboarding，但不应负责手势逻辑。

### 3.3 Foreground App Gate
可能取值：
- `supported`
- `unsupported`

app gate 应被视作独立的放行 / 拒绝条件，而不是 recognition state machine 的替代品。

### 3.4 组合规则
只有同时满足以下条件时，动作才可以触发：
- 识别已开启
- 必需权限可用
- 前台应用受支持
- state machine 允许该手势

其中 `recognition_state` 是主控制态，`permission_state` 只是它的原因细分之一。

---

## 4. 数据模型

保持运行时模型显式、朴素。

### 4.1 推荐核心类型

建议使用如下小型类型：

- `RecognitionState`
- `PermissionStatus`
- `ForegroundAppStatus`
- `GestureCandidate`
- `GestureAction`
- `KeyboardAction`
- `OverlayMessage`
- `TimerToken`
- `AppConfiguration`

### 4.2 推荐配置模型

配置应存为一个轻量、可持久化的值对象：
- 全局识别 toggle 快捷键
- record toggle 快捷键
- submit 快捷键
- cancel 快捷键

V1 约束：
- record toggle 快捷键仅允许单键
- 不支持手势训练配置
- 不支持用户可编辑白名单

### 4.3 推荐运行时标志

coordinator 应能快速回答以下问题：
- 当前识别是否开启？
- 当前录音是否开启？
- 是否存在待处理的 submit 延迟？
- cooldown 是否激活？
- 前台是否是受支持的应用？
- 权限是否有效？

这些都不应从分散的 UI 状态去推导。

---

## 5. 模块契约

## 5.1 App Shell / 菜单栏

### 输入
- app 启动 / 终止
- 菜单栏切换
- 全局快捷键

### 输出
- 显示或隐藏设置
- 启用或禁用识别
- 更新菜单栏状态

### 规则
壳层不得直接读取摄像头数据，也不得合成键盘事件。

---

## 5.2 权限管理器

### 职责
- 检查 Camera 权限
- 检查 Accessibility trust
- 展示首次启动引导
- 当权限丢失时，判断是否需要安全停录

### 行为
- 首次启动时，只提示缺失的那个权限
- 如果两个权限都缺失，则一次只引导一个权限
- 如果必要权限在录音开启期间被撤销，应先停止录音，再转入 `error_permission_missing`

### 实现说明
Camera 权限和 Accessibility trust 应分开检查，这样 UI 才能准确说明缺少什么。

---

## 5.3 摄像头采集管理器

### 职责
- 创建并管理 `AVCaptureSession`
- 仅使用默认摄像头
- 将帧送入 Vision pipeline

### 行为
- 仅当识别已开启且权限有效时，才开始采集
- 当识别关闭，或应用需要安全关停时，应立即停止采集

### 建议
把采集会话生命周期与手势解释分离。这样在排查摄像头问题时，不需要触碰状态逻辑。

---

## 5.4 手部姿态检测器

### 职责
- 运行 Vision hand pose 请求
- 产出适用于单只右手的标准化观测
- 为手势解释器提供足以识别 pinch、submit、cancel 和 re-arm 条件的信号

### 行为
- 仅使用默认摄像头输入
- V1 仅考虑右手
- 如果置信度过低，检测器应返回“没有可执行手势”，而不是猜测

### 建议
不要让检测器自己解释“pinch 意味着开始录音”。那应该属于 gesture interpreter。

---

## 5.5 手势解释器

### 职责
- 将手部姿态观测转成手势候选
- 应用阈值和 debounce 规则
- 输出抽象手势事件，而不是键盘事件

### 输出类型
- `pinch_started`
- `pinch_rearmed`
- `submit_started`
- `cancel_started`
- `no_action`

### 规则
解释器应不知道当前配置了哪些前台应用。

### 时间默认值
除非调优证明有必要，否则使用以下默认值：
- 目标帧率：`10-15 FPS`
- pinch 激活：`6 consecutive frames`
- pinch re-arm：`4 consecutive frames without pinch`
- submit 激活：`4 consecutive frames`
- cancel 激活：`3 consecutive frames`
- cooldown：`700 ms`
- submit-stop 延迟：`300 ms`
- 识别超时：`1 hour` 的 active recognition time

### 重要约束
解释器不应决定某个识别结果是否可以触发。这个判断属于 state machine。

### 边界说明
gesture interpreter 只负责把原始观测变成候选事件，不负责判断这些候选事件最终能不能触发。  
最终放行仍然由 recognition state machine 决定。

---

## 5.6 识别协调器 / State Machine

### 职责
- 拥有当前识别状态
- 按顺序处理手势候选
- 处理 cooldown 和 re-arm 规则
- 协调 submit 和 cancel 的时序
- 协调安全停录行为

### 边界说明
state machine 是唯一的主控制点。它可以读取 `permission_state` 和 `foreground_app_gate`，但不应把它们实现成和自己平级的另一套控制系统。

### 推荐事件处理规则
所有手势候选都应先进入同一个串行协调器，以避免以下对象之间产生竞态：
- camera frames
- submit 延迟计时器
- cancel 中断
- app gating 变化
- 权限丢失

### 内部状态语义

#### `disabled`
- 识别关闭
- 不应触发任何手势动作

#### `idle`
- 识别开启
- 录音关闭
- 系统正在等待有效手势

#### `recording_active`
- 目标应用中的录音已经切到开启

#### `cooldown`
- 一次性动作已经触发
- cooldown 期间不处理任何手势
- 系统等待 refractory 窗口结束

#### `error_permission_missing`
- 因为必需权限缺失，识别无法继续

### 状态转移规则

#### 开启识别
条件：
- 用户开启识别
- 权限有效
- 前台应用受支持

动作：
- 进入 `idle`
- 开始摄像头采集
- 开始 active-recognition 计时

#### Pinch Start
条件：
- gesture interpreter 发出 `pinch_started`
- cooldown 未激活
- 当前录音关闭

动作：
1. 单击一次配置好的 record toggle 键
2. 显示 `Recording`
3. 进入 `cooldown`
4. cooldown 结束后进入 `recording_active`

#### Pinch Stop
条件：
- gesture interpreter 发出 `pinch_started`
- cooldown 未激活
- 当前录音开启

动作：
1. 单击一次配置好的 record toggle 键
2. 显示 `Recording Stopped`
3. 进入 `cooldown`
4. cooldown 结束后进入 `idle`

#### 录音关闭时的 Submit
条件：
- gesture interpreter 发出 `submit_started`
- 当前录音关闭

动作：
1. 发射 submit 键
2. 显示 `Submitted`
3. 进入 `cooldown`
4. cooldown 结束后进入 `idle`

#### 录音开启时的 Submit
条件：
- gesture interpreter 发出 `submit_started`
- 当前录音开启

动作：
1. 单击一次 record toggle 键，停止录音
2. 等待 `300 ms`
3. 发射 submit 键
4. 显示 `Submitted`
5. 进入 `cooldown`
6. cooldown 结束后进入 `idle`

#### 录音开启时的 Cancel
条件：
- gesture interpreter 发出 `cancel_started`
- 当前录音开启

动作：
1. 单击一次 record toggle 键，停止录音
2. 发射 cancel 键
3. 显示 `Cancelled`
4. 进入 `cooldown`
5. cooldown 结束后进入 `idle`

#### 录音关闭时的 Cancel
条件：
- gesture interpreter 发出 `cancel_started`
- 当前录音关闭

动作：
1. 发射 cancel 键
2. 显示 `Cancelled`
3. 进入 `cooldown`
4. cooldown 结束后进入 `idle`

#### 关闭识别 / 超时 / 权限丢失 / app gate 丢失
条件：
- 用户手动关闭识别
- 或 active-recognition 计时到期
- 或权限丢失
- 或前台应用在录音开启时变成不受支持

动作：
1. 如果录音开启，单击一次 record toggle 键停止录音
2. 停止或挂起采集
3. 转入 blocked 或 disabled 状态

### Submit 中断规则
如果 cancel 在 `300 ms` submit 等待窗口内到达，cancel 必须清除待处理的 submit 动作，确保之后不会再发出 Enter。

### 采样规则
Submit 的行为由 submit 手势被采样时看到的录音状态决定，而不是由后续状态决定。

---

## 6. 支持应用 gating

### 白名单
使用 bundle identifier：
- Codex: `com.openai.codex`
- Claude Code: `com.anthropic.claudefordesktop`
- Cursor: `com.todesktop.230313mzl4w4u92`

### gating 政策
- 前台应用不受支持时忽略手势
- V1 的白名单固定
- 用户不能编辑白名单

### 安全政策
如果前台应用在录音开启时切换为不受支持，应先停止录音，再抑制后续手势动作。

### 实现说明
app detection 应足够快，不能阻塞摄像头流水线。

---

## 7. 键盘事件发射

### 7.1 发射模型
键盘事件应通过一个集中的 dispatcher 发射。

### 7.2 事件类型
dispatcher 应支持：
- 单键 tap
- submit 键事件
- cancel 键事件

V1 中，record toggle 快捷键仅允许单键。

### 7.3 不对 Fn 做特殊映射
把 record toggle 键当作普通配置的单键即可。  
不要在 dispatcher 中为 “Fn semantics” 建立特殊分支。

### 7.4 安全规则
不要绕过 dispatcher 直接发射手势触发的动作。

---

## 8. UI 与反馈实现

### 8.1 菜单栏
菜单栏图标应体现：
- 非激活
- 识别已开启
- 权限缺失
- 如果有助于图标层表达，则可以体现录音开启状态

### 8.2 Overlay 文案
推荐文案：
- `Gesture On`
- `Gesture Off`
- `Recording`
- `Recording Stopped`
- `Submitted`
- `Cancelled`
- `Permission Required`

### 8.3 设置界面
推荐形态：
- 作为主要设置入口的轻量 popover
- 只有在实现简单性需要时才使用紧凑窗口

### 8.4 UX 规则
反馈要简短、非打扰。

---

## 9. 持久化与配置

### 9.1 持久化配置
仅持久化 V1 真正需要的内容：
- 识别 toggle 状态跨启动不保留
- 全局识别快捷键
- record toggle 快捷键
- submit 快捷键
- cancel 快捷键

### 9.2 不持久化的运行时状态
不要持久化：
- 当前录音状态
- cooldown 状态
- 当前前台应用 gate 状态
- submit 延迟状态

这些都属于运行时状态。

### 9.3 计时器重置规则
手动关闭识别会重置下一次激活时的 active-recognition 计时器。

---

## 10. 线程与并发建议

### 推荐布局
- main actor：UI、菜单、overlay
- capture queue：摄像头与 Vision 工作
- serial coordinator queue：state machine、计时器、动作时序
- 如果需要，dispatcher queue：键盘事件发射

### 原因
这样可以让帧处理与 UI 更新分离，同时保证动作发射的顺序是确定的。

### 实现注意
不要让多个 queue 同时修改同一份识别状态。

---

## 11. 推荐文件布局

这只是建议组织方式，不是硬性要求。

- `App` 入口
- 菜单栏壳层
- 配置存储
- 权限管理器
- 摄像头采集管理器
- Vision hand pose 检测器
- gesture interpreter
- recognition coordinator
- 前台应用 gate
- 键盘事件发射器
- overlay 控制器
- 设置视图
- 共享模型类型

### 文件组织规则
共享模型类型要尽量小而明显。后续 coder agent 应该能在不翻乱无关视图文件的情况下，找到完整的 state machine。

---

## 12. 推荐构建顺序

实现顺序应当是：

1. app 壳层和配置连线
2. 权限管理器和首次启动流程
3. 摄像头采集和 Vision 观测流水线
4. gesture interpreter 和阈值调优
5. recognition coordinator 和 state machine
6. 键盘事件发射器和安全停录行为
7. 前台应用 gate
8. overlay 和菜单栏反馈
9. 设置界面
10. 稳定化和调优

### 为什么按这个顺序
- 它能最先打通最小的端到端 vertical slice
- 它能尽早把 state machine 暴露出来
- 它能减少 UI 工作偏离核心行为

---

## 13. 验证清单

后续 coder agent 应使用以下场景验证实现：

### 识别
- 开启识别
- 关闭识别
- 在 1 小时 active recognition time 后自动超时

### Pinch
- pinch 一次开始录音
- 再 pinch 一次停止录音
- 手势持续保持时不会重复触发
- cooldown 能阻止重复触发

### Submit
- 录音关闭时 submit 会发送 Enter
- 录音开启时 submit 会先停止录音，等待 300 ms，再发送 Enter
- cancel 在 submit 等待窗口内会抑制 Enter

### Cancel
- 录音关闭时 cancel 会发送 Esc
- 录音开启时 cancel 会先停止录音，再发送 Esc

### App Gating
- 支持的应用可以接受动作
- 不支持的应用会忽略动作
- 如果在录音开启时丢失 app gate，录音会先停止

### 权限
- 缺少 camera 会阻止识别
- 缺少 accessibility 会阻止识别
- 如果权限在录音开启时丢失，录音会先停止

### UI
- 菜单栏状态清晰
- overlay 文案简短
- 设置入口轻量

---

## 14. 保持灵活的部分

以下内容可以在实现中调优，而不改变架构：
- `10-15 FPS` 范围内的具体帧率
- debounce 的具体实现细节
- overlay 的具体视觉样式
- 设置界面在边缘场景下是只用 popover 还是补一个小 window
- coordinator 是串行对象还是小型 actor-backed 等价实现

不要把这些当成产品决策。它们只是实现细节。

---

## 15. 总结

推荐实现是一条小型原生 pipeline：

`camera -> Vision -> gesture interpreter -> serial coordinator -> app gate -> keyboard dispatcher -> overlay`

核心实现规则是：
- 先检测原始手部姿态
- 再集中解释手势
- 再集中决定状态转移
- 最后才发射键盘动作
