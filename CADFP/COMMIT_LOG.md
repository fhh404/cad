# Git 提交日志

## 最新提交 (2026-04-09)

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
