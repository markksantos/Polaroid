import AppKit
import Foundation

enum ExportError: LocalizedError, Equatable {
    case cannotCreatePNG
    case cannotCreateDirectory(URL)
    case cannotWrite(URL)
    case cannotReadClipboard
    case noImage

    var errorDescription: String? {
        switch self {
        case .cannotCreatePNG:
            "Could not create a PNG from this print."
        case .cannotCreateDirectory(let url):
            "Could not create \(url.path)."
        case .cannotWrite(let url):
            "Could not write \(url.lastPathComponent)."
        case .cannotReadClipboard:
            "The clipboard does not contain an image."
        case .noImage:
            "There is no print to export."
        }
    }
}

@MainActor
final class ExportService {
    private let fileManager: FileManager
    private let renderer = PolaroidRenderer()

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func renderPNG(
        screenshot: Screenshot,
        style: PolaroidStyle,
        caption: String,
        texture: CGImage?,
        exportSize: ExportSize
    ) -> Result<(image: NSImage, data: Data), ExportError> {
        let image = renderer.render(
            screenshot: screenshot.image,
            style: style,
            caption: caption,
            date: screenshot.creationDate,
            texture: texture,
            exportSize: exportSize
        )

        guard let data = image.pngData() else {
            return .failure(.cannotCreatePNG)
        }
        return .success((image, data))
    }

    func save(
        screenshot: Screenshot,
        style: PolaroidStyle,
        caption: String,
        texture: CGImage?,
        settings: AppSettings
    ) -> Result<URL, ExportError> {
        let render = renderPNG(
            screenshot: screenshot,
            style: style,
            caption: caption,
            texture: texture,
            exportSize: settings.exportSize
        )

        guard case .success(let output) = render else {
            if case .failure(let error) = render { return .failure(error) }
            return .failure(.cannotCreatePNG)
        }

        let directory = settings.resolvedSaveDirectory()
        let accessGranted = directory.startAccessingSecurityScopedResource()
        defer {
            if accessGranted {
                directory.stopAccessingSecurityScopedResource()
            }
        }

        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            return .failure(.cannotCreateDirectory(directory))
        }

        let url = uniqueOutputURL(in: directory, pattern: settings.fileNamingPattern, date: Date())
        do {
            try output.data.write(to: url, options: [.atomic])
        } catch {
            return .failure(.cannotWrite(url))
        }

        return .success(url)
    }

    func saveAs(
        destination: URL,
        screenshot: Screenshot,
        style: PolaroidStyle,
        caption: String,
        texture: CGImage?,
        exportSize: ExportSize
    ) -> Result<URL, ExportError> {
        let render = renderPNG(
            screenshot: screenshot,
            style: style,
            caption: caption,
            texture: texture,
            exportSize: exportSize
        )

        guard case .success(let output) = render else {
            if case .failure(let error) = render { return .failure(error) }
            return .failure(.cannotCreatePNG)
        }

        let directory = destination.deletingLastPathComponent()
        let accessGranted = directory.startAccessingSecurityScopedResource()
        defer {
            if accessGranted {
                directory.stopAccessingSecurityScopedResource()
            }
        }

        do {
            try output.data.write(to: destination, options: [.atomic])
        } catch {
            return .failure(.cannotWrite(destination))
        }
        return .success(destination)
    }

    func copy(
        screenshot: Screenshot,
        style: PolaroidStyle,
        caption: String,
        texture: CGImage?,
        exportSize: ExportSize
    ) -> Result<Void, ExportError> {
        let render = renderPNG(
            screenshot: screenshot,
            style: style,
            caption: caption,
            texture: texture,
            exportSize: exportSize
        )

        guard case .success(let output) = render else {
            if case .failure(let error) = render { return .failure(error) }
            return .failure(.cannotCreatePNG)
        }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([output.image])
        pasteboard.setString("Instant Frame.png", forType: .string)
        return .success(())
    }

    func copyPath(_ url: URL) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(url.path, forType: .string)
    }

    func imageFromClipboard() -> Result<NSImage, ExportError> {
        let pasteboard = NSPasteboard.general
        if let image = NSImage(pasteboard: pasteboard) {
            return .success(image)
        }
        return .failure(.cannotReadClipboard)
    }

    func share(
        from view: NSView,
        screenshot: Screenshot,
        style: PolaroidStyle,
        caption: String,
        texture: CGImage?,
        exportSize: ExportSize
    ) -> Result<Void, ExportError> {
        let render = renderPNG(
            screenshot: screenshot,
            style: style,
            caption: caption,
            texture: texture,
            exportSize: exportSize
        )

        guard case .success(let output) = render else {
            if case .failure(let error) = render { return .failure(error) }
            return .failure(.cannotCreatePNG)
        }

        let picker = NSSharingServicePicker(items: [output.image])
        picker.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
        return .success(())
    }

    func writeRecentThumbnail(
        image: NSImage,
        originalURL: URL?,
        renderedURL: URL,
        caption: String
    ) -> RecentPolaroid? {
        guard let support = applicationSupportDirectory() else {
            return nil
        }

        let thumbnails = support.appendingPathComponent("RecentThumbnails", isDirectory: true)
        try? fileManager.createDirectory(at: thumbnails, withIntermediateDirectories: true)

        let thumbnailURL = thumbnails.appendingPathComponent(UUID().uuidString).appendingPathExtension("png")
        let thumbnail = image.thumbnail(maxDimension: 220)
        guard let data = thumbnail.pngData(), (try? data.write(to: thumbnailURL, options: [.atomic])) != nil else {
            return nil
        }

        return RecentPolaroid(
            originalURL: originalURL,
            renderedURL: renderedURL,
            thumbnailURL: thumbnailURL,
            createdAt: Date(),
            caption: caption
        )
    }

    private func uniqueOutputURL(in directory: URL, pattern: String, date: Date) -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = pattern.replacingOccurrences(of: "Instant Frame ", with: "'Instant Frame' ")
        formatter.locale = Locale(identifier: "en_US_POSIX")

        var baseName = formatter.string(from: date)
        if baseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            baseName = "Instant Frame \(Self.filenameDateFormatter.string(from: date))"
        }

        var candidate = directory.appendingPathComponent(baseName).appendingPathExtension("png")
        var suffix = 2
        while fileManager.fileExists(atPath: candidate.path) {
            candidate = directory.appendingPathComponent("\(baseName) \(suffix)").appendingPathExtension("png")
            suffix += 1
        }
        return candidate
    }

    private func applicationSupportDirectory() -> URL? {
        guard let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        let directory = support.appendingPathComponent("Polaroid", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private static let filenameDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH.mm.ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}

private extension NSImage {
    func pngData() -> Data? {
        guard
            let tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffRepresentation)
        else {
            return nil
        }
        return bitmap.representation(using: .png, properties: [:])
    }

    func thumbnail(maxDimension: CGFloat) -> NSImage {
        let longest = max(size.width, size.height)
        guard longest > maxDimension else {
            return self
        }

        let scale = maxDimension / longest
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        let thumbnail = NSImage(size: targetSize)
        thumbnail.lockFocus()
        draw(in: CGRect(origin: .zero, size: targetSize), from: .zero, operation: .copy, fraction: 1)
        thumbnail.unlockFocus()
        return thumbnail
    }
}
