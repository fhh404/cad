# Level Tools Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在测量工具模块中实现可用的圆形水平仪与条形水平仪页面，并用 CoreMotion 提供真实重力测量。

**Architecture:** 先抽出共享的 `LevelMotionEngine` 和 `LevelGeometry`，用测试锁住角度与气泡位置换算，再分别实现圆形与条形两个 SwiftUI 页面，最后接入目录页与首页路由。条形水平仪复用同一套重力数据，但根据当前界面方向自动切换主测量轴。

**Tech Stack:** SwiftUI, CoreMotion, XCTest, existing measurement navigation

---

### Task 1: Add Level Geometry and Motion Mapping Tests

**Files:**
- Create: `CADFP/Main/Measurement/LevelGeometry.swift`
- Test: `CADFPTests/LevelGeometryTests.swift`

- [ ] **Step 1: Write the failing tests**

覆盖：
- 圆形气泡偏移会被限制在圆盘安全半径内
- 条形水平仪角度会按界面方向切换主轴
- 角度格式化对整数和小数值都稳定

- [ ] **Step 2: Run test build and verify it fails**

Run: `xcodebuild build-for-testing -project CADFP.xcodeproj -scheme CADFP -destination 'generic/platform=iOS' -only-testing:CADFPTests/LevelGeometryTests`

Expected: FAIL because `LevelGeometry` and tests do not exist yet.

- [ ] **Step 3: Implement minimal geometry helpers**

实现：
- 圆形气泡二维偏移计算
- 条形角度与位置换算
- 角度格式化

- [ ] **Step 4: Re-run the test build and verify it passes**

Run: `xcodebuild build-for-testing -project CADFP.xcodeproj -scheme CADFP -destination 'generic/platform=iOS' -only-testing:CADFPTests/LevelGeometryTests`

Expected: `TEST BUILD SUCCEEDED`.

### Task 2: Build Shared Motion Engine

**Files:**
- Create: `CADFP/Main/Measurement/LevelMotionEngine.swift`

- [ ] **Step 1: Add a focused engine API**

定义：
- 最新滤波重力值
- 传感器是否可用
- `start()` / `stop()`
- 当前条形水平仪主轴角度

- [ ] **Step 2: Implement minimal CoreMotion integration**

使用 `CMMotionManager.deviceMotionUpdateInterval` 和 `gravity`，加轻量低通滤波，避免页面抖动。

- [ ] **Step 3: Keep lifecycle simple**

页面出现启动，页面消失停止；不要把持续运行的运动传感器挂在全局单例上。

### Task 3: Implement Circular Level Screen

**Files:**
- Create: `CADFP/Main/Measurement/CircularLevelScreen.swift`

- [ ] **Step 1: Build the Figma-aligned static shell**

实现：
- 白底
- 右上关闭按钮
- 大号蓝色圆盘
- 十字分隔线

- [ ] **Step 2: Bind the motion engine to the bubble**

让气泡根据 `LevelGeometry` 的二维偏移实时移动，并保持在圆盘安全区域内。

- [ ] **Step 3: Add unavailable fallback**

传感器不可用时显示友好提示，避免页面空白。

### Task 4: Implement Bar Level Screen

**Files:**
- Create: `CADFP/Main/Measurement/BarLevelScreen.swift`

- [ ] **Step 1: Build the Figma-aligned static shell**

实现：
- 白底
- 中央大号角度文本
- 右上关闭按钮

- [ ] **Step 2: Add the minimal horizontal bar instrument**

补充一条克制的水平条和气泡，用来表达实时偏移，不破坏 Figma 的极简布局。

- [ ] **Step 3: Wire automatic axis switching**

根据当前界面方向自动切换条形水平仪主测量轴，并同步更新读数和气泡位置。

### Task 5: Wire Routes Into the Measurement Module

**Files:**
- Modify: `CADFP/ContentView.swift`
- Modify: `CADFP/Main/Measurement/MeasurementCatalogScreen.swift`
- Modify: `CADFP/Main/Measurement/MeasurementModels.swift`

- [ ] **Step 1: Add new home routes**

新增：
- `measurementCircularLevel`
- `measurementBarLevel`

- [ ] **Step 2: Replace catalog placeholders**

将 `圆形水平仪` 与 `条形水平仪` 从 alert 占位改成真实跳转。

- [ ] **Step 3: Keep existing ruler and protractor behavior intact**

不要破坏已经修好的 tabBar 隐藏与统一导航栈行为。

### Task 6: Final Verification

**Files:**
- Modify as needed based on verification failures

- [ ] **Step 1: Run level-focused test build**

Run: `xcodebuild build-for-testing -project CADFP.xcodeproj -scheme CADFP -destination 'generic/platform=iOS' -only-testing:CADFPTests/LevelGeometryTests`

Expected: `TEST BUILD SUCCEEDED`.

- [ ] **Step 2: Run full app build**

Run: `xcodebuild build -project CADFP.xcodeproj -scheme CADFP -destination 'id=00008120-0000794A3EE2201E'`

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 3: Manual device verification**

确认：
- 圆形气泡会随设备倾斜移动
- 条形页在横竖屏切换后仍能正确测量
- 两页返回路径正确，tabBar 隐藏正确
