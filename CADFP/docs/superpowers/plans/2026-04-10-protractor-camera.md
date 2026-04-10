# Camera Protractor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在测量工具模块中补齐基于相机预览的手动量角器页面，使用户可以拖动两条测量边实时读取夹角。

**Architecture:** 复用现有水印相机里的 `CameraCaptureService` 与 `CameraPreviewView` 提供预览，把量角器交互拆成独立的几何层与展示层。目录页路由、相机权限处理、量角器绘制和角度计算分别落在独立文件中，避免把测量逻辑塞进视图代码里。

**Tech Stack:** SwiftUI, XCTest, AVFoundation, existing camera preview service, geometry helpers

---

### Task 1: Add Protractor Geometry and Tests

**Files:**
- Create: `CADFP/Main/Measurement/ProtractorGeometry.swift`
- Test: `CADFPTests/ProtractorGeometryTests.swift`

- [ ] **Step 1: Write the failing tests for angle normalization and readout**

Create tests for:
- acute / obtuse angle calculation from two ray angles
- normalization across `0` and `180`
- readout formatting such as `70.7°`
- drag updates clamped into the supported semicircle range

- [ ] **Step 2: Run the new test target and verify it fails**

Run: `xcodebuild test -project CADFP.xcodeproj -scheme CADFP -destination 'id=00008120-0000794A3EE2201E' -only-testing:CADFPTests/ProtractorGeometryTests`

Expected: FAIL because the protractor geometry types do not exist yet.

- [ ] **Step 3: Implement the minimal geometry helpers**

Add:
- `ProtractorHandle`
- `ProtractorMeasurementState`
- `ProtractorGeometry`

- [ ] **Step 4: Re-run the geometry tests and verify they pass**

Run: `xcodebuild test -project CADFP.xcodeproj -scheme CADFP -destination 'id=00008120-0000794A3EE2201E' -only-testing:CADFPTests/ProtractorGeometryTests`

Expected: PASS for `ProtractorGeometryTests`.

### Task 2: Build the Protractor Screen

**Files:**
- Create: `CADFP/Main/Measurement/ProtractorScreen.swift`
- Modify: `CADFP/Main/WatermarkCamera/WatermarkCameraCapture.swift`

- [ ] **Step 1: Establish the reusable camera preview contract**

Confirm that `CameraCaptureService` and `CameraPreviewView` can be reused by another screen without watermark-specific dependencies.

- [ ] **Step 2: Implement a lightweight protractor view model or local state container**

Add state for:
- camera service lifecycle
- current measurement state
- active drag handle
- permission / unavailable messages

- [ ] **Step 3: Implement the full-screen protractor page**

Create a SwiftUI screen with:
- full-screen camera preview
- right-top close button
- semicircle protractor overlay
- center pivot point
- two draggable measurement rays
- right-bottom angle readout

- [ ] **Step 4: Match the Figma visual structure**

Ensure the screen keeps:
- dark translucent protractor strokes over the preview
- readout placement near the lower-right corner
- circular close button style aligned with the screenshot

- [ ] **Step 5: Validate build after adding the new screen**

Run: `xcodebuild build -project CADFP.xcodeproj -scheme CADFP -destination 'id=00008120-0000794A3EE2201E'`

Expected: compile succeeds with the new screen and reused camera preview.

### Task 3: Wire Protractor Into Measurement Navigation

**Files:**
- Modify: `CADFP/ContentView.swift`
- Modify: `CADFP/Main/Measurement/MeasurementModels.swift`
- Modify: `CADFP/Main/Measurement/MeasurementCatalogScreen.swift`

- [ ] **Step 1: Add the new route**

Introduce `HomeRoute.measurementProtractor`.

- [ ] **Step 2: Mark the protractor tool as implemented**

Update `MeasurementToolKind` so `量角器` participates in real navigation instead of placeholder alert behavior.

- [ ] **Step 3: Update the catalog card behavior**

Make `量角器` push `ProtractorScreen`, while preserving:
- `直尺` -> `RulerScreen`
- 其他未完成工具 -> placeholder alert

- [ ] **Step 4: Verify the route compiles cleanly**

Run: `xcodebuild build -project CADFP.xcodeproj -scheme CADFP -destination 'id=00008120-0000794A3EE2201E'`

Expected: BUILD SUCCEEDED.

### Task 4: Polish Permissions and Interaction Boundaries

**Files:**
- Modify: `CADFP/Main/Measurement/ProtractorScreen.swift`

- [ ] **Step 1: Handle camera permission and unavailable states**

Surface friendly messaging for:
- denied permission
- restricted permission
- unavailable camera

- [ ] **Step 2: Protect top-level interactions**

Ensure:
- close button remains tappable
- dragging rays does not accidentally dismiss or drag the whole screen
- overlay gestures only affect the selected measurement ray

- [ ] **Step 3: Clamp unstable drag input**

Prevent:
- angle jumps when crossing the semicircle boundary
- rays rotating outside the supported overlay arc

- [ ] **Step 4: Run geometry and existing measurement tests together**

Run: `xcodebuild test -project CADFP.xcodeproj -scheme CADFP -destination 'id=00008120-0000794A3EE2201E' -only-testing:CADFPTests/ProtractorGeometryTests -only-testing:CADFPTests/RulerGeometryTests -only-testing:CADFPTests/CalculatorEngineTests`

Expected: PASS, unless the device is locked or unavailable.

### Task 5: Final Verification

**Files:**
- Modify as needed based on verification findings

- [ ] **Step 1: Run a final device build**

Run: `xcodebuild build -project CADFP.xcodeproj -scheme CADFP -destination 'id=00008120-0000794A3EE2201E'`

Expected: BUILD SUCCEEDED.

- [ ] **Step 2: Manual UI verification against Figma**

Check:
- page opens from measurement catalog
- camera preview fills the screen
- protractor overlay placement matches the screenshot closely
- rays drag smoothly
- readout updates continuously
- close button returns to the measurement catalog

- [ ] **Step 3: Summarize intentional deviations**

Document the one intentional difference:
- adding interactive rays and center-point affordances so the static Figma composition becomes a usable measurement tool
