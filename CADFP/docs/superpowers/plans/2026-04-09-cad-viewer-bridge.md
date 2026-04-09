# CAD Viewer Bridge Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在新项目中完成一张按 Figma 重做的 CAD 查看页，并接通旧 CAD 内核的首批可用功能。

**Architecture:** SwiftUI 负责页面外壳与交互状态，Objective-C++ bridge 负责连接旧 CAD 内核。首页仅负责跳转到新的 viewer 页面，CAD 能力首版以 `Sample.dwg` 自动打开为主。

**Tech Stack:** SwiftUI, UIKit, Objective-C++, C++, ODA static libs, xcodeproj

---

### Task 1: Add Planning Artifacts

**Files:**
- Create: `docs/superpowers/specs/2026-04-09-cad-viewer-bridge-design.md`
- Create: `docs/superpowers/plans/2026-04-09-cad-viewer-bridge.md`

- [ ] **Step 1: Save the approved design**

Write the approved design into the spec document.

- [ ] **Step 2: Save the execution plan**

Write this plan document into the repo.

- [ ] **Step 3: Self-review for consistency**

Check that the spec and plan agree on scope:
- `Sample.dwg`
- `图层 / 批注 / 隐藏批注 / 文字提取`
- `测量` 仅占位

### Task 2: Introduce a Bridge-Friendly CAD Module

**Files:**
- Create: `CADFP/CADBridge/`
- Create or copy: `CADFP/CADBridge/AppCore/...`
- Create: `CADFP/CADBridge/CADBaseViewController.h`
- Create: `CADFP/CADBridge/CADBaseViewController.mm`
- Create: `CADFP/CADBridge/RenderViewController.h`
- Create: `CADFP/CADBridge/RenderViewController.mm`
- Create: `CADFP/CADBridge/CADViewerBridgeController.h`
- Create: `CADFP/CADBridge/CADViewerBridgeController.mm`

- [ ] **Step 1: Copy the required AppCore sources**

Bring the minimum `AppCore` set into the new repo.

- [ ] **Step 2: Create a minimal host controller**

Implement a new `CADBaseViewController` compatible host with:
- `TviCore`
- open file lifecycle
- pan / pinch / tap handling for markups
- no legacy business UI

- [ ] **Step 3: Create the rendering controller**

Wire the rendering controller to the new host controller.

- [ ] **Step 4: Add bridge-facing APIs**

Expose methods for:
- load sample
- list layers
- toggle layer
- start markup mode
- hide/show markups
- collect text extraction results

### Task 3: Adapt TviCore for the New UI

**Files:**
- Modify: `CADFP/CADBridge/AppCore/TviCore.hpp`
- Modify: `CADFP/CADBridge/AppCore/TviCore.mm`

- [ ] **Step 1: Add text extraction output**

Change text extraction so it can return data to the new UI instead of only logging.

- [ ] **Step 2: Add markup visibility control**

Add a bridge-safe API to hide and restore all markups.

- [ ] **Step 3: Keep behavior minimal**

Do not add new CAD abilities beyond the first-page scope.

### Task 4: Wire Objective-C++ Into the Xcode Project

**Files:**
- Modify: `CADFP.xcodeproj/project.pbxproj`
- Create: `CADFP/CADFP-Bridging-Header.h`

- [ ] **Step 1: Add bridge files to the target**

Register the new Objective-C++ and C++ files in the app target.

- [ ] **Step 2: Add build settings**

Configure:
- header search paths
- library search paths
- other linker flags
- bridging header

- [ ] **Step 3: Verify device-only build path**

Make sure the target can at least build for `iphoneos`.

### Task 5: Implement the Figma Viewer Screen

**Files:**
- Create: `CADFP/Main/CADViewer/CADViewerScreen.swift`
- Create: `CADFP/Main/CADViewer/CADViewerBridgeView.swift`
- Create: `CADFP/Main/CADViewer/CADViewerViewModel.swift`
- Modify: `CADFP/ContentView.swift`
- Modify: `CADFP/Main/HomeView.swift`

- [ ] **Step 1: Write a failing state test or equivalent verification target if available**

If a test target is available, add a minimal failing test for viewer tool state.  
If not, document the absence and use build verification as the first executable guard.

- [ ] **Step 2: Build the Figma shell**

Implement the new CAD viewer page:
- top title bar
- center CAD canvas
- bottom tool bar
- tool active state

- [ ] **Step 3: Embed the bridge controller**

Use `UIViewControllerRepresentable` to host the CAD bridge.

- [ ] **Step 4: Connect toolbar actions**

Wire:
- 图层
- 批注
- 隐藏批注
- 文字提取
- 测量占位

- [ ] **Step 5: Route from home**

Make `最近文件` entry open the new viewer page.

### Task 6: Verify the Build and Integration

**Files:**
- Modify as needed based on failures

- [ ] **Step 1: Build the app for device**

Run a fresh `iphoneos` build.

- [ ] **Step 2: Fix compile or link failures**

Address missing headers, symbols, and resource issues.

- [ ] **Step 3: Re-run the build**

Do not claim completion until the build is green.

- [ ] **Step 4: Summarize known gaps**

Explicitly note:
- `测量` 仍是占位
- 模拟器可能不可用
- 后续功能包分离未开始
