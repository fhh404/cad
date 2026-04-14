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

    func testMeasurementToolbarItemsMatchMeasurementDesign() {
        let items = CADMeasurementToolbarItemKind.allCases

        XCTAssertEqual(items.map(\.title), ["", "测长度", "测面积", "测坐标"])
        XCTAssertEqual(items.map(\.inactiveIconName), ["返回 (2) 1", "长度测量 1-1", "面积 1", "坐标 1"])
        XCTAssertEqual(items.map(\.activeIconName), ["返回 (2) 1", "长度测量 1", "面积 2", "坐标 1-1"])
    }

    @MainActor
    func testSettingsBackgroundOptionsMatchDesign() {
        let options = CADViewerSettingsBackgroundOption.allCases

        XCTAssertEqual(options.map(\.rawValue), [0, 1, 2])
        XCTAssertEqual(options.map(\.rgb), [
            CADMarkupRGB(red: 255, green: 255, blue: 255),
            CADMarkupRGB(red: 151, green: 154, blue: 153),
            CADMarkupRGB(red: 0, green: 0, blue: 0)
        ])
        XCTAssertEqual(CADViewerSettingsBackgroundOption.defaultOption, .black)
    }

    @MainActor
    func testSettingsRotationWrapsInQuarterTurns() {
        XCTAssertEqual(CADViewerSettingsRotation.normalizedDegrees(90), 90)
        XCTAssertEqual(CADViewerSettingsRotation.normalizedDegrees(0), 0)
        XCTAssertEqual(CADViewerSettingsRotation.normalizedDegrees(-90), 270)
        XCTAssertEqual(CADViewerSettingsRotation.normalizedDegrees(450), 90)
    }

    @MainActor
    func testMarkupStyleOptionsMapToBridgeValues() {
        XCTAssertEqual(CADMarkupColorOption.cyan.rgb, CADMarkupRGB(red: 35, green: 196, blue: 254))
        XCTAssertEqual(CADMarkupLineWeightOption.thick.bridgeWeight, 6)
        XCTAssertEqual(CADMarkupFontSizeMapper.textScale(for: 49), 0.0)
        XCTAssertGreaterThan(CADMarkupFontSizeMapper.textScale(for: 80), CADMarkupFontSizeMapper.textScale(for: 49))
    }

    @MainActor
    func testHotspotAnnotationStoresText() {
        XCTAssertEqual(CADHotspotAnnotation(text: "检查门洞").text, "检查门洞")
    }

    func testCADMeasurementCalculatorUsesWorldCoordinates() {
        let first = CADMeasurementWorldPoint(x: 0, y: 0, z: 0)
        let second = CADMeasurementWorldPoint(x: 3, y: 4, z: 12)

        XCTAssertEqual(CADMeasurementCalculator.length(from: [first, second]), 13, accuracy: 0.0001)
        XCTAssertEqual(
            CADMeasurementCalculator.area(from: [
                CADMeasurementWorldPoint(x: 0, y: 0, z: 0),
                CADMeasurementWorldPoint(x: 10, y: 0, z: 0),
                CADMeasurementWorldPoint(x: 10, y: 5, z: 0),
                CADMeasurementWorldPoint(x: 0, y: 5, z: 0)
            ]),
            50,
            accuracy: 0.0001
        )
        XCTAssertEqual(CADMeasurementCalculator.formattedLength(5679), "5679")
        XCTAssertEqual(CADMeasurementCalculator.formattedArea(45), "45㎡")
        XCTAssertEqual(
            CADMeasurementCalculator.formattedCoordinate(CADMeasurementWorldPoint(x: 4154453, y: 515454, z: 0)),
            "X:4154453\nY:515454"
        )
    }

    func testTextExtractionSelectionGeometryMovesAndResizesInsideCanvas() {
        let canvas = CGSize(width: 393, height: 852)
        let initial = CADTextExtractionSelectionGeometry.initialDesignRect

        let moved = CADTextExtractionSelectionGeometry.moved(
            initial,
            by: CGSize(width: -100, height: -400),
            in: canvas
        )
        XCTAssertEqual(moved.origin.x, 0, accuracy: 0.0001)
        XCTAssertEqual(moved.origin.y, 0, accuracy: 0.0001)
        XCTAssertEqual(moved.size, initial.size)

        let resized = CADTextExtractionSelectionGeometry.resized(
            initial,
            handle: .bottomTrailing,
            by: CGSize(width: 200, height: 400),
            in: canvas
        )
        XCTAssertEqual(resized.maxX, canvas.width, accuracy: 0.0001)
        XCTAssertEqual(resized.maxY, canvas.height, accuracy: 0.0001)

        let roundTrip = CADTextExtractionSelectionGeometry.denormalized(
            CADTextExtractionSelectionGeometry.normalized(initial, in: canvas),
            in: canvas
        )
        XCTAssertEqual(roundTrip.origin.x, initial.origin.x, accuracy: 0.0001)
        XCTAssertEqual(roundTrip.origin.y, initial.origin.y, accuracy: 0.0001)
        XCTAssertEqual(roundTrip.width, initial.width, accuracy: 0.0001)
        XCTAssertEqual(roundTrip.height, initial.height, accuracy: 0.0001)
    }

    @MainActor
    func testTextExtractionFullViewRangeReturnsSampleTextsOnDevice() async throws {
        #if targetEnvironment(simulator)
        throw XCTSkip("ODA iOS libraries in this project are device-only.")
        #else
        let sampleURL = try XCTUnwrap(Bundle.main.url(forResource: "Sample", withExtension: "dwg"))
        let delegate = CADTextExtractionProbeDelegate(testCase: self)
        let controller = CADBaseViewController(filePath: sampleURL.path)
        controller.delegate = delegate

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        window.rootViewController = controller
        window.makeKeyAndVisible()

        await fulfillment(of: [delegate.loadingExpectation], timeout: 30)
        delegate.prepareForTextExtraction(description: "CAD sample extracts all text")
        controller.requestExtractedTexts()
        await fulfillment(of: [try XCTUnwrap(delegate.textExtractionExpectation)], timeout: 5)
        XCTAssertGreaterThan(delegate.extractedTexts.count, 0)

        delegate.prepareForTextExtraction(description: "CAD sample extracts text in full view")
        controller.requestExtractedTexts(inViewRect: controller.view.bounds)
        await fulfillment(of: [try XCTUnwrap(delegate.textExtractionExpectation)], timeout: 5)
        XCTAssertGreaterThan(delegate.extractedTexts.count, 0)

        controller.setDrawingBackground(red: 151, green: 154, blue: 153)
        controller.setViewRotation(degrees: 90)
        controller.setViewRotation(degrees: 0)
        controller.setDrawingBackground(red: 0, green: 0, blue: 0)
        #endif
    }

}

private final class CADTextExtractionProbeDelegate: NSObject, CADBaseViewControllerDelegate {
    let loadingExpectation: XCTestExpectation
    private(set) var textExtractionExpectation: XCTestExpectation?
    private(set) var extractedTexts: [String] = []

    init(testCase: XCTestCase) {
        loadingExpectation = testCase.expectation(description: "CAD sample loads")
        self.testCase = testCase
        super.init()
    }

    private weak var testCase: XCTestCase?

    func prepareForTextExtraction(description: String) {
        extractedTexts = []
        textExtractionExpectation = testCase?.expectation(description: description)
    }

    func cadControllerDidFinishLoading(_ controller: CADBaseViewController) {
        loadingExpectation.fulfill()
    }

    func cadController(_ controller: CADBaseViewController, didExtractTextItems textItems: [String]) {
        extractedTexts = textItems
        textExtractionExpectation?.fulfill()
    }
}
