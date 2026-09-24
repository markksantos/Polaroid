import AppKit
import Foundation
import Observation
import UniformTypeIdentifiers

@Observable
@MainActor
final class PolaroidDocumentModel {
    var screenshot: Screenshot?
    var style: PolaroidStyle
    var caption = ""
    var toast: ToastMessage?
    var isImporting = false
    var isShowingShareAnchor = false
    var developAnimation = DevelopAnimation()
    var lastExportURL: URL?
    var isWatcherPausedForSession = false

    @ObservationIgnored
    let settings: AppSettings

    @ObservationIgnored
    let textureStore: PaperTextureStore

    @ObservationIgnored
    private let watcher = ScreenshotWatcher()

    @ObservationIgnored
    private let exportService = ExportService()

    @ObservationIgnored
    private var watcherTask: Task<Void, Never>?

    @ObservationIgnored
    private let renderer = PolaroidRenderer()

    @ObservationIgnored
    var openMainWindow: (@MainActor () -> Void)?

    init(settings: AppSettings, textureStore: PaperTextureStore) {
        self.settings = settings
        self.textureStore = textureStore
        style = PolaroidStyle.newDisplayStyle(from: settings)
    }

    var previewImage: NSImage? {
        guard let screenshot else {
            return nil
        }

        return renderer.render(
            screenshot: screenshot.image,
            style: style,
            caption: caption,
            date: screenshot.creationDate,
            texture: textureStore.texture(for: style.paperTexture),
            exportSize: .highRes1920
        )
    }

    var currentTexture: CGImage? {
        textureStore.texture(for: style.paperTexture)
    }

    var captionCharacterCountText: String {
        "\(caption.count)/60"
    }

    var renderDiagnostics: String {
        guard let screenshot else {
            return "No image loaded"
        }
        return renderer.summary(for: screenshot.image, style: style, exportSize: settings.exportSize).displayText
    }

    var styleMetadataSummary: String {
        style.metadataSummary
    }

    var captionSuggestions: [String] {
        let base = [
            "ship it",
            "today",
            "work in progress",
            "made on Mac",
            "tiny moment",
            "looks good",
            "save this"
        ]

        let recent = settings.recentPolaroids
            .map(\.caption)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        return Array((recent + base).uniqued().prefix(7))
    }

    func startWatchingDesktop() {
        guard watcherTask == nil else { return }

        watcherTask = Task { [weak self] in
            guard let self else { return }
            for await url in watcher.events {
                await MainActor.run {
                    self.loadImage(from: url, source: .desktopWatcher)
                }
            }
        }

        updateWatcher()
    }

    func updateWatcher() {
        guard settings.autoWatchDesktop, !isWatcherPausedForSession else {
            watcher.stop()
            return
        }

        watcher.start(watching: settings.resolvedDesktopDirectory())
    }

    func stopWatchingDesktop() {
        watcherTask?.cancel()
        watcherTask = nil
        watcher.stop()
    }

    func loadImage(from url: URL, source: LoadSource = .userSelected) {
        let accessGranted = url.startAccessingSecurityScopedResource()
        defer {
            if accessGranted {
                url.stopAccessingSecurityScopedResource()
            }
        }

        switch Screenshot.load(from: url) {
        case .success(let loaded):
            screenshot = loaded
            caption = suggestedCaption(for: loaded, source: source)
            style = PolaroidStyle.newDisplayStyle(from: settings)
            triggerDevelop()
            bringMainWindowForward()
        case .failure(let error):
            showToast(error.localizedDescription)
        }
    }

    func loadDroppedProviders(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.image.identifier) }) else {
            return false
        }

        provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { [weak self] item, _ in
            let loadedURL = item as? URL
            let loadedData = item as? Data

            Task { @MainActor in
                guard let self else { return }
                if let url = loadedURL {
                    self.loadImage(from: url)
                } else if let data = loadedData, let image = NSImage(data: data) {
                    self.screenshot = Screenshot(
                        image: image,
                        sourceURL: nil,
                        creationDate: Date(),
                        displayName: "Dropped image"
                    )
                    self.caption = ""
                    self.style = PolaroidStyle.newDisplayStyle(from: self.settings)
                    self.triggerDevelop()
                    self.bringMainWindowForward()
                }
            }
        }

        return true
    }

    func triggerDevelop() {
        developAnimation = DevelopAnimation()

        if !settings.skipDevelopAnimation {
            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
        }
    }

    func applyCaptionSuggestion(_ suggestion: String) {
        caption = String(suggestion.prefix(60))
        showToast("Caption applied")
    }

    func uppercaseCaption() {
        caption = String(caption.uppercased().prefix(60))
    }

    func lowercaseCaption() {
        caption = String(caption.lowercased().prefix(60))
    }

    func titleCaseCaption() {
        caption = String(caption.capitalized.prefix(60))
    }

    func clearCaption() {
        caption = ""
    }

    func nudgeRotationLeft() {
        style.rotationDegrees = max(-12, style.rotationDegrees - 0.5)
    }

    func nudgeRotationRight() {
        style.rotationDegrees = min(12, style.rotationDegrees + 0.5)
    }

    func straightenRotation() {
        style.rotationDegrees = 0
    }

    func shuffleRotation() {
        style.rotationDegrees = Double.random(in: -3 ... 3)
    }

    func cyclePaperTexture() {
        style.paperTexture = PaperTexture.allCases.next(after: style.paperTexture)
    }

    func cycleInkColor() {
        style.inkColor = InkColor.allCases.next(after: style.inkColor)
    }

    func cycleFont() {
        style.handwritingFont = HandwritingFont.allCases.next(after: style.handwritingFont)
    }

    func randomizeStyle() {
        style.paperTexture = PaperTexture.allCases.randomElement() ?? style.paperTexture
        style.inkColor = InkColor.allCases.randomElement() ?? style.inkColor
        style.handwritingFont = HandwritingFont.allCases.randomElement() ?? style.handwritingFont
        style.captionAlignment = CaptionAlignment.allCases.randomElement() ?? style.captionAlignment
        style.captionPosition = CaptionPosition.allCases.randomElement() ?? style.captionPosition
        style.captionSize = CaptionSize.allCases.randomElement() ?? style.captionSize
        style.shadowStrength = ShadowStrength.allCases.randomElement() ?? style.shadowStrength
        shuffleRotation()
    }

    func resetStyle() {
        style = PolaroidStyle.default
    }

    func useCurrentStyleAsDefaults() {
        settings.captureDefaults(from: style)
        showToast("Defaults updated")
    }

    func applyDefaultStyle() {
        style = PolaroidStyle.newDisplayStyle(from: settings)
        showToast("Defaults applied")
    }

    func save() {
        guard let screenshot else {
            showToast(ExportError.noImage.localizedDescription)
            return
        }

        switch exportService.save(
            screenshot: screenshot,
            style: style,
            caption: caption,
            texture: currentTexture,
            settings: settings
        ) {
        case .success(let url):
            lastExportURL = url
            if let render = exportService.renderPNG(
                screenshot: screenshot,
                style: style,
                caption: caption,
                texture: currentTexture,
                exportSize: settings.exportSize
            ).successValue?.image,
                let recent = exportService.writeRecentThumbnail(
                    image: render,
                    originalURL: screenshot.sourceURL,
                    renderedURL: url,
                    caption: caption
                ) {
                settings.recentPolaroids = [recent] + settings.recentPolaroids.filter { $0.renderedURL != url }
            }
            showToast("Saved to \(url.deletingLastPathComponent().lastPathComponent)")
        case .failure(let error):
            showToast(error.localizedDescription)
        }
    }

    func saveAs() {
        guard let screenshot else {
            showToast(ExportError.noImage.localizedDescription)
            return
        }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = settings.filenamePreview
        panel.directoryURL = settings.resolvedSaveDirectory()

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        switch exportService.saveAs(
            destination: url,
            screenshot: screenshot,
            style: style,
            caption: caption,
            texture: currentTexture,
            exportSize: settings.exportSize
        ) {
        case .success(let url):
            lastExportURL = url
            showToast("Saved as \(url.lastPathComponent)")
        case .failure(let error):
            showToast(error.localizedDescription)
        }
    }

    func copy() {
        guard let screenshot else {
            showToast(ExportError.noImage.localizedDescription)
            return
        }

        switch exportService.copy(
            screenshot: screenshot,
            style: style,
            caption: caption,
            texture: currentTexture,
            exportSize: settings.exportSize
        ) {
        case .success:
            showToast("Copied")
        case .failure(let error):
            showToast(error.localizedDescription)
        }
    }

    func pasteImageFromClipboard() {
        switch exportService.imageFromClipboard() {
        case .success(let image):
            screenshot = Screenshot(
                image: image,
                sourceURL: nil,
                creationDate: Date(),
                displayName: "Clipboard image"
            )
            caption = ""
            style = PolaroidStyle.newDisplayStyle(from: settings)
            triggerDevelop()
            bringMainWindowForward()
        case .failure(let error):
            showToast(error.localizedDescription)
        }
    }

    func removeCurrentPolaroid() {
        screenshot = nil
        caption = ""
        lastExportURL = nil
    }

    func share(from view: NSView?) {
        guard let screenshot else {
            showToast(ExportError.noImage.localizedDescription)
            return
        }
        guard let view else {
            showToast("Share sheet could not open.")
            return
        }

        switch exportService.share(
            from: view,
            screenshot: screenshot,
            style: style,
            caption: caption,
            texture: currentTexture,
            exportSize: settings.exportSize
        ) {
        case .success:
            break
        case .failure(let error):
            showToast(error.localizedDescription)
        }
    }

    func openRecent(_ recent: RecentPolaroid) {
        if let originalURL = recent.originalURL, FileManager.default.fileExists(atPath: originalURL.path) {
            loadImage(from: originalURL)
        } else {
            loadImage(from: recent.renderedURL)
        }
        caption = recent.caption
    }

    func revealRecent(_ recent: RecentPolaroid) {
        NSWorkspace.shared.activateFileViewerSelecting([recent.renderedURL])
    }

    func removeRecent(_ recent: RecentPolaroid) {
        settings.recentPolaroids.removeAll { $0.id == recent.id }
        showToast("Removed recent print")
    }

    func clearRecentPolaroids() {
        settings.recentPolaroids = []
        showToast("Recent prints cleared")
    }

    func revealLastExport() {
        guard let lastExportURL else {
            showToast("No saved export yet")
            return
        }
        NSWorkspace.shared.activateFileViewerSelecting([lastExportURL])
    }

    func openSaveFolder() {
        NSWorkspace.shared.open(settings.resolvedSaveDirectory())
    }

    func copyLastExportPath() {
        guard let lastExportURL else {
            showToast("No saved export yet")
            return
        }
        exportService.copyPath(lastExportURL)
        showToast("Path copied")
    }

    func openImagePanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        if panel.runModal() == .OK, let url = panel.url {
            loadImage(from: url)
        }
    }

    func chooseSaveLocation() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Use Folder"

        if panel.runModal() == .OK, let url = panel.url {
            if let data = try? url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil) {
                settings.saveLocationBookmark = data
                showToast("Save folder updated")
            }
        }
    }

    func chooseDesktopWatchFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Watch Folder"
        panel.directoryURL = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Desktop", isDirectory: true)

        if panel.runModal() == .OK, let url = panel.url {
            if let data = try? url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil) {
                settings.desktopBookmark = data
                updateWatcher()
                showToast("Desktop watch folder updated")
            }
        }
    }

    func pauseWatcherForSession() {
        isWatcherPausedForSession = true
        updateWatcher()
        showToast("Desktop watcher paused")
    }

    func resumeWatcher() {
        isWatcherPausedForSession = false
        settings.autoWatchDesktop = true
        updateWatcher()
        showToast("Desktop watcher resumed")
    }

    func rescanDesktop() {
        let directory = settings.resolvedDesktopDirectory()
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.creationDateKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            showToast("Desktop scan failed")
            return
        }

        let screenshotURLs = urls
            .filter(ScreenshotWatcher.isScreenshotURL)
            .sorted { lhs, rhs in
                let left = (try? lhs.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                let right = (try? rhs.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                return left > right
            }

        guard let latest = screenshotURLs.first else {
            showToast("No screenshots found")
            return
        }
        loadImage(from: latest, source: .desktopWatcher)
    }

    func resetSettingsToDefaults() {
        settings.resetToDefaults()
        style = PolaroidStyle.newDisplayStyle(from: settings)
        updateWatcher()
        showToast("Settings reset")
    }

    func showToast(_ message: String) {
        toast = ToastMessage(message: message)
        let id = toast?.id
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.8))
            await MainActor.run {
                if self?.toast?.id == id {
                    self?.toast = nil
                }
            }
        }
    }

    private func bringMainWindowForward() {
        openMainWindow?()
        NSApplication.shared.activate(ignoringOtherApps: true)
        NSApplication.shared.windows.first(where: { $0.identifier?.rawValue == "main" || $0.title == "Instant Frame" })?.makeKeyAndOrderFront(nil)
    }

    private func suggestedCaption(for screenshot: Screenshot, source: LoadSource) -> String {
        switch source {
        case .desktopWatcher:
            ""
        case .userSelected:
            screenshot.displayName.hasPrefix("Screenshot") || screenshot.displayName.hasPrefix("Screen Shot") ? "" : screenshot.displayName
        }
    }
}

private extension Array where Element: Equatable {
    func next(after current: Element) -> Element {
        guard let index = firstIndex(of: current) else {
            return first ?? current
        }
        let nextIndex = self.index(after: index)
        return nextIndex == endIndex ? self[startIndex] : self[nextIndex]
    }
}

private extension Array where Element == String {
    func uniqued() -> [String] {
        var seen = Set<String>()
        return filter { item in
            let normalized = item.lowercased()
            guard !seen.contains(normalized) else { return false }
            seen.insert(normalized)
            return true
        }
    }
}

enum LoadSource: Sendable {
    case userSelected
    case desktopWatcher
}

struct ToastMessage: Equatable, Identifiable, Sendable {
    let id = UUID()
    var message: String
}

private extension Result {
    var successValue: Success? {
        guard case .success(let value) = self else { return nil }
        return value
    }
}
