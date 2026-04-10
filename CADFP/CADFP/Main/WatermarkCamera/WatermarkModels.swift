//
//  WatermarkModels.swift
//  CADFP
//
//  Created by Codex on 2026/4/10.
//

import CoreGraphics
import Foundation
import SwiftUI
import UIKit

enum WatermarkCardContext {
    case preview
    case export
    case thumbnail
}

struct WatermarkDraft: Equatable {
    static let unavailableLocationText = "无法获取当前定位"

    var title: String
    var area: String
    var content: String
    var company: String
    var address: String
    var captureDate: Date

    static func seeded() -> WatermarkDraft {
        WatermarkDraft(
            title: "",
            area: "",
            content: "",
            company: "",
            address: unavailableLocationText,
            captureDate: Date()
        )
    }
}

struct WatermarkOverlayContent: Equatable {
    var title: String?
    var badgeText: String?
    var timeText: String?
    var primaryLines: [String]
    var footerLine: String?
}

enum WatermarkTemplateStyle: String, CaseIterable, Identifiable {
    case classic
    case punchCard

    var id: String { rawValue }

    var title: String {
        switch self {
        case .classic:
            return "经典信息卡"
        case .punchCard:
            return "打卡样式"
        }
    }

    func makeOverlayContent(from draft: WatermarkDraft) -> WatermarkOverlayContent {
        switch self {
        case .classic:
            return WatermarkOverlayContent(
                title: draft.title.normalized(or: "未填写标题"),
                badgeText: nil,
                timeText: nil,
                primaryLines: [
                    "施工区域:\(draft.area.normalized(or: "未填写施工区域"))",
                    "施工内容:\(draft.content.normalized(or: "未填写施工内容"))",
                    "拍摄时间:\(WatermarkDateFormatter.classicTimestamp.string(from: draft.captureDate))",
                    "地址:\(draft.address.normalized(or: WatermarkDraft.unavailableLocationText))"
                ],
                footerLine: "施工单位:\(draft.company.normalized(or: "未填写施工单位"))"
            )
        case .punchCard:
            return WatermarkOverlayContent(
                title: nil,
                badgeText: "打卡",
                timeText: WatermarkDateFormatter.clock.string(from: draft.captureDate),
                primaryLines: [
                    "地址：\(draft.address.normalized(or: WatermarkDraft.unavailableLocationText))",
                    "时间：\(WatermarkDateFormatter.weekdayAndDateString(from: draft.captureDate))"
                ],
                footerLine: nil
            )
        }
    }

    func exportFrame(in canvas: CGSize) -> CGRect {
        switch self {
        case .classic:
            CGRect(
                x: canvas.width * 0.0407407407,
                y: canvas.height * 0.7598958333,
                width: canvas.width * 0.5296296296,
                height: canvas.height * 0.1953125
            )
        case .punchCard:
            CGRect(
                x: canvas.width * 0.0610687023,
                y: canvas.height * 0.7555865922,
                width: canvas.width * 0.5826972010,
                height: canvas.height * 0.1167597765
            )
        }
    }

    func exportFrame(in canvas: CGSize, content: WatermarkOverlayContent) -> CGRect {
        positionedFrame(in: canvas, content: content, context: .export, offsetRatio: .zero)
    }

    func exportFrame(in canvas: CGSize, content: WatermarkOverlayContent, offsetRatio: CGSize) -> CGRect {
        positionedFrame(in: canvas, content: content, context: .export, offsetRatio: offsetRatio)
    }

    func previewFrame(in previewSize: CGSize) -> CGRect {
        exportFrame(in: previewSize)
    }

    func previewFrame(in previewSize: CGSize, content: WatermarkOverlayContent) -> CGRect {
        positionedFrame(in: previewSize, content: content, context: .preview, offsetRatio: .zero)
    }

    func previewFrame(in previewSize: CGSize, content: WatermarkOverlayContent, offsetRatio: CGSize) -> CGRect {
        positionedFrame(in: previewSize, content: content, context: .preview, offsetRatio: offsetRatio)
    }

    var previewSelectionSize: CGSize {
        switch self {
        case .classic:
            return CGSize(width: 154, height: 86)
        case .punchCard:
            return CGSize(width: 172, height: 90)
        }
    }

    func classicLayoutMetrics(
        for content: WatermarkOverlayContent,
        width: CGFloat,
        minimumHeight: CGFloat,
        context: WatermarkCardContext
    ) -> ClassicWatermarkLayoutMetrics {
        let titleFontSize = max(context == .thumbnail ? 10 : 12, width * (context == .thumbnail ? 0.056 : 0.066))
        let bodyFontSize = max(context == .thumbnail ? 7 : 8, width * (context == .thumbnail ? 0.039 : 0.047))
        let footerFontSize = max(context == .thumbnail ? 8 : 9, width * (context == .thumbnail ? 0.046 : 0.056))
        let horizontalPadding = width * (context == .thumbnail ? 0.05 : 0.06)
        let titleTopInset = width * (context == .thumbnail ? 0.02 : 0.03)
        let titleBottomInset = width * (context == .thumbnail ? 0.02 : 0.028)
        let headerMinHeight = width * (context == .thumbnail ? 0.11 : 0.13)
        let footerTopInset = width * (context == .thumbnail ? 0.022 : 0.03)
        let footerBottomInset = width * (context == .thumbnail ? 0.02 : 0.03)
        let bodyTopInset = width * (context == .thumbnail ? 0.04 : 0.07)
        let bodyBottomInset = width * (context == .thumbnail ? 0.04 : 0.07)
        let bodyLineSpacing = width * (context == .thumbnail ? 0.014 : 0.018)
        let lineLimit = context == .thumbnail ? 1 : nil
        let textWidth = max(1, width - horizontalPadding * 2)

        let titleFont = UIFont.systemFont(ofSize: titleFontSize, weight: .bold)
        let bodyFont = UIFont.systemFont(ofSize: bodyFontSize, weight: .medium)
        let footerFont = UIFont.systemFont(ofSize: footerFontSize, weight: .medium)

        let titleHeight = WatermarkTextMeasurer.height(
            for: content.title ?? "",
            font: titleFont,
            width: textWidth,
            lineLimit: lineLimit
        )
        let footerHeight = WatermarkTextMeasurer.height(
            for: content.footerLine ?? "",
            font: footerFont,
            width: textWidth,
            lineLimit: lineLimit
        )
        let lineHeights = content.primaryLines.map {
            WatermarkTextMeasurer.height(for: $0, font: bodyFont, width: textWidth, lineLimit: lineLimit)
        }

        let topBandHeight = max(headerMinHeight, titleHeight + titleTopInset + titleBottomInset)
        let bottomBandHeight = max(headerMinHeight, footerHeight + footerTopInset + footerBottomInset)
        let contentLinesHeight = lineHeights.reduce(0, +)
        let contentLinesSpacing = max(0, CGFloat(max(content.primaryLines.count - 1, 0))) * bodyLineSpacing
        let baseMiddleHeight = bodyTopInset + contentLinesHeight + contentLinesSpacing + bodyBottomInset
        let totalBaseHeight = topBandHeight + baseMiddleHeight + bottomBandHeight
        let extraHeight = max(0, minimumHeight - totalBaseHeight)
        let middleHeight = baseMiddleHeight + extraHeight

        return ClassicWatermarkLayoutMetrics(
            cornerRadius: width * 0.038,
            titleFont: titleFont,
            bodyFont: bodyFont,
            footerFont: footerFont,
            horizontalPadding: horizontalPadding,
            titleTopInset: titleTopInset,
            titleBottomInset: titleBottomInset,
            topBandHeight: topBandHeight,
            bodyTopInset: bodyTopInset,
            bodyBottomInset: bodyBottomInset + extraHeight,
            bodyLineSpacing: bodyLineSpacing,
            middleHeight: middleHeight,
            footerTopInset: footerTopInset,
            footerBottomInset: footerBottomInset,
            bottomBandHeight: bottomBandHeight,
            lineLimit: lineLimit
        )
    }

    func punchLayoutMetrics(
        for content: WatermarkOverlayContent,
        width: CGFloat,
        minimumHeight: CGFloat,
        context: WatermarkCardContext
    ) -> PunchCardLayoutMetrics {
        let badgeHeight = max(context == .thumbnail ? 24 : 24, width * (context == .thumbnail ? 0.2 : 0.125))
        let badgeWidth = width * (context == .thumbnail ? 0.48 : 0.39)
        let badgeLabelWidth = badgeWidth * (context == .thumbnail ? 0.38 : 0.35)
        let badgeInnerPadding = badgeWidth * (context == .thumbnail ? 0.045 : 0.055)
        let topPadding = width * (context == .thumbnail ? 0.04 : 0.03)
        let bottomPadding = width * (context == .thumbnail ? 0.04 : 0.035)
        let leadingPadding = width * (context == .thumbnail ? 0.018 : 0.02)
        let bodySpacing = width * (context == .thumbnail ? 0.035 : 0.045)
        let bodyLineSpacing = width * (context == .thumbnail ? 0.016 : 0.02)
        let bodyWidth = max(1, width - leadingPadding * 2)
        let lineLimit = context == .thumbnail ? 1 : nil

        let badgeFont = UIFont.systemFont(
            ofSize: max(context == .thumbnail ? 8 : 9, badgeHeight * (context == .thumbnail ? 0.34 : 0.36)),
            weight: .bold
        )
        let timeFont = UIFont.systemFont(
            ofSize: max(context == .thumbnail ? 10 : 12, badgeHeight * (context == .thumbnail ? 0.42 : 0.46)),
            weight: .bold
        )
        let bodyFont = UIFont.systemFont(ofSize: max(context == .thumbnail ? 6.5 : 7, width * (context == .thumbnail ? 0.037 : 0.05)), weight: .medium)

        let lineHeights = content.primaryLines.map {
            WatermarkTextMeasurer.height(for: $0, font: bodyFont, width: bodyWidth, lineLimit: lineLimit)
        }
        let linesHeight = lineHeights.reduce(0, +)
        let linesSpacing = max(0, CGFloat(max(content.primaryLines.count - 1, 0))) * bodyLineSpacing
        let baseHeight = topPadding + badgeHeight + bodySpacing + linesHeight + linesSpacing + bottomPadding
        let extraHeight = max(0, minimumHeight - baseHeight)

        return PunchCardLayoutMetrics(
            badgeHeight: badgeHeight,
            badgeWidth: badgeWidth,
            badgeLabelWidth: badgeLabelWidth,
            badgeInnerPadding: badgeInnerPadding,
            badgeFont: badgeFont,
            timeFont: timeFont,
            bodyFont: bodyFont,
            topPadding: topPadding,
            bottomPadding: bottomPadding + extraHeight,
            leadingPadding: leadingPadding,
            bodySpacing: bodySpacing,
            bodyLineSpacing: bodyLineSpacing,
            bodyWidth: bodyWidth,
            bodyContentHeight: linesHeight + linesSpacing,
            lineLimit: lineLimit
        )
    }

    func clampedOffsetRatio(
        in canvas: CGSize,
        content: WatermarkOverlayContent,
        proposedOffsetRatio: CGSize,
        context: WatermarkCardContext
    ) -> CGSize {
        let baseFrame = contentSizedFrame(in: canvas, content: content, context: context)
        let clampedFrame = positionedFrame(
            in: canvas,
            content: content,
            context: context,
            offsetRatio: proposedOffsetRatio
        )

        guard canvas.width > 0, canvas.height > 0 else {
            return .zero
        }

        return CGSize(
            width: (clampedFrame.minX - baseFrame.minX) / canvas.width,
            height: (clampedFrame.minY - baseFrame.minY) / canvas.height
        )
    }

    private func positionedFrame(
        in canvas: CGSize,
        content: WatermarkOverlayContent,
        context: WatermarkCardContext,
        offsetRatio: CGSize
    ) -> CGRect {
        let baseFrame = contentSizedFrame(in: canvas, content: content, context: context)
        let translatedFrame = baseFrame.offsetBy(
            dx: offsetRatio.width * canvas.width,
            dy: offsetRatio.height * canvas.height
        )

        return translatedFrame.clamped(within: CGRect(origin: .zero, size: canvas))
    }

    private func contentSizedFrame(
        in canvas: CGSize,
        content: WatermarkOverlayContent,
        context: WatermarkCardContext
    ) -> CGRect {
        let baseFrame = exportFrame(in: canvas)
        let height = switch self {
        case .classic:
            classicLayoutMetrics(
                for: content,
                width: baseFrame.width,
                minimumHeight: baseFrame.height,
                context: context
            ).totalHeight
        case .punchCard:
            punchLayoutMetrics(
                for: content,
                width: baseFrame.width,
                minimumHeight: baseFrame.height,
                context: context
            ).totalHeight
        }

        return CGRect(
            x: baseFrame.minX,
            y: baseFrame.maxY - height,
            width: baseFrame.width,
            height: height
        )
    }
}

enum WatermarkDateFormatter {
    static let shanghaiTimeZone = TimeZone(identifier: "Asia/Shanghai") ?? .current

    static let classicTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = shanghaiTimeZone
        formatter.dateFormat = "yyyy.MM.dd HH:mm:ss"
        return formatter
    }()

    static let clock: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = shanghaiTimeZone
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    static let dateOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = shanghaiTimeZone
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()

    static func weekdayAndDateString(from date: Date) -> String {
        let calendar = Calendar(identifier: .gregorian)
        let weekday = calendar.component(.weekday, from: date)
        let weekdayText = switch weekday {
        case 1: "星期日"
        case 2: "星期一"
        case 3: "星期二"
        case 4: "星期三"
        case 5: "星期四"
        case 6: "星期五"
        default: "星期六"
        }

        return "\(weekdayText) \(dateOnly.string(from: date))"
    }
}

enum WatermarkPhotoComposer {
    @MainActor
    static func compose(
        photo: UIImage,
        draft: WatermarkDraft,
        style: WatermarkTemplateStyle,
        offsetRatio: CGSize = .zero
    ) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: photo.size, format: format)

        return renderer.image { _ in
            photo.draw(in: CGRect(origin: .zero, size: photo.size))

            let overlayContent = style.makeOverlayContent(from: draft)
            let overlayFrame = style.exportFrame(
                in: photo.size,
                content: overlayContent,
                offsetRatio: offsetRatio
            )
            let overlayView = WatermarkTemplateCard(
                style: style,
                content: overlayContent,
                cardSize: overlayFrame.size,
                context: .export
            )
            .frame(width: overlayFrame.width, height: overlayFrame.height)

            let imageRenderer = ImageRenderer(content: overlayView)
            imageRenderer.scale = 1

            if let overlayImage = imageRenderer.uiImage {
                overlayImage.draw(in: overlayFrame)
            }
        }
    }

    static func placeholderPhoto(size: CGSize = CGSize(width: 1080, height: 1920)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let colors = [UIColor(white: 0.37, alpha: 1).cgColor, UIColor(white: 0.21, alpha: 1).cgColor] as CFArray
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
            context.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: size.width / 2, y: 0),
                end: CGPoint(x: size.width / 2, y: size.height),
                options: []
            )
        }
    }
}

struct ClassicWatermarkLayoutMetrics {
    let cornerRadius: CGFloat
    let titleFont: UIFont
    let bodyFont: UIFont
    let footerFont: UIFont
    let horizontalPadding: CGFloat
    let titleTopInset: CGFloat
    let titleBottomInset: CGFloat
    let topBandHeight: CGFloat
    let bodyTopInset: CGFloat
    let bodyBottomInset: CGFloat
    let bodyLineSpacing: CGFloat
    let middleHeight: CGFloat
    let footerTopInset: CGFloat
    let footerBottomInset: CGFloat
    let bottomBandHeight: CGFloat
    let lineLimit: Int?

    var totalHeight: CGFloat {
        topBandHeight + middleHeight + bottomBandHeight
    }
}

struct PunchCardLayoutMetrics {
    let badgeHeight: CGFloat
    let badgeWidth: CGFloat
    let badgeLabelWidth: CGFloat
    let badgeInnerPadding: CGFloat
    let badgeFont: UIFont
    let timeFont: UIFont
    let bodyFont: UIFont
    let topPadding: CGFloat
    let bottomPadding: CGFloat
    let leadingPadding: CGFloat
    let bodySpacing: CGFloat
    let bodyLineSpacing: CGFloat
    let bodyWidth: CGFloat
    let bodyContentHeight: CGFloat
    let lineLimit: Int?

    var totalHeight: CGFloat {
        topPadding + badgeHeight + bodySpacing + bodyContentHeight + bottomPadding
    }
}

private enum WatermarkTextMeasurer {
    static func height(for text: String, font: UIFont, width: CGFloat, lineLimit: Int?) -> CGFloat {
        guard !text.isEmpty else {
            return font.lineHeight
        }

        let measured = NSString(string: text).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        ).height
        let height = max(font.lineHeight, ceil(measured))

        guard let lineLimit else {
            return height
        }

        return min(height, ceil(font.lineHeight * CGFloat(lineLimit)))
    }
}

private extension String {
    func normalized(or fallback: String) -> String {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }
}

private extension CGRect {
    func clamped(within bounds: CGRect) -> CGRect {
        guard width <= bounds.width, height <= bounds.height else {
            return self
        }

        let clampedMinX = min(max(minX, bounds.minX), bounds.maxX - width)
        let clampedMinY = min(max(minY, bounds.minY), bounds.maxY - height)

        return CGRect(x: clampedMinX, y: clampedMinY, width: width, height: height)
    }
}
