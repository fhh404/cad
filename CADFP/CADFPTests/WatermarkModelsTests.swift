import XCTest
@testable import CADFP

final class WatermarkModelsTests: XCTestCase {
    func testClassicStyleUsesFallbackTextForEmptyFields() {
        let draft = WatermarkDraft(
            title: "",
            area: "",
            content: "",
            company: "",
            address: "",
            captureDate: makeDate(year: 2026, month: 3, day: 27, hour: 11, minute: 38, second: 29)
        )

        let overlay = WatermarkTemplateStyle.classic.makeOverlayContent(from: draft)

        XCTAssertEqual(overlay.title, "未填写标题")
        XCTAssertEqual(
            overlay.primaryLines,
            [
                "施工区域:未填写施工区域",
                "施工内容:未填写施工内容",
                "拍摄时间:2026.03.27 11:38:29",
                "地址:无法获取当前定位"
            ]
        )
        XCTAssertEqual(overlay.footerLine, "施工单位:未填写施工单位")
    }

    func testPunchStyleBuildsClockAndDateLines() {
        let draft = WatermarkDraft(
            title: "工程记录",
            area: "外立面",
            content: "变电施工",
            company: "中铁集团",
            address: "泉州市罗山街道",
            captureDate: makeDate(year: 2026, month: 3, day: 27, hour: 11, minute: 30, second: 0)
        )

        let overlay = WatermarkTemplateStyle.punchCard.makeOverlayContent(from: draft)

        XCTAssertEqual(overlay.badgeText, "打卡")
        XCTAssertEqual(overlay.timeText, "11:30")
        XCTAssertEqual(overlay.primaryLines, ["地址：泉州市罗山街道", "时间：星期五 2026/03/27"])
    }

    func testPunchStyleUsesLocationFallbackWhenAddressIsUnavailable() {
        let draft = WatermarkDraft(
            title: "工程记录",
            area: "外立面",
            content: "变电施工",
            company: "中铁集团",
            address: "",
            captureDate: makeDate(year: 2026, month: 3, day: 27, hour: 11, minute: 30, second: 0)
        )

        let overlay = WatermarkTemplateStyle.punchCard.makeOverlayContent(from: draft)

        XCTAssertEqual(overlay.primaryLines.first, "地址：无法获取当前定位")
    }

    func testClassicStyleExportFrameMatchesDesignRatios() {
        let canvas = CGSize(width: 1080, height: 1920)

        let frame = WatermarkTemplateStyle.classic.exportFrame(in: canvas)

        XCTAssertEqual(frame.origin.x, 44, accuracy: 0.5)
        XCTAssertEqual(frame.origin.y, 1459, accuracy: 0.5)
        XCTAssertEqual(frame.size.width, 572, accuracy: 0.5)
        XCTAssertEqual(frame.size.height, 375, accuracy: 0.5)
    }

    func testClassicStyleExpandsHeightForWrappedTextWhileKeepingBottomInset() {
        let canvas = CGSize(width: 1080, height: 1920)
        let shortDraft = WatermarkDraft(
            title: "工程记录",
            area: "外立面",
            content: "变电施工",
            company: "中铁集团",
            address: "泉州市罗山街道",
            captureDate: makeDate(year: 2026, month: 3, day: 27, hour: 11, minute: 30, second: 0)
        )
        let longDraft = WatermarkDraft(
            title: "工程记录工程记录工程记录工程记录工程记录工程记录",
            area: "外立面钢结构二期施工区域需要继续向东侧延展并补充说明",
            content: "变电施工以及配套布线校验，需要分三段完成并同步记录现场情况",
            company: "中铁集团华南建设工程有限公司项目管理中心",
            address: "泉州市罗山街道福埔工业区 8 号地块东侧配电施工区域",
            captureDate: makeDate(year: 2026, month: 3, day: 27, hour: 11, minute: 30, second: 0)
        )

        let shortFrame = WatermarkTemplateStyle.classic.exportFrame(
            in: canvas,
            content: WatermarkTemplateStyle.classic.makeOverlayContent(from: shortDraft)
        )
        let longFrame = WatermarkTemplateStyle.classic.exportFrame(
            in: canvas,
            content: WatermarkTemplateStyle.classic.makeOverlayContent(from: longDraft)
        )

        XCTAssertGreaterThan(longFrame.height, shortFrame.height)
        XCTAssertEqual(longFrame.maxY, shortFrame.maxY, accuracy: 0.5)
    }

    func testPunchStyleExpandsHeightForLongAddressWhileKeepingBottomInset() {
        let canvas = CGSize(width: 1080, height: 1920)
        let shortDraft = WatermarkDraft(
            title: "工程记录",
            area: "外立面",
            content: "变电施工",
            company: "中铁集团",
            address: "泉州市罗山街道",
            captureDate: makeDate(year: 2026, month: 3, day: 27, hour: 11, minute: 30, second: 0)
        )
        let longDraft = WatermarkDraft(
            title: "工程记录",
            area: "外立面",
            content: "变电施工",
            company: "中铁集团",
            address: "泉州市罗山街道福埔工业区 8 号地块东侧配电施工区域临时围挡入口",
            captureDate: makeDate(year: 2026, month: 3, day: 27, hour: 11, minute: 30, second: 0)
        )

        let shortFrame = WatermarkTemplateStyle.punchCard.exportFrame(
            in: canvas,
            content: WatermarkTemplateStyle.punchCard.makeOverlayContent(from: shortDraft)
        )
        let longFrame = WatermarkTemplateStyle.punchCard.exportFrame(
            in: canvas,
            content: WatermarkTemplateStyle.punchCard.makeOverlayContent(from: longDraft)
        )

        XCTAssertGreaterThan(longFrame.height, shortFrame.height)
        XCTAssertEqual(longFrame.maxY, shortFrame.maxY, accuracy: 0.5)
    }

    func testClassicStyleAppliesOffsetRatioToFrame() {
        let canvas = CGSize(width: 1080, height: 1920)
        let draft = WatermarkDraft(
            title: "工程记录",
            area: "外立面",
            content: "变电施工",
            company: "中铁集团",
            address: "泉州市罗山街道",
            captureDate: makeDate(year: 2026, month: 3, day: 27, hour: 11, minute: 30, second: 0)
        )
        let content = WatermarkTemplateStyle.classic.makeOverlayContent(from: draft)
        let baseFrame = WatermarkTemplateStyle.classic.exportFrame(in: canvas, content: content)

        let movedFrame = WatermarkTemplateStyle.classic.exportFrame(
            in: canvas,
            content: content,
            offsetRatio: CGSize(width: 0.1, height: -0.05)
        )

        XCTAssertEqual(movedFrame.origin.x, baseFrame.origin.x + 108, accuracy: 0.5)
        XCTAssertEqual(movedFrame.origin.y, baseFrame.origin.y - 96, accuracy: 0.5)
    }

    func testClassicStyleOffsetFrameStaysInsideCanvas() {
        let canvas = CGSize(width: 1080, height: 1920)
        let draft = WatermarkDraft(
            title: "工程记录",
            area: "外立面",
            content: "变电施工",
            company: "中铁集团",
            address: "泉州市罗山街道",
            captureDate: makeDate(year: 2026, month: 3, day: 27, hour: 11, minute: 30, second: 0)
        )
        let content = WatermarkTemplateStyle.classic.makeOverlayContent(from: draft)

        let movedFrame = WatermarkTemplateStyle.classic.exportFrame(
            in: canvas,
            content: content,
            offsetRatio: CGSize(width: 10, height: 10)
        )

        XCTAssertGreaterThanOrEqual(movedFrame.minX, -0.5)
        XCTAssertGreaterThanOrEqual(movedFrame.minY, -0.5)
        XCTAssertLessThanOrEqual(movedFrame.maxX, canvas.width + 0.5)
        XCTAssertLessThanOrEqual(movedFrame.maxY, canvas.height + 0.5)
    }

    private func makeDate(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int) -> Date {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(secondsFromGMT: 8 * 3600)
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second
        return try! XCTUnwrap(components.date)
    }
}
