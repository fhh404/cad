import Foundation
import SwiftUI

enum ConversionKind: String, CaseIterable, Codable, Hashable, Identifiable {
    case dwgToPdf
    case modelToStp
    case pdfToDwg
    case pdfToWord
    case pdfToImage
    case dwgToImage
    case dwgToDxf

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dwgToPdf:
            return "DWG转PDF"
        case .modelToStp:
            return "3D转STP"
        case .pdfToDwg:
            return "PDF转DWG"
        case .pdfToWord:
            return "PDF转Word"
        case .pdfToImage:
            return "PDF转图片"
        case .dwgToImage:
            return "DWG转图片"
        case .dwgToDxf:
            return "DWG转DXF"
        }
    }

    var sourceExtension: String {
        switch self {
        case .dwgToPdf, .dwgToImage, .dwgToDxf:
            return "DWG"
        case .modelToStp:
            return "3D"
        case .pdfToDwg, .pdfToWord, .pdfToImage:
            return "PDF"
        }
    }

    var outputExtension: String {
        switch self {
        case .dwgToPdf:
            return "pdf"
        case .modelToStp:
            return "stp"
        case .pdfToDwg:
            return "dwg"
        case .pdfToWord:
            return "docx"
        case .pdfToImage, .dwgToImage:
            return "png"
        case .dwgToDxf:
            return "dxf"
        }
    }

    var completionSubtitle: String {
        "\(sourceExtension)文件转\(outputExtension.uppercased())文件"
    }

    var defaultSourceFileName: String {
        switch self {
        case .modelToStp:
            return "模型 示例 -1.obj"
        case .pdfToDwg, .pdfToWord, .pdfToImage:
            return "示例 -1.pdf"
        case .dwgToPdf, .dwgToImage, .dwgToDxf:
            return "DWG 示例 -1.dwg"
        }
    }

    var defaultOutputFileName: String {
        let baseName = (defaultSourceFileName as NSString).deletingPathExtension
        return "\(baseName).\(outputExtension)"
    }

    var accentColor: Color {
        switch self {
        case .dwgToPdf:
            return Color(red: 73 / 255, green: 206 / 255, blue: 224 / 255)
        case .modelToStp:
            return Color(red: 247 / 255, green: 169 / 255, blue: 56 / 255)
        case .pdfToDwg:
            return Color(red: 255 / 255, green: 108 / 255, blue: 133 / 255)
        case .pdfToWord:
            return Color(red: 64 / 255, green: 110 / 255, blue: 255 / 255)
        case .pdfToImage, .dwgToImage:
            return Color(red: 98 / 255, green: 89 / 255, blue: 247 / 255)
        case .dwgToDxf:
            return Color(red: 39 / 255, green: 204 / 255, blue: 122 / 255)
        }
    }
}

struct ConversionDocument: Codable, Hashable, Identifiable {
    let id: UUID
    let kind: ConversionKind
    let fileName: String
    let createdAt: Date
    let relativePath: String

    var fileURL: URL {
        ConversionDocumentStore.defaultBaseDirectory
            .appendingPathComponent(relativePath, isDirectory: false)
    }

    func fileURL(relativeTo baseDirectory: URL) -> URL {
        baseDirectory.appendingPathComponent(relativePath, isDirectory: false)
    }
}

extension HomeAction {
    var conversionKind: ConversionKind? {
        switch self {
        case .dwgToPdf:
            return .dwgToPdf
        case .modelToStp:
            return .modelToStp
        case .pdfToDwg:
            return .pdfToDwg
        case .pdfToWord:
            return .pdfToWord
        case .pdfToImage:
            return .pdfToImage
        case .dwgToImage:
            return .dwgToImage
        case .dwgToDxf:
            return .dwgToDxf
        default:
            return nil
        }
    }
}
