# DEV_REPORT_TASK_20260418_019

## 任务
- Task：TASK_20260418_019
- 本轮目标：收敛菜单栏与 settings 中的调试 / 诊断信息，让一般用户默认只看到简洁、易理解、能操作的界面；本轮不改底层识别、状态机、键盘、gate、权限或摄像头逻辑。

## 完成内容
- 菜单栏顶层已收敛为最小状态摘要，只保留 `State`、`Recording`、`Gate`、`Permissions`、Recognition toggle、`Diagnostics`、`Settings…` 和 `Quit`。
- 菜单栏中的 `Gesture candidate`、`Gesture pose`、`Recent action`、`Keyboard`、`Runtime`、`Camera` 等诊断信息已移入 `Diagnostics` 子菜单，默认不打扰普通用户。
- settings 页面默认只保留权限、快捷键和校准入口；recognition / pipeline / gate / calibration diagnostics 已收进默认折叠区。
- settings 中原本可见的样本统计、saved / working samples、calibration source 等诊断字段已移入折叠诊断区。
- 保留了原有诊断信息与排障能力，只是改变了默认展示层级，没有改动识别、状态机、键盘、gate、权限或摄像头逻辑。

## 修改文件
- [`Sources/VibeGesture/StatusItemController.swift`](/Users/linpeiwen/knightspace/vibegesture/Sources/VibeGesture/StatusItemController.swift)
- [`Sources/VibeGesture/SettingsView.swift`](/Users/linpeiwen/knightspace/vibegesture/Sources/VibeGesture/SettingsView.swift)
- [`Tests/VibeGestureTests/StatusItemControllerTests.swift`](/Users/linpeiwen/knightspace/vibegesture/Tests/VibeGestureTests/StatusItemControllerTests.swift)
- [`docs/ROADMAP.md`](/Users/linpeiwen/knightspace/vibegesture/docs/ROADMAP.md)
- [`PROJECT_CONTEXT.md`](/Users/linpeiwen/knightspace/vibegesture/PROJECT_CONTEXT.md)
- [`docs/handoff/README.md`](/Users/linpeiwen/knightspace/vibegesture/docs/handoff/README.md)
- [`docs/handoff/CHANGELOG.md`](/Users/linpeiwen/knightspace/vibegesture/docs/handoff/CHANGELOG.md)
- [`pm/task/TASK_20260418_019.md`](/Users/linpeiwen/knightspace/vibegesture/pm/task/TASK_20260418_019.md)

## 未完成 / 未处理
- 未做真实手动菜单栏 / settings 视觉截图验收。

## 自测情况
- 已验证：`swift build` 通过。
- 已验证：`swift test` 通过，`StatusItemControllerTests` 已更新并通过。
- 未验证：真实系统界面上的视觉观感与点击路径。

## 风险 / 说明
- 这轮仅调整默认可见层级，没有删掉诊断信息本身；如果后续 reviewer 觉得 Diagnostics 子菜单或折叠区仍然偏多，再根据反馈继续收紧。
- 由于没有做真实视觉验收，提测更适合标记为有条件提测。

## 提测结论
- 有条件提测

## 提交
- git提交和信息：`61c52fe` - `TASK019: simplify visible diagnostics`
