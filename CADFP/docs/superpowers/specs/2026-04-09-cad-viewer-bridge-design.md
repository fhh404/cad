# CAD Viewer Bridge Design

**Date:** 2026-04-09

**Goal**

在新项目 `CADFP` 中实现一张与 Figma 节点 `88:451` 对齐的 CAD 查看页面，并把旧项目中的 CAD 能力嵌入到新页面中。第一版使用内置 `Sample.dwg`，实现 `图层 / 批注 / 隐藏批注 / 文字提取`，`测量` 先占位。

**Constraints**

- 新页面按 Figma 视觉重做，不直接复用旧页面 UI。
- 第一版仅要求内置 `Sample.dwg` 自动打开。
- 旧 CAD 能力优先复用内核与渲染，不优先迁移历史业务页面。
- 功能包与私有引擎分离是后续目标，本次实现先保证边界清晰。

**Recommended Approach**

采用“新 SwiftUI 页面 + Objective-C++ CAD bridge”的结构：

- SwiftUI 负责 Figma 页面、顶部导航、底部工具栏、弹层与状态。
- 旧 CAD 能力通过一个最小的 bridge 宿主控制器嵌入。
- 第一版优先复用旧项目 `AppCore`、渲染控制器和 ODA 激活流程。
- 旧大页面 UI 不进入新页面，只保留必要的 CAD 行为。

**Architecture**

1. 页面层

- 新增 `CADViewerScreen`
- 页面结构分为：
  - 顶部返回区和标题
  - 中间 CAD 画布区
  - 底部工具栏和工具状态区

2. CAD bridge 层

- 新增一个最小宿主控制器，负责：
  - 激活 ODA
  - 加载 `Sample.dwg`
  - 管理渲染控制器
  - 对外暴露图层、批注、隐藏批注、文字提取接口

3. 旧 CAD 内核层

- 复用旧项目 `AppCore` 中的核心逻辑
- 必要时对 `TviCore` 做小范围适配，以支持：
  - 返回文字提取结果而不是仅 `NSLog`
  - 批量隐藏/恢复批注

**Functional Mapping**

- `图层`
  - 展示图层列表
  - 支持切换显隐

- `批注`
  - 第一版支持 `矩形 / 圆 / 云线 / 文字`
  - 按钮进入批注模式
  - 触控事件交给旧 CAD dragger 处理

- `测量`
  - 第一版保留按钮与激活态
  - 点击提示“开发中”

- `隐藏批注`
  - 作为开关按钮
  - 支持隐藏全部批注与恢复显示

- `文字提取`
  - 从旧 CAD 内核读取文字
  - 结果展示为新页面中的列表弹层

**Entry Flow**

- 首页点击“最近文件”中的 `DWG 示例 -1.dwg`
- 跳转到 `CADViewerScreen`
- 页面自动打开内置 `Sample.dwg`

**Implementation Notes**

- 第一版优先确保真机编译与运行。
- 如旧工程的 Metal 路径迁移成本高，则允许第一版沿用旧默认渲染路径，只要页面与功能可用。
- 所有新 UI 状态管理放在 SwiftUI 层，不把历史宏和旧业务依赖继续带入。

**Success Criteria**

- 能从新首页进入新的 CAD 查看页
- 页面视觉基本对齐 Figma
- 自动打开 `Sample.dwg`
- `图层 / 批注 / 隐藏批注 / 文字提取` 可用
- `测量` 为占位按钮

**Risks**

- 旧 CAD 内核更偏真机构建，模拟器大概率不可用
- 旧批注能力与新 UI 状态需要手势协调
- 文字提取当前实现需要补成可回传数据

**Out of Scope**

- 真实文件导入
- 测量真功能
- 真正修改 DWG 实体并保存回 DWG
- 私有引擎与 GitHub 分离交付
