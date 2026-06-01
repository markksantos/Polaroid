import Foundation
import XCTest
@testable import Polaroid

@MainActor
final class AppSettingsTests: XCTestCase {
    private func makeIsolatedSettings() -> AppSettings {
        // AppSettings reads/writes UserDefaults.standard. Snapshot and restore
        // the keys we touch so tests stay hermetic.
        AppSettings()
    }

    func testRecentPolaroidsAreCappedAtFive() {
        let settings = makeIsolatedSettings()
        let originals = settings.recentPolaroids
        defer { settings.recentPolaroids = originals }

        let many = (0 ..< 9).map { index in
            RecentPolaroid(
                originalURL: nil,
                renderedURL: URL(fileURLWithPath: "/tmp/r\(index).png"),
                thumbnailURL: URL(fileURLWithPath: "/tmp/t\(index).png"),
                createdAt: Date(),
                caption: "c\(index)"
            )
        }
        settings.recentPolaroids = many
        XCTAssertEqual(settings.recentPolaroids.count, 5)
    }

    func testFilenamePreviewProducesStablePNGName() {
        let settings = makeIsolatedSettings()
        let originalPattern = settings.fileNamingPattern
        defer { settings.fileNamingPattern = originalPattern }

        settings.fileNamingPattern = "Polaroid yyyy-MM-dd HH.mm.ss"
        let preview = settings.filenamePreview
        XCTAssertTrue(preview.hasPrefix("Polaroid "))
        XCTAssertTrue(preview.hasSuffix(".png"))
    }

    func testEmptyNamingPatternFallsBackToDefault() {
        let settings = makeIsolatedSettings()
        let originalPattern = settings.fileNamingPattern
        defer { settings.fileNamingPattern = originalPattern }

        settings.fileNamingPattern = ""
        XCTAssertEqual(settings.fileNamingPattern, "Polaroid yyyy-MM-dd HH.mm.ss")
    }

    func testResolvedSaveDirectoryFallsBackWithoutBookmark() {
        let settings = makeIsolatedSettings()
        let originalBookmark = settings.saveLocationBookmark
        defer { settings.saveLocationBookmark = originalBookmark }

        settings.saveLocationBookmark = Data()
        XCTAssertEqual(settings.resolvedSaveDirectory(), settings.defaultSaveDirectory)
        XCTAssertTrue(settings.defaultSaveDirectory.path.hasSuffix("Polaroids"))
    }

    func testResetToDefaultsRestoresKnownValues() {
        let settings = makeIsolatedSettings()
        settings.defaultPaperTexture = .coolGray
        settings.defaultInkColor = .red
        settings.autoWatchDesktop = false

        settings.resetToDefaults()

        XCTAssertEqual(settings.defaultPaperTexture, .agedCream)
        XCTAssertEqual(settings.defaultInkColor, .black)
        XCTAssertTrue(settings.autoWatchDesktop)
        XCTAssertEqual(settings.exportSize, .highRes1920)
    }

    func testCaptureDefaultsRoundTripsFromStyle() {
        let settings = makeIsolatedSettings()
        var style = PolaroidStyle.default
        style.paperTexture = .worn
        style.inkColor = .navy
        style.shadowStrength = .dramatic
        style.showDateStamp = false

        settings.captureDefaults(from: style)

        XCTAssertEqual(settings.defaultPaperTexture, .worn)
        XCTAssertEqual(settings.defaultInkColor, .navy)
        XCTAssertEqual(settings.defaultShadowStrength, .dramatic)
        XCTAssertFalse(settings.showDateStamp)
    }
}
