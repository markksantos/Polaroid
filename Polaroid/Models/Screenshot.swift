import AppKit
import Foundation

struct Screenshot: Identifiable, Equatable, @unchecked Sendable {
    let id: UUID
    let image: NSImage
    let sourceURL: URL?
    let creationDate: Date
    let displayName: String

    init(
        id: UUID = UUID(),
        image: NSImage,
        sourceURL: URL?,
        creationDate: Date,
        displayName: String
    ) {
        self.id = id
        self.image = image
        self.sourceURL = sourceURL
        self.creationDate = creationDate
        self.displayName = displayName
    }

    static func == (lhs: Screenshot, rhs: Screenshot) -> Bool {
        lhs.id == rhs.id
    }

    static func load(from url: URL) -> Result<Screenshot, ScreenshotLoadError> {
        guard let image = NSImage(contentsOf: url), image.isValid else {
            return .failure(.invalidImage(url))
        }

        let values = try? url.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey])
        let date = values?.creationDate ?? values?.contentModificationDate ?? Date()

        return .success(
            Screenshot(
                image: image,
                sourceURL: url,
                creationDate: date,
                displayName: url.deletingPathExtension().lastPathComponent
            )
        )
    }
}

enum ScreenshotLoadError: LocalizedError, Equatable {
    case invalidImage(URL)

    var errorDescription: String? {
        switch self {
        case .invalidImage(let url):
            "Could not open \(url.lastPathComponent) as an image."
        }
    }
}

struct RecentPolaroid: Identifiable, Codable, Equatable, Sendable {
    var id: UUID
    var originalURL: URL?
    var renderedURL: URL
    var thumbnailURL: URL
    var createdAt: Date
    var caption: String

    init(
        id: UUID = UUID(),
        originalURL: URL?,
        renderedURL: URL,
        thumbnailURL: URL,
        createdAt: Date,
        caption: String
    ) {
        self.id = id
        self.originalURL = originalURL
        self.renderedURL = renderedURL
        self.thumbnailURL = thumbnailURL
        self.createdAt = createdAt
        self.caption = caption
    }
}
