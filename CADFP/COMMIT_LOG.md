# Git 提交日志

## 最新提交 (2026-04-09)

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

## 上次提交 (2026-04-09)

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
