import AVFoundation
import FactoryKit
import SwiftUI

/// Pronunciation, on the device and for nothing. No key, no account, no network, and it works
/// in a tunnel — which is the whole reason the spec chose it over a recorded voice.
///
/// It shares `Tones`' ambient session deliberately: the user's music keeps playing and the
/// silent switch silences the app, which is what a phone in a pocket on a train should do.
@MainActor
final class Speech {
    static let shared = Speech()

    /// The Settings key behind *Say it on turn*. On unless the user turns it off.
    static let onTurnKey = "thousand.speakOnTurn"

    static var speaksOnTurn: Bool {
        UserDefaults.standard.object(forKey: onTurnKey) as? Bool ?? true
    }

    private let synthesizer = AVSpeechSynthesizer()

    private init() {}

    /// Reads a headword in Castilian, a little under natural pace so a learner can hear the
    /// shape of it. Silent under the capture tooling, which has no speaker and no patience.
    func say(_ word: Word) {
        guard !Motion.isStill else { return }
        let utterance = AVSpeechUtterance(string: word.spoken)
        utterance.voice = AVSpeechSynthesisVoice(language: "es-ES")
        utterance.rate = 0.46
        utterance.postUtteranceDelay = 0
        synthesizer.stopSpeaking(at: .immediate)
        synthesizer.speak(utterance)
    }
}

/// The Settings row for the speech. Sits above `SoundsToggle()`, because it is the one a
/// learner reaches for first.
struct SayItOnTurnToggle: View {
    @AppStorage(Speech.onTurnKey) private var on = true

    var body: some View {
        Toggle(isOn: $on) {
            Label("Say it on turn", systemImage: on ? "waveform" : "waveform.slash")
        }
    }
}
