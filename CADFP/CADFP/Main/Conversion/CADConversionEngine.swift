import Foundation
import PDFKit
import UIKit

enum CADConversionEngine {
    static let supportedKinds: Set<ConversionKind> = [
        .dwgToPdf,
        .dwgToImage,
        .dwgToDxf,
        .pdfToDwg,
        .pdfToImage
    ]

    enum ConversionError: LocalizedError, Equatable {
        case unsupported(ConversionKind)
        case systemConversionUnavailable(ConversionKind)
        case invalidPDF(URL)
        case emptyPDF(URL)
        case missingOutput(URL)

        var errorDescription: String? {
            switch self {
            case let .unsupported(kind):
                return "\(kind.title) 本地转换还没有接入。"
            case let .systemConversionUnavailable(kind):
                return "iOS 系统没有提供 \(kind.title) 的本地转换 API。"
            case let .invalidPDF(url):
                return "PDF 文件无法读取：\(url.lastPathComponent)"
            case let .emptyPDF(url):
                return "PDF 文件没有可转换页面：\(url.lastPathComponent)"
            case let .missingOutput(url):
                return "转换完成后没有找到输出文件：\(url.lastPathComponent)"
            }
        }
    }

    static func convert(sourceURL: URL, kind: ConversionKind) throws -> URL {
        switch kind {
        case .dwgToPdf:
            return try convertDWG(
                sourceURL: sourceURL,
                outputExtension: kind.outputExtension,
                conversion: CADConversionBridge.convertDWG(atPath:toPDFAtPath:)
            )
        case .dwgToImage:
            return try convertDWG(
                sourceURL: sourceURL,
                outputExtension: kind.outputExtension,
                conversion: CADConversionBridge.convertDWG(atPath:toImageAtPath:)
            )
        case .dwgToDxf:
            return try convertDWG(
                sourceURL: sourceURL,
                outputExtension: kind.outputExtension,
                conversion: CADConversionBridge.convertDWG(atPath:toDXFAtPath:)
            )
        case .pdfToDwg:
            return try convertPDF(
                sourceURL: sourceURL,
                outputExtension: kind.outputExtension,
                conversion: CADConversionBridge.convertPDF(atPath:toDWGAtPath:)
            )
        case .pdfToImage:
            return try convertPDFToImage(sourceURL: sourceURL, outputExtension: kind.outputExtension)
        case .pdfToWord:
            throw ConversionError.systemConversionUnavailable(kind)
        default:
            throw ConversionError.unsupported(kind)
        }
    }

    private static func convertDWG(
        sourceURL: URL,
        outputExtension: String,
        conversion: (String, String) throws -> Void
    ) throws -> URL {
        let outputURL = try makeOutputURL(sourceURL: sourceURL, outputExtension: outputExtension)

        let isSecurityScoped = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if isSecurityScoped {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        try conversion(sourceURL.path, outputURL.path)

        guard FileManager.default.fileExists(atPath: outputURL.path) else {
            throw ConversionError.missingOutput(outputURL)
        }

        return outputURL
    }

    private static func convertPDF(
        sourceURL: URL,
        outputExtension: String,
        conversion: (String, String) throws -> Void
    ) throws -> URL {
        let outputURL = try makeOutputURL(sourceURL: sourceURL, outputExtension: outputExtension)

        let isSecurityScoped = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if isSecurityScoped {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        try conversion(sourceURL.path, outputURL.path)

        guard FileManager.default.fileExists(atPath: outputURL.path) else {
            throw ConversionError.missingOutput(outputURL)
        }

        return outputURL
    }

    private static func convertPDFToImage(sourceURL: URL, outputExtension: String) throws -> URL {
        let outputURL = try makeOutputURL(sourceURL: sourceURL, outputExtension: outputExtension)
        let isSecurityScoped = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if isSecurityScoped {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        guard let document = PDFDocument(url: sourceURL) else {
            throw ConversionError.invalidPDF(sourceURL)
        }

        guard let page = document.page(at: 0) else {
            throw ConversionError.emptyPDF(sourceURL)
        }

        let pageBounds = page.bounds(for: .mediaBox)
        let imageScale: CGFloat = 2
        let imageSize = CGSize(
            width: max(pageBounds.width * imageScale, 1),
            height: max(pageBounds.height * imageScale, 1)
        )
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: imageSize, format: format)
        let pngData = renderer.pngData { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: imageSize))

            context.cgContext.saveGState()
            context.cgContext.translateBy(x: 0, y: imageSize.height)
            context.cgContext.scaleBy(x: imageScale, y: -imageScale)
            context.cgContext.translateBy(x: -pageBounds.origin.x, y: -pageBounds.origin.y)
            page.draw(with: .mediaBox, to: context.cgContext)
            context.cgContext.restoreGState()
        }

        try pngData.write(to: outputURL, options: .atomic)
        return outputURL
    }

    private static func makeOutputURL(sourceURL: URL, outputExtension: String) throws -> URL {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("CADConversion-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(
            at: temporaryDirectory,
            withIntermediateDirectories: true
        )

        let baseName = sourceURL.deletingPathExtension().lastPathComponent.isEmpty
            ? "converted"
            : sourceURL.deletingPathExtension().lastPathComponent
        return temporaryDirectory
            .appendingPathComponent(baseName, isDirectory: false)
            .appendingPathExtension(outputExtension)
    }
}
