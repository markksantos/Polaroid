import Foundation
import Observation

@propertyWrapper
struct UserDefaultBacked<Value: Codable> {
    private let key: String
    private let defaultValue: Value
    private let defaults: UserDefaults

    init(_ key: String, default defaultValue: Value, defaults: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.defaults = defaults
    }

    var wrappedValue: Value {
        get {
            guard let data = defaults.data(forKey: key) else {
                return defaultValue
            }
            return (try? JSONDecoder().decode(Value.self, from: data)) ?? defaultValue
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: key)
            }
        }
    }
}

@Observable
@MainActor
final class AppSettings {
    @ObservationIgnored
    @UserDefaultBacked("defaultPaperTexture", default: PaperTexture.agedCream)
    private var storedDefaultPaperTexture: PaperTexture

    @ObservationIgnored
    @UserDefaultBacked("defaultInkColor", default: InkColor.black)
    private var storedDefaultInkColor: InkColor

    @ObservationIgnored
    @UserDefaultBacked("defaultFont", default: HandwritingFont.markerFelt)
    private var storedDefaultFont: HandwritingFont

    @ObservationIgnored
    @UserDefaultBacked("defaultRotationBehavior", default: RotationBehavior.random)
    private var storedDefaultRotationBehavior: RotationBehavior

    @ObservationIgnored
    @UserDefaultBacked("defaultCaptionAlignment", default: CaptionAlignment.center)
    private var storedDefaultCaptionAlignment: CaptionAlignment

    @ObservationIgnored
    @UserDefaultBacked("defaultCaptionPosition", default: CaptionPosition.middle)
    private var storedDefaultCaptionPosition: CaptionPosition

    @ObservationIgnored
    @UserDefaultBacked("defaultCaptionSize", default: CaptionSize.medium)
    private var storedDefaultCaptionSize: CaptionSize

    @ObservationIgnored
    @UserDefaultBacked("defaultExportFrameMode", default: ExportFrameMode.polaroid)
    private var storedDefaultExportFrameMode: ExportFrameMode

    @ObservationIgnored
    @UserDefaultBacked("defaultCanvasBackground", default: CanvasBackground.transparent)
    private var storedDefaultCanvasBackground: CanvasBackground

    @ObservationIgnored
    @UserDefaultBacked("defaultShadowStrength", default: ShadowStrength.standard)
    private var storedDefaultShadowStrength: ShadowStrength

    @ObservationIgnored
    @UserDefaultBacked("autoWatchDesktop", default: true)
    private var storedAutoWatchDesktop: Bool

    @ObservationIgnored
    @UserDefaultBacked("skipDevelopAnimation", default: false)
    private var storedSkipDevelopAnimation: Bool

    @ObservationIgnored
    @UserDefaultBacked("showDateStamp", default: true)
    private var storedShowDateStamp: Bool

    @ObservationIgnored
    @UserDefaultBacked("exportSize", default: ExportSize.highRes1920)
    private var storedExportSize: ExportSize

    @ObservationIgnored
    @UserDefaultBacked("fileNamingPattern", default: "Polaroid yyyy-MM-dd HH.mm.ss")
    private var storedFileNamingPattern: String

    @ObservationIgnored
    @UserDefaultBacked("saveLocationBookmark", default: Data())
    private var storedSaveLocationBookmark: Data

    @ObservationIgnored
    @UserDefaultBacked("desktopBookmark", default: Data())
    private var storedDesktopBookmark: Data

    @ObservationIgnored
    @UserDefaultBacked("recentPolaroids", default: [RecentPolaroid]())
    private var storedRecentPolaroids: [RecentPolaroid]

    var defaultPaperTexture: PaperTexture {
        get { storedDefaultPaperTexture }
        set { storedDefaultPaperTexture = newValue }
    }

    var defaultInkColor: InkColor {
        get { storedDefaultInkColor }
        set { storedDefaultInkColor = newValue }
    }

    var defaultFont: HandwritingFont {
        get { storedDefaultFont }
        set { storedDefaultFont = newValue }
    }

    var defaultRotationBehavior: RotationBehavior {
        get { storedDefaultRotationBehavior }
        set { storedDefaultRotationBehavior = newValue }
    }

    var defaultCaptionAlignment: CaptionAlignment {
        get { storedDefaultCaptionAlignment }
        set { storedDefaultCaptionAlignment = newValue }
    }

    var defaultCaptionPosition: CaptionPosition {
        get { storedDefaultCaptionPosition }
        set { storedDefaultCaptionPosition = newValue }
    }

    var defaultCaptionSize: CaptionSize {
        get { storedDefaultCaptionSize }
        set { storedDefaultCaptionSize = newValue }
    }

    var defaultExportFrameMode: ExportFrameMode {
        get { storedDefaultExportFrameMode }
        set { storedDefaultExportFrameMode = newValue }
    }

    var defaultCanvasBackground: CanvasBackground {
        get { storedDefaultCanvasBackground }
        set { storedDefaultCanvasBackground = newValue }
    }

    var defaultShadowStrength: ShadowStrength {
        get { storedDefaultShadowStrength }
        set { storedDefaultShadowStrength = newValue }
    }

    var autoWatchDesktop: Bool {
        get { storedAutoWatchDesktop }
        set { storedAutoWatchDesktop = newValue }
    }

    var skipDevelopAnimation: Bool {
        get { storedSkipDevelopAnimation }
        set { storedSkipDevelopAnimation = newValue }
    }

    var showDateStamp: Bool {
        get { storedShowDateStamp }
        set { storedShowDateStamp = newValue }
    }

    var exportSize: ExportSize {
        get { storedExportSize }
        set { storedExportSize = newValue }
    }

    var fileNamingPattern: String {
        get { storedFileNamingPattern }
        set { storedFileNamingPattern = newValue.isEmpty ? "Polaroid yyyy-MM-dd HH.mm.ss" : newValue }
    }

    var saveLocationBookmark: Data {
        get { storedSaveLocationBookmark }
        set { storedSaveLocationBookmark = newValue }
    }

    var desktopBookmark: Data {
        get { storedDesktopBookmark }
        set { storedDesktopBookmark = newValue }
    }

    var recentPolaroids: [RecentPolaroid] {
        get { storedRecentPolaroids }
        set { storedRecentPolaroids = Array(newValue.prefix(5)) }
    }

    var defaultSaveDirectory: URL {
        FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("Polaroids", isDirectory: true)
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Pictures/Polaroids", isDirectory: true)
    }

    var filenamePreview: String {
        let formatter = DateFormatter()
        formatter.dateFormat = fileNamingPattern.replacingOccurrences(of: "Polaroid ", with: "'Polaroid' ")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let preview = formatter.string(from: Date(timeIntervalSince1970: 1_767_225_600))
        return preview.isEmpty ? "Polaroid 2026-01-01 00.00.00.png" : "\(preview).png"
    }

    func resolvedSaveDirectory() -> URL {
        guard !saveLocationBookmark.isEmpty else {
            return defaultSaveDirectory
        }

        var isStale = false
        if let url = try? URL(
            resolvingBookmarkData: saveLocationBookmark,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ), !isStale {
            return url
        }

        return defaultSaveDirectory
    }

    func resolvedDesktopDirectory() -> URL {
        guard !desktopBookmark.isEmpty else {
            return URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Desktop", isDirectory: true)
        }

        var isStale = false
        if let url = try? URL(
            resolvingBookmarkData: desktopBookmark,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ), !isStale {
            return url
        }

        return URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Desktop", isDirectory: true)
    }

    func captureDefaults(from style: PolaroidStyle) {
        defaultPaperTexture = style.paperTexture
        defaultInkColor = style.inkColor
        defaultFont = style.handwritingFont
        defaultRotationBehavior = style.rotationBehavior
        defaultCaptionAlignment = style.captionAlignment
        defaultCaptionPosition = style.captionPosition
        defaultCaptionSize = style.captionSize
        defaultExportFrameMode = style.exportFrameMode
        defaultCanvasBackground = style.canvasBackground
        defaultShadowStrength = style.shadowStrength
        showDateStamp = style.showDateStamp
    }

    func resetToDefaults() {
        defaultPaperTexture = .agedCream
        defaultInkColor = .black
        defaultFont = .markerFelt
        defaultRotationBehavior = .random
        defaultCaptionAlignment = .center
        defaultCaptionPosition = .middle
        defaultCaptionSize = .medium
        defaultExportFrameMode = .polaroid
        defaultCanvasBackground = .transparent
        defaultShadowStrength = .standard
        autoWatchDesktop = true
        skipDevelopAnimation = false
        showDateStamp = true
        exportSize = .highRes1920
        fileNamingPattern = "Polaroid yyyy-MM-dd HH.mm.ss"
    }
}
