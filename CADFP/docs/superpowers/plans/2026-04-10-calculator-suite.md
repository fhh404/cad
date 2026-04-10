# Calculator Suite Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在现有 SwiftUI 工程中补齐从首页进入的计算器模块，并实现 8 个几何计算工具的 Figma 对齐 UI 与可用公式逻辑。

**Architecture:** 入口导航仍由 `ContentView` 管理，新增独立 `Calculator` 模块承接目录页与详情页。公式与字段配置提取为纯 Swift 逻辑，先通过 `XCTest` 以 TDD 方式锁定行为，再让 SwiftUI 页面消费这些定义，减少 8 张页面的重复代码。

**Tech Stack:** SwiftUI, XCTest, Xcode project navigation, asset catalogs

---

### Task 1: Add Calculator Domain Models and Formula Tests

**Files:**
- Create: `CADFP/Main/Calculator/CalculatorModels.swift`
- Create: `CADFP/Main/Calculator/CalculatorEngine.swift`
- Create: `CADFP/Main/Calculator/CalculatorFormatting.swift`
- Test: `CADFPTests/CalculatorEngineTests.swift`

- [ ] **Step 1: Write the failing tests for all supported formulas**

Create `CADFPTests/CalculatorEngineTests.swift` with focused cases for:
- cylinder total area and volume
- sphere surface area and volume from diameter
- cube area and volume
- cone slant height, lateral area, total area, and volume
- triangle area
- rectangle area and perimeter
- circle area and circumference from radius
- trapezoid area
- invalid or missing inputs returning a validation error

- [ ] **Step 2: Run the new test target and verify it fails**

Run: `xcodebuild test -project CADFP.xcodeproj -scheme CADFP -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:CADFPTests/CalculatorEngineTests`

Expected: FAIL because calculator types and engine do not exist yet.

- [ ] **Step 3: Implement the minimal calculator models and engine**

Add:
- `CalculatorKind` for the 8 tools
- `CalculatorInputFieldDefinition`
- `CalculatorResultDefinition`
- `CalculatorComputationError`
- `CalculatorEngine.compute(kind:inputs:)`
- `CalculatorFormatting` for result strings

- [ ] **Step 4: Re-run the formula tests and verify they pass**

Run: `xcodebuild test -project CADFP.xcodeproj -scheme CADFP -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:CADFPTests/CalculatorEngineTests`

Expected: PASS for `CalculatorEngineTests`.

- [ ] **Step 5: Refactor names and formatting while keeping tests green**

Keep model names aligned with UI copy and reuse a shared number formatter for all result rows.

### Task 2: Build the Calculator Catalog Screen From Figma

**Files:**
- Create: `CADFP/Main/Calculator/CalculatorCatalogScreen.swift`
- Modify: `CADFP/Main/HomeView.swift`

- [ ] **Step 1: Write the first failing UI-oriented testable guard**

If no UI test target exists, use a preview/build guard instead of inventing a brittle UI test:
- confirm `HomeAction.calculator` is already available in `HomeView`
- treat the first executable guard as compile verification after the screen is introduced

- [ ] **Step 2: Implement the calculator catalog screen**

Create a SwiftUI screen that matches node `75:195`:
- light gray background
- centered title `计算器`
- 2-column grid with 8 rounded white cards
- icon + title for each calculator kind

- [ ] **Step 3: Map Figma assets to calculator kinds**

Use the existing asset names from `CADFP/Assets.xcassets/CAD看图_icon-3/`:
- `Group 353`
- `Group 352`
- `Group 351`
- `Group 349`
- `Group 350`
- `Group 344`
- `Group 347`
- `Group 345`

- [ ] **Step 4: Add navigation from the catalog to each detail screen**

Selecting a card should push the matching `CalculatorDetailScreen`.

- [ ] **Step 5: Run a build verification**

Run: `xcodebuild build -project CADFP.xcodeproj -scheme CADFP -destination 'platform=iOS Simulator,name=iPhone 16'`

Expected: compile succeeds with the new catalog screen wired in isolation.

### Task 3: Build the Shared Calculator Detail Screen

**Files:**
- Create: `CADFP/Main/Calculator/CalculatorDetailScreen.swift`
- Create: `CADFP/Main/Calculator/CalculatorTheme.swift`

- [ ] **Step 1: Write the first failing behavior test for invalid input**

Add a test in `CADFPTests/CalculatorEngineTests.swift` asserting non-positive or missing values return a validation error message suitable for the UI.

- [ ] **Step 2: Run the test to verify it fails for the new validation rule**

Run: `xcodebuild test -project CADFP.xcodeproj -scheme CADFP -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:CADFPTests/CalculatorEngineTests`

Expected: FAIL until the validation path is implemented.

- [ ] **Step 3: Implement the shared detail screen**

Create a reusable screen that renders per-kind configuration:
- top title
- large white icon card
- one to three labeled inputs
- blue `开始计算` button
- result card with one to four output rows

- [ ] **Step 4: Connect the detail screen to the calculator engine**

On tap:
- parse current input strings
- validate values
- compute results
- update the result card
- show a friendly alert for invalid input

- [ ] **Step 5: Re-run the test target and verify it passes**

Run: `xcodebuild test -project CADFP.xcodeproj -scheme CADFP -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:CADFPTests/CalculatorEngineTests`

Expected: PASS with validation coverage included.

### Task 4: Wire Home Navigation Into the App Flow

**Files:**
- Modify: `CADFP/ContentView.swift`

- [ ] **Step 1: Replace the calculator placeholder route**

Update `ContentView` so `HomeAction.calculator` pushes the new `CalculatorCatalogScreen` instead of setting `pendingAction`.

- [ ] **Step 2: Preserve existing routes**

Keep:
- `最近文件` -> `CADViewerScreen`
- `水印相机` -> `WatermarkCameraScreen`
- other actions -> existing placeholder alert behavior

- [ ] **Step 3: Run a full build verification**

Run: `xcodebuild build -project CADFP.xcodeproj -scheme CADFP -destination 'platform=iOS Simulator,name=iPhone 16'`

Expected: compile succeeds with the new home navigation path.

### Task 5: Final Verification and Cleanup

**Files:**
- Modify as needed based on verification failures

- [ ] **Step 1: Run the calculator-focused test suite**

Run: `xcodebuild test -project CADFP.xcodeproj -scheme CADFP -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:CADFPTests/CalculatorEngineTests`

Expected: PASS.

- [ ] **Step 2: Run a full app build**

Run: `xcodebuild build -project CADFP.xcodeproj -scheme CADFP -destination 'platform=iOS Simulator,name=iPhone 16'`

Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Compare UI against the Figma screenshots**

Visually verify:
- catalog spacing, corner radius, card layout
- detail page input block spacing
- button color and corner radius
- result card spacing and typography hierarchy

- [ ] **Step 4: Summarize any intentional deviations**

If keyboard avoidance, font fallback, or simulator-only rendering differ slightly from Figma, document the reason in the final handoff.
