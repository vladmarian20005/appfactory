// Joins simulator recordings into one vertical 1080x1920, 30 fps H.264 MP4.
//
//   xcrun swift apps/quizday/content/vertical.swift <out.mp4> <trim> <in.mov> [<trim> <in.mov>…]
//
// The runner has no ffmpeg, and AVFoundation does the whole job: each take loses its first
// <trim> seconds (the home screen and the launch), is scaled to the full 1920 height, centred,
// and padded with the app's newsprint (#F5EFE2) so nothing is cropped and captions have margins.
import AVFoundation
import Foundation

let argv = CommandLine.arguments
let pairs = Array(argv.dropFirst(2))
// A range is "start" (to the end of the take) or "start-end", in seconds.
func range(_ s: String) -> (Double, Double?)? {
    let parts = s.split(separator: "-").map { Double($0) }
    if parts.count == 1, let a = parts[0] { return (a, nil) }
    if parts.count == 2, let a = parts[0], let b = parts[1], b > a { return (a, b) }
    return nil
}
guard argv.count >= 4, pairs.count % 2 == 0,
      let inputs = Optional(stride(from: 0, to: pairs.count, by: 2).compactMap({ i -> ((Double, Double?), URL)? in
          range(pairs[i]).map { ($0, URL(fileURLWithPath: pairs[i + 1])) }
      })), inputs.count * 2 == pairs.count else {
    FileHandle.standardError.write("usage: vertical.swift <out.mp4> <trim> <in.mov> [<trim> <in.mov>…]\n".data(using: .utf8)!)
    exit(2)
}
let out = URL(fileURLWithPath: argv[1])
let render = CGSize(width: 1080, height: 1920)
let paper = CGColor(red: 0xF5 / 255.0, green: 0xEF / 255.0, blue: 0xE2 / 255.0, alpha: 1)

let composition = AVMutableComposition()
guard let track = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
    fatalError("could not add a video track")
}
let layer = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
var cursor = CMTime.zero

for (trim, url) in inputs {
    let asset = AVURLAsset(url: url)
    let semaphore = DispatchSemaphore(value: 0)
    var source: AVAssetTrack?
    var duration = CMTime.zero
    Task {
        source = try? await asset.loadTracks(withMediaType: .video).first
        duration = (try? await asset.load(.duration)) ?? .zero
        semaphore.signal()
    }
    semaphore.wait()
    guard let source else { fatalError("no video track in \(url.path)") }

    let start = CMTime(seconds: trim.0, preferredTimescale: 600)
    let end = trim.1.map { min(CMTime(seconds: $0, preferredTimescale: 600), duration) } ?? duration
    let range = CMTimeRange(start: start, end: end)
    try track.insertTimeRange(range, of: source, at: cursor)

    // Fit the take's height to 1920 and centre it; recordVideo writes upright frames.
    let size = source.naturalSize
    let scale = render.height / size.height
    let x = (render.width - size.width * scale) / 2
    layer.setTransform(CGAffineTransform(scaleX: scale, y: scale)
        .concatenating(CGAffineTransform(translationX: x, y: 0)), at: cursor)
    cursor = cursor + range.duration
}

let instruction = AVMutableVideoCompositionInstruction()
instruction.timeRange = CMTimeRange(start: .zero, duration: cursor)
instruction.backgroundColor = paper
instruction.layerInstructions = [layer]

let video = AVMutableVideoComposition()
video.renderSize = render
video.frameDuration = CMTime(value: 1, timescale: 30)
video.instructions = [instruction]

try? FileManager.default.removeItem(at: out)
guard let export = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
    fatalError("could not create an export session")
}
export.videoComposition = video
export.outputURL = out
export.outputFileType = .mp4
export.shouldOptimizeForNetworkUse = true

let done = DispatchSemaphore(value: 0)
export.exportAsynchronously { done.signal() }
done.wait()
guard export.status == .completed else {
    fatalError("export failed: \(export.error?.localizedDescription ?? "unknown")")
}
print(String(format: "%@  %.1f s", out.path, cursor.seconds))
