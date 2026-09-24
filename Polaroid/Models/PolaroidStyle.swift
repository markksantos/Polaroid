import AppKit
import Foundation

enum PaperTexture: String, CaseIterable, Codable, Identifiable, Sendable {
    case cleanWhite
    case agedCream
    case worn
    case coolGray

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cleanWhite: "Clean white"
        case .agedCream: "Aged cream"
        case .worn: "Worn"
        case .coolGray: "Cool gray"
        }
    }
}

enum InkColor: String, CaseIterable, Codable, Identifiable, Sendable {
    case black
    case navy
    case red
    case forest
    case fadedBlue
    case pencilGray

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .black: "Black"
        case .navy: "Navy"
        case .red: "Red"
        case .forest: "Forest"
        case .fadedBlue: "Faded blue"
        case .pencilGray: "Pencil gray"
        }
    }

    var hex: String {
        switch self {
        case .black: "#1A1A1A"
        case .navy: "#1B3A5C"
        case .red: "#A0282E"
        case .forest: "#2C5530"
        case .fadedBlue: "#6B8FB5"
        case .pencilGray: "#4A4A4A"
        }
    }

    var nsColor: NSColor {
        switch self {
        case .black: NSColor(calibratedRed: 0.102, green: 0.102, blue: 0.102, alpha: 1)
        case .navy: NSColor(calibratedRed: 0.106, green: 0.227, blue: 0.361, alpha: 1)
        case .red: NSColor(calibratedRed: 0.627, green: 0.157, blue: 0.180, alpha: 1)
        case .forest: NSColor(calibratedRed: 0.173, green: 0.333, blue: 0.188, alpha: 1)
        case .fadedBlue: NSColor(calibratedRed: 0.420, green: 0.561, blue: 0.710, alpha: 1)
        case .pencilGray: NSColor(calibratedRed: 0.290, green: 0.290, blue: 0.290, alpha: 1)
        }
    }
}

enum HandwritingFont: String, CaseIterable, Codable, Identifiable, Sendable {
    case markerFelt
    case bradleyHand
    case chalkduster

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .markerFelt: "Marker Felt"
        case .bradleyHand: "Bradley Hand"
        case .chalkduster: "Chalkduster"
        }
    }

    var postScriptName: String {
        switch self {
        case .markerFelt: "MarkerFelt-Thin"
        case .bradleyHand: "BradleyHandITCTT-Bold"
        case .chalkduster: "Chalkduster"
        }
    }

    func nsFont(size: CGFloat) -> NSFont {
        NSFont(name: postScriptName, size: size)
            ?? NSFont(name: displayName, size: size)
            ?? .systemFont(ofSize: size, weight: .regular)
    }
}

enum RotationBehavior: String, CaseIterable, Codable, Identifiable, Sendable {
    case random
    case straight

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .random: "Random"
        case .straight: "Straight"
        }
    }
}

enum ExportSize: String, CaseIterable, Codable, Identifiable, Sendable {
    case square1080
    case highRes1920
    case original

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .square1080: "Square (1080)"
        case .highRes1920: "High-res (1920)"
        case .original: "Original"
        }
    }
}

enum CaptionAlignment: String, CaseIterable, Codable, Identifiable, Sendable {
    case left
    case center
    case right

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .left: "Left"
        case .center: "Center"
        case .right: "Right"
        }
    }

    var textAlignment: NSTextAlignment {
        switch self {
        case .left: .left
        case .center: .center
        case .right: .right
        }
    }
}

enum CaptionPosition: String, CaseIterable, Codable, Identifiable, Sendable {
    case low
    case middle
    case high

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .low: "Low"
        case .middle: "Middle"
        case .high: "High"
        }
    }

    var yOffset: CGFloat {
        switch self {
        case .low: 52
        case .middle: 82
        case .high: 116
        }
    }
}

enum CaptionSize: String, CaseIterable, Codable, Identifiable, Sendable {
    case small
    case medium
    case large

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .small: "Small"
        case .medium: "Medium"
        case .large: "Large"
        }
    }

    var fontScale: CGFloat {
        switch self {
        case .small: 0.82
        case .medium: 1.0
        case .large: 1.18
        }
    }
}

enum ExportFrameMode: String, CaseIterable, Codable, Identifiable, Sendable {
    case polaroid
    case photoOnly

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .polaroid: "Full frame"
        case .photoOnly: "Photo only"
        }
    }
}

enum CanvasBackground: String, CaseIterable, Codable, Identifiable, Sendable {
    case transparent
    case matte

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .transparent: "Transparent"
        case .matte: "Matte"
        }
    }

    var nsColor: NSColor {
        switch self {
        case .transparent:
            .clear
        case .matte:
            NSColor(calibratedRed: 0.944, green: 0.932, blue: 0.904, alpha: 1)
        }
    }
}

enum ShadowStrength: String, CaseIterable, Codable, Identifiable, Sendable {
    case soft
    case standard
    case dramatic

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .soft: "Soft"
        case .standard: "Standard"
        case .dramatic: "Dramatic"
        }
    }

    var blur: CGFloat {
        switch self {
        case .soft: 14
        case .standard: 25
        case .dramatic: 42
        }
    }

    var offsetY: CGFloat {
        switch self {
        case .soft: 4
        case .standard: 8
        case .dramatic: 14
        }
    }

    var opacity: CGFloat {
        switch self {
        case .soft: 0.18
        case .standard: 0.30
        case .dramatic: 0.42
        }
    }
}

struct PolaroidStyle: Codable, Equatable, Sendable {
    var paperTexture: PaperTexture
    var inkColor: InkColor
    var handwritingFont: HandwritingFont
    var rotationDegrees: Double
    var rotationBehavior: RotationBehavior
    var showDateStamp: Bool
    var captionAlignment: CaptionAlignment
    var captionPosition: CaptionPosition
    var captionSize: CaptionSize
    var exportFrameMode: ExportFrameMode
    var canvasBackground: CanvasBackground
    var shadowStrength: ShadowStrength

    static let `default` = PolaroidStyle(
        paperTexture: .agedCream,
        inkColor: .black,
        handwritingFont: .markerFelt,
        rotationDegrees: -1.4,
        rotationBehavior: .random,
        showDateStamp: true,
        captionAlignment: .center,
        captionPosition: .middle,
        captionSize: .medium,
        exportFrameMode: .polaroid,
        canvasBackground: .transparent,
        shadowStrength: .standard
    )

    @MainActor
    static func newDisplayStyle(from settings: AppSettings) -> PolaroidStyle {
        let rotation: Double
        switch settings.defaultRotationBehavior {
        case .random:
            rotation = Double.random(in: -3 ... 3)
        case .straight:
            rotation = 0
        }

        return PolaroidStyle(
            paperTexture: settings.defaultPaperTexture,
            inkColor: settings.defaultInkColor,
            handwritingFont: settings.defaultFont,
            rotationDegrees: rotation,
            rotationBehavior: settings.defaultRotationBehavior,
            showDateStamp: settings.showDateStamp,
            captionAlignment: settings.defaultCaptionAlignment,
            captionPosition: settings.defaultCaptionPosition,
            captionSize: settings.defaultCaptionSize,
            exportFrameMode: settings.defaultExportFrameMode,
            canvasBackground: settings.defaultCanvasBackground,
            shadowStrength: settings.defaultShadowStrength
        )
    }

    var metadataSummary: String {
        [
            "paper=\(paperTexture.displayName)",
            "ink=\(inkColor.displayName)",
            "font=\(handwritingFont.displayName)",
            "rotation=\(String(format: "%.1f", rotationDegrees))",
            "caption=\(captionAlignment.displayName)/\(captionPosition.displayName)/\(captionSize.displayName)",
            "frame=\(exportFrameMode.displayName)",
            "background=\(canvasBackground.displayName)",
            "shadow=\(shadowStrength.displayName)"
        ].joined(separator: " | ")
    }
}
