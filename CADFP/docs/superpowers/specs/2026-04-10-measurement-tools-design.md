# Measurement Tools Design

**Date:** 2026-04-10

**Goal**

在首页点击“测量工具”后进入与 Figma 节点 `106:497` 对齐的测量工具目录页，并优先完成其中的“直尺”模块，使其在真实 iPhone 设备上按物理尺寸展示厘米刻度，支持上下手柄拖拽和持续拉伸测量。

**Constraints**

- 保持现有 SwiftUI 工程结构，不引入第三方测量或设备识别依赖。
- 目录页视觉尽量对齐 Figma 节点 `106:497`，直尺页视觉和交互骨架尽量对齐节点 `107:537`。
- 图标资源优先复用 `Assets.xcassets/CAD看图_icon-4`。
- 首页导航继续由现有 `NavigationStack` 承接，不破坏已有计算器、CAD、相机路由。
- 第一版仅把“直尺”做成真实可用工具；圆形水平仪、条形水平仪、量角器先保留目录入口与友好占位。

**Recommended Approach**

采用“目录页 + 真实直尺内核”两层设计：

- 首页只负责把 `HomeAction.measurementTools` 路由到新的 `MeasurementCatalogScreen`。
- 目录页负责展示 4 个测量工具卡片。
- 直尺页不依赖静态图片刻度，而是用代码绘制厘米 / 毫米刻度和数字，保证物理尺寸与拖拽状态同步。
- 物理尺寸换算基于：
  - iPhone 机型标识（如 `iPhone15,4`）
  - 机型对应的屏幕 PPI
  - 当前设备的 `nativeScale`
- 测量区通过两个可拖拽手柄确定，内部保留高精度点位计算，界面展示保留 2 位小数。

**Architecture**

1. 入口层

- `ContentView` 新增测量工具相关路由：
  - `measurementCatalog`
  - `measurementRuler`

2. 展示层

- `MeasurementCatalogScreen`
  - 复用当前计算器页的导航头部风格
  - 使用 2 列 4 宫格承载圆形水平仪、条形水平仪、直尺、量角器
- `RulerScreen`
  - 左侧灰色标尺条
  - 主内容区白底
  - 蓝色半透明测量区
  - 顶部 / 底部拖拽手柄
  - 中央动态读数
  - 右上关闭按钮

3. 领域层

- `MeasurementToolKind`
  - 描述 4 个工具的标题、图标和可用状态
- `RulerDisplayProfile`
  - 描述设备的 PPI、`nativeScale`、每厘米对应点数
- `RulerDeviceRegistry`
  - 根据 `uname` / `utsname` 读取硬件标识
  - 将支持的 iPhone 机型映射到 PPI
- `RulerGeometry`
  - 负责厘米与 points 的双向换算
  - 负责测量长度格式化
  - 负责拖拽中的边界和可视区域平移计算

4. 验证层

- 用 `XCTest` 覆盖：
  - `pointsPerCentimeter` 换算
  - 点位差到厘米读数
  - 拖拽超出可视区时的连续平移逻辑
- UI 通过真机构建验证与实际交互检查为主。

**Physical Accuracy Strategy**

- 真实厘米换算公式：
  - `pixelsPerCentimeter = ppi / 2.54`
  - `pointsPerCentimeter = pixelsPerCentimeter / nativeScale`
- 设备标识来源：
  - 使用 `utsname().machine`
- 首批支持机型覆盖 iOS 16+ 常见 iPhone：
  - iPhone 8 / 8 Plus
  - iPhone X / XR / XS / XS Max
  - iPhone 11 / 11 Pro / 11 Pro Max
  - iPhone 12 / 12 mini / 12 Pro / 12 Pro Max
  - iPhone 13 / 13 mini / 13 Pro / 13 Pro Max
  - iPhone 14 / 14 Plus / 14 Pro / 14 Pro Max
  - iPhone 15 / 15 Plus / 15 Pro / 15 Pro Max
  - iPhone 16 / 16 Plus / 16 Pro / 16 Pro Max / 16e
- 若遇到未知 iPhone 机型：
  - 页面仍可进入
  - 给出“当前设备未完成真尺标定”的提示
  - 不伪装成精确物理尺寸

**Ruler Interaction Design**

- 初始状态展示一段约 `4.7 cm` 的测量区，贴近 Figma 稿读数。
- 上下两个蓝色手柄均可独立拖拽。
- 手柄相交时保持最小测量距离，避免出现负值或视觉穿插。
- 当用户继续向屏幕上下边缘拖拽时：
  - 不依赖真实 `ScrollView` 无限内容
  - 通过“虚拟可视窗口偏移量”滚动标尺刻度
  - 达到持续拉伸测量的效果
- 中央读数实时更新，格式为：
  - `4.70CM`

**Catalog Behavior**

- 点击“直尺”进入真实直尺页面。
- 点击圆形水平仪、条形水平仪、量角器：
  - 暂时展示“功能开发中”提示
  - 保持目录和路由结构可继续扩展

**Success Criteria**

- 首页“测量工具”入口不再走占位提示，而是进入目录页。
- 目录页视觉、标题、卡片布局基本对齐 Figma。
- “直尺”页可打开、关闭并稳定返回目录。
- 在真实 iPhone 设备上，厘米刻度与物理长度一致。
- 上下手柄拖拽读数连续、稳定，支持超出首屏后的持续测量。
- 核心换算与拖拽逻辑有单元测试覆盖。

**Risks**

- Apple 没有提供直接返回 PPI 的公开 API，真实尺寸需要依赖机型映射表。
- 新发布但未登记的 iPhone 机型无法保证真尺精度，需要兜底提示。
- 真尺交互要避免浮点累计误差导致读数抖动，内部计算需要统一基于 points / centimeters 的单一真值源。
- 当前工程存在未提交改动，实现时需要避免覆盖用户现有工作。

**Out of Scope**

- 圆形水平仪真实传感器测量
- 条形水平仪真实传感器测量
- 量角器真实角度测量
- 手动校准流程
- 测量历史、截图、分享导出
