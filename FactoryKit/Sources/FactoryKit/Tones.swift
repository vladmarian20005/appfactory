import AVFoundation
import SwiftUI

/// Short synthesized sounds for feedback: a pop, a chime, a fanfare, a gentle miss, and a
/// scale to climb for combos and streaks.
///
/// Generated at first use, so there are no audio files to license, bundle or lose. The
/// session is `.ambient`: the ring/silent switch mutes it and it mixes under the user's music
/// instead of stopping it. Quiet under `-stillFrames`, off with the `SoundsToggle`, and silent
/// rather than crashing wherever audio cannot start (a CI simulator has no output device).
///
/// Callable from anywhere; the audio work runs on its own queue.
public final class Tones: @unchecked Sendable {
    public static let shared = Tones()

    /// The `@AppStorage` key behind `SoundsToggle`. On unless the user turns it off.
    public static let storageKey = "factory.sounds"

    public enum Tone: Hashable, Sendable {
        /// A soft tick: selection, a light touch.
        case tap
        /// A rising bloop: a piece landing, a pour arriving, a card flipping.
        case pop
        /// Two notes up: a right answer, a completed unit.
        case success
        /// An arpeggio that resolves: a level cleared, a round finished.
        case fanfare
        /// Two notes down, soft: a wrong answer. Forgiving, never a buzzer.
        case miss
        /// The nth note of a major pentatonic scale, climbing an octave every five: combos,
        /// streak days, count-ups. Any sequence of steps sounds musical.
        case step(Int)
    }

    public static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: storageKey) as? Bool ?? true
    }

    private let queue = DispatchQueue(label: "factorykit.tones")
    private let engine = AVAudioEngine()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    private var players: [AVAudioPlayerNode] = []
    private var cursor = 0
    private var cache: [Tone: AVAudioPCMBuffer] = [:]
    private var state = State.idle
    private enum State { case idle, running, unavailable }

    private init() {}

    /// Plays `tone`. Overlapping calls layer, up to six at once.
    public func play(_ tone: Tone, volume: Float = 0.8) {
        guard Self.isEnabled, !Motion.isStill else { return }
        queue.async { [self] in
            guard start(), let buffer = buffer(for: tone), !players.isEmpty else { return }
            let player = players[cursor]
            cursor = (cursor + 1) % players.count
            player.volume = volume
            player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
            if !player.isPlaying { player.play() }
        }
    }

    /// Starts the engine and renders every tone ahead of time, so the first sound the user
    /// makes is not the one that arrives late. Call once when the main screen appears.
    public func warmUp() {
        guard Self.isEnabled, !Motion.isStill else { return }
        queue.async { [self] in
            guard start() else { return }
            for tone in [Tone.tap, .pop, .success, .fanfare, .miss] { _ = buffer(for: tone) }
            for n in 0..<10 { _ = buffer(for: .step(n)) }
        }
    }

    private func start() -> Bool {
        switch state {
        case .unavailable:
            return false
        case .running:
            if !engine.isRunning { try? engine.start() }
            return engine.isRunning
        case .idle:
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
                try session.setActive(true)
                for _ in 0..<6 {
                    let node = AVAudioPlayerNode()
                    engine.attach(node)
                    engine.connect(node, to: engine.mainMixerNode, format: format)
                    players.append(node)
                }
                engine.prepare()
                try engine.start()
                state = .running
                return true
            } catch {
                state = .unavailable
                return false
            }
        }
    }

    // MARK: - Synthesis

    private struct Note {
        let hz: Double
        let at: Double
        let length: Double
        let gain: Double
        /// Pitch at the end relative to the start: 1 holds, 2 glides up an octave.
        var bend: Double = 1
    }

    private func notes(for tone: Tone) -> [Note] {
        switch tone {
        case .tap:
            return [Note(hz: 1568, at: 0, length: 0.045, gain: 0.3)]
        case .pop:
            return [Note(hz: 480, at: 0, length: 0.12, gain: 0.6, bend: 2.1)]
        case .success:
            return [Note(hz: 659.25, at: 0, length: 0.2, gain: 0.5),
                    Note(hz: 987.77, at: 0.075, length: 0.34, gain: 0.5)]
        case .fanfare:
            return [Note(hz: 523.25, at: 0, length: 0.24, gain: 0.42),
                    Note(hz: 659.25, at: 0.085, length: 0.24, gain: 0.42),
                    Note(hz: 783.99, at: 0.17, length: 0.26, gain: 0.44),
                    Note(hz: 1046.5, at: 0.255, length: 0.75, gain: 0.52)]
        case .miss:
            return [Note(hz: 392, at: 0, length: 0.16, gain: 0.32),
                    Note(hz: 311.13, at: 0.1, length: 0.3, gain: 0.32)]
        case let .step(n):
            let scale = [523.25, 587.33, 659.25, 783.99, 880.0]
            let i = max(0, n)
            let octave = Double(1 << min(i / scale.count, 2))
            return [Note(hz: scale[i % scale.count] * octave, at: 0, length: 0.2, gain: 0.46)]
        }
    }

    private func buffer(for tone: Tone) -> AVAudioPCMBuffer? {
        if let cached = cache[tone] { return cached }
        let notes = notes(for: tone)
        let rate = format.sampleRate
        let seconds = (notes.map { $0.at + $0.length }.max() ?? 0) + 0.02
        let frames = AVAudioFrameCount(seconds * rate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames),
              let out = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = frames
        for i in 0..<Int(frames) { out[i] = 0 }

        for note in notes {
            let first = Int(note.at * rate)
            let count = Int(note.length * rate)
            var phase = 0.0
            for j in 0..<count {
                let index = first + j
                guard index < Int(frames) else { break }
                let t = Double(j) / rate
                let progress = t / note.length
                phase += 2 * .pi * note.hz * pow(note.bend, progress) / rate
                // A 4 ms attack and a 10 ms release keep every edge free of clicks; the
                // exponential decay between them is what makes it a chime and not a beep.
                let envelope = min(1, t / 0.004) * exp(-5 * progress) * min(1, (note.length - t) / 0.01)
                let voice = sin(phase) + 0.3 * sin(2 * phase) + 0.12 * sin(3 * phase)
                out[index] += Float(voice * envelope * note.gain * 0.3)
            }
        }
        cache[tone] = buffer
        return buffer
    }
}

/// The Settings row for `Tones`. Add it to `SettingsView`'s extra section in any app that
/// makes sound.
public struct SoundsToggle: View {
    @AppStorage(Tones.storageKey) private var on = true

    public init() {}

    public var body: some View {
        Toggle(isOn: $on) {
            Label("Sounds", systemImage: on ? "speaker.wave.2.fill" : "speaker.slash.fill")
        }
    }
}
