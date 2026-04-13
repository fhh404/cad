import CoreGraphics
import UIKit
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

    func testSaveImportedFileCopiesOriginalIntoSandboxAndPersistsMetadata() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "ConversionDocumentStoreTests"))
        defaults.removePersistentDomain(forName: "ConversionDocumentStoreTests")

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let sourceURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("现场图纸.pdf")
        defer {
            try? FileManager.default.removeItem(at: directory)
            try? FileManager.default.removeItem(at: sourceURL.deletingLastPathComponent())
            defaults.removePersistentDomain(forName: "ConversionDocumentStoreTests")
        }

        try FileManager.default.createDirectory(
            at: sourceURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let sourceData = Data("PDF bytes".utf8)
        try sourceData.write(to: sourceURL, options: .atomic)

        let store = ConversionDocumentStore(
            userDefaults: defaults,
            baseDirectory: directory,
            dateProvider: { Date(timeIntervalSince1970: 1_775_520_000) }
        )

        let saved = try store.saveImportedFile(at: sourceURL, kind: .pdfToDwg)
        let savedURL = saved.fileURL(relativeTo: directory)

        XCTAssertTrue(store.documents(for: .pdfToDwg).isEmpty)
        XCTAssertEqual(saved.fileName, "现场图纸.pdf")
        XCTAssertTrue(FileManager.default.fileExists(atPath: savedURL.path))
        XCTAssertEqual(try Data(contentsOf: savedURL), sourceData)
    }

    func testSaveConvertedFileCopiesOutputIntoSandboxAndPersistsMetadata() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "ConversionDocumentStoreTests"))
        defaults.removePersistentDomain(forName: "ConversionDocumentStoreTests")

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("oda-output.dxf")
        defer {
            try? FileManager.default.removeItem(at: directory)
            try? FileManager.default.removeItem(at: outputURL.deletingLastPathComponent())
            defaults.removePersistentDomain(forName: "ConversionDocumentStoreTests")
        }

        try FileManager.default.createDirectory(
            at: outputURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let convertedData = Data("DXF bytes".utf8)
        try convertedData.write(to: outputURL, options: .atomic)

        let store = ConversionDocumentStore(
            userDefaults: defaults,
            baseDirectory: directory,
            dateProvider: { Date(timeIntervalSince1970: 1_775_520_000) }
        )

        let saved = try store.saveConvertedFile(
            at: outputURL,
            kind: .dwgToDxf,
            sourceName: "平面布置.dwg"
        )
        let documents = store.documents(for: .dwgToDxf)
        let savedURL = saved.fileURL(relativeTo: directory)

        XCTAssertEqual(documents, [saved])
        XCTAssertEqual(saved.fileName, "平面布置.dxf")
        XCTAssertTrue(FileManager.default.fileExists(atPath: savedURL.path))
        XCTAssertEqual(try Data(contentsOf: savedURL), convertedData)
    }

    func testPreferredImportKindUsesFileExtension() {
        XCTAssertEqual(ConversionKind.preferredImportKind(for: URL(fileURLWithPath: "现场图纸.pdf")), .pdfToDwg)
        XCTAssertEqual(ConversionKind.preferredImportKind(for: URL(fileURLWithPath: "平面.dwg")), .dwgToPdf)
        XCTAssertEqual(ConversionKind.preferredImportKind(for: URL(fileURLWithPath: "导出.dxf")), .dwgToDxf)
        XCTAssertNil(ConversionKind.preferredImportKind(for: URL(fileURLWithPath: "模型.obj")))
        XCTAssertNil(ConversionKind.preferredImportKind(for: URL(fileURLWithPath: "备注.txt")))
    }

    func testConversionEngineMarksAvailableConversionKindsAsSupported() {
        XCTAssertEqual(
            CADConversionEngine.supportedKinds,
            [.dwgToPdf, .dwgToImage, .dwgToDxf, .pdfToDwg, .pdfToImage]
        )
    }

    func testConversionEngineKeepsUnavailableKindsUnsupported() {
        XCTAssertFalse(CADConversionEngine.supportedKinds.contains(.modelToStp))
        XCTAssertFalse(CADConversionEngine.supportedKinds.contains(.pdfToWord))
    }

    func testHomeRecommendationsHideUnavailable3DToSTPConversion() {
        let actions = homeRecommendationActions(in: HomeView())

        XCTAssertFalse(actions.compactMap(\.conversionKind).contains(.modelToStp))
    }

    @MainActor
    func testConversionDocumentPreviewDestinationUsesCADViewerForDwgAndDxf() {
        let dwgDocument = ConversionDocument(
            id: UUID(),
            kind: .pdfToDwg,
            fileName: "图纸.dwg",
            createdAt: Date(timeIntervalSince1970: 1_775_520_000),
            relativePath: "图纸.dwg"
        )
        let dxfDocument = ConversionDocument(
            id: UUID(),
            kind: .dwgToDxf,
            fileName: "图纸.dxf",
            createdAt: Date(timeIntervalSince1970: 1_775_520_000),
            relativePath: "图纸.dxf"
        )

        XCTAssertEqual(dwgDocument.previewDestination, .cadViewer)
        XCTAssertEqual(dxfDocument.previewDestination, .cadViewer)
    }

    @MainActor
    func testConversionDocumentPreviewDestinationUsesSystemPreviewForOtherOutputs() {
        let pdfDocument = ConversionDocument(
            id: UUID(),
            kind: .dwgToPdf,
            fileName: "图纸.pdf",
            createdAt: Date(timeIntervalSince1970: 1_775_520_000),
            relativePath: "图纸.pdf"
        )
        let imageDocument = ConversionDocument(
            id: UUID(),
            kind: .dwgToImage,
            fileName: "图纸.png",
            createdAt: Date(timeIntervalSince1970: 1_775_520_000),
            relativePath: "图纸.png"
        )

        XCTAssertEqual(pdfDocument.previewDestination, .systemPreview)
        XCTAssertEqual(imageDocument.previewDestination, .systemPreview)
    }

    func testDWGToDXFConversionCreatesOutputFile() throws {
        #if targetEnvironment(simulator)
        throw XCTSkip("ODA iOS libraries in this project are device-only.")
        #else
        let sampleURL = try XCTUnwrap(Bundle.main.url(forResource: "Sample", withExtension: "dwg"))

        let outputURL = try CADConversionEngine.convert(sourceURL: sampleURL, kind: .dwgToDxf)
        let attributes = try FileManager.default.attributesOfItem(atPath: outputURL.path)
        let fileSize = try XCTUnwrap(attributes[.size] as? NSNumber)

        XCTAssertEqual(outputURL.pathExtension.lowercased(), "dxf")
        XCTAssertGreaterThan(fileSize.intValue, 0)
        #endif
    }

    func testDWGToPDFConversionCreatesOutputFile() throws {
        #if targetEnvironment(simulator)
        throw XCTSkip("ODA iOS libraries in this project are device-only.")
        #else
        let sampleURL = try XCTUnwrap(Bundle.main.url(forResource: "Sample", withExtension: "dwg"))

        let outputURL = try CADConversionEngine.convert(sourceURL: sampleURL, kind: .dwgToPdf)
        let attributes = try FileManager.default.attributesOfItem(atPath: outputURL.path)
        let fileSize = try XCTUnwrap(attributes[.size] as? NSNumber)
        let pdfData = try Data(contentsOf: outputURL)

        XCTAssertEqual(outputURL.pathExtension.lowercased(), "pdf")
        XCTAssertGreaterThan(fileSize.intValue, 0)
        XCTAssertTrue(pdfData.starts(with: Data("%PDF".utf8)))
        #endif
    }

    func testDWGToImageConversionCreatesOutputFile() throws {
        #if targetEnvironment(simulator)
        throw XCTSkip("ODA iOS libraries in this project are device-only.")
        #else
        let sampleURL = try XCTUnwrap(Bundle.main.url(forResource: "Sample", withExtension: "dwg"))

        let outputURL = try CADConversionEngine.convert(sourceURL: sampleURL, kind: .dwgToImage)
        let attributes = try FileManager.default.attributesOfItem(atPath: outputURL.path)
        let fileSize = try XCTUnwrap(attributes[.size] as? NSNumber)
        let imageData = try Data(contentsOf: outputURL)
        let pngSignature = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])

        XCTAssertEqual(outputURL.pathExtension.lowercased(), "png")
        XCTAssertGreaterThan(fileSize.intValue, 0)
        XCTAssertTrue(imageData.starts(with: pngSignature))
        #endif
    }

    func testPDFToDWGConversionCreatesOutputFile() throws {
        #if targetEnvironment(simulator)
        throw XCTSkip("ODA iOS libraries in this project are device-only.")
        #else
        let sampleURL = try makeSamplePDF()
        defer { try? FileManager.default.removeItem(at: sampleURL) }

        let outputURL = try CADConversionEngine.convert(sourceURL: sampleURL, kind: .pdfToDwg)
        let attributes = try FileManager.default.attributesOfItem(atPath: outputURL.path)
        let fileSize = try XCTUnwrap(attributes[.size] as? NSNumber)

        XCTAssertEqual(outputURL.pathExtension.lowercased(), "dwg")
        XCTAssertGreaterThan(fileSize.intValue, 0)
        #endif
    }

    func testPDFToImageSystemConversionCreatesPNGOutputFile() throws {
        let sampleURL = try makeSamplePDF()
        defer { try? FileManager.default.removeItem(at: sampleURL) }

        let outputURL = try CADConversionEngine.convert(sourceURL: sampleURL, kind: .pdfToImage)
        let attributes = try FileManager.default.attributesOfItem(atPath: outputURL.path)
        let fileSize = try XCTUnwrap(attributes[.size] as? NSNumber)
        let imageData = try Data(contentsOf: outputURL)
        let pngSignature = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])

        XCTAssertEqual(outputURL.pathExtension.lowercased(), "png")
        XCTAssertGreaterThan(fileSize.intValue, 0)
        XCTAssertTrue(imageData.starts(with: pngSignature))
    }

    func testPDFToWordReportsMissingSystemConversion() throws {
        let sampleURL = try makeSamplePDF()
        defer { try? FileManager.default.removeItem(at: sampleURL) }

        XCTAssertThrowsError(try CADConversionEngine.convert(sourceURL: sampleURL, kind: .pdfToWord)) { error in
            XCTAssertEqual(error as? CADConversionEngine.ConversionError, .systemConversionUnavailable(.pdfToWord))
        }
    }

    func testConversionScreenLayoutMatchesFigmaAnchorPositions() {
        XCTAssertEqual(ConversionScreenLayout.designWidth, 393)
        XCTAssertEqual(ConversionScreenLayout.headerTop, 125)
        XCTAssertEqual(ConversionScreenLayout.importCardsTop, 233)
        XCTAssertEqual(ConversionScreenLayout.documentsPanelTop, 409)
        XCTAssertEqual(ConversionScreenLayout.documentsPanelHeight, 443)
    }

    private func makeSamplePDF() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: false)
            .appendingPathExtension("pdf")
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 300, height: 300))

        try renderer.writePDF(to: url) { context in
            context.beginPage()

            UIColor.black.setStroke()
            UIBezierPath(rect: CGRect(x: 40, y: 40, width: 180, height: 120)).stroke()

            let text = "CADFP PDF"
            text.draw(
                at: CGPoint(x: 58, y: 88),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 28, weight: .semibold),
                    .foregroundColor: UIColor.black
                ]
            )
        }

        return url
    }

    private func homeRecommendationActions(in homeView: HomeView) -> [HomeAction] {
        guard let recommendRows = Mirror(reflecting: homeView).descendant("recommendRows") else {
            return []
        }

        return collectHomeActions(from: recommendRows)
    }

    private func collectHomeActions(from value: Any) -> [HomeAction] {
        if let action = value as? HomeAction {
            return [action]
        }

        return Mirror(reflecting: value).children.flatMap { child in
            collectHomeActions(from: child.value)
        }
    }
}
