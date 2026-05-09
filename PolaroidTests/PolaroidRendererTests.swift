import AppKit
import XCTest
@testable import Polaroid

final class PolaroidRendererTests: XCTestCase {
    func testHighResolutionRenderUsesPolaroidAspectRatio() throws {
        let renderer = PolaroidRenderer()
        let screenshot = syntheticImage(size: CGSize(width: 1600, height: 900))
        let texture = PaperTextureGenerator().generate(.agedCream)

        let output = renderer.render(
            screenshot: screenshot,
            style: .default,
            caption: "Design pass",
            date: Date(timeIntervalSince1970: 1_767_225_600),
            texture: texture,
            exportSize: .highRes1920
        )

        XCTAssertEqual(output.size.width, 1920, accuracy: 0.5)
        XCTAssertEqual(output.size.height, 2347, accuracy: 0.5)
        XCTAssertNotNil(output.tiffRepresentation)
    }

    func testPhotoAreaKeepsInputAspectRatioInsideSquarePhoto() {
        let renderer = PolaroidRenderer()
        let wide = syntheticImage(size: CGSize(width: 1920, height: 1080))
        let metrics = renderer.metrics(for: .highRes1920, screenshot: wide)

        XCTAssertEqual(metrics.photoRect.width, metrics.photoRect.height, accuracy: 0.5)
        XCTAssertGreaterThan(metrics.bottomBorderHeight, metrics.photoRect.height * 0.25)
    }

    func testSquareExportProducesSquareCanvas() {
        let renderer = PolaroidRenderer()
        let screenshot = syntheticImage(size: CGSize(width: 1080, height: 1920))
        let output = renderer.render(
            screenshot: screenshot,
            style: .default,
            caption: nil,
            date: Date(),
            texture: PaperTextureGenerator().generate(.cleanWhite),
            exportSize: .square1080
        )

        XCTAssertEqual(output.size.width, 1080, accuracy: 0.5)
        XCTAssertEqual(output.size.height, 1080, accuracy: 0.5)
    }

    func testPaperTexturesAreDistinct() throws {
        let generator = PaperTextureGenerator()
        let textures = PaperTexture.allCases.compactMap { generator.generate($0, size: CGSize(width: 160, height: 200)) }

        XCTAssertEqual(textures.count, PaperTexture.allCases.count)
        XCTAssertNotEqual(textures[0].dataProvider?.data as Data?, textures[1].dataProvider?.data as Data?)
    }

    func testWornPaperTextureHandlesTinyGenerationSizes() throws {
        let texture = PaperTextureGenerator().generate(.worn, size: CGSize(width: 12, height: 12))

        XCTAssertNotNil(texture)
        XCTAssertEqual(texture?.width, 12)
        XCTAssertEqual(texture?.height, 12)
    }

    func testPhotoOnlyFrameModeUsesFullCanvasAsPhotoArea() {
        let renderer = PolaroidRenderer()
        let screenshot = syntheticImage(size: CGSize(width: 900, height: 1600))
        var style = PolaroidStyle.default
        style.exportFrameMode = .photoOnly

        let summary = renderer.summary(for: screenshot, style: style, exportSize: .square1080)
        let output = renderer.render(
            screenshot: screenshot,
            style: style,
            caption: "Hidden caption",
            date: Date(timeIntervalSince1970: 1_767_225_600),
            texture: nil,
            exportSize: .square1080
        )

        XCTAssertEqual(summary.frameMode, .photoOnly)
        XCTAssertEqual(summary.photoSize, summary.canvasSize)
        XCTAssertEqual(output.size.width, 1080, accuracy: 0.5)
        XCTAssertEqual(output.size.height, 1080, accuracy: 0.5)
    }

    func testOriginalExportTracksInputLongestDimension() {
        let renderer = PolaroidRenderer()
        let screenshot = syntheticImage(size: CGSize(width: 1500, height: 900))
        let target = renderer.targetCanvasSize(for: .original, screenshot: screenshot)
        let summary = renderer.summary(for: screenshot, style: .default, exportSize: .original)
        let longestInputDimension = max(summary.inputSize.width, summary.inputSize.height)

        XCTAssertEqual(target.width, longestInputDimension, accuracy: 0.5)
        XCTAssertEqual(target.height, longestInputDimension * 1480 / 1240, accuracy: 0.5)
    }

    func testStyleMetadataSummaryIncludesNewControls() {
        var style = PolaroidStyle.default
        style.captionAlignment = .right
        style.captionPosition = .high
        style.captionSize = .large
        style.exportFrameMode = .photoOnly
        style.canvasBackground = .matte
        style.shadowStrength = .dramatic

        let summary = style.metadataSummary

        XCTAssertTrue(summary.contains("caption=Right/High/Large"))
        XCTAssertTrue(summary.contains("frame=Photo only"))
        XCTAssertTrue(summary.contains("background=Matte"))
        XCTAssertTrue(summary.contains("shadow=Dramatic"))
    }

    @MainActor
    func testSaveAsWritesPNGAtSelectedExportSize() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let destination = directory.appendingPathComponent("Saved Polaroid.png")
        let screenshot = Screenshot(
            image: syntheticImage(size: CGSize(width: 640, height: 480)),
            sourceURL: nil,
            creationDate: Date(timeIntervalSince1970: 1_767_225_600),
            displayName: "Synthetic"
        )
        var style = PolaroidStyle.default
        style.exportFrameMode = .photoOnly

        let result = ExportService().saveAs(
            destination: destination,
            screenshot: screenshot,
            style: style,
            caption: "Save as",
            texture: nil,
            exportSize: .square1080
        )

        guard case .success(let url) = result else {
            return XCTFail("Expected Save As to write a PNG, got \(result)")
        }

        let data = try Data(contentsOf: url)
        let bitmap = NSBitmapImageRep(data: data)
        XCTAssertEqual(bitmap?.pixelsWide, 1080)
        XCTAssertEqual(bitmap?.pixelsHigh, 1080)
    }

    private func syntheticImage(size: CGSize) -> NSImage {
        let width = max(1, Int(size.width.rounded()))
        let height = max(1, Int(size.height.rounded()))
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return NSImage(size: size)
        }

        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        context.setFillColor(NSColor(calibratedRed: 0.18, green: 0.28, blue: 0.78, alpha: 1).cgColor)
        context.fill(rect)
        context.setFillColor(NSColor(calibratedRed: 0.96, green: 0.72, blue: 0.22, alpha: 1).cgColor)
        context.fillEllipse(in: CGRect(x: size.width * 0.26, y: size.height * 0.20, width: size.width * 0.48, height: size.height * 0.58))

        guard let cgImage = context.makeImage() else {
            return NSImage(size: size)
        }
        return NSImage(cgImage: cgImage, size: size)
    }
}
