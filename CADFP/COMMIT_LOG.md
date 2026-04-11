# Git 提交日志

## 最新提交 (2026-04-10)

### 提交信息
**Commit:** f37e2b79f111c960dca82783749e323b1b8c3569  
**作者:** fhh404 <406138227@qq.com>  
**日期:** Fri Apr 10 18:10:12 2026 +0800

### 提交标题
feat: 添加工具套件（计算器、测量工具、水印相机）

### 提交详情
- 实现计算器套件：支持 8 种几何图形计算，提供面积、体积、周长计算
- 实现测量工具：标尺测量和量角器工具，支持设备注册和几何计算
- 实现水印相机：支持地理位置水印的相机功能
- 更新导航架构：重构 ContentView 使用 NavigationStack 和 HomeRoute 路由
- 添加图标资源和单元测试

### 文件变更统计
- **64 个文件修改**
- **6507 行新增**
- **11 行删除**

### 主要变更文件

#### 新增计算器套件（Calculator）
- `CalculatorCatalogScreen.swift` - 计算器目录界面（95 行）
- `CalculatorDetailScreen.swift` - 计算器详情界面（202 行）
- `CalculatorEngine.swift` - 计算引擎（87 行）
- `CalculatorFormatting.swift` - 计算格式化（32 行）
- `CalculatorModels.swift` - 数据模型（240 行）
- `CalculatorTheme.swift` - 主题样式（44 行）

**支持的几何图形：**
- 圆柱体（Cylinder）- 总面积、体积
- 球体（Sphere）- 表面积、体积
- 立方体（Cube）- 表面积、体积
- 圆锥（Cone）- 斜面高、曲面表面积、圆锥表面积、体积
- 三角形（Triangle）- 面积
- 矩形（Rectangle）- 面积、周长
- 圆形（Circle）- 面积、周长
- 梯形（Trapezoid）- 面积

#### 新增测量工具套件（Measurement）
- `MeasurementCatalogScreen.swift` - 测量工具目录（127 行）
- `MeasurementModels.swift` - 测量数据模型（72 行）
- `ProtractorGeometry.swift` - 量角器几何计算（109 行）
- `ProtractorScreen.swift` - 量角器界面（519 行）
- `RulerDeviceRegistry.swift` - 标尺设备注册（82 行）
- `RulerGeometry.swift` - 标尺几何计算（118 行）
- `RulerScreen.swift` - 标尺界面（369 行）

#### 新增水印相机功能（WatermarkCamera）
- `WatermarkCameraCapture.swift` - 相机捕获（299 行）
- `WatermarkCameraScreen.swift` - 水印相机界面（592 行）
- `WatermarkCameraViewModel.swift` - 视图模型（236 行）
- `WatermarkLocationService.swift` - 位置服务（144 行）
- `WatermarkModels.swift` - 水印数据模型（519 行）

#### 新增单元测试
- `CalculatorEngineTests.swift` - 计算器引擎测试（132 行）
- `LevelGeometryTests.swift` - 水平仪几何测试（68 行）
- `ProtractorGeometryTests.swift` - 量角器几何测试（90 行）
- `RulerGeometryTests.swift` - 标尺几何测试（108 行）
- `WatermarkModelsTests.swift` - 水印模型测试（196 行）

#### 更新主界面导航
- `ContentView.swift` - 重构为 NavigationStack + HomeRoute 路由系统（+54 行，-11 行）
  - 实现 HomeRoute 枚举路由
  - 支持计算器目录/详情导航
  - 支持测量工具目录/详情导航
  - 集成水印相机全屏展示

#### 新增图标资源
- 几何图形图标（圆柱体、球体、立方体、圆锥、三角形等）
- 测量工具图标（标尺、量角器）
- 其他 CAD 功能图标

#### 新增文档
- `docs/superpowers/plans/2026-04-10-calculator-suite.md` - 计算器套件计划
- `docs/superpowers/plans/2026-04-10-level-tools.md` - 水平仪工具计划
- `docs/superpowers/plans/2026-04-10-measurement-tools.md` - 测量工具计划
- `docs/superpowers/plans/2026-04-10-protractor-camera.md` - 量角器相机计划
- `docs/superpowers/specs/2026-04-10-calculator-suite-design.md` - 计算器设计规格
- `docs/superpowers/specs/2026-04-10-level-tools-design.md` - 水平仪设计规格
- `docs/superpowers/specs/2026-04-10-measurement-tools-design.md` - 测量工具设计规格
- `docs/superpowers/specs/2026-04-10-protractor-camera-design.md` - 量角器相机设计规格

#### 修改文件
- `CADFP.xcodeproj/project.pbxproj` - Xcode 项目配置更新（+266 行）
- `CADFP.xcodeproj/project.xcworkspace/xcuserdata/` - Xcode 用户界面状态
- `CADFP.xcodeproj/xcshareddata/xcschemes/CADFP.xcscheme` - Xcode 共享方案（114 行）

### 提交说明
本次提交实现了三大工具套件，大幅丰富了应用功能：

1. **计算器套件**：提供 8 种常见几何图形的面积、体积、周长计算，采用 MVVM 架构，包含完整的输入验证和单元测试
2. **测量工具**：实现标尺和量角器两种测量工具，支持设备注册和精确几何计算
3. **水印相机**：支持地理位置水印的相机功能，可拍摄带位置信息的照片
4. **导航架构升级**：重构主界面使用 NavigationStack 和 HomeRoute 路由系统，支持更复杂的导航场景

这为应用提供了完整的工具生态系统，满足用户在 CAD 设计、测量和文档记录方面的需求。

---

## 上次提交 (2026-04-09)

### 提交信息
**Commit:** 60fdb31091bd8d7abb97bdaa2d4d0018f8f5b28e  
**作者:** fhh404 <406138227@qq.com>  
**日期:** Thu Apr 9 19:39:11 2026 +0800

### 提交标题
feat: 添加 CAD 查看器桥接功能

### 提交详情
- 实现 CADBridge 核心模块（AppCore）
- 实现 CADBridge UI 工具模块（AppUITools）
- 添加视图控制器（CADBaseViewController, RenderViewController 等）
- 添加 Swift 桥接文件
- 添加 CAD 查看器视图组件
- 添加项目配置和文档

### 文件变更统计
- **42 个文件修改**
- **8796 行新增**
- **6 行删除**

### 主要变更文件

#### 新增 CADBridge 核心模块（AppCore）
- `TviCore.hpp/mm` - 核心引擎封装（1835 行）
- `TviDraggers.hpp/mm` - 拖拽器实现（1487 行）
- `TviAxisControl.cpp/hpp` - 轴控制模块（699 行）
- `TviGlobalParameters.hpp/mm` - 全局参数管理
- `TviImportParameters.hpp/mm` - 导入参数配置
- `TviMemoryStatus.h/mm` - 内存状态监控
- `TviProgressMeter.hpp/mm` - 进度计量
- `TviLimitManager.cpp/hpp` - 限制管理器
- `TviActivator.cpp/hpp` - 激活器
- `TviDatabaseInfo.h` - 数据库信息
- `TviTools.h/mm` - 工具模块

#### 新增 CADBridge UI 工具模块（AppUITools）
- `TviProgressControl.h/m` - 进度控制组件（325 行）

#### 新增视图控制器
- `CADBaseViewController.h/mm` - CAD 基础视图控制器（534 行）
- `RenderViewController.h/mm` - 渲染视图控制器
- `CADEngineBootstrap.h/mm` - CAD 引擎引导
- `CADLayerItem.h/m` - CAD 图层管理

#### 新增 Swift 桥接文件
- `CADFP-Bridging-Header.h` - Objective-C 到 Swift 的桥接头文件

#### 新增 CAD 查看器视图组件
- `CADViewerScreen.swift` - CAD 查看器屏幕（286 行）
- `CADViewerViewModel.swift` - CAD 查看器视图模型（112 行）
- `CADViewerBridgeView.swift` - CAD 查看器桥接视图（56 行）

#### 修改文件
- `CADFP.xcodeproj/project.pbxproj` - Xcode 项目配置更新（+402 行）
- `CADFP/ContentView.swift` - 内容视图更新
- `.gitignore` - 添加 Git 忽略规则

#### 新增文档
- `docs/superpowers/plans/2026-04-09-cad-viewer-bridge.md` - 架构设计计划
- `docs/superpowers/specs/2026-04-09-cad-viewer-bridge-design.md` - 架构设计规格

### 提交说明
本次提交实现了完整的 CAD 查看器桥接功能，主要包括：

1. **核心引擎封装**：通过 TviCore 实现 CAD 引擎的底层封装
2. **UI 工具集**：提供进度控制等 UI 组件
3. **视图控制器体系**：实现完整的 CAD 视图渲染和管理
4. **Swift 互操作**：通过桥接头文件实现 Objective-C 与 Swift 的无缝交互
5. **MVVM 架构**：采用 ViewModel 模式管理 CAD 查看器状态
6. **文档完善**：添加详细的架构设计和规格文档

这为后续的 CAD 功能开发奠定了坚实的基础。

---

## 上上次提交 (2026-04-09)

### 提交信息
**Commit:** 8c5ac85d82124365f44aea00271155255d7077c0  
**作者:** fhh404 <406138227@qq.com>  
**日期:** Thu Apr 9 18:33:09 2026 +0800

### 提交标题
feat: 添加 CAD 图标资源和主页视图

### 提交详情
- 添加大量 CAD 相关图标资源（布尔运算、标注、测量等）
- 添加主页视图 HomeView
- 添加示例 DWG 文件 Sample.dwg
- 更新 ContentView 和 Xcode 项目配置

### 文件变更统计
- **49 个文件修改**
- **1086 行新增**
- **22 行删除**

### 主要变更文件

#### 新增资源文件
- CAD 图标资源（Assets.xcassets/CAD 地图_icon/）
  - Group 324, 326, 328-334
  - Intersect, Union, Mask group
  - Vector5
  - dwg (1) 1
  - 查地图图标、返回图标、隐藏大头像图标等
  
- Tab 栏资源（Assets.xcassets/tab/）
  - Group 243-246（底部导航图标）

#### 新增代码文件
- `CADFP/Main/HomeView.swift` (529 行) - 主页视图实现

#### 新增数据文件
- `CADFP/Sample.dwg` (65KB) - 示例 DWG 图纸文件

#### 修改文件
- `CADFP.xcodeproj/project.pbxproj` - Xcode 项目配置更新
- `CADFP/ContentView.swift` - 内容视图更新
- Xcode 用户界面状态文件

### 提交说明
本次提交主要为 CAD 功能添加了完整的图标资源体系，包括：
1. 布尔运算图标（并集、交集等）
2. 标注和测量工具图标
3. 图层管理相关图标
4. 底部导航栏图标
5. 实现了新的主页视图架构
6. 添加了示例 DWG 文件用于测试
