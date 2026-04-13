import XCTest
@testable import CADFP

final class CADViewerToolbarItemTests: XCTestCase {
    func testDefaultToolbarItemsMatchCADViewerDesign() {
        let items = CADViewerToolbarItemKind.allCases

        XCTAssertEqual(items.map(\.title), ["图层", "批注", "测量", "隐藏批注", "文字提取", "重置", "设置"])
        XCTAssertEqual(items.map(\.inactiveIconName), ["图层-L 1", "批注 1", "测量 1", "隐藏批注 1", "文字提取 1", "重置筛选 1", "设置 (2) 1"])
        XCTAssertEqual(items.map(\.activeIconName), ["图层-L 2", "批注 2", "测量 2", "隐藏批注 2", "文字提取 2", "重置筛选 2", "设置 (2) 2"])
    }

    func testMarkupToolbarItemsMatchAnnotationDesign() {
        let items = CADMarkupToolbarItemKind.allCases

        XCTAssertEqual(items.map(\.title), ["", "文字", "手绘", "热点"])
        XCTAssertEqual(items.map(\.inactiveIconName), ["返回 (2) 1", "文字 (2) 1", "手写体 2", "定位 (1) 1"])
        XCTAssertEqual(items.map(\.activeIconName), ["返回 (2) 1", "文字 (2) 2", "手写体 3", "定位 (1) 2"])
    }

    @MainActor
    func testMarkupStyleOptionsMapToBridgeValues() {
        XCTAssertEqual(CADMarkupColorOption.cyan.rgb, CADMarkupRGB(red: 35, green: 196, blue: 254))
        XCTAssertEqual(CADMarkupLineWeightOption.thick.bridgeWeight, 6)
        XCTAssertEqual(CADMarkupFontSizeMapper.textScale(for: 49), 1.0)
        XCTAssertGreaterThan(CADMarkupFontSizeMapper.textScale(for: 80), CADMarkupFontSizeMapper.textScale(for: 49))
    }

    @MainActor
    func testHotspotAnnotationStoresText() {
        XCTAssertEqual(CADHotspotAnnotation(text: "检查门洞").text, "检查门洞")
    }
}
