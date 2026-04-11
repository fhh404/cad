import XCTest
@testable import CADFP

final class ConversionDocumentStoreTests: XCTestCase {
    func testSaveConvertedPlaceholderPersistsMetadataAndFile() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "ConversionDocumentStoreTests"))
        defaults.removePersistentDomain(forName: "ConversionDocumentStoreTests")

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
            defaults.removePersistentDomain(forName: "ConversionDocumentStoreTests")
        }

        let store = ConversionDocumentStore(
            userDefaults: defaults,
            baseDirectory: directory,
            dateProvider: { Date(timeIntervalSince1970: 1_775_520_000) }
        )

        let saved = try store.saveConvertedPlaceholder(kind: .pdfToDwg, sourceName: "示例 -1.pdf")
        let documents = store.documents(for: .pdfToDwg)

        XCTAssertEqual(documents, [saved])
        XCTAssertEqual(saved.fileName, "示例 -1.dwg")
        XCTAssertTrue(FileManager.default.fileExists(atPath: saved.fileURL(relativeTo: directory).path))
    }
}
