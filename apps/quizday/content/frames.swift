// Pulls stills out of a clip so it can be looked at: a contact sheet of frames at given times.
//
//   xcrun swift apps/quizday/content/frames.swift <clip.mp4> <out.png> <t1> <t2> …
import AVFoundation
import AppKit

let argv = CommandLine.arguments
let asset = AVURLAsset(url: URL(fileURLWithPath: argv[1]))
let out = URL(fileURLWithPath: argv[2])
let times = argv[3...].compactMap(Double.init)
let generator = AVAssetImageGenerator(asset: asset)
generator.requestedTimeToleranceBefore = .positiveInfinity
generator.requestedTimeToleranceAfter = .zero
generator.maximumSize = CGSize(width: 270, height: 480)

let cell = CGSize(width: 270, height: 480)
let sheet = NSImage(size: CGSize(width: cell.width * CGFloat(times.count), height: cell.height + 24))
sheet.lockFocus()
NSColor.white.setFill()
NSRect(origin: .zero, size: sheet.size).fill()
for (i, t) in times.enumerated() {
    guard let image = try? generator.copyCGImage(at: CMTime(seconds: t, preferredTimescale: 600), actualTime: nil) else { continue }
    NSImage(cgImage: image, size: cell).draw(in: NSRect(x: CGFloat(i) * cell.width, y: 24, width: cell.width, height: cell.height))
    (String(format: "%.1fs", t) as NSString).draw(at: NSPoint(x: CGFloat(i) * cell.width + 6, y: 4),
        withAttributes: [.font: NSFont.monospacedSystemFont(ofSize: 13, weight: .medium)])
}
sheet.unlockFocus()
let rep = NSBitmapImageRep(data: sheet.tiffRepresentation!)!
try rep.representation(using: .png, properties: [:])!.write(to: out)
print(out.path)
