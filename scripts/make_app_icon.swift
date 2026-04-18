import CoreGraphics
import AppKit
import Foundation
import ImageIO
import UniformTypeIdentifiers

guard CommandLine.arguments.count == 2 else {
    fputs("Usage: make_app_icon.swift <output.png>\n", stderr)
    exit(64)
}

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let canvasSize = 1024
let colorSpace = CGColorSpaceCreateDeviceRGB()

try FileManager.default.createDirectory(
    at: outputURL.deletingLastPathComponent(),
    withIntermediateDirectories: true
)

guard let context = CGContext(
    data: nil,
    width: canvasSize,
    height: canvasSize,
    bitsPerComponent: 8,
    bytesPerRow: canvasSize * 4,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    fputs("Failed to create drawing context.\n", stderr)
    exit(1)
}

context.setAllowsAntialiasing(true)
context.setShouldAntialias(true)
context.translateBy(x: 0, y: CGFloat(canvasSize))
context.scaleBy(x: 1, y: -1)

func fillRoundedRect(_ rect: CGRect, radius: CGFloat, color: CGColor) {
    context.setFillColor(color)
    context.addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
    context.fillPath()
}

let outerRect = CGRect(x: 54, y: 54, width: 916, height: 916)
fillRoundedRect(outerRect, radius: 196, color: CGColor(red: 0.975, green: 0.965, blue: 0.95, alpha: 1))

let borderPath = CGPath(roundedRect: outerRect, cornerWidth: 196, cornerHeight: 196, transform: nil)
context.setStrokeColor(CGColor(red: 0.86, green: 0.84, blue: 0.81, alpha: 1))
context.setLineWidth(24)
context.addPath(borderPath)
context.strokePath()

guard let symbolBase = NSImage(systemSymbolName: "hand.raised", accessibilityDescription: "VibeGesture hand icon") ??
    NSImage(systemSymbolName: "hand.fingers.spread", accessibilityDescription: "VibeGesture hand icon") else {
    fputs("Failed to create SF Symbol image.\n", stderr)
    exit(1)
}

let symbolConfig = NSImage.SymbolConfiguration(pointSize: 760, weight: .regular, scale: .large)
let symbolImage = symbolBase.withSymbolConfiguration(symbolConfig) ?? symbolBase
let symbolRect = CGRect(x: 176, y: 176, width: 672, height: 672)

let nsContext = NSGraphicsContext(cgContext: context, flipped: false)
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = nsContext
symbolImage.isTemplate = true
NSColor.black.set()
context.saveGState()
context.translateBy(x: symbolRect.midX, y: symbolRect.midY)
context.rotate(by: .pi)
context.translateBy(x: -symbolRect.midX, y: -symbolRect.midY)
symbolImage.draw(in: symbolRect)
context.restoreGState()
NSGraphicsContext.restoreGraphicsState()

guard let image = context.makeImage() else {
    fputs("Failed to render icon image.\n", stderr)
    exit(1)
}

guard let destination = CGImageDestinationCreateWithURL(
    outputURL as CFURL,
    UTType.png.identifier as CFString,
    1,
    nil
) else {
    fputs("Failed to create PNG destination.\n", stderr)
    exit(1)
}

CGImageDestinationAddImage(destination, image, nil)

guard CGImageDestinationFinalize(destination) else {
    fputs("Failed to write PNG output.\n", stderr)
    exit(1)
}
