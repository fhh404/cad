import XCTest
@testable import CADFP

final class ProfileMenuItemTests: XCTestCase {
    func testDefaultItemsMatchFigmaOrder() {
        XCTAssertEqual(
            ProfileMenuItem.defaultItems.map(\.title),
            [
                "常见问题",
                "去App Store给我们好评！",
                "分享给朋友！",
                "服务条款",
                "联系我们"
            ]
        )
    }
}
