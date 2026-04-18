import CoreGraphics
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
context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
context.fill(CGRect(x: 0, y: 0, width: canvasSize, height: canvasSize))
context.translateBy(x: 0, y: CGFloat(canvasSize))
context.scaleBy(x: 1, y: -1)

func fillRoundedRect(_ rect: CGRect, radius: CGFloat, rotation: CGFloat = 0, about pivot: CGPoint? = nil) {
    let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
    guard rotation != 0, let pivot else {
        context.addPath(path)
        context.fillPath()
        return
    }

    var transform = CGAffineTransform.identity
    transform = transform.translatedBy(x: pivot.x, y: pivot.y)
    transform = transform.rotated(by: rotation)
    transform = transform.translatedBy(x: -pivot.x, y: -pivot.y)
    context.addPath(path.copy(using: &transform) ?? path)
    context.fillPath()
}

context.setFillColor(CGColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1))

let palm = CGRect(x: 320, y: 250, width: 384, height: 370)
fillRoundedRect(palm, radius: 120)

let fingerWidth: CGFloat = 92
let fingerGap: CGFloat = 28
let fingerTop: CGFloat = 120
let fingerHeight: CGFloat = 250

let fingerXs: [CGFloat] = [0, 1, 2, 3].map { index in
    322 + CGFloat(index) * (fingerWidth + fingerGap)
}

for x in fingerXs {
    fillRoundedRect(
        CGRect(x: x, y: fingerTop, width: fingerWidth, height: fingerHeight),
        radius: 46
    )
}

let thumb = CGRect(x: 238, y: 355, width: 98, height: 245)
fillRoundedRect(
    thumb,
    radius: 48,
    rotation: -.pi / 6,
    about: CGPoint(x: 286, y: 465)
)

let wrist = CGRect(x: 354, y: 560, width: 296, height: 168)
fillRoundedRect(wrist, radius: 84)

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
