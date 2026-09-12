import Foundation

/// One glazed tile's worth of Spanish: the word, what it means, and a sentence that shows it
/// doing its job. Written in `content/band-*.json`, merged and checked by
/// `content/build-deck.mjs`, and bundled as `deck.json`. Nothing here is fetched.
struct Word: Codable, Identifiable, Hashable {
    let word: String
    let translation: String
    let example: String
    let exampleTranslation: String
    /// Index into `Deck.themes`, which is also the index of the glaze it is fired in.
    let theme: Int
    /// 1 is the commonest word in the deck. Ranks run 1…`Deck.total` with no gaps.
    let rank: Int

    var id: Int { rank }

    /// What `AVSpeechSynthesizer` should read: the headword without the slash form, because
    /// "el / la" is a spelling convention and not something anybody says.
    var spoken: String {
        word.components(separatedBy: " / ").first ?? word
    }
}

/// The bundled thousand, loaded once.
enum Deck {
    private struct Payload: Codable {
        let themes: [String]
        let words: [Word]
    }

    private static let payload: Payload = {
        guard let url = Bundle.main.url(forResource: "deck", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(Payload.self, from: data)
        else { return Payload(themes: [], words: []) }
        return decoded
    }()

    static let themes: [String] = payload.themes
    static let words: [Word] = payload.words.sorted { $0.rank < $1.rank }
    static let total: Int = words.count

    private static let index: [Int: Word] = Dictionary(uniqueKeysWithValues: words.map { ($0.rank, $0) })
    private static let panels: [[Word]] = (0..<max(themes.count, 1)).map { theme in
        words.filter { $0.theme == theme }
    }

    static func word(rank: Int) -> Word? { index[rank] }

    static func panel(_ theme: Int) -> [Word] {
        theme >= 0 && theme < panels.count ? panels[theme] : []
    }

    static func themeName(_ theme: Int) -> String {
        theme >= 0 && theme < themes.count ? themes[theme] : ""
    }

    /// The mark under a hero count. Spelled while the deck really is a thousand, so the app
    /// can never claim a size it does not have.
    static var totalMark: String {
        total == 1000 ? "OF A THOUSAND" : "OF \(total)"
    }

    // MARK: - What one payment opens

    /// The panels anyone can open without buying: the first two, as SPEC.md's free tier says.
    static let freePanels = 2

    /// A word is free if it sits in one of the open panels or inside the first hundred by
    /// frequency. The hundred scattered through the sheeted panels are what shows through the
    /// dust sheet on the Wall.
    static func isFree(_ word: Word) -> Bool {
        word.theme < freePanels || word.rank <= 100
    }

    static let freeWords: [Word] = words.filter(isFree)
}
