import AppKit
import CoreGraphics
import Foundation
import Observation

struct PaperTextureGenerator: Sendable {
    static let baseSize = CGSize(width: 1080, height: 1320)

    func generateAll(size: CGSize = Self.baseSize) -> [PaperTexture: CGImage] {
        Dictionary(uniqueKeysWithValues: PaperTexture.allCases.compactMap { texture in
            guard let image = generate(texture, size: size) else {
                return nil
            }
            return (texture, image)
        })
    }

    func generate(_ texture: PaperTexture, size: CGSize = Self.baseSize) -> CGImage? {
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
            return nil
        }

        context.setFillColor(texture.baseColor.cgColor)
        context.fill(CGRect(origin: .zero, size: CGSize(width: width, height: height)))

        if texture == .agedCream || texture == .worn {
            drawWarmCorners(in: context, size: CGSize(width: width, height: height), strength: texture == .worn ? 0.12 : 0.08)
        }

        drawGrain(in: context, width: width, height: height, opacity: texture.grainOpacity, seed: texture.seed)

        if texture == .worn {
            drawScuffs(in: context, size: CGSize(width: width, height: height), seed: 9_104)
        }

        return context.makeImage()
    }

    private func drawGrain(in context: CGContext, width: Int, height: Int, opacity: CGFloat, seed: UInt64) {
        var generator = SeededRandom(seed: seed)
        let sampleCount = max(1_000, width * height / 75)

        for _ in 0 ..< sampleCount {
            let x = CGFloat(generator.nextInt(upperBound: width))
            let y = CGFloat(generator.nextInt(upperBound: height))
            let brightness = CGFloat(generator.nextDouble(in: 0.78 ... 1.0))
            let alpha = CGFloat(generator.nextDouble(in: 0.0 ... Double(opacity)))
            context.setFillColor(NSColor(calibratedWhite: brightness, alpha: alpha).cgColor)
            context.fill(CGRect(x: x, y: y, width: 1, height: 1))
        }

        let fiberCount = max(120, width / 4)
        for _ in 0 ..< fiberCount {
            let x = CGFloat(generator.nextInt(upperBound: width))
            let y = CGFloat(generator.nextInt(upperBound: height))
            let length = CGFloat(generator.nextDouble(in: 5 ... 24))
            let alpha = CGFloat(generator.nextDouble(in: 0.002 ... Double(max(0.003, opacity * 0.45))))

            context.saveGState()
            context.translateBy(x: x, y: y)
            context.rotate(by: CGFloat(generator.nextDouble(in: -0.15 ... 0.15)))
            context.setStrokeColor(NSColor(calibratedWhite: 0.55, alpha: alpha).cgColor)
            context.setLineWidth(CGFloat(generator.nextDouble(in: 0.25 ... 0.7)))
            context.move(to: .zero)
            context.addLine(to: CGPoint(x: length, y: 0))
            context.strokePath()
            context.restoreGState()
        }
    }

    private func drawWarmCorners(in context: CGContext, size: CGSize, strength: CGFloat) {
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        let warm = NSColor(calibratedRed: 0.92, green: 0.74, blue: 0.38, alpha: strength).cgColor
        let clear = NSColor.clear.cgColor
        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: [warm, clear] as CFArray, locations: [0, 1]) else {
            return
        }

        let radius = max(size.width, size.height) * 0.55
        let corners = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: size.width, y: 0),
            CGPoint(x: 0, y: size.height),
            CGPoint(x: size.width, y: size.height)
        ]

        for corner in corners {
            context.drawRadialGradient(
                gradient,
                startCenter: corner,
                startRadius: 0,
                endCenter: corner,
                endRadius: radius,
                options: [.drawsAfterEndLocation]
            )
        }
    }

    private func drawScuffs(in context: CGContext, size: CGSize, seed: UInt64) {
        var generator = SeededRandom(seed: seed)

        for _ in 0 ..< 34 {
            let x = generator.coordinate(in: size.width, margin: 40)
            let y = generator.coordinate(in: size.height, margin: 70)
            let width = CGFloat(generator.nextDouble(in: 22 ... 120))
            let height = CGFloat(generator.nextDouble(in: 2 ... 8))

            context.saveGState()
            context.translateBy(x: x, y: y)
            context.rotate(by: CGFloat(generator.nextDouble(in: -0.65 ... 0.65)))
            context.setFillColor(NSColor(calibratedWhite: 0.62, alpha: CGFloat(generator.nextDouble(in: 0.018 ... 0.045))).cgColor)
            context.fillEllipse(in: CGRect(x: -width / 2, y: -height / 2, width: width, height: height))
            context.restoreGState()
        }

        for _ in 0 ..< 16 {
            let x = generator.coordinate(in: size.width, margin: 60)
            let y = generator.coordinate(in: size.height, margin: 60)
            let length = CGFloat(generator.nextDouble(in: 50 ... 190))

            context.saveGState()
            context.translateBy(x: x, y: y)
            context.rotate(by: CGFloat(generator.nextDouble(in: -0.9 ... 0.9)))
            context.setStrokeColor(NSColor(calibratedWhite: 0.35, alpha: CGFloat(generator.nextDouble(in: 0.012 ... 0.035))).cgColor)
            context.setLineWidth(CGFloat(generator.nextDouble(in: 0.7 ... 1.5)))
            context.move(to: .zero)
            context.addCurve(
                to: CGPoint(x: length, y: CGFloat(generator.nextDouble(in: -8 ... 8))),
                control1: CGPoint(x: length * 0.3, y: CGFloat(generator.nextDouble(in: -12 ... 12))),
                control2: CGPoint(x: length * 0.7, y: CGFloat(generator.nextDouble(in: -12 ... 12)))
            )
            context.strokePath()
            context.restoreGState()
        }
    }
}

@MainActor
@Observable
final class PaperTextureStore {
    private(set) var textures: [PaperTexture: CGImage] = [:]
    private let generator = PaperTextureGenerator()

    init() {
        regenerate()
    }

    func regenerate() {
        textures = generator.generateAll()
    }

    func texture(for texture: PaperTexture) -> CGImage? {
        textures[texture]
    }
}

private extension PaperTexture {
    var baseColor: NSColor {
        switch self {
        case .cleanWhite:
            NSColor(calibratedWhite: 1, alpha: 1)
        case .agedCream:
            NSColor(calibratedRed: 0.973, green: 0.949, blue: 0.894, alpha: 1)
        case .worn:
            NSColor(calibratedRed: 0.957, green: 0.925, blue: 0.843, alpha: 1)
        case .coolGray:
            NSColor(calibratedRed: 0.941, green: 0.949, blue: 0.957, alpha: 1)
        }
    }

    var grainOpacity: CGFloat {
        switch self {
        case .cleanWhite: 0.010
        case .agedCream: 0.020
        case .worn: 0.030
        case .coolGray: 0.010
        }
    }

    var seed: UInt64 {
        switch self {
        case .cleanWhite: 1_037
        case .agedCream: 2_071
        case .worn: 3_019
        case .coolGray: 4_043
        }
    }
}

private struct SeededRandom {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    mutating func nextDouble(in range: ClosedRange<Double>) -> Double {
        let unit = Double(next() >> 11) / Double(1 << 53)
        return range.lowerBound + (range.upperBound - range.lowerBound) * unit
    }

    mutating func nextInt(upperBound: Int) -> Int {
        guard upperBound > 0 else { return 0 }
        return Int(next() % UInt64(upperBound))
    }

    mutating func coordinate(in length: CGFloat, margin: CGFloat) -> CGFloat {
        let clampedLength = max(1, length)
        let lower = min(max(0, margin), clampedLength / 2)
        let upper = max(lower, clampedLength - margin)
        return CGFloat(nextDouble(in: Double(lower) ... Double(upper)))
    }
}
