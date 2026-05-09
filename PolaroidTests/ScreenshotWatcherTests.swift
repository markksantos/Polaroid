import Foundation
import XCTest
@testable import Polaroid

final class ScreenshotWatcherTests: XCTestCase {
    func testScreenshotFilenameMatchingCoversModernAndLegacyNames() {
        XCTAssertTrue(ScreenshotWatcher.isScreenshotURL(URL(fileURLWithPath: "/tmp/Screenshot 2026-05-07 at 10.31.22 AM.png")))
        XCTAssertTrue(ScreenshotWatcher.isScreenshotURL(URL(fileURLWithPath: "/tmp/Screen Shot 2026-05-07 at 10.31.22 AM.png")))
    }

    func testScreenshotFilenameMatchingRejectsOtherImages() {
        XCTAssertFalse(ScreenshotWatcher.isScreenshotURL(URL(fileURLWithPath: "/tmp/photo.png")))
        XCTAssertFalse(ScreenshotWatcher.isScreenshotURL(URL(fileURLWithPath: "/tmp/Screenshot 2026-05-07.jpg")))
        XCTAssertFalse(ScreenshotWatcher.isScreenshotURL(URL(fileURLWithPath: "/tmp/My Screenshot 2026-05-07.png")))
    }
}
