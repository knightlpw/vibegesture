# PROJECT_CONTEXT.md — VibeGesture

## 项目是什么

VibeGesture 是一个轻量级 macOS 菜单栏工具，面向 vibe coder。
它的目标是用固定的右手手势把语音输入工作流里的重复键盘操作最小化，当前文档语义仍然以 Codex、Claude Code、Cursor 为主要支持对象。

## 项目不是什么

- 不是通用手势自动化平台
- 不是可编辑白名单的平台
- 不是多手 / 左手识别产品
- 不是 Typeless 内部集成
- 不是 Mac App Store 项目

## 当前产品状态

- PRD、AGENTS、技术架构、技术详细方案、roadmap 和 task card 已对齐
- TASK001 已完成并验证通过
- TASK002 已完成并验证通过
- TASK003 已完成并验证通过
- 阶段 1 已落地：仓库现在有可编译的 macOS 菜单栏壳层和配置骨架
- 阶段 2 已开始落地：仓库现在有权限状态模型、权限检查器、受限状态展示与轻量系统设置引导
- 阶段 3 已落地：仓库现在有默认摄像头采集、Vision hand pose 观测骨架与摄像头 / pipeline 状态展示
- TASK004 已完成：仓库现在有 gesture interpreter、显式 recognition state machine、一次性候选事件和 recognition 状态展示
- TASK005 已完成并修正 cooldown 关闭识别时的安全停录边界：仓库现在有集中式 keyboard dispatcher、record toggle 单键 tap、submit / cancel 安全时序、显式 recording state，以及 keyboard dispatch 结果展示
- TASK006 已完成：仓库现在有前台应用 gate 检测、固定 bundle id 白名单、gate 状态展示，以及 gate 丢失时的安全停录与 pending submit 收束
- 阶段 6 代码已接入且 gate 丢失时的 pending submit 收束边界已修复，可以继续进入设置界面与配置持久化
- TASK007 已完成并验证通过：仓库现在有可编辑的设置界面、配置持久化、启动恢复，以及 recognition hotkey 运行时重绑
- TASK008 已完成并验证通过：仓库现在有稳定化、调优与端到端验证骨架，补充了 workflow 级回归测试和运行时热键重绑验证
- TASK008 reviewer 验证已通过：workflow 级稳定化回归测试、gate 丢失收束、录音中 gate 丢失安全停录、runtime hotkey rebind 和配置注入行为都已独立验收
- 阶段 8 已落地：仓库现在有稳定化、调优与端到端验证骨架，可继续交给 reviewer 独立验收
- 2026-04-15 因手势设计更新，新增 TASK009：把现有实现统一对齐到最新的 `Record` / `Submit` / `Cancel` 手部姿态映射
- 当前实现是一个 SwiftPM executable 形式的 accessory app shell，不是完整的摄像头 / Vision / 手势产品
- TASK009 的姿态边界问题已修复并验证通过：`Record` / `Submit` / `Cancel` 的实际判定已切到新姿态组合，reviewer 复验已通过
- 已实现的阶段 1-8 能力包括：菜单栏状态项、识别开关壳层、全局快捷键入口、设置窗口占位、配置持久化骨架、权限状态展示与受限态处理、默认摄像头采集、Vision hand pose 观测骨架、gesture candidate 解释、显式 state machine、键盘发射与安全时序、前台应用 gate 状态展示、可编辑快捷键设置，以及摄像头流水线 / 识别 / keyboard / gate / settings 状态展示
- 2026-04-15 增加了权限引导 follow-up：设置页的按钮现在会按缺失权限直达 `Camera` 或 `Accessibility` 的系统设置页面，而不是只打开系统设置首页
- 2026-04-15 进一步补齐了权限申请链路：设置页按钮会优先触发 Camera 的系统授权请求，必要时再回落到对应系统设置页；Accessibility 也会触发系统信任提示
- 2026-04-15 进一步补齐了旧配置迁移：启动时会自动修复缺少 `recordToggleShortcut.keyCode` 的历史配置，并把它恢复为 `Fn`
- 2026-04-15 形成了验收复盘文档 [`pm/acceptance/ACCEPTANCE_20260415_001.md`](/Users/linpeiwen/knightspace/vibegesture/pm/acceptance/ACCEPTANCE_20260415_001.md)，记录权限引导和旧配置迁移这两个验收问题的根因与预防措施
- 2026-04-16 已校正 cancel 的设计语义：PRD / AGENTS / TECH_IMPLEMENTATION_PLAN 现在把 cancel 统一定义为直接发送 `Esc`，不再把“先停止录音，再发送 Esc”写进产品语义
- 2026-04-16 进一步补齐了 TASK_20260415_011：runtime feedback task 现在明确要求 cancel 不再携带 `stopRecordingFirst`，state machine / dispatcher 只产出并发送直接 `Esc`
- 2026-04-16 已将 record / submit 的产品手势细化为“拇指食指指尖触碰 + 其余三指握拳 / 张开”，并已完成 TASK_20260415_013，把 GestureInterpreter 升级为轻量训练分类器
- 2026-04-16 TASK_20260415_014 已完成并通过 reviewer 验证：仓库现在有用户可直接操作的校准入口，支持采样、清空、保存、重训和 classifier reload 闭环，settings 里可直接完成 record / submit / background 的样本采集
- 2026-04-17 TASK_20260415_015 已完成并通过 reviewer 验证：仓库现在有补齐 `cancel` 的校准闭环，并在校准模式下允许 VibeGesture 自己前台时继续采样
- 2026-04-16 新增 TASK_20260415_012：需要定位并修复 `record` 反复触发和 `submit` 误触这两类手势稳定性问题，保持 cancel 直发 `Esc` 语义不回退
- 2026-04-16 TASK_20260415_012 已完成：record 现在只有在连续 4 帧不再是 record 后才会再次触发，submit 的半卷手指误触已收紧，相关回归测试已补齐
- 2026-04-16 TASK_20260415_013 已完成并通过 reviewer 验证：仓库现在有基于 Vision hand landmarks 的单用户轻量训练分类器、校准数据格式与落盘存储、启动时 classifier 加载路径，以及覆盖训练 / 持久化 / 回归边界的测试
- 2026-04-15 ISSUE_20260415_001 已修复并验证通过：`GestureInterpreter` 的 `Record` / `Submit` / `Cancel` 判定已改成新姿态组合，reviewer 复验已通过
- 2026-04-15 新增 TASK_20260415_010：需要把当前 SwiftPM executable 壳层收束成真正的 macOS app bundle / app identity，确保 Camera / Accessibility 权限绑定到 VibeGesture 自身而不是 Terminal
- 2026-04-15 新增 TASK_20260415_011：需要收紧菜单栏实时刷新、gesture 展示、cancel 时序与 record / submit 误触率
- 2026-04-16 TASK_20260415_011 已完成：菜单栏现在会在打开期间实时刷新，gesture 展示已拆成 candidate / pose / recent action，cancel 已收口为直接 `Esc`，record / submit 的判定也已进一步收紧并补齐回归测试
- 2026-04-15 TASK_20260415_010 的 bundle identity 已进一步补强为 ad-hoc signed bundle：仓库现在有最小 macOS app bundle 包装脚本、稳定 bundle identifier、Info.plist / app identity、简约 app icon、ad-hoc 签名，以及可复验的 bundle 启动路径；Camera / Accessibility 授权目标仍需 reviewer 在系统设置里复验是否已切换到 VibeGesture
- 2026-04-15 ISSUE_20260415_002 已修复并通过验收：用户将应用从辅助功能授权列表移除后重新添加一次后，`AXIsProcessTrusted()` 回到 true，settings 页与菜单栏都显示 live Accessibility trusted，当前 Camera / Accessibility 都已闭环到 VibeGesture
- 2026-04-15 这组临时 live permission diagnostics 已在验证完成后移除，settings 页和菜单栏恢复为只展示正式权限状态
- 2026-04-16 TASK011 reviewer 验证已通过：实际菜单栏状态项已通过 System Events 复验，`Gesture candidate` / `Gesture pose` / `Recent action` 拆分与直接 `Esc` 的 cancel 语义都已独立验证
- 2026-04-16 TASK012 reviewer 验证已通过：`record` repeat 边界已收紧到连续 4 帧不再是 record，`submit` 半卷手指误触已进一步下降，相关回归测试与 bundle smoke check 都通过
- 当前 roadmap 主阶段已完成；如果要继续推进现有实现，手势语义应以 TASK009 的最新设计为基线，而运行身份与权限归属应继续围绕 TASK_20260415_010 的 bundle identity 问题补证或修正，实时反馈与误触稳定性则由 TASK_20260415_011 负责
- TASK_20260415_013 已完成并通过 reviewer 验证：`record` / `submit` 已切到单用户轻量分类器路径，校准样本和持久化存储也已接入
- TASK_20260415_014 已完成并通过 reviewer 独立验收：settings 里现在有可直接操作的校准入口，用户可以采样、清空、保存、重训并热加载 classifier
- 2026-04-18 TASK_20260418_016 已完成并通过 reviewer 验证：训练模式已优化为用户样本优先主导 classifier，bootstrap 仅作为 cold-start fallback
- 2026-04-18 TASK_20260418_017 已完成并通过 reviewer 验证：record runtime 门槛已对齐 calibrated profile 的置信度阈值，标准 record 样本的 runtime 召回问题已继续收紧
- 2026-04-18 TASK_20260418_018 已完成并通过 reviewer 验证：runtime 已直接重构回规则模式，在线识别不再继续依赖 classifier
- 2026-04-18 TASK_20260418_019 已完成：菜单栏与 settings 的诊断信息已默认折叠，普通用户默认只看到最小状态与操作项
- 2026-04-18 当前代码已标记为稳定基线：`stable-20260418`
- 2026-04-18 已更新 app bundle icon：当前 bundle 通过 `scripts/make_app_icon.swift` 生成简约线条手势图标，并已整体倒置为你确认的反向样式，替换了原先的 V 字标识
- 2026-04-18 已新增 `scripts/build_dmg.sh`：可直接从 release bundle 生成可安装的 `.dmg`，默认产物位于 `.build/distribution/VibeGesture-release.dmg`
- 2026-04-18 已收紧 calibration camera 启动条件：打开 Settings 窗口不再自动进入 calibration mode，只有用户真正点击采样动作时才会拉起摄像头
- 2026-04-18 TASK_20260418_019 已完成：菜单栏与 settings 的诊断信息已默认折叠，普通用户默认只看到最小状态与操作项
- 用户最新验收反馈表明：当前训练模式虽然已落地，但 `record` / `submit` 仍然容易落到 `background`，因此本轮把加载策略调整为用户样本优先训练，bootstrap 仅作为 cold-start fallback；若 reviewer 仍反馈不够好，再决定是否需要回退到规则模式
- `record release / re-arm` 的实现现在回到最小语义：只要离开 `record`，连续 4 帧不再是 `record` 就可重新武装，不再依赖额外的内部 release pose
- 2026-04-18 TASK_20260418_017 已完成并通过 reviewer 验证：`record` 的运行时接受门槛已对齐到 calibrated profile，补齐了 calibrated record confidence 的回归测试
- 2026-04-18 TASK_20260418_018 已完成并通过 reviewer 验证：`record / submit / cancel` 的在线识别已切回规则模式，runtime 不再依赖 classifier
- 2026-04-18 TASK_20260418_019 已完成：菜单栏与 settings 的诊断信息已默认折叠，普通用户默认只看到最小状态与操作项

## 架构 / 状态流

当前代码的运行链路是：

`main.swift -> ApplicationDelegate -> AppCoordinator -> PermissionManager / RecognitionCoordinator / CameraPipelineController / StatusItemController / GlobalHotKeyManager / SettingsWindowController -> AppState + ConfigurationStore`

未来完整链路仍应保持：

`camera -> Vision -> gesture interpreter -> state machine -> app gate -> keyboard dispatcher -> overlay`

核心状态仍然是：
- `disabled`
- `idle`
- `recording_active`
- `cooldown`
- `error_permission_missing`

关键语义仍然不变：
- `record` 是单击切换录音的 one-shot toggle
- `submit` 和 `cancel` 也是一次性手势
- `cooldown` 期间不处理任何手势
- 前台应用 gating 基于 bundle identifier

## 关键文件

- [`Package.swift`](/Users/linpeiwen/knightspace/vibegesture/Package.swift)
- [`Sources/VibeGesture/main.swift`](/Users/linpeiwen/knightspace/vibegesture/Sources/VibeGesture/main.swift)
- [`Sources/VibeGesture/AppCoordinator.swift`](/Users/linpeiwen/knightspace/vibegesture/Sources/VibeGesture/AppCoordinator.swift)
- [`Sources/VibeGesture/AppState.swift`](/Users/linpeiwen/knightspace/vibegesture/Sources/VibeGesture/AppState.swift)
- [`Sources/VibeGesture/PermissionState.swift`](/Users/linpeiwen/knightspace/vibegesture/Sources/VibeGesture/PermissionState.swift)
- [`Sources/VibeGesture/PermissionManager.swift`](/Users/linpeiwen/knightspace/vibegesture/Sources/VibeGesture/PermissionManager.swift)
- [`Sources/VibeGesture/StatusItemController.swift`](/Users/linpeiwen/knightspace/vibegesture/Sources/VibeGesture/StatusItemController.swift)
- [`Sources/VibeGesture/GlobalHotKeyManager.swift`](/Users/linpeiwen/knightspace/vibegesture/Sources/VibeGesture/GlobalHotKeyManager.swift)
- [`Sources/VibeGesture/SettingsWindowController.swift`](/Users/linpeiwen/knightspace/vibegesture/Sources/VibeGesture/SettingsWindowController.swift)
- [`Sources/VibeGesture/SettingsView.swift`](/Users/linpeiwen/knightspace/vibegesture/Sources/VibeGesture/SettingsView.swift)
- [`Sources/VibeGesture/ShortcutEditing.swift`](/Users/linpeiwen/knightspace/vibegesture/Sources/VibeGesture/ShortcutEditing.swift)
- [`Sources/VibeGesture/SafeShutdown.swift`](/Users/linpeiwen/knightspace/vibegesture/Sources/VibeGesture/SafeShutdown.swift)
- [`Sources/VibeGesture/AppConfiguration.swift`](/Users/linpeiwen/knightspace/vibegesture/Sources/VibeGesture/AppConfiguration.swift)
- [`Sources/VibeGesture/ConfigurationStore.swift`](/Users/linpeiwen/knightspace/vibegesture/Sources/VibeGesture/ConfigurationStore.swift)
- [`Sources/VibeGesture/CameraObservation.swift`](/Users/linpeiwen/knightspace/vibegesture/Sources/VibeGesture/CameraObservation.swift)
- [`Sources/VibeGesture/CameraCaptureManager.swift`](/Users/linpeiwen/knightspace/vibegesture/Sources/VibeGesture/CameraCaptureManager.swift)
- [`Sources/VibeGesture/VisionHandPoseProcessor.swift`](/Users/linpeiwen/knightspace/vibegesture/Sources/VibeGesture/VisionHandPoseProcessor.swift)
- [`Sources/VibeGesture/CameraPipelineController.swift`](/Users/linpeiwen/knightspace/vibegesture/Sources/VibeGesture/CameraPipelineController.swift)
- [`Sources/VibeGesture/GestureClassifier.swift`](/Users/linpeiwen/knightspace/vibegesture/Sources/VibeGesture/GestureClassifier.swift)
- [`Sources/VibeGesture/GestureCalibrationStore.swift`](/Users/linpeiwen/knightspace/vibegesture/Sources/VibeGesture/GestureCalibrationStore.swift)
- [`Sources/VibeGesture/GestureCalibrationController.swift`](/Users/linpeiwen/knightspace/vibegesture/Sources/VibeGesture/GestureCalibrationController.swift)
- [`Sources/VibeGesture/GestureRecognitionModels.swift`](/Users/linpeiwen/knightspace/vibegesture/Sources/VibeGesture/GestureRecognitionModels.swift)
- [`Sources/VibeGesture/GestureInterpreter.swift`](/Users/linpeiwen/knightspace/vibegesture/Sources/VibeGesture/GestureInterpreter.swift)
- [`Sources/VibeGesture/RecognitionStateMachine.swift`](/Users/linpeiwen/knightspace/vibegesture/Sources/VibeGesture/RecognitionStateMachine.swift)
- [`Sources/VibeGesture/RecognitionCoordinator.swift`](/Users/linpeiwen/knightspace/vibegesture/Sources/VibeGesture/RecognitionCoordinator.swift)
- [`Sources/VibeGesture/KeyboardDispatcher.swift`](/Users/linpeiwen/knightspace/vibegesture/Sources/VibeGesture/KeyboardDispatcher.swift)
- [`docs/PRD.md`](/Users/linpeiwen/knightspace/vibegesture/docs/PRD.md)
- [`docs/AGENTS.md`](/Users/linpeiwen/knightspace/vibegesture/docs/AGENTS.md)
- [`docs/TECH_ARCHITECTURE.md`](/Users/linpeiwen/knightspace/vibegesture/docs/TECH_ARCHITECTURE.md)
- [`docs/TECH_IMPLEMENTATION_PLAN.md`](/Users/linpeiwen/knightspace/vibegesture/docs/TECH_IMPLEMENTATION_PLAN.md)
- [`docs/ROADMAP.md`](/Users/linpeiwen/knightspace/vibegesture/docs/ROADMAP.md)
- [`docs/handoff/README.md`](/Users/linpeiwen/knightspace/vibegesture/docs/handoff/README.md)
- [`docs/handoff/CHANGELOG.md`](/Users/linpeiwen/knightspace/vibegesture/docs/handoff/CHANGELOG.md)
- [`pm/task/TASK_20260414_001.md`](/Users/linpeiwen/knightspace/vibegesture/pm/task/TASK_20260414_001.md)
- [`pm/task/TASK_20260414_002.md`](/Users/linpeiwen/knightspace/vibegesture/pm/task/TASK_20260414_002.md)
- [`pm/task/TASK_20260414_003.md`](/Users/linpeiwen/knightspace/vibegesture/pm/task/TASK_20260414_003.md)
- [`pm/task/TASK_20260414_004.md`](/Users/linpeiwen/knightspace/vibegesture/pm/task/TASK_20260414_004.md)
- [`pm/task/TASK_20260414_005.md`](/Users/linpeiwen/knightspace/vibegesture/pm/task/TASK_20260414_005.md)
- [`pm/task/TASK_20260414_006.md`](/Users/linpeiwen/knightspace/vibegesture/pm/task/TASK_20260414_006.md)
- [`pm/task/TASK_20260414_007.md`](/Users/linpeiwen/knightspace/vibegesture/pm/task/TASK_20260414_007.md)
- [`pm/task/TASK_20260414_008.md`](/Users/linpeiwen/knightspace/vibegesture/pm/task/TASK_20260414_008.md)
- [`pm/task/TASK_20260415_009.md`](/Users/linpeiwen/knightspace/vibegesture/pm/task/TASK_20260415_009.md)

## 已验证信息

- `swift build` 通过
- `swift test` 通过
- 启动检查通过：`.build/debug/VibeGesture` 能拉起进程且未在启动阶段报错
- 已验证设置页权限引导可以编译通过并覆盖缺失 Camera / Accessibility 的目标选择
- 已验证设置页权限引导的 Camera request / Accessibility prompt 逻辑可以编译通过并覆盖缺失权限的目标选择
- 已验证缺失 `recordToggleShortcut.keyCode` 的历史配置可在加载时自动修复并写回
- 已验证新增稳定化 workflow tests、`AppCoordinator` 配置重绑路径与配置存储注入行为
- `git` 目前已初始化在本仓库中
- 已完成提交：`9b22db3` / `TASK001: scaffold VibeGesture menu bar shell`
- 已完成提交：`47363d5` / `TASK002: add permission and restricted-state scaffold`
- TASK003 已完成，摄像头 / Vision 采集骨架已接入当前壳层
- TASK004 已完成，gesture interpreter / recognition state machine 骨架已接入当前壳层
- TASK005 已完成，keyboard dispatcher / submit / cancel 安全时序骨架已接入当前壳层，且 cooldown 关闭识别时的安全停录边界已修正
- TASK006 已完成，前台应用 gating / feedback 骨架已接入当前壳层，且 gate 丢失时的 pending submit 收束边界已修复
- TASK007 已完成，设置界面 / 配置持久化已承接当前壳层
- TASK008 已完成，稳定化、调优与端到端验证骨架已承接当前壳层
- 已确认本地安装的前台应用 bundle id：
  - Codex: `com.openai.codex`
  - Claude Code: `com.anthropic.claudefordesktop`
  - Cursor: `com.todesktop.230313mzl4w4u92`

## 运行备注

- 现在的菜单栏壳层使用 accessory activation policy，不显示 Dock 图标
- 全局快捷键壳层目前只注册识别开关，默认是 `⌥⇧G`
- record / submit / cancel 现在已经进入 gesture candidate / state machine / keyboard dispatcher 骨架
- 设置窗口现在包含权限状态、受限态说明、去系统设置的引导按钮，以及可编辑快捷键设置
- 设置窗口的权限引导按钮会根据缺失项直达对应的 Camera / Accessibility 系统设置页面
- 设置窗口的权限引导按钮会优先触发 Camera 授权请求，并在需要时回退到对应的 Camera / Accessibility 系统设置页面
- 安全关停现在已接入实际停录与 submit / cancel 时序
- 菜单栏和设置窗口的 Diagnostics 区现在可以查看摄像头 / pipeline 的基础状态、最新 gesture candidate、recognition action intent 和 keyboard dispatch result
- 菜单栏和设置窗口现在也会展示前台应用 gate 状态，非支持应用前台时会抑制后续手势与动作
- 菜单栏和设置窗口现在默认收敛为普通用户可见的最小状态集，内部诊断信息已折叠到 Diagnostics 子菜单和 settings 的折叠区
- 设置窗口现在会自动保存快捷键修改，并在 recognition shortcut 变化时运行时重绑
- 设置窗口的 Accessibility 授权按钮现在只会先触发系统 prompt，不会再同时自动打开下层系统设置页；跳转由上层 prompt 自己的 “Open System Settings” 按钮负责
- 配置加载现在会自动修复缺少 `recordToggleShortcut.keyCode` 的历史配置，避免 `KeyboardDispatcher` 继续拿到无 keyCode 的 record toggle
- 增加了稳定化 workflow tests，用来验证 gate 丢失、pending submit 收束和 runtime hotkey rebind
- 现在的 `GestureInterpreter` 会在启动时加载 `GestureCalibrationStore` 训练出的 classifier，若没有校准数据则回退到 bootstrap 样本

## 给后续 agent 的工作规则

- 按 `PRD.md` 和 `AGENTS.md` 作为产品与执行约束
- 按 `ROADMAP.md` 的顺序推进，不要跳阶段
- 先做最小闭环，再做 UI 和调优
- 不要在没有明确任务时把 stage 1 的 shell 继续扩成手势实现
- 不要在没有明确任务时把 stage 2 的权限骨架继续扩成真正的摄像头或手势流
- 不要在没有明确任务时把 stage 3 的摄像头 / Vision 骨架继续扩成 gesture interpreter
- 不要在没有明确任务时把 stage 4 的 gesture / recognition 骨架继续扩成键盘发射或 app gating
- 不要把 `record` 重新实现成按住 / 松开语义
- 不要把 `Claude Code`、Codex、Cursor 的前台限制扩大到白名单外应用
- 如果某个实现会影响多个阶段，先记录风险再继续

## 仍待注意的风险 / 权衡

- 当前实现是 SwiftPM executable，不是完整的 Xcode app bundle；后续若要做正式分发，或要让 Camera / Accessibility 权限绑定到 VibeGesture 自身，仍需要重构打包方式
- 当前实现已经补上最小 macOS app bundle 包装脚本和 app icon；bundle identity 现在可以通过本地脚本复验，后续若要正式分发仍不涉及签名 / 公证 / 分发流水线
- 菜单栏状态刷新、gesture 展示语义、cancel 时序和 record / submit 误触率这一组运行时体验问题已由 TASK_20260415_011 收口；后续 reviewer 只需验证这轮回归是否真的把 live refresh、展示层和 cancel 语义稳住
- `GlobalHotKeyManager` 目前只用于 recognition toggle，后续若加入更多全局快捷键，需要补更完整的注册管理
- `permission_state` 现在已经进入运行态；主控制态仍然是 `recognition_state`，二者不要合并
- `Fn` 现在是单键 record toggle 配置，但 dispatcher 仍不应对它做特殊分支语义
- 前台应用检测必须保持轻量，不能阻塞摄像头流水线
- 摄像头采集当前已经接入 gesture interpreter 与 recognition state machine 骨架；键盘发射骨架已接入，且安全停录的 cooldown 关闭识别边界已经修正
- gate 丢失时除了停录，还要确保任何已排队的 submit 动作不会继续向不支持应用发射；该边界已修复

## 可能影响的现有行为

这次已经影响到的行为主要是：
- 菜单栏壳层
- 配置存储
- 全局快捷键入口
- 设置入口
- 权限状态与受限态展示
- 摄像头采集与 Vision hand pose 观测骨架

## 下一步

- 当前已有 TASK_20260415_014：settings 里的校准入口已完成并等待 reviewer 独立验收
- 当前已有 TASK_20260415_015：settings 校准入口已补齐 `cancel` 训练与 self-frontmost 采样闭环，并已通过 reviewer 独立验收
- 当前已有 TASK_20260418_016：训练模式已优化为用户样本优先主导 classifier，bootstrap 仅作为 cold-start fallback，已通过 reviewer 独立验收
- 当前已有 TASK_20260418_017：record runtime 门槛已对齐 calibrated profile 的置信度阈值，已通过 reviewer 独立验收
- 当前已有 TASK_20260418_018：runtime 已重构回规则模式并通过 reviewer 验证
- 当前已有 TASK_20260418_019：菜单栏与 settings 的诊断信息已默认折叠，普通用户默认只看到最小状态与操作项
- 当前已有 TASK009：把现有实现统一对齐到最新的 `Record` / `Submit` / `Cancel` 手部姿态设计，但 reviewer 独立验收未通过，需先修正 `Record` / `Cancel` 姿态判定
- 当前已有 TASK_20260415_010：把当前 SwiftPM executable 壳层收束成真正的 macOS app bundle / app identity，解决权限绑定到 Terminal 的问题
- 当前已有 TASK_20260415_011：把菜单栏实时刷新、gesture 展示、cancel 时序和 record / submit 误触率收紧到可用水平，当前代码已完成并等待 reviewer 独立验收
- roadmap 第 8 阶段已经完成：稳定化、调优与端到端验证骨架已落地
- 如果继续推进手势语义，优先修正 TASK009 的姿态判定并补回归测试；如果继续推进权限归属和运行身份，优先处理 TASK_20260415_010；如果继续推进菜单栏反馈与误触稳定性，优先查看 TASK_20260415_011 的 reviewer 结果再决定是否继续收紧阈值；如果继续推进校准体验，先复盘 TASK_20260415_015 的 cancel 样本和前台采样闭环；如果需要继续改进 runtime，优先在规则模式下收紧 rule pose 边界，而不是重新引入在线 classifier 作为主路径

后续进入权限、摄像头、手势、键盘发射和 overlay 时，需要继续沿着同一套状态与配置模型扩展，而不是另起一套运行时状态。
