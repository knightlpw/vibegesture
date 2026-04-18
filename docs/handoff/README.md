# Handoff Pack

这个目录是给后续 session / agent 用的紧凑型接续包。
它的目标是让新的 agent 在几分钟内知道：
- 项目是什么
- 当前做到哪一步
- 下一步应该先做什么
- 哪些文档是源头

## 读取顺序

1. [`PROJECT_CONTEXT.md`](/Users/linpeiwen/knightspace/vibegesture/PROJECT_CONTEXT.md)
2. [`docs/ROADMAP.md`](/Users/linpeiwen/knightspace/vibegesture/docs/ROADMAP.md)
3. [`docs/PRD.md`](/Users/linpeiwen/knightspace/vibegesture/docs/PRD.md)
4. [`docs/AGENTS.md`](/Users/linpeiwen/knightspace/vibegesture/docs/AGENTS.md)
5. [`docs/TECH_ARCHITECTURE.md`](/Users/linpeiwen/knightspace/vibegesture/docs/TECH_ARCHITECTURE.md)
6. [`docs/TECH_IMPLEMENTATION_PLAN.md`](/Users/linpeiwen/knightspace/vibegesture/docs/TECH_IMPLEMENTATION_PLAN.md)
7. [`pm/task/TASK_20260414_001.md`](/Users/linpeiwen/knightspace/vibegesture/pm/task/TASK_20260414_001.md)
8. [`pm/task/TASK_20260414_002.md`](/Users/linpeiwen/knightspace/vibegesture/pm/task/TASK_20260414_002.md)
9. [`pm/task/TASK_20260414_003.md`](/Users/linpeiwen/knightspace/vibegesture/pm/task/TASK_20260414_003.md)
10. [`pm/task/TASK_20260414_004.md`](/Users/linpeiwen/knightspace/vibegesture/pm/task/TASK_20260414_004.md)
11. [`pm/task/TASK_20260414_005.md`](/Users/linpeiwen/knightspace/vibegesture/pm/task/TASK_20260414_005.md)
12. [`pm/task/TASK_20260414_006.md`](/Users/linpeiwen/knightspace/vibegesture/pm/task/TASK_20260414_006.md)
13. [`pm/task/TASK_20260414_007.md`](/Users/linpeiwen/knightspace/vibegesture/pm/task/TASK_20260414_007.md)
14. [`pm/task/TASK_20260414_008.md`](/Users/linpeiwen/knightspace/vibegesture/pm/task/TASK_20260414_008.md)
15. [`pm/task/TASK_20260415_009.md`](/Users/linpeiwen/knightspace/vibegesture/pm/task/TASK_20260415_009.md)
16. [`pm/task/TASK_20260415_010.md`](/Users/linpeiwen/knightspace/vibegesture/pm/task/TASK_20260415_010.md)
17. [`pm/task/TASK_20260415_011.md`](/Users/linpeiwen/knightspace/vibegesture/pm/task/TASK_20260415_011.md)
18. [`pm/task/TASK_20260415_012.md`](/Users/linpeiwen/knightspace/vibegesture/pm/task/TASK_20260415_012.md)
19. [`pm/task/TASK_20260415_013.md`](/Users/linpeiwen/knightspace/vibegesture/pm/task/TASK_20260415_013.md)
20. [`pm/task/TASK_20260415_014.md`](/Users/linpeiwen/knightspace/vibegesture/pm/task/TASK_20260415_014.md)
21. [`pm/task/TASK_20260415_015.md`](/Users/linpeiwen/knightspace/vibegesture/pm/task/TASK_20260415_015.md)
22. [`pm/task/TASK_20260418_016.md`](/Users/linpeiwen/knightspace/vibegesture/pm/task/TASK_20260418_016.md)
23. [`pm/task/TASK_20260418_019.md`](/Users/linpeiwen/knightspace/vibegesture/pm/task/TASK_20260418_019.md)

## 说明

- 这个 handoff pack 是刻意做得很紧凑的
- `PROJECT_CONTEXT.md` 是当前状态的唯一入口
- `CHANGELOG.md` 只记录有意义的增量变化，不重复写状态总结
- 如果后续项目开始出现源码实现，优先更新 `PROJECT_CONTEXT.md`，再补 `CHANGELOG.md`
- 现在的源码入口是 SwiftPM + `Sources/VibeGesture/*`，不是 Xcode 工程
- 当前 roadmap 主阶段已完成，`TASK009` 已完成并通过 reviewer 复验，`TASK010` 的最小 app bundle / app identity、简约 app icon 与 ad-hoc 签名已完成但仍需继续盯权限归属表现，`TASK011` 的 runtime feedback / gesture robustness 收紧已通过 reviewer 复验，`TASK012` 的 record 重复触发和 submit 误触收紧也已通过 reviewer 复验，`TASK013` 已完成并通过 reviewer 复验，`TASK014` 已完成并通过 reviewer 复验，`TASK015` 已完成并通过 reviewer 复验，`TASK016` 已完成并通过 reviewer 复验，`TASK017` 已完成并通过 reviewer 复验，`TASK018` 已完成并等待 reviewer 复验，`TASK019` 已完成并把菜单栏与 settings 的诊断信息收进折叠 / 子菜单区域，`cancel` 校准样本和 self-frontmost 采样闭环已纳入当前阶段状态
- 这一阶段后续 agent 先看 `AppCoordinator.swift`、`AppState.swift`、`PermissionState.swift`、`PermissionManager.swift`、`StatusItemController.swift`、`GlobalHotKeyManager.swift`、`SettingsWindowController.swift`、`SettingsView.swift`、`GestureCalibrationController.swift`、`CameraObservation.swift`、`CameraCaptureManager.swift`、`VisionHandPoseProcessor.swift`、`CameraPipelineController.swift`、`GestureRecognitionModels.swift`、`GestureInterpreter.swift`、`RecognitionStateMachine.swift`、`RecognitionCoordinator.swift` 和 `KeyboardDispatcher.swift`
- 如果在 stage 7 之后继续往前推进，还应优先看 `ShortcutEditing.swift`
- 如果在 stage 6 之后继续往前推进，还应优先看 `ForegroundAppGate.swift`
- 如果在 stage 8 之后继续复盘稳定化结果，还应优先看 `Tests/VibeGestureTests/StabilizationWorkflowTests.swift`
