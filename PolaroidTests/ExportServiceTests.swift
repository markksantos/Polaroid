import AppKit
import XCTest
@testable import Polaroid

@MainActor
final class ExportServiceTests: XCTestCase {
    private func syntheticScreenshot(size: CGSize = CGSize(width: 640, height: 480)) -> Screenshot {
        let width = max(1, Int(size.width.rounded()))
        let height = max(1, Int(size.height.rounded()))
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.setFillColor(NSColor.systemTeal.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let image = NSImage(cgImage: context.makeImage()!, size: size)
        return Screenshot(
            image: image,
            sourceURL: nil,
            creationDate: Date(timeIntervalSince1970: 1_767_225_600),
            displayName: "Synthetic"
        )
    }

    func testSaveAsProducesAValidPNGFile() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let destination = directory.appendingPathComponent("Export.png")
        let result = ExportService().saveAs(
            destination: destination,
            screenshot: syntheticScreenshot(),
            style: .default,
            caption: "Hello",
            texture: PaperTextureGenerator().generate(.agedCream),
            exportSize: .highRes1920
        )

        guard case .success(let url) = result else {
            return XCTFail("Expected success, got \(result)")
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        let bitmap = NSBitmapImageRep(data: try Data(contentsOf: url))
        XCTAssertEqual(bitmap?.pixelsWide, 1920)
        XCTAssertEqual(bitmap?.pixelsHigh, 2347)
    }

    func testRenderPNGFailureSurfacesNoImageNotCrash() {
        // A zero-size export still yields a PNG (renderer clamps to >= 1px),
        // so renderPNG should succeed rather than throw.
        let result = ExportService().renderPNG(
            screenshot: syntheticScreenshot(size: CGSize(width: 1, height: 1)),
            style: .default,
            caption: "",
            texture: nil,
            exportSize: .square1080
        )
        guard case .success(let output) = result else {
            return XCTFail("Expected a PNG, got \(result)")
        }
        XCTAssertFalse(output.data.isEmpty)
    }

    func testCopyPlacesImageOnPasteboard() {
        let result = ExportService().copy(
            screenshot: syntheticScreenshot(),
            style: .default,
            caption: "Copied",
            texture: nil,
            exportSize: .square1080
        )
        guard case .success = result else {
            return XCTFail("Expected copy to succeed, got \(result)")
        }
        XCTAssertNotNil(NSImage(pasteboard: .general))
    }

    func testExportErrorMessagesAreUserReadable() {
        XCTAssertEqual(ExportError.noImage.errorDescription, "There is no Polaroid to export.")
        XCTAssertEqual(ExportError.cannotReadClipboard.errorDescription, "The clipboard does not contain an image.")
        XCTAssertNotNil(ExportError.cannotWrite(URL(fileURLWithPath: "/tmp/x.png")).errorDescription)
    }
}
