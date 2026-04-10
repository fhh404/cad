# Measurement Tools Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在现有 SwiftUI 工程中补齐从首页进入的测量工具模块，并实现与 Figma 对齐的目录页和一套在真实 iPhone 上可用的物理尺寸直尺。

**Architecture:** 首页导航继续由 `ContentView` 统一维护，新增独立 `Measurement` 模块承接目录页与直尺页。真实厘米换算、机型识别和拖拽几何逻辑提取为纯 Swift 类型并先通过 `XCTest` 锁定行为，再让 SwiftUI 页面消费这些结果，降低 UI 与物理换算耦合。

**Tech Stack:** SwiftUI, XCTest, UIKit screen APIs, `utsname` device identification, Xcode project navigation

---

### Task 1: Add Measurement Domain Models and Physical Ruler Tests

**Files:**
- Create: `CADFP/Main/Measurement/MeasurementModels.swift`
- Create: `CADFP/Main/Measurement/RulerDeviceRegistry.swift`
- Create: `CADFP/Main/Measurement/RulerGeometry.swift`
- Test: `CADFPTests/RulerGeometryTests.swift`

- [ ] **Step 1: Write the failing tests for physical ruler math**

Create `CADFPTests/RulerGeometryTests.swift` with focused cases for:
- points-per-centimeter conversion from `ppi` and `nativeScale`
- distance in points to centimeters conversion
- formatting readout values to `CM`
- viewport shifting when a handle is dragged beyond the visible threshold

- [ ] **Step 2: Run the new test target and verify it fails**

Run: `xcodebuild test -project CADFP.xcodeproj -scheme CADFP -destination 'id=00008120-0000794A3EE2201E' -only-testing:CADFPTests/RulerGeometryTests`

Expected: FAIL because the measurement types and ruler geometry do not exist yet.

- [ ] **Step 3: Implement the minimal measurement models and ruler math**

Add:
- `MeasurementToolKind`
- `RulerDisplayProfile`
- `RulerViewportState`
- `RulerDeviceRegistry`
- `RulerGeometry`

- [ ] **Step 4: Re-run the ruler tests and verify they pass**

Run: `xcodebuild test -project CADFP.xcodeproj -scheme CADFP -destination 'id=00008120-0000794A3EE2201E' -only-testing:CADFPTests/RulerGeometryTests`

Expected: PASS for `RulerGeometryTests`.

- [ ] **Step 5: Refactor profile names and constants while keeping tests green**

Keep PPI tables and drag thresholds readable and colocated with the ruler domain code.

### Task 2: Build the Measurement Catalog Screen From Figma

**Files:**
- Create: `CADFP/Main/Measurement/MeasurementCatalogScreen.swift`

- [ ] **Step 1: Establish the first executable guard**

Use compile verification instead of inventing a brittle UI test:
- confirm `MeasurementToolKind` covers the 4 catalog cards
- treat the first executable guard as build verification after the screen is introduced

- [ ] **Step 2: Implement the measurement catalog screen**

Create a SwiftUI screen that matches node `106:497`:
- centered title `测量工具`
- 2-column grid with 4 rounded white cards
- icon + title for each tool
- hidden navigation bar and tab bar

- [ ] **Step 3: Map Figma assets to measurement tools**

Use the existing asset names from `CADFP/Assets.xcassets/CAD看图_icon-4/`:
- `水平仪 1`
- `Group 355`
- `直尺 1`
- `测量角度 1`

- [ ] **Step 4: Add card behavior**

- `直尺` pushes the new `RulerScreen`
- other cards surface a friendly “功能开发中” alert

- [ ] **Step 5: Run a build verification**

Run: `xcodebuild build -project CADFP.xcodeproj -scheme CADFP -destination 'id=00008120-0000794A3EE2201E'`

Expected: compile succeeds with the new catalog screen added.

### Task 3: Build the True-Size Ruler Screen

**Files:**
- Create: `CADFP/Main/Measurement/RulerScreen.swift`

- [ ] **Step 1: Write the next failing behavior tests**

Add test coverage in `CADFPTests/RulerGeometryTests.swift` for:
- minimum handle separation enforcement
- live measurement updates during drag
- continuous viewport shifting for long-distance drag

- [ ] **Step 2: Run the test target and verify it fails**

Run: `xcodebuild test -project CADFP.xcodeproj -scheme CADFP -destination 'id=00008120-0000794A3EE2201E' -only-testing:CADFPTests/RulerGeometryTests`

Expected: FAIL until the drag-state helpers exist.

- [ ] **Step 3: Implement the ruler screen**

Create a SwiftUI full-screen page that matches node `107:537`:
- white background
- left gray ruler strip with dynamically drawn centimeter / millimeter ticks
- blue translucent measurement area
- two blue drag handles
- centered measurement text
- top-right close button

- [ ] **Step 4: Connect the ruler screen to physical sizing**

On appear:
- resolve the current device profile
- compute `pointsPerCentimeter`
- seed the initial measurement to about `4.7CM`
- update the visible ruler and readout as handles move
- show a friendly fallback message if the device profile is unavailable

- [ ] **Step 5: Re-run the ruler tests and verify they pass**

Run: `xcodebuild test -project CADFP.xcodeproj -scheme CADFP -destination 'id=00008120-0000794A3EE2201E' -only-testing:CADFPTests/RulerGeometryTests`

Expected: PASS with drag and conversion coverage included.

### Task 4: Wire Measurement Navigation Into the App Flow

**Files:**
- Modify: `CADFP/ContentView.swift`

- [ ] **Step 1: Add measurement routes to the home navigation stack**

Introduce route cases for:
- `measurementCatalog`
- `measurementRuler`

- [ ] **Step 2: Replace the measurement placeholder route**

Update `ContentView` so `HomeAction.measurementTools` pushes `MeasurementCatalogScreen` instead of showing the generic placeholder alert.

- [ ] **Step 3: Preserve existing routes**

Keep:
- `最近文件` -> `CADViewerScreen`
- `计算器` -> calculator module
- `水印相机` -> `WatermarkCameraScreen`
- other actions -> existing placeholder alert behavior

- [ ] **Step 4: Run a full build verification**

Run: `xcodebuild build -project CADFP.xcodeproj -scheme CADFP -destination 'id=00008120-0000794A3EE2201E'`

Expected: compile succeeds with the new measurement navigation path.

### Task 5: Final Verification and Cleanup

**Files:**
- Modify as needed based on verification failures

- [ ] **Step 1: Run the ruler-focused test suites**

Run: `xcodebuild test -project CADFP.xcodeproj -scheme CADFP -destination 'id=00008120-0000794A3EE2201E' -only-testing:CADFPTests/RulerGeometryTests -only-testing:CADFPTests/CalculatorEngineTests`

Expected: PASS.

- [ ] **Step 2: Run a full app build on the connected iPhone**

Run: `xcodebuild build -project CADFP.xcodeproj -scheme CADFP -destination 'id=00008120-0000794A3EE2201E'`

Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Compare UI against the Figma screenshots**

Visually verify:
- catalog spacing, card size, icon placement, title alignment
- ruler strip width and background tone
- blue measurement area position and opacity
- handle placement, readout typography, close button position

- [ ] **Step 4: Summarize any intentional deviations**

If unsupported devices need a fallback prompt or the continuous ruler uses a virtual viewport instead of a real infinite scroll, document the reason in the final handoff.
