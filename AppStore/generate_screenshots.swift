import AppKit
import Foundation

let outputDirectory = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .appendingPathComponent("Screenshots", isDirectory: true)
try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

let size = CGSize(width: 2880, height: 1800)

let scenes: [(String, String, NSColor)] = [
    ("Desktop screenshots become instant film", "Auto-watch Desktop catches new screenshots and starts the develop animation.", NSColor(hex: 0xA84636)),
    ("Write it like a real Polaroid", "Tap the bottom border, add a caption, and choose the ink.", NSColor(hex: 0x2C5530)),
    ("Paper with actual texture", "Clean white, aged cream, worn, and cool gray are generated locally.", NSColor(hex: 0x6B8FB5)),
    ("Save, copy, or share in seconds", "Export a polished PNG to Pictures, clipboard, or the macOS share sheet.", NSColor(hex: 0x1B3A5C)),
    ("Recent Polaroids in the menu bar", "Reopen the last five exports without digging through folders.", NSColor(hex: 0x8B4513)),
    ("Local-only by design", "Sandboxed settings for watcher behavior, appearance, and export size.", NSColor(hex: 0x4A4A4A))
]

for (index, scene) in scenes.enumerated() {
    // Render into an explicit 1x bitmap so output is always exactly `size`
    // in pixels, regardless of the display's backing scale factor.
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(size.width),
        pixelsHigh: Int(size.height),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        fatalError("Could not allocate bitmap for screenshot \(index + 1)")
    }

    guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        fatalError("Could not create graphics context for screenshot \(index + 1)")
    }

    let previous = NSGraphicsContext.current
    NSGraphicsContext.current = context
    defer { NSGraphicsContext.current = previous }

    drawBackground(size: size, accent: scene.2)
    drawWindow(size: size, index: index, title: scene.0, subtitle: scene.1, accent: scene.2)

    context.flushGraphics()

    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("Could not encode screenshot \(index + 1) as PNG")
    }

    let url = outputDirectory.appendingPathComponent(String(format: "%02d-polaroid.png", index + 1))
    try data.write(to: url, options: [.atomic])
}

func drawBackground(size: CGSize, accent: NSColor) {
    let rect = CGRect(origin: .zero, size: size)
    NSColor(hex: 0xF1EEE8).setFill()
    rect.fill()

    accent.withAlphaComponent(0.16).setFill()
    NSBezierPath(ovalIn: CGRect(x: size.width - 780, y: -260, width: 980, height: 980)).fill()
    NSColor(hex: 0xE0C58D).withAlphaComponent(0.18).setFill()
    NSBezierPath(ovalIn: CGRect(x: -280, y: size.height - 720, width: 880, height: 880)).fill()
}

func drawWindow(size: CGSize, index: Int, title: String, subtitle: String, accent: NSColor) {
    let window = CGRect(x: 220, y: 160, width: 2440, height: 1480)
    shadow(window, radius: 48, y: -18)
    rounded(window, radius: 26, color: NSColor(hex: 0xFBFAF7))

    rounded(CGRect(x: window.minX, y: window.maxY - 92, width: window.width, height: 92), radius: 26, color: NSColor(hex: 0xF5F2EC))
    drawTrafficLights(origin: CGPoint(x: window.minX + 40, y: window.maxY - 56))
    drawText("Polaroid", in: CGRect(x: window.midX - 140, y: window.maxY - 62, width: 280, height: 36), size: 22, weight: .semibold, color: NSColor(hex: 0x2A2523), alignment: .center)

    drawText(title, in: CGRect(x: 320, y: 1380, width: 940, height: 70), size: 42, weight: .bold, color: NSColor(hex: 0x211B18), alignment: .left)
    drawText(subtitle, in: CGRect(x: 320, y: 1324, width: 960, height: 42), size: 24, weight: .regular, color: NSColor(hex: 0x6D625D), alignment: .left)

    drawToolbar(window: window, accent: accent)
    drawPolaroid(center: CGPoint(x: 1400, y: 770), rotation: -4 + CGFloat(index % 3) * 3, accent: accent, caption: caption(for: index), stamp: stamp(for: index))

    switch index {
    case 1:
        drawCaptionPopover(accent: accent)
    case 2:
        drawStylePanel(accent: accent)
    case 3:
        drawExportPanel(accent: accent)
    case 4:
        drawMenuPanel(accent: accent)
    case 5:
        drawSettingsPanel(accent: accent)
    default:
        drawDevelopBadge(accent: accent)
    }
}

func drawToolbar(window: CGRect, accent: NSColor) {
    let y = window.maxY - 156
    let labels = ["New", "Develop", "Style", "Save", "Copy", "Share"]
    for (idx, label) in labels.enumerated() {
        let rect = CGRect(x: window.maxX - 760 + CGFloat(idx) * 112, y: y, width: 92, height: 44)
        rounded(rect, radius: 12, color: idx == 2 ? accent.withAlphaComponent(0.16) : NSColor(hex: 0xEFEAE2))
        drawText(label, in: rect.insetBy(dx: 8, dy: 10), size: 15, weight: .semibold, color: idx == 2 ? accent : NSColor(hex: 0x4D4540), alignment: .center)
    }
}

func drawPolaroid(center: CGPoint, rotation: CGFloat, accent: NSColor, caption: String, stamp: String) {
    let paper = CGRect(x: -390, y: -476, width: 780, height: 954)
    NSGraphicsContext.current?.cgContext.saveGState()
    let transform = NSAffineTransform()
    transform.translateX(by: center.x, yBy: center.y)
    transform.rotate(byDegrees: rotation)
    transform.concat()

    shadow(paper, radius: 30, y: -12)
    rounded(paper, radius: 8, color: NSColor(hex: 0xFFF7E8))

    NSColor(hex: 0xF1E5CF).withAlphaComponent(0.24).setFill()
    paper.insetBy(dx: 0, dy: 0).fill(using: .sourceAtop)

    let photo = CGRect(x: -354, y: -246, width: 708, height: 708)
    NSColor(hex: 0x161B22).setFill()
    photo.fill()
    drawFakePhoto(photo, accent: accent)
    drawText(stamp, in: CGRect(x: photo.maxX - 112, y: photo.minY + 16, width: 92, height: 24), size: 18, weight: .semibold, color: NSColor(hex: 0x8B4513), alignment: .right, monospaced: true)
    drawText(caption, in: CGRect(x: paper.minX + 70, y: paper.minY + 78, width: paper.width - 140, height: 70), size: 38, weight: .regular, color: NSColor(hex: 0x1A1A1A), alignment: .center)

    NSGraphicsContext.current?.cgContext.restoreGState()
}

func drawFakePhoto(_ rect: CGRect, accent: NSColor) {
    NSColor(hex: 0x243447).setFill()
    rect.fill()
    accent.withAlphaComponent(0.80).setFill()
    NSBezierPath(ovalIn: CGRect(x: rect.minX + 80, y: rect.minY + 120, width: 190, height: 190)).fill()
    NSColor(hex: 0xF1C66D).setFill()
    NSBezierPath(ovalIn: CGRect(x: rect.maxX - 210, y: rect.maxY - 210, width: 120, height: 120)).fill()
    NSColor(hex: 0xDDE8EA).withAlphaComponent(0.88).setFill()
    NSBezierPath(rect: CGRect(x: rect.minX + 90, y: rect.minY + 330, width: rect.width - 180, height: 28)).fill()
    NSBezierPath(rect: CGRect(x: rect.minX + 90, y: rect.minY + 390, width: rect.width - 250, height: 28)).fill()
    NSColor(hex: 0xE9A55D).setFill()
    let path = NSBezierPath()
    path.move(to: CGPoint(x: rect.minX, y: rect.minY))
    path.line(to: CGPoint(x: rect.minX + 220, y: rect.minY + 220))
    path.line(to: CGPoint(x: rect.minX + 390, y: rect.minY + 90))
    path.line(to: CGPoint(x: rect.minX + 560, y: rect.minY + 270))
    path.line(to: CGPoint(x: rect.maxX, y: rect.minY))
    path.close()
    path.fill()
}

func drawDevelopBadge(accent: NSColor) {
    let rect = CGRect(x: 1840, y: 1220, width: 440, height: 86)
    rounded(rect, radius: 18, color: accent)
    drawText("Developing...", in: rect.insetBy(dx: 28, dy: 22), size: 28, weight: .bold, color: .white, alignment: .center)
}

func drawCaptionPopover(accent: NSColor) {
    let rect = CGRect(x: 1780, y: 500, width: 600, height: 240)
    shadow(rect, radius: 22, y: -8)
    rounded(rect, radius: 18, color: NSColor(hex: 0xFFFFFF))
    drawText("Caption", in: CGRect(x: rect.minX + 36, y: rect.maxY - 68, width: 220, height: 32), size: 25, weight: .bold, color: NSColor(hex: 0x211B18), alignment: .left)
    rounded(CGRect(x: rect.minX + 34, y: rect.minY + 72, width: rect.width - 68, height: 62), radius: 12, color: NSColor(hex: 0xF6F1EA))
    drawText("ship it", in: CGRect(x: rect.minX + 54, y: rect.minY + 83, width: rect.width - 108, height: 40), size: 30, weight: .regular, color: accent, alignment: .center)
}

func drawStylePanel(accent: NSColor) {
    let rect = CGRect(x: 1800, y: 420, width: 560, height: 480)
    shadow(rect, radius: 22, y: -8)
    rounded(rect, radius: 18, color: .white)
    drawText("Style", in: CGRect(x: rect.minX + 34, y: rect.maxY - 66, width: 200, height: 32), size: 25, weight: .bold, color: NSColor(hex: 0x211B18), alignment: .left)
    let colors: [NSColor] = [.black, NSColor(hex: 0x1B3A5C), NSColor(hex: 0xA0282E), NSColor(hex: 0x2C5530), NSColor(hex: 0x6B8FB5), NSColor(hex: 0x4A4A4A)]
    for (idx, color) in colors.enumerated() {
        color.setFill()
        NSBezierPath(ovalIn: CGRect(x: rect.minX + 44 + CGFloat(idx) * 74, y: rect.minY + 80, width: 44, height: 44)).fill()
    }
    for idx in 0..<4 {
        rounded(CGRect(x: rect.minX + 40, y: rect.maxY - 138 - CGFloat(idx) * 72, width: rect.width - 80, height: 48), radius: 10, color: idx == 1 ? accent.withAlphaComponent(0.14) : NSColor(hex: 0xF5F2EC))
    }
}

func drawExportPanel(accent: NSColor) {
    let rect = CGRect(x: 1840, y: 500, width: 500, height: 350)
    shadow(rect, radius: 22, y: -8)
    rounded(rect, radius: 18, color: .white)
    for (idx, label) in ["Save PNG", "Copy image", "Share sheet"].enumerated() {
        let row = CGRect(x: rect.minX + 36, y: rect.maxY - 96 - CGFloat(idx) * 84, width: rect.width - 72, height: 58)
        rounded(row, radius: 12, color: idx == 0 ? accent.withAlphaComponent(0.16) : NSColor(hex: 0xF5F2EC))
        drawText(label, in: row.insetBy(dx: 22, dy: 14), size: 22, weight: .semibold, color: NSColor(hex: 0x211B18), alignment: .left)
    }
}

func drawMenuPanel(accent: NSColor) {
    let rect = CGRect(x: 1840, y: 570, width: 500, height: 500)
    shadow(rect, radius: 22, y: -8)
    rounded(rect, radius: 18, color: .white)
    drawText("Recent Polaroids", in: CGRect(x: rect.minX + 34, y: rect.maxY - 68, width: 260, height: 32), size: 23, weight: .bold, color: NSColor(hex: 0x211B18), alignment: .left)
    for idx in 0..<5 {
        let rowY = rect.maxY - 132 - CGFloat(idx) * 74
        rounded(CGRect(x: rect.minX + 34, y: rowY, width: 52, height: 58), radius: 4, color: idx == 0 ? accent.withAlphaComponent(0.26) : NSColor(hex: 0xF5F2EC))
        drawText("Polaroid \(idx + 1)", in: CGRect(x: rect.minX + 106, y: rowY + 14, width: 260, height: 28), size: 18, weight: .semibold, color: NSColor(hex: 0x211B18), alignment: .left)
    }
}

func drawSettingsPanel(accent: NSColor) {
    let rect = CGRect(x: 1740, y: 380, width: 690, height: 650)
    shadow(rect, radius: 22, y: -8)
    rounded(rect, radius: 18, color: .white)
    drawText("Settings", in: CGRect(x: rect.minX + 36, y: rect.maxY - 68, width: 220, height: 32), size: 26, weight: .bold, color: NSColor(hex: 0x211B18), alignment: .left)
    for (idx, label) in ["Auto-watch Desktop", "Skip develop animation", "Show date stamp", "High-res export"].enumerated() {
        let row = CGRect(x: rect.minX + 38, y: rect.maxY - 140 - CGFloat(idx) * 92, width: rect.width - 76, height: 62)
        rounded(row, radius: 12, color: NSColor(hex: 0xF5F2EC))
        drawText(label, in: row.insetBy(dx: 24, dy: 17), size: 21, weight: .semibold, color: NSColor(hex: 0x211B18), alignment: .left)
        accent.setFill()
        NSBezierPath(roundedRect: CGRect(x: row.maxX - 86, y: row.minY + 17, width: 54, height: 28), xRadius: 14, yRadius: 14).fill()
    }
}

func drawTrafficLights(origin: CGPoint) {
    for (idx, color) in [NSColor(hex: 0xFF5F57), NSColor(hex: 0xFFBD2E), NSColor(hex: 0x28C840)].enumerated() {
        color.setFill()
        NSBezierPath(ovalIn: CGRect(x: origin.x + CGFloat(idx) * 28, y: origin.y, width: 15, height: 15)).fill()
    }
}

func drawText(_ text: String, in rect: CGRect, size: CGFloat, weight: NSFont.Weight, color: NSColor, alignment: NSTextAlignment, monospaced: Bool = false) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = alignment
    paragraph.lineBreakMode = .byTruncatingTail
    let font = monospaced ? NSFont.monospacedDigitSystemFont(ofSize: size, weight: weight) : NSFont.systemFont(ofSize: size, weight: weight)
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
        .paragraphStyle: paragraph
    ]
    NSAttributedString(string: text, attributes: attributes).draw(in: rect)
}

func rounded(_ rect: CGRect, radius: CGFloat, color: NSColor) {
    color.setFill()
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
}

func shadow(_ rect: CGRect, radius: CGFloat, y: CGFloat) {
    NSGraphicsContext.current?.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.22)
    shadow.shadowOffset = CGSize(width: 0, height: y)
    shadow.shadowBlurRadius = radius
    shadow.set()
    NSColor.white.setFill()
    NSBezierPath(roundedRect: rect, xRadius: 20, yRadius: 20).fill()
    NSGraphicsContext.current?.restoreGraphicsState()
}

func caption(for index: Int) -> String {
    ["ship it", "looks good", "paper test", "sent", "recent", "local only"][index]
}

func stamp(for index: Int) -> String {
    ["05.07.26", "04.18.26", "03.09.26", "02.14.26", "01.22.26", "05.07.26"][index]
}

extension NSColor {
    convenience init(hex: Int) {
        self.init(
            calibratedRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
