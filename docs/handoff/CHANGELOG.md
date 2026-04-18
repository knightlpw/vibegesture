# CHANGELOG

## 2026-04-18 — UI simplification task completed

- 菜单栏现在只保留最少量的状态摘要，内部诊断收进 `Diagnostics` 子菜单
- settings 现在默认只保留权限、快捷键和校准入口，认知 / pipeline / gate / calibration diagnostics 收进折叠区
- 这次只收敛界面层，不改识别、状态机、键盘、gate、权限或摄像头逻辑

## 2026-04-18 — Calibration camera launch tightened

- 打开 Settings 窗口不再自动进入 calibration mode
- camera 现在只会在用户真正点击采样动作时才启动，避免授权完成后 settings 自动拉起摄像头
- 这次只收紧 calibration 启动条件，不改 recognition 主流程或权限判定

## 2026-04-18 — DMG packaging added

- 新增 `scripts/build_dmg.sh`，可以从 release bundle 生成可安装的 `.dmg`
- 默认输出路径是 `.build/distribution/VibeGesture-release.dmg`
- DMG 根目录已验证包含 `VibeGesture.app` 和 `Applications` 链接，符合 macOS 常见拖拽安装习惯

## 2026-04-18 — App icon updated to hand glyph

- `scripts/make_app_icon.swift` 现在会生成一个简约线条手势图标，不再使用原先的 V 字标识
- 随后按反馈把手势图标整体倒置，当前 bundle / DMG 里的 icon 是反向朝下版本
- `bash scripts/build_bundle.sh` 已重新出包验证通过，生成的 `.app` bundle 已带上新的 hand icon
- 这次只替换 bundle 图标和打包产物，不改运行时手势语义或识别链路

## 2026-04-18 — Stable baseline tagged

- 当前代码基线已完成规则模式回退并通过 reviewer 验证
- 我把这一版标记为稳定基线，后续若继续迭代，应该以这次已验收通过的规则模式为起点
- 稳定基线标签：`stable-20260418`

## 2026-04-18 — Reviewer verification for TASK_20260418_018

- 重新在最新工作区代码上独立验证 `swift build`、`swift test`、`bash scripts/build_bundle.sh`，均通过
- 通过真实状态栏菜单抽查，确认 `Runtime: Rules mode` 已显示，且菜单中只保留最小状态摘要与折叠后的诊断入口
- `GestureInterpreter` 不再依赖训练 classifier，回归测试覆盖了 `record` re-arm、`submit` / `cancel` 一次性触发以及 `cancel` direct `Esc` 语义
- 本轮最终验收结论：pass

## 2026-04-18 — TASK_20260418_018 completed

- runtime 的在线识别主路径已切回规则模式，`record / submit / cancel` 不再依赖训练 classifier
- `GestureInterpreter` 现在直接根据几何规则判断候选姿态，`RecognitionCoordinator` 与 `AppCoordinator` 也已解除运行时 classifier 注入
- 状态栏菜单和 settings 页面现在明确显示 `Runtime: Rules mode`，便于区分 legacy calibration 数据与在线识别模式
- `swift build`、`swift test`、bundle smoke check 与状态栏菜单复验均通过
- 当前结论：TASK_20260418_018 已完成并通过 reviewer 独立验收

## 2026-04-18 — Reviewer verification for TASK_20260418_017

- 重新在最新工作区代码上独立验证 `swift build`、`swift test`、bundle 启动 smoke check，均通过
- `GestureInterpreter` 的 record runtime 门槛已对齐 calibrated profile 的置信度阈值，新增回归测试覆盖 runtime 稳定触发边界
- settings 窗口与既有校准流程未受影响，`submit` / `cancel` 语义未改，`cancel` 的 direct `Esc` 路径未受影响
- 本轮最终验收结论：pass

## 2026-04-18 — TASK_20260418_017 completed

- `GestureInterpreter` 现在把 record 的运行时接受门槛对齐到 calibrated profile 的置信度阈值
- 新增回归测试覆盖“calibrated record confidence 能在运行时稳定触发”这个边界，确保训练侧和运行侧口径一致
- 这次只修 record recall 的阈值口径，不改 `submit` / `cancel` 语义，也不回退到规则模式

## 2026-04-18 — Record recall follow-up planning

- 当前验收显示 calibrated classifier 对 `record` 的召回率仍不够稳定，`record` 仍容易回退为 `background`
- 下一张 task card 会先对齐 calibrated runtime 与训练口径，再视需要补更直接的 `record` 几何特征
- 这次只规划 `record` recall 的 follow-up，不回退到规则模式，也不改 `submit` / `cancel` 的既有语义

## 2026-04-18 — Record re-arm simplified

- `record` 的 re-arm 条件已去掉额外的 release pose 限制
- 现在只要连续 4 帧不再是 `record`，就可以重新武装下一次 `record`
- 这次只放宽 `recordLatched` 的回收条件，不改 `record` / `submit` / `cancel` 的产品语义

## 2026-04-18 — Record release semantics updated

- `record` 的内部 re-arm 条件已改成：拇指和食指指尖不再接触，其余三指保持握拳
- 这次调整只改 `recordLatched` 的释放态判定，不改 `record` / `submit` / `cancel` 的产品语义
- 相关测试样本已同步更新，后续 reviewer 复验应以新的 release pose 为准

## 2026-04-18 — Accessibility permission prompt flow tightened

- 点击辅助功能授权时，现在只会先触发系统的 Accessibility prompt，不再同时自动打开系统设置页
- 这样可以保留系统弹窗里的 “Open System Settings” 交互，由用户在上层弹窗完成跳转后再进入下层设置页
- 这次只收紧授权引导交互，不改变权限判定、设置页布局或 Camera / Accessibility 的整体授权流程

## 2026-04-18 — Reviewer verification for TASK_20260418_016

- 重新在最新工作区代码上独立验证 `swift build`、`swift test`、bundle 启动 smoke check，均通过
- settings 窗口中的 calibration 区块仍可正常打开，`GestureCalibrationController` 也能正确显示 classifier source
- `GestureCalibrationStore` 已按用户样本优先策略训练 calibrated model，bootstrap 仅作为 cold-start fallback；相关回归测试通过
- `cancel` 的 direct `Esc` 语义未改，未引入 bundle identity、permission 或 gate 逻辑的额外改动
- 本轮最终验收结论：pass

## 2026-04-18 — TASK_20260418_016 completed

- `TASK_20260418_016` 已完成，当前基于 Vision hand landmarks 的训练分类器已改成用户样本优先主导
- `GestureCalibrationStore` 现在会优先使用本地用户校准样本训练 calibrated model，bootstrap 仅作为 cold-start fallback
- calibrated model 和 bootstrap model 的阈值策略已分离，新增回归测试覆盖用户样本优先、bootstrap fallback 和分类来源可见性
- 代码已通过 `swift build` / `swift test`，并已通过 reviewer 独立验收

## 2026-04-17 — Reviewer verification for TASK_20260415_015

- 重新在最新工作区代码上独立验证 `swift build`、`swift test`、bundle 启动 smoke check，均通过
- 通过状态栏菜单与真实 settings 窗口复验，calibration 区块可见，`cancel` 标签、采样按钮、保存 / 重载按钮和 reset 流程都在位
- `ForegroundAppGatePolicy` 的 self-frontmost calibration bypass 与 `GestureCalibrationController` 的 `cancel` 保存条件都已通过回归测试覆盖
- `cancel` 的 direct `Esc` 语义未改，未引入 bundle identity、permission 或 gate 逻辑的额外改动
- 本轮最终验收结论：pass

## 2026-04-17 — TASK_20260415_015 completed

- `TASK_20260415_015` 已把 `TASK_20260415_014` 的校准入口补齐到包含 `cancel`
- settings 里的校准入口现在可以采集、清空、保存、重训并热加载 `cancel` 样本
- 校准模式下，当 VibeGesture 自己前台打开时，camera 可以继续保持可采样状态
- `cancel` 的 direct `Esc` 语义未改，`swift build` / `swift test` 已通过

## 2026-04-16 — Reviewer verification for TASK_20260415_013

- 重新在最新工作区代码上独立验证 `swift build`、`swift test`、bundle 启动 smoke check，均通过
- `GestureInterpreter` 已切到 classifier-based 的 `record` / `submit` 路径，`cancel` 仍然直接发送 `Esc`
- `GestureCalibrationStore` 的样本落盘、恢复和训练路径已通过测试与独立复验
- settings 界面中可见 calibration 区块，支持采样、保存和重置
- 本轮最终验收结论：pass

## 2026-04-16 — TASK_20260415_014 completed

- `TASK_20260415_014` 已把 `TASK_20260415_013` 的单用户 classifier 后端补成用户可直接操作的校准入口
- settings 里现在可以直接采集、清空、保存、重训并热加载 `record` / `submit` / `background` 样本
- 新增 `GestureCalibrationController`，把校准操作、状态流和 classifier reload 闭环收拢到一个最小控制器
- `cancel` 的 direct `Esc` 语义未改，`swift build` / `swift test` 已通过

## 2026-04-16 — Reviewer verification for TASK_20260415_014

- 重新在最新工作区代码上独立验证 `swift build`、`swift test`、bundle 启动 smoke check，均通过
- settings 的 calibration 区块与 `GestureCalibrationController` 接线完整，支持采样、清空、保存、重训和 classifier reload 闭环
- `cancel` 的 direct `Esc` 语义未改，未引入 bundle identity、permission 或 gate 逻辑的额外改动
- 本轮最终验收结论：pass

## 2026-04-16 — TASK_20260415_014 planned

- 新增 `TASK_20260415_014.md`，用于把 `TASK_20260415_013` 已完成的单用户轻量分类器后端补成用户可直接操作的校准入口
- 新任务聚焦 settings / 轻量入口里的采样、重训、重置和 classifier reload 闭环，不改变 `cancel` direct `Esc` 语义
- 本次是规划与接续更新，不涉及源码实现

## 2026-04-16 — TASK_20260415_013 completed

- `record` / `submit` 已从硬阈值规则升级为基于 Vision hand landmarks 的单用户轻量训练分类器
- 新增 `GestureCalibrationStore`、`GestureCalibrationSession` 和训练 / 持久化回归测试，启动时会加载校准过的 classifier
- `cancel` 仍然保持直接 `Esc` 语义，没有回退
- 当前结果已通过 `swift build` / `swift test` 验证，等待 reviewer 独立验收

## 2026-04-16 — TASK_20260415_013 planned

- 新增 `TASK_20260415_013.md`，用于把 `record` / `submit` 从硬阈值规则升级为基于 Vision hand landmarks 的单用户轻量训练分类器
- 任务保持 `cancel` 直发 `Esc` 语义不变，聚焦提升 `record` / `submit` 的触发率
- 本次是规划与接续更新，不涉及源码实现

## 2026-04-16 — Reviewer verification for TASK_20260415_012

- 重新在最新工作区代码上独立验证 `swift build`、`swift test`、bundle 启动 smoke check，均通过
- `GestureInterpreter` 的 `record` repeat 边界已收紧，稳定保持同一 record 姿态时不会轻易再次触发 `Fn`
- `submit` 的半卷手指误触样本已被回归测试覆盖并拒绝
- `cancel` 仍然保持直接 `Esc` 语义，没有回退
- 本轮最终验收结论：pass

## 2026-04-16 — TASK_20260415_012 stability fix completed

- `record` 的 re-arm 现在要求更明确的 release pose，稳定保持边界 record 时不会轻易再次触发
- `submit` 的手指伸展阈值已进一步收紧，半卷手指姿态不再轻易被当作提交
- 已补 record repeat 与 curled-submit 的回归测试，现有 workflow 测试继续通过

## 2026-04-16 — TASK_20260415_012 planned

- 新增 `TASK_20260415_012.md`，专门定位并修复 `record` 反复触发和 `submit` 误触这两类手势稳定性问题
- 任务要求先补失败测试，再收紧 gesture interpreter / state machine 的边界，且不回退 cancel 直发 `Esc` 语义
- 本次是规划与接续更新，不涉及源码实现

## 2026-04-16 — Reviewer verification for TASK_20260415_011

- 重新在最新工作区代码上独立验证 `swift build`、`swift test`、bundle 启动 smoke check，均通过
- 通过 System Events 打开了真实菜单栏状态项，确认当前菜单内容已拆分为 `Gesture candidate`、`Gesture pose` 和 `Recent action`，且状态项内容会跟随当前 AppState 展示
- `cancel` 现在只会发出直接 `Esc`，不再走 `stopRecordingFirst` 前置分支
- `record` / `submit` 的边界样本与 workflow 回归测试均通过
- 本轮最终验收结论：pass

## 2026-04-16 — TASK_20260415_011 runtime feedback收紧完成

- 菜单栏状态现在会在打开期间直接刷新，不再依赖关闭后重开才能看到最新值
- `Gesture` / `Action` 展示已拆成 candidate / pose / recent action，便于区分当前姿态与已触发动作
- `cancel` 已收口为直接 `Esc`，`stopRecordingFirst` 的 cancel 分支已移除
- record / submit 的姿态判定已做最小收紧，降低握拳和模糊姿态误触
- 已补菜单快照、gesture 展示、cancel 直接 Esc 与误触样本的回归测试

## 2026-04-16 — TASK_20260415_011 cancel detail corrected

- `TASK_20260415_011.md` 已补充 runtime 实现细节：cancel 不再保留 `stopRecordingFirst`，state machine / dispatcher 只产出并发送直接 `Esc`
- `TECH_IMPLEMENTATION_PLAN.md` 已同步校正 cancel 的状态机描述，明确 `recordingActive` 回收只属于内部 bookkeeping
- 本次仍是文档口径修正，不涉及源码实现

## 2026-04-16 — Cancel semantics corrected

- PRD / AGENTS / TECH_IMPLEMENTATION_PLAN 已统一把 `cancel` 的设计语义改成直接发送 `Esc`
- 原先把 cancel 写成“先停止录音，再发送 Esc”的产品语义已移除，避免后续实现继续沿用旧口径
- 本次只修设计文档，不改实现代码

## 2026-04-15 — Live permission diagnostics removed

- 临时的 live Camera / live Accessibility 展示已从 settings 页和菜单栏移除
- 现在界面只保留正式的权限状态与引导，不再把诊断值暴露给正常用户
- 这组诊断只用于排查 Accessibility trust 闭环，验证完成后已经收回

## 2026-04-15 — Reviewer verification for ISSUE_20260415_002 after reauthorization

- 用户将应用从辅助功能授权列表移除后重新添加一次
- 重新打开 VibeGesture 后，settings 页里的 `Live Accessibility trust` 已变为 `Trusted`，菜单栏里的 live AX 也同步为 `Trusted`
- 这次问题根因确认是旧的 Accessibility trust 状态需要被重建
- 现在 Camera 和 Accessibility 都已闭环到 `com.linpeiwen.vibegesture`
- 本轮最终验收结论：pass

## 2026-04-15 — Live permission diagnostics added

- settings 页和菜单栏现在直接显示 Camera 授权状态与 `AXIsProcessTrusted()` 的实时值
- 这次仅是诊断增强，不改变 Camera / Accessibility 的实际授权流程
- 便于后续复验时区分“授权入口已打开”与“app 侧仍读回 missing”

## 2026-04-15 — Reviewer verification for ISSUE_20260415_002

- 重新在最新工作区代码上独立验证 `swift build`、`swift test`、bundle 启动 smoke check 以及 ad-hoc 签名状态，均通过
- 通过 `sqlite3 ~/Library/Application Support/com.apple.TCC/TCC.db` 复验后，Camera 侧已经在 `com.linpeiwen.vibegesture` 下落库，说明 bundle identity 的签名补强确实生效
- Accessibility 设置页里已经能看到 VibeGesture 且开关处于开启状态，但 app 侧在重新激活与重新启动后仍读回 `Accessibility permission required`
- 说明授权入口已打开，但权限读取 / 刷新链路仍未闭环
- 因此本轮验收结论：fail
- 下一步最小修复方向：继续把 Accessibility 的真实授权请求或系统设置后的状态刷新补全，再重新复验

## 2026-04-15 — Reviewer verification for TASK_20260415_010

- 重新在最新工作区代码上独立验证 `swift build`、`swift test`、最小 bundle 启动检查以及 `open -gj -n .build/app-bundle/debug/VibeGesture.app`，均通过
- 通过 `plutil -p` 确认 bundle 产物包含稳定的 `com.linpeiwen.vibegesture` bundle identifier、`LSUIElement`、`Info.plist` 和 app icon 资源
- 通过 `sqlite3 ~/Library/Application Support/com.apple.TCC/TCC.db` 核对当前本机授权记录后，仍只看到 `com.apple.Terminal` 的 Camera 记录，未观察到 `com.linpeiwen.vibegesture` 的 Camera / Accessibility 授权目标
- 由于任务验收标准要求 Camera / Accessibility 授权目标显示为 VibeGesture，而这一关键点在独立验收中仍未成立，因此本轮验收结论：fail
- 下一步最小修复方向：继续补强或重跑 bundle 路径下的真实授权请求验证，直到系统权限目标能明确落到 VibeGesture 自身

## 2026-04-15 — ISSUE_20260415_002 bundle identity follow-up

- 针对 `Camera / Accessibility` 授权目标仍停留在 Terminal 的问题，已对 bundle 生成脚本补入 ad-hoc `codesign --deep` 签名与验签步骤
- 这样 bundle 现在除了 `Info.plist` / `PkgInfo` / `AppIcon.icns` 之外，也具有更完整的可识别 app identity，减少系统仍将其视作 Terminal 派生身份的风险
- `swift test` 与 bundle 启动 smoke check 已重新通过；系统设置里的授权目标是否已切换为 VibeGesture，仍需 reviewer 在真机上复验

## 2026-04-15 — Reviewer verification for ISSUE_20260415_001

- 重新在最新工作区代码上独立验证 `swift build`、`swift test`、`swift test --filter GestureRecognitionTests/testGestureInterpreterRejectsLegacyCancelLikePose` 和最小启动检查，均通过
- 对照 issue 的验收标准，`Record` / `Submit` / `Cancel` 的姿态边界回归已经覆盖，旧式 `Cancel` 启发式姿态也已被拒绝
- 验证结论：pass
- 下一步可继续按 task / issue 流程推进后续修复或新需求

## 2026-04-15 — ISSUE_20260415_001 gesture boundary fix completed

- `GestureInterpreter` 的 `Record` / `Submit` / `Cancel` 判定已切成三组姿态组合，不再沿用旧式 `Record` / `Cancel` 启发式
- 新增回归测试覆盖新 `Cancel` 开掌姿态、旧 `Cancel` 启发式姿态拒绝，以及 `Submit` 的新捏合姿态
- 已验证 `swift build`、`swift test` 和短启动检查通过
- reviewer 复验已通过
- 相关 git commit：`f502b8a` / `fix: align record and cancel pose boundaries`

## 2026-04-15 — TASK009 Record / Submit / Cancel semantic refactor completed

- 已将 gesture candidate、gesture interpreter、recognition state machine、workflow tests 和任务收口文档统一到 `Record` / `Submit` / `Cancel`
- 源码与主要测试中已移除产品语义上的 `pinch` 命名，仅保留手部姿态几何判定所需的内部实现细节
- 现有的一次性触发、cooldown、submit 延迟和 cancel 抢占语义保持不变
- 已验证 `swift build`、`swift test` 和短启动检查通过；后续 reviewer 复验结果见上方 issue 结论
- 相关 git commit：`1754892` / `TASK009: align gesture terminology to record`

## 2026-04-15 — Reviewer verification for TASK009

- 重新在最新工作区代码上独立验证 `swift build`、`swift test` 和最小启动检查，均通过
- 发现阻断性问题：`GestureInterpreter` 仍然用 `thumbTip` / `indexTip` 距离加上少量手指伸展启发式来判断 `Record` / `Cancel`，与 task 卡里要求的最新三姿态定义仍不完全一致
- 因此本轮验收结论：fail
- 下一步最小修复方向：把 `Record` / `Cancel` 的判定条件改成与设计文档一致的手部姿态组合，再补一组覆盖这两个姿态边界的回归测试

## 2026-04-15 — TASK009 planning after hand-pose design update

- 设计文档已明确三种对摄像头的手部姿态及系统操作映射：`Record` -> `Fn`，`Submit` -> `Enter`，`Cancel` -> `Esc`
- 当前源码仍保留 `pinch` 术语与旧的手势启发式判定，因此新增 TASK009 用于统一实现到最新设计
- 下一张 task card 应围绕 gesture interpreter、record / submit / cancel 姿态判定、内部候选命名和状态展示收敛展开
- 任务边界仍然是对齐现有实现，不应扩大到权限、摄像头 pipeline、前台 gating 或快捷键模型重构

## 2026-04-14 — Initial compact handoff pack

- 创建了 root 级 `PROJECT_CONTEXT.md`，作为后续 session 的单一项目接续入口
- 创建了 `docs/handoff/README.md`，作为紧凑型 handoff 索引
- 创建了 `docs/handoff/CHANGELOG.md`，作为追加式变更记录
- 创建了第一张 task card：`pm/task/TASK_20260414_001.md`，目标是先完成 App Shell 与配置骨架
- 现阶段仓库仍处于设计对齐完成、尚未开始代码实现的状态
- 已对齐的产品语义包括：`record` 单击切换录音、`submit` / `cancel` 为一次性手势、`cooldown` 期间忽略手势、前台应用基于 bundle identifier gating

## 2026-04-14 — TASK008 stabilization workflow 骨架

- 新增 `StabilizationWorkflowTests`，把 recognition、keyboard dispatch、foreground gate 和 settings persistence 串成 workflow 级回归测试
- `AppCoordinator` 现在支持注入 `ConfigurationStore` 与 `GlobalHotKeyManaging`，便于验证 runtime hotkey rebind 和配置落盘行为
- `ConfigurationStore` 现在会真正使用注入的 `FileManager`，让 hasStoredConfiguration 与目录创建行为和测试注入保持一致
- 已验证 `swift build`、`swift test` 和短启动检查通过

## 2026-04-14 — TASK001 App Shell 落地

- 新增 SwiftPM executable 形式的 macOS 菜单栏壳层，作为阶段 1 的最小可运行实现
- 新增 `AppState`、`AppConfiguration`、`ConfigurationStore`，建立识别状态与快捷键配置骨架
- 新增 `StatusItemController`、`GlobalHotKeyManager`、`SettingsWindowController`、`SettingsView`，提供菜单栏开关、全局快捷键入口和轻量设置占位
- 默认配置包含 recognition toggle、record toggle、submit、cancel 四类快捷键槽位；record toggle 暂以 `Fn` 作为占位配置语义
- 配置会在首次启动时写入 Application Support 的 `VibeGesture/config.json`
- 已验证 `swift build`、`swift test` 和短启动检查通过

## 2026-04-14 — Reviewer verification for TASK001

- 重新在最新工作区代码上独立验证 `swift build`、`swift test` 和短启动检查，均通过
- 对照 task card 的 6 条验收标准，当前实现满足阶段 1 的 App Shell 与配置骨架范围
- 验证结论：pass
- 主要保留项仍是文档中已明确说明的后续阶段能力：摄像头、Vision、手势解释、state machine、app gating 和键盘发射尚未接入

## 2026-04-14 — TASK002 planning after TASK001 completion

- 基于当前实际完成状态，下一步不再是 App Shell，而是 roadmap 第 2 阶段的权限与安全关停
- 下一张 task card 应围绕 Camera / Accessibility 权限管理、首次启动引导、识别受限状态，以及为后续录音安全关停预留接口展开
- 当前代码仍然没有摄像头、Vision、手势解释和键盘发射实现，因此下一 task 必须继续沿用现有 shell 与配置骨架，而不要引入后续阶段的完整语义

## 2026-04-14 — TASK002 权限与受限态骨架

- 新增 `PermissionState` 与 `PermissionManager`，在启动与应用重新激活时检查 Camera / Accessibility 状态
- `AppState` 与 `AppCoordinator` 已接入权限状态，缺权限时识别态会保持在 `errorPermissionMissing`
- 菜单栏和设置窗口现在会展示权限状态，设置窗口提供“Open System Settings”轻量引导按钮
- 新增 `SafeShutdownHandling` 与 `SafeShutdownReason` 协议/枚举，占位后续录音与键盘发射阶段的安全关停接口
- 已验证 `swift build`、`swift test` 和短启动检查通过

## 2026-04-14 — Reviewer verification for TASK002

- 重新在最新工作区代码上独立验证 `swift build`、`swift test` 和短启动检查，均通过
- 对照 task card 的验收标准，当前实现满足权限状态骨架、受限态展示与轻量引导的范围
- 验证结论：pass
- 保留项仍符合任务边界：摄像头、Vision、手势解释、键盘发射和真实安全关停逻辑尚未接入

## 2026-04-14 — TASK003 planning after TASK002 completion

- 基于当前实际完成状态，下一步应进入 roadmap 第 3 阶段：摄像头采集与 Vision pipeline
- 下一张 task card 应围绕默认摄像头采集、帧分发、Vision hand pose 观测输出以及采集启停骨架展开
- 当前代码已经具备权限状态与受限态处理，因此下一 task 不应继续扩权限 UI，也不应提前写手势解释或 app gating

## 2026-04-14 — TASK003 摄像头采集与 Vision pipeline 骨架

- 新增 `CameraCaptureManager`，负责默认摄像头 `AVCaptureSession` 的创建、启动与停止
- 新增 `VisionHandPoseProcessor`，把摄像头帧送入 Vision hand pose 请求并产出标准化的右手观测
- 新增 `CameraPipelineController` 与 `CameraFrameObservation` / `CameraPipelineState` 等模型，把 frame -> observation 数据流接回 `AppCoordinator`
- `AppState`、菜单栏和设置窗口现在都会展示摄像头 / pipeline 的基础状态和最新观测摘要
- 识别开启会驱动采集启动，识别关闭或权限失效会驱动采集停止
- 已验证 `swift build`、`swift test` 和短启动检查通过

## 2026-04-14 — Reviewer verification for TASK003

- 重新在最新工作区代码上独立验证 `swift build`、`swift test` 和短启动检查，均通过
- 对照 task card 的验收标准，当前实现满足默认摄像头采集骨架、Vision hand pose 观测骨架与启停接回现有 shell 的范围
- 验证结论：pass
- 保留项仍符合任务边界：gesture interpreter、record / submit / cancel 判定、完整 state machine、前台应用 gating 和键盘发射尚未接入

## 2026-04-14 — TASK004 planning after TASK003 completion

- 基于当前实际完成状态，下一步应进入 roadmap 第 4 阶段：手势解释与显式 state machine
- 下一张 task card 应围绕 gesture interpreter、record / submit / cancel 候选、cooldown / re-arm 规则与状态迁移展开
- 当前代码已经有摄像头 / Vision 观测骨架，因此下一 task 不应继续扩摄像头采集，也不应提前接键盘发射或前台 app gating

## 2026-04-14 — TASK004 gesture interpreter 与 state machine 骨架

- 新增 `GestureCandidate`、`GestureInterpretation`、`RecognitionActionIntent` 和 `RecognitionTransition` 作为共享模型
- 新增 `GestureInterpreter`，根据 `CameraFrameObservation` 提取 record / submit / cancel / re-arm 候选，并使用 6 / 4 / 4 / 3 帧阈值做 debounce
- 新增 `RecognitionStateMachine` 与 `RecognitionCoordinator`，集中管理 `disabled` / `idle` / `recording_active` / `cooldown` / `error_permission_missing` 状态与动作意图
- `AppState`、菜单栏和设置窗口现在会展示最新 gesture candidate 和 recognition action intent，方便调试
- 已验证 `swift build`、`swift test` 和短启动检查通过

## 2026-04-14 — Reviewer verification for TASK004

- 重新在最新工作区代码上独立验证 `swift build`、`swift test` 和短启动检查，均通过
- 对照 task card 的验收标准，当前实现满足 gesture candidate、显式 state machine、cooldown / re-arm 与 UI 透传的范围
- 验证结论：pass
- 保留项仍符合任务边界：keyboard dispatcher、frontmost app gating 与 overlay 尚未接入

## 2026-04-14 — TASK005 planning after TASK004 completion

- 基于当前实际完成状态，下一步应进入 roadmap 第 5 阶段：键盘事件发射与安全时序
- 下一张 task card 应围绕 keyboard dispatcher、record toggle 单键 tap、submit-after-recording-stop 的 300 ms 延迟、cancel 抢占 submit 待处理动作展开
- 当前代码已经有 gesture interpreter 和 recognition state machine，因此下一 task 不应继续扩 gesture 解释，也不应提前进入前台应用 gating

## 2026-04-14 — TASK006 前台应用 gating 与反馈骨架

- 新增 `ForegroundAppGateMonitor` 与 `ForegroundAppGatePolicy`，基于前台应用 bundle identifier 做固定白名单 gating
- `AppCoordinator`、`AppState`、菜单栏和设置窗口已接入 gate 状态展示，并在 gate 丢失时触发安全停录
- 非支持应用前台时，后续 gesture candidate 与 keyboard action intent 会被抑制
- 已验证 `swift build`、`swift test` 通过

## 2026-04-14 — ISSUE_20260414_002 gate lost pending submit fix

- 当前台应用切换为不支持时，如果当前没有录音开启但存在 pending submit，`AppCoordinator` 现在会显式取消这笔待发送动作
- 新增 `KeyboardDispatcher.cancelPendingSubmit()`，用于 gate 丢失时收束未执行的延迟 submit
- 新增回归测试覆盖 gate 丢失但未录音时的 pending submit 取消场景
- 已验证 `swift test` 和最小启动检查通过
- 相关 git commit：`13a8e0c` / `fix: cancel pending submit on gate loss`

## 2026-04-14 — TASK007 settings UI and persistence scaffold

- 设置窗口从只读状态展示升级为可编辑快捷键设置，覆盖 recognition toggle、record toggle、submit、cancel 四类配置
- `ConfigurationStore` 现在支持可测试的文件路径注入，快捷键修改会自动保存到 `config.json`
- `AppCoordinator` 会在 recognition hotkey 变更时立即重绑全局快捷键
- `SettingsView` 和 `ShortcutEditing` 现在提供轻量的 inline 捕获交互，并对 record toggle 做单键约束
- 已验证 `swift build`、`swift test` 和最小启动检查通过

## 2026-04-14 — Reviewer verification for TASK006

- 重新在最新工作区代码上独立验证 `swift build`、`swift test` 和短启动检查，均通过
- 发现一个阻断性边界问题：当前台应用切换为不支持时，如果当下没有处于录音开启状态，但 `KeyboardDispatcher` 里已经排队了 submit 的延迟 Enter，`AppCoordinator` 目前不会取消这笔待发送动作
- 因此本轮验收结论：fail
- 下一步最小修复方向：在 gate 丢失时也显式收束 `pending submit`，或让 gate 状态与 keyboard dispatcher 的待发送动作共享更明确的抑制信号

## 2026-04-14 — ISSUE_20260414_002 gate lost pending submit fix

- 当前台应用切换为不支持时，如果当前没有录音开启但 `KeyboardDispatcher` 存在 pending submit，`AppCoordinator` 现在会显式取消这笔待发送动作
- gate 丢失且正在录音时，仍沿用原有安全停录路径
- 已补回归测试覆盖 gate 丢失但未录音时的 pending submit 取消场景
- 已验证 `swift build`、`swift test` 和最小启动检查通过

## 2026-04-14 — Reviewer verification for ISSUE_20260414_002

- 重新在最新工作区代码上独立验证 `swift build`、`swift test` 和最小启动检查，均通过
- 对照 issue 的验收标准，前台应用切换为不支持时的 pending submit 漏取消边界已修正
- 验证结论：pass
- 下一步可继续按 roadmap 进入设置界面与配置持久化

## 2026-04-14 — TASK005 keyboard dispatcher 与安全时序骨架

- 新增集中式 `KeyboardDispatcher`，作为 record toggle / submit / cancel 的唯一键盘事件出口
- `RecognitionActionIntent.submit` 现在会在录音开启时先发 record toggle，再等待 300 ms 后发 submit；`cancel` 会抢占并清除 pending submit
- record toggle 默认配置从占位语义升级为真正的单键 Fn 快捷键，dispatcher 不对 Fn 做特殊分支
- `AppState`、菜单栏和设置窗口现在会展示 keyboard dispatch result，便于验证时序
- 识别停用、权限缺失、摄像头失败与终止路径都会通过安全停录逻辑收束 pending submit 或录音状态
- 已验证 `swift build`、`swift test` 和短启动检查通过

## 2026-04-14 — Reviewer verification for TASK005

- 重新在最新工作区代码上独立验证 `swift build`、`swift test` 和短启动检查，均通过
- 发现一个阻断性边界问题：当识别在 `cooldown` 期间被关闭，而该 `cooldown` 由“刚把录音切到开启”触发时，`AppCoordinator` 当前只依据 `previousRecognitionState == .recordingActive` 决定是否停录，可能漏停录
- 因此本轮验收结论：fail
- 下一步最小修复方向：把“录音是否开启”从 `RecognitionState` 中独立出来，或让 `RecognitionTransition` / `AppState` 显式携带录音开关状态，再由安全停录逻辑消费

## 2026-04-14 — ISSUE_20260414_001 cooldown safe shutdown fix

- 将录音状态从 `RecognitionState` 中显式拆出，新增 `AppState.isRecordingActive` 与 `RecognitionTransition.recordingActive`
- `RecognitionStateMachine` 现在会在 `record` / `submit` / `cancel` 路径上维护明确的录音状态，`AppCoordinator` 安全停录直接消费该状态，不再依赖 `previousRecognitionState == .recordingActive`
- `cooldown` 期间关闭识别的边界已补回归测试，`swift test` 重新通过
- 当前实现已具备再次提测的条件，等待 reviewer 再验

## 2026-04-14 — Reviewer verification for ISSUE_20260414_001

- 重新在最新工作区代码上独立验证 `swift build`、`swift test`，均通过
- 对照 issue 的验收标准，`cooldown` 期间关闭识别时的漏停录边界已修正
- 验证结论：pass
- 下一步可继续按 roadmap 进入前台应用 gating 与反馈

## 2026-04-14 — TASK006 planning after TASK005 completion

- 基于当前实际完成状态，下一步应进入 roadmap 第 6 阶段：前台应用 gating 与反馈
- 下一张 task card 应围绕前台应用 bundle id 检测、支持应用白名单、非支持应用时忽略手势、录音开启时切到不支持应用的安全停录、以及菜单栏 / 设置窗口的 gate 反馈展开
- 当前代码已经有 gesture interpreter、recognition state machine 和 keyboard dispatcher，因此下一 task 不应继续扩键盘发射，也不应提前做 overlay 的完整视觉细节

## 2026-04-14 — TASK007 planning after TASK006 completion

- 基于当前实际完成状态，下一步应进入 roadmap 第 7 阶段：设置界面与配置持久化
- 下一张 task card 应围绕可编辑的快捷键设置、配置持久化、设置窗口的轻量交互，以及重启后恢复配置展开
- 当前代码已经有 settings window scaffold 和配置存储骨架，因此下一 task 不应继续扩 app gating，也不应提前做稳定化调优

## 2026-04-14 — Reviewer verification for TASK007

- 重新在最新工作区代码上独立验证 `swift build`、`swift test` 和最小启动检查，均通过
- 对照 task 的验收标准，可编辑设置界面、四类快捷键修改、record toggle 单键约束、配置持久化、重启恢复与 recognition hotkey 运行时重绑都已满足
- 验证结论：pass
- 下一步可继续按 roadmap 进入稳定化、调优与端到端验证

## 2026-04-14 — TASK008 planning after TASK007 completion

- 基于当前实际完成状态，下一步应进入 roadmap 第 8 阶段：稳定化、调优与端到端验证
- 下一张 task card 应围绕端到端验证、阈值微调、权限 / gate 边界验证，以及回归测试展开
- 当前代码已经有完整的基础闭环，因此下一 task 不应继续增加新手势、新设置项或新的白名单范围

## 2026-04-14 — Reviewer verification for TASK008

- 重新在最新工作区代码上独立验证 `swift build`、`swift test` 和最小启动检查，均通过
- 对照 task 的验收标准，workflow 级稳定化回归测试、gate 丢失收束、录音中 gate 丢失安全停录、runtime hotkey rebind 和配置注入行为都已覆盖
- 验证结论：pass
- 下一步可继续按 roadmap 进入更进一步的稳定化观察或其他后续需求

## 2026-04-15 — Permission guidance follow-up

- 修正设置页的权限引导按钮，不再只打开系统设置首页，而是按当前缺失权限直达 `Camera` 或 `Accessibility` 的对应 Privacy & Security 页面
- 更新权限说明文案，明确告诉用户到 `System Settings > Privacy & Security` 下的具体授权位置
- 新增回归测试，覆盖缺失 Camera 与缺失 Accessibility 时的引导目标
- 已验证 `swift build` 和 `swift test` 通过

## 2026-04-15 — Permission request flow completion

- 补齐 Camera 主动授权请求：设置页按钮会优先调用 `AVCaptureDevice.requestAccess(for: .video)`，避免只打开空的 Camera 设置页
- 补齐 Accessibility 的系统信任提示：在需要时会调用 `AXIsProcessTrustedWithOptions(prompt: true)` 并在必要时回退到 Accessibility 设置页
- 将权限按钮抽象为“执行权限动作”，由 `AppCoordinator` 根据当前缺失项决定请求、提示或回退到系统设置
- 已验证 `swift build`、`swift test` 通过

## 2026-04-15 — Legacy config migration

- `ConfigurationStore.load()` 现在会自动把历史配置中缺少 `recordToggleShortcut.keyCode` 的数据归一化为默认的 `Fn` 快捷键，并写回磁盘
- 新增回归测试，确保旧格式配置不会再把 `KeyboardDispatcher` 喂成无 keyCode 的 record toggle
- 这次修复对应的直接症状是键盘层报错 `Shortcut is missing a key code`
- 已验证 `swift build`、`swift test` 通过

## 2026-04-15 — Acceptance retrospective document

- 新增验收复盘文档 [`pm/acceptance/ACCEPTANCE_20260415_001.md`](/Users/linpeiwen/knightspace/vibegesture/pm/acceptance/ACCEPTANCE_20260415_001.md)
- 文档记录了本次验收暴露的两个问题：权限引导空 Camera 页面、以及历史配置缺少 `recordToggleShortcut.keyCode`
- 文档还总结了为什么在开发和测试阶段没有提前发现，以及需要补哪些 workflow / harness 才能在开发阶段就把它们拦住

## 2026-04-15 — Acceptance semantic conclusion

- 补充确认了一条手势语义层面的验收结论：`submit` / `cancel` 的视觉手势映射在设计阶段没有被显式定义到可执行粒度，导致实现阶段对姿态语义存在自由发挥空间
- 本次“张开手掌触发 Submit”的偏差已在实现层修正，当前验收结论为 pass
- 后续 planner / 设计阶段需要先明确“手势形状 -> 系统动作”的显式映射，再交给开发实现与测试 harness 固化

## 2026-04-15 — App bundle identity follow-up

- 新增后续 task：需要把当前 SwiftPM executable 壳层收束成真正的 macOS app bundle / app identity，确保 Camera / Accessibility 权限绑定到 VibeGesture 自身而不是 Terminal
- 这不是手势、键盘或 gate 逻辑的问题，而是运行身份与系统权限归属的问题
- 后续 coder 任务应优先把 bundle identity 做稳，再继续验收权限状态

## 2026-04-15 — Minimal app bundle wrapper and icon

- 已实现最小 macOS app bundle 包装脚本，bundle 现在可以由本地脚本生成并通过 `open` 启动
- 已为 bundle 补入稳定的 `com.linpeiwen.vibegesture` identifier、`Info.plist`、`PkgInfo`、`AppIcon.icns`
- 已补一个简约白底黑图案 app icon，图标由本地脚本生成，避免引入额外依赖
- 后续 reviewer 应使用 bundle 启动路径复验 Camera / Accessibility 权限是否归属到 VibeGesture

## 2026-04-15 — Runtime feedback and gesture robustness follow-up

- 新增后续 task：需要收紧菜单栏实时刷新、gesture 展示、cancel 时序与 record / submit 误触率
- 这组问题属于运行时反馈与手势鲁棒性，不是 bundle identity 或权限归属问题
- 后续 coder 任务应优先把 `Esc` 优先 cancel、状态栏实时刷新和误触回归测试做稳
