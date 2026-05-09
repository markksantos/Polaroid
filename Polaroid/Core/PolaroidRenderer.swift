import AppKit
import CoreGraphics
import Foundation

struct PolaroidRenderer {
    struct Metrics: Equatable, Sendable {
        let canvasSize: CGSize
        let paperRect: CGRect
        let photoRect: CGRect
        let bottomBorderHeight: CGFloat

        static let base = Metrics(
            canvasSize: CGSize(width: 1240, height: 1480),
            paperRect: CGRect(x: 80, y: 80, width: 1080, height: 1320),
            photoRect: CGRect(x: 130, y: 370, width: 980, height: 980),
            bottomBorderHeight: 290
        )
    }

    struct RenderSummary: Equatable, Sendable {
        let canvasSize: CGSize
        let paperSize: CGSize
        let photoSize: CGSize
        let inputSize: CGSize
        let exportSize: ExportSize
        let frameMode: ExportFrameMode

        var displayText: String {
            let canvas = "\(Int(canvasSize.width))x\(Int(canvasSize.height))"
            let photo = "\(Int(photoSize.width))x\(Int(photoSize.height))"
            let input = "\(Int(inputSize.width))x\(Int(inputSize.height))"
            return "\(canvas) canvas | \(photo) photo | \(input) source | \(frameMode.displayName)"
        }
    }

    private let dateFormatter: DateFormatter

    init() {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM·dd·yy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter = formatter
    }

    func render(
        screenshot: NSImage,
        style: PolaroidStyle,
        caption: String?,
        date: Date,
        texture: CGImage?,
        exportSize: ExportSize = .highRes1920
    ) -> NSImage {
        let requestedSize = targetCanvasSize(for: exportSize, screenshot: screenshot)
        let targetSize = CGSize(
            width: max(1, requestedSize.width.rounded()),
            height: max(1, requestedSize.height.rounded())
        )
        let scale = targetSize.width / Metrics.base.canvasSize.width
        let metrics = scaledMetrics(scale: scale, targetSize: targetSize, exportSize: exportSize)
        guard let context = makeBitmapContext(size: targetSize) else {
            return NSImage(size: targetSize)
        }
        let previousGraphicsContext = NSGraphicsContext.current
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
        defer { NSGraphicsContext.current = previousGraphicsContext }

        context.setFillColor(style.canvasBackground.nsColor.cgColor)
        context.fill(CGRect(origin: .zero, size: targetSize))

        if style.exportFrameMode == .photoOnly {
            drawPhoto(screenshot, in: context, photoRect: CGRect(origin: .zero, size: targetSize))
            return outputImage(from: context, size: targetSize)
        }

        drawShadow(in: context, paperRect: metrics.paperRect, style: style, scale: scale)
        drawPaper(in: context, rect: metrics.paperRect, texture: texture, style: style)
        drawPhoto(screenshot, in: context, photoRect: metrics.photoRect)

        if style.showDateStamp {
            drawDate(date, in: context, photoRect: metrics.photoRect, scale: scale)
        }

        if let caption = normalizedCaption(caption), !caption.isEmpty {
            drawCaption(caption, in: context, paperRect: metrics.paperRect, photoRect: metrics.photoRect, style: style, scale: scale)
        }

        return outputImage(from: context, size: targetSize)
    }

    func targetCanvasSize(for exportSize: ExportSize, screenshot: NSImage) -> CGSize {
        switch exportSize {
        case .square1080:
            return CGSize(width: 1080, height: 1080)
        case .highRes1920:
            return CGSize(width: 1920, height: 2347)
        case .original:
            let longest = max(screenshot.pixelSize.width, screenshot.pixelSize.height)
            let width = max(720, longest)
            return CGSize(width: width, height: width * Metrics.base.canvasSize.height / Metrics.base.canvasSize.width)
        }
    }

    func metrics(for exportSize: ExportSize, screenshot: NSImage) -> Metrics {
        let targetSize = targetCanvasSize(for: exportSize, screenshot: screenshot)
        let scale = targetSize.width / Metrics.base.canvasSize.width
        return scaledMetrics(scale: scale, targetSize: targetSize, exportSize: exportSize)
    }

    func summary(for screenshot: NSImage, style: PolaroidStyle, exportSize: ExportSize) -> RenderSummary {
        let metrics = metrics(for: exportSize, screenshot: screenshot)
        return RenderSummary(
            canvasSize: metrics.canvasSize,
            paperSize: metrics.paperRect.size,
            photoSize: style.exportFrameMode == .photoOnly ? metrics.canvasSize : metrics.photoRect.size,
            inputSize: screenshot.pixelSize,
            exportSize: exportSize,
            frameMode: style.exportFrameMode
        )
    }

    private func scaledMetrics(scale: CGFloat, targetSize: CGSize, exportSize: ExportSize) -> Metrics {
        if exportSize == .square1080 {
            let paperWidth = targetSize.width * 0.82
            let paperHeight = paperWidth * 1320 / 1080
            let paperRect = CGRect(
                x: (targetSize.width - paperWidth) / 2,
                y: (targetSize.height - paperHeight) / 2,
                width: paperWidth,
                height: paperHeight
            )
            let localScale = paperWidth / 1080
            let photoRect = CGRect(
                x: paperRect.minX + 50 * localScale,
                y: paperRect.minY + 290 * localScale,
                width: 980 * localScale,
                height: 980 * localScale
            )
            return Metrics(canvasSize: targetSize, paperRect: paperRect, photoRect: photoRect, bottomBorderHeight: 290 * localScale)
        }

        return Metrics(
            canvasSize: targetSize,
            paperRect: Metrics.base.paperRect.scaled(by: scale),
            photoRect: Metrics.base.photoRect.scaled(by: scale),
            bottomBorderHeight: Metrics.base.bottomBorderHeight * scale
        )
    }

    private func makeBitmapContext(size: CGSize) -> CGContext? {
        let width = Int(size.width)
        let height = Int(size.height)
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        context?.interpolationQuality = .high
        context?.setShouldAntialias(true)
        context?.setAllowsAntialiasing(true)
        return context
    }

    private func outputImage(from context: CGContext, size: CGSize) -> NSImage {
        guard let cgImage = context.makeImage() else {
            return NSImage(size: size)
        }
        return NSImage(cgImage: cgImage, size: size)
    }

    private func drawShadow(in context: CGContext, paperRect: CGRect, style: PolaroidStyle, scale: CGFloat) {
        context.saveGState()
        context.setShadow(
            offset: CGSize(width: 0, height: -style.shadowStrength.offsetY * scale),
            blur: style.shadowStrength.blur * scale,
            color: NSColor.black.withAlphaComponent(style.shadowStrength.opacity).cgColor
        )
        let path = CGPath(roundedRect: paperRect, cornerWidth: 8 * scale, cornerHeight: 8 * scale, transform: nil)
        context.setFillColor(NSColor.white.cgColor)
        context.addPath(path)
        context.fillPath()
        context.restoreGState()
    }

    private func drawPaper(in context: CGContext, rect: CGRect, texture: CGImage?, style: PolaroidStyle) {
        context.saveGState()
        let path = CGPath(roundedRect: rect, cornerWidth: 8 * rect.width / 1080, cornerHeight: 8 * rect.width / 1080, transform: nil)
        context.addPath(path)
        context.clip()

        if let texture {
            context.draw(texture, in: rect)
        } else {
            context.setFillColor(style.paperTexture.fallbackColor.cgColor)
            context.fill(rect)
        }

        context.setStrokeColor(NSColor.black.withAlphaComponent(0.06).cgColor)
        context.setLineWidth(max(1, rect.width / 540))
        context.addPath(path)
        context.strokePath()
        context.restoreGState()
    }

    private func drawPhoto(_ screenshot: NSImage, in context: CGContext, photoRect: CGRect) {
        context.saveGState()
        context.addRect(photoRect)
        context.clip()

        context.setFillColor(NSColor(calibratedWhite: 0.08, alpha: 1).cgColor)
        context.fill(photoRect)

        guard let cgImage = screenshot.bestCGImage() else {
            context.restoreGState()
            return
        }

        let fitted = CGSize(width: cgImage.width, height: cgImage.height).aspectFit(in: photoRect)
        context.draw(cgImage, in: fitted)
        context.restoreGState()
    }

    private func drawCaption(
        _ caption: String,
        in context: CGContext,
        paperRect: CGRect,
        photoRect: CGRect,
        style: PolaroidStyle,
        scale: CGFloat
    ) {
        let font = style.handwritingFont.nsFont(size: 58 * scale * style.captionSize.fontScale)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = style.captionAlignment.textAlignment
        paragraph.lineBreakMode = .byTruncatingTail

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: style.inkColor.nsColor.withAlphaComponent(0.96),
            .paragraphStyle: paragraph,
            .kern: 0.4 * scale
        ]

        let text = NSAttributedString(string: caption, attributes: attributes)
        let rect = CGRect(
            x: paperRect.minX + 80 * scale,
            y: paperRect.minY + style.captionPosition.yOffset * scale,
            width: paperRect.width - 160 * scale,
            height: max(72 * scale, photoRect.minY - paperRect.minY - 120 * scale)
        )
        text.draw(in: rect)
    }

    private func drawDate(_ date: Date, in context: CGContext, photoRect: CGRect, scale: CGFloat) {
        let dateText = dateFormatter.string(from: date)
        let font = NSFont.monospacedDigitSystemFont(ofSize: 22 * scale, weight: .semibold)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor(calibratedRed: 0.545, green: 0.271, blue: 0.075, alpha: 0.88),
            .kern: 1.1 * scale
        ]
        let attributed = NSAttributedString(string: dateText, attributes: attributes)
        let size = attributed.size()
        let inset = 18 * scale
        let rect = CGRect(
            x: photoRect.maxX - size.width - inset,
            y: photoRect.minY + inset,
            width: size.width + 4 * scale,
            height: size.height + 4 * scale
        )
        attributed.draw(in: rect)
    }

    private func normalizedCaption(_ caption: String?) -> String? {
        caption?
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .prefix(60)
            .description
    }
}

private extension PaperTexture {
    var fallbackColor: NSColor {
        switch self {
        case .cleanWhite:
            NSColor(calibratedWhite: 1, alpha: 1)
        case .agedCream:
            NSColor(calibratedRed: 0.973, green: 0.949, blue: 0.894, alpha: 1)
        case .worn:
            NSColor(calibratedRed: 0.957, green: 0.925, blue: 0.843, alpha: 1)
        case .coolGray:
            NSColor(calibratedRed: 0.941, green: 0.949, blue: 0.957, alpha: 1)
        }
    }
}

private extension CGRect {
    func scaled(by scale: CGFloat) -> CGRect {
        CGRect(x: minX * scale, y: minY * scale, width: width * scale, height: height * scale)
    }
}

private extension CGSize {
    func aspectFit(in rect: CGRect) -> CGRect {
        guard width > 0, height > 0 else {
            return rect
        }

        let scale = min(rect.width / width, rect.height / height)
        let fitSize = CGSize(width: width * scale, height: height * scale)
        return CGRect(
            x: rect.midX - fitSize.width / 2,
            y: rect.midY - fitSize.height / 2,
            width: fitSize.width,
            height: fitSize.height
        )
    }
}

private extension NSImage {
    var pixelSize: CGSize {
        if let representation = representations.first {
            return CGSize(width: representation.pixelsWide, height: representation.pixelsHigh)
        }
        return size
    }

    func bestCGImage() -> CGImage? {
        var proposed = CGRect(origin: .zero, size: size)
        return cgImage(forProposedRect: &proposed, context: nil, hints: nil)
    }
}
