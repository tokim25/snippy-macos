import AppKit

let rootURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let svgURL = rootURL.appendingPathComponent("Resources/AppIcon.svg")

guard let image = NSImage(contentsOf: svgURL) else {
    fatalError("Could not load \(svgURL.path)")
}

let sizes: [(name: String, pixels: Int)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024)
]

let iconsetURL = rootURL.appendingPathComponent("AppIcon.iconset")
try FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

for (name, pixels) in sizes {
    let size = NSSize(width: pixels, height: pixels)
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        fatalError("Could not create bitmap for \(name)")
    }
    rep.size = size

    guard let context = NSGraphicsContext(bitmapImageRep: rep) else {
        fatalError("Could not create graphics context for \(name)")
    }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    image.draw(in: NSRect(origin: .zero, size: size), from: .zero, operation: .copy, fraction: 1.0)
    NSGraphicsContext.restoreGraphicsState()

    guard let data = rep.representation(using: .png, properties: [:]) else {
        fatalError("Could not encode \(name)")
    }
    let outURL = iconsetURL.appendingPathComponent("\(name).png")
    try data.write(to: outURL)
    print("Wrote \(outURL.lastPathComponent)")
}
