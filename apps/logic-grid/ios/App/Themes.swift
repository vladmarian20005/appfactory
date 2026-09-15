import Foundation

/// A member of a category, in the two grammatical forms every clue in the app is built from:
/// the subject ("the ferry") and the predicate ("on the ferry"). Any pairing of any two
/// categories reads as a sentence — "Amos is on the ferry", "The salt is carrying"… no:
/// "The ferry is carrying the salt" — without a phrase table per pair of categories.
struct CastMember {
    let short: String
    let subject: String
    let predicate: String
    let preferred: Glyph
}

/// How an ordered category compares. One category on every plate is ordered — an hour, a
/// weight, a berth, a fee — which is what the relational, arithmetic and adjacency clues are
/// about. The templates are the block's own words, so a plate about a quay says "goes out
/// before" and one about a scale says "weighs less than".
struct Ordering {
    let before: String       // "%1 goes out before %2"
    let gap: String          // "%1 goes out %n %u after %2"
    let adjacent: String     // "%1 and %2 go out an hour apart"
    let unit: String         // "hour"
    let unitPlural: String   // "hours"
}

struct CastBlock {
    let id: String
    let caps: String
    let members: [CastMember]
    var ordering: Ordering?

    init(_ id: String, _ caps: String, _ ordering: Ordering? = nil, _ members: [CastMember]) {
        self.id = id
        self.caps = caps
        self.members = members
        self.ordering = ordering
    }
}

private func member(_ short: String, _ subject: String, _ predicate: String, _ glyph: Glyph) -> CastMember {
    CastMember(short: short, subject: subject, predicate: predicate, preferred: glyph)
}

/// The shop's whole cast. Blocks are reused across themes, which is why thirty-two subjects
/// cost what four do.
enum Cast {
    // MARK: People

    static let hands = CastBlock("hands", "Hands", nil, [
        member("Amos", "Amos", "Amos's", .hand),
        member("Brice", "Brice", "Brice's", .chest),
        member("Dyer", "Dyer", "Dyer's", .spoon),
        member("Field", "Field", "Field's", .leaf),
        member("Garrow", "Garrow", "Garrow's", .hook),
        member("Holt", "Holt", "Holt's", .feather),
    ])

    static let folk = CastBlock("folk", "Names", nil, [
        member("Nance", "Nance", "Nance's", .candle),
        member("Orrin", "Orrin", "Orrin's", .key),
        member("Pell", "Pell", "Pell's", .jar),
        member("Quill", "Quill", "Quill's", .feather),
        member("Ruddock", "Ruddock", "Ruddock's", .bell),
        member("Speke", "Speke", "Speke's", .hand),
    ])

    static let trades = CastBlock("trades", "Trades", nil, [
        member("chandler", "the chandler", "the chandler", .candle),
        member("cooper", "the cooper", "the cooper", .barrel),
        member("ferryman", "the ferryman", "the ferryman", .steamer),
        member("ropemaker", "the ropemaker", "the ropemaker", .rope),
        member("lamplighter", "the lamplighter", "the lamplighter", .lamp),
        member("pilot", "the pilot", "the pilot", .anchor),
    ])

    // MARK: Things

    static let craft = CastBlock("craft", "Craft", nil, [
        member("ferry", "the ferry", "on the ferry", .steamer),
        member("packet", "the packet", "on the packet", .sloop),
        member("lugger", "the lugger", "on the lugger", .dinghy),
        member("skiff", "the skiff", "on the skiff", .wave),
        member("hoy", "the hoy", "on the hoy", .anchor),
        member("barge", "the barge", "on the barge", .bridge),
    ])

    static let cargo = CastBlock("cargo", "Cargo", nil, [
        member("salt", "the salt", "carrying the salt", .basket),
        member("rope", "the rope", "carrying the rope", .coil),
        member("lamp oil", "the lamp oil", "carrying the lamp oil", .lamp),
        member("apples", "the apples", "carrying the apples", .apple),
        member("hides", "the hides", "carrying the hides", .chest),
        member("tea", "the tea", "carrying the tea", .jar),
    ])

    static let lanes = CastBlock("lanes", "Lanes", nil, [
        member("Frost Lane", "Frost Lane", "on Frost Lane", .moon),
        member("Cutler's Row", "Cutler's Row", "on Cutler's Row", .hook),
        member("Mill Steps", "Mill Steps", "on Mill Steps", .gate),
        member("Anchor Walk", "Anchor Walk", "on Anchor Walk", .anchor),
        member("Kiln Yard", "Kiln Yard", "in Kiln Yard", .kiln),
        member("Bridge End", "Bridge End", "at Bridge End", .bridge),
    ])

    static let beasts = CastBlock("beasts", "Beasts", nil, [
        member("tabby", "the tabby", "keeping the tabby", .moon),
        member("lurcher", "the lurcher", "keeping the lurcher", .hook),
        member("grey mare", "the grey mare", "keeping the grey mare", .gate),
        member("gander", "the gander", "keeping the gander", .feather),
        member("bantam", "the bantam", "keeping the bantam", .leaf),
        member("lop rabbit", "the lop rabbit", "keeping the lop rabbit", .basket),
    ])

    static let inks = CastBlock("inks", "Inks", nil, [
        member("lamp black", "the lamp black", "inked in lamp black", .jar),
        member("prussian", "the prussian", "inked in prussian", .cask),
        member("verdigris", "the verdigris", "inked in verdigris", .leaf),
        member("sanguine", "the sanguine", "inked in sanguine", .kiln),
        member("bistre", "the bistre", "inked in bistre", .candle),
        member("payne's grey", "the payne's grey", "inked in payne's grey", .moon),
    ])

    static let papers = CastBlock("papers", "Papers", nil, [
        member("laid", "the laid sheet", "printed on laid", .feather),
        member("wove", "the wove sheet", "printed on wove", .leaf),
        member("chine", "the chine sheet", "printed on chine", .jar),
        member("blotting", "the blotting sheet", "printed on blotting", .basket),
        member("cartridge", "the cartridge sheet", "printed on cartridge", .chest),
        member("india", "the india sheet", "printed on india", .moon),
    ])

    static let tools = CastBlock("tools", "Tools", nil, [
        member("burin", "the burin", "cutting with the burin", .hook),
        member("scraper", "the scraper", "cutting with the scraper", .spoon),
        member("roulette", "the roulette", "cutting with the roulette", .coil),
        member("rocker", "the rocker", "cutting with the rocker", .gate),
        member("needle", "the needle", "cutting with the needle", .feather),
        member("burnisher", "the burnisher", "cutting with the burnisher", .scale),
    ])

    static let catches = CastBlock("catches", "Catch", nil, [
        member("herring", "the herring", "landing the herring", .fish),
        member("crab", "the crab", "landing the crab", .hook),
        member("eel", "the eel", "landing the eel", .rope),
        member("sprat", "the sprat", "landing the sprat", .wave),
        member("mackerel", "the mackerel", "landing the mackerel", .anchor),
        member("lobster", "the lobster", "landing the lobster", .basket),
    ])

    static let errands = CastBlock("errands", "Errands", nil, [
        member("ledger", "the ledger", "taking the ledger", .chest),
        member("letter", "the letter", "taking the letter", .feather),
        member("parcel", "the parcel", "taking the parcel", .basket),
        member("keys", "the keys", "taking the keys", .key),
        member("lantern", "the lantern", "taking the lantern", .lamp),
        member("pail", "the pail", "taking the pail", .jar),
    ])

    // MARK: The ordered categories

    static let hours = CastBlock("hours", "Hour", Ordering(
        before: "%1 goes out before %2",
        gap: "%1 goes out %n %u after %2",
        adjacent: "%1 and %2 go out an hour apart",
        unit: "hour", unitPlural: "hours"
    ), [
        member("four", "the four o'clock", "at four o'clock", .hourOne),
        member("five", "the five o'clock", "at five o'clock", .hourTwo),
        member("six", "the six o'clock", "at six o'clock", .hourThree),
        member("seven", "the seven o'clock", "at seven o'clock", .hourFour),
        member("eight", "the eight o'clock", "at eight o'clock", .hourFive),
        member("nine", "the nine o'clock", "at nine o'clock", .hourSix),
    ])

    static let weights = CastBlock("weights", "Weight", Ordering(
        before: "%1 weighs less than %2",
        gap: "%1 weighs %n %u more than %2",
        adjacent: "%1 and %2 are one weight apart",
        unit: "pound", unitPlural: "pounds"
    ), [
        member("eight", "the eight-pound load", "at eight pounds", .scale),
        member("nine", "the nine-pound load", "at nine pounds", .scale),
        member("ten", "the ten-pound load", "at ten pounds", .scale),
        member("eleven", "the eleven-pound load", "at eleven pounds", .scale),
        member("twelve", "the twelve-pound load", "at twelve pounds", .scale),
        member("thirteen", "the thirteen-pound load", "at thirteen pounds", .scale),
    ])

    static let berths = CastBlock("berths", "Berth", Ordering(
        before: "%1 lies further up the quay than %2",
        gap: "%1 lies %n %u beyond %2",
        adjacent: "%1 and %2 lie side by side",
        unit: "berth", unitPlural: "berths"
    ), [
        member("one", "berth one", "at berth one", .gate),
        member("two", "berth two", "at berth two", .gate),
        member("three", "berth three", "at berth three", .gate),
        member("four", "berth four", "at berth four", .gate),
        member("five", "berth five", "at berth five", .gate),
        member("six", "berth six", "at berth six", .gate),
    ])

    static let fees = CastBlock("fees", "Fee", Ordering(
        before: "%1 costs less than %2",
        gap: "%1 costs %n %u more than %2",
        adjacent: "%1 and %2 are a shilling apart",
        unit: "shilling", unitPlural: "shillings"
    ), [
        member("two", "the two-shilling fee", "at two shillings", .cask),
        member("three", "the three-shilling fee", "at three shillings", .cask),
        member("four", "the four-shilling fee", "at four shillings", .cask),
        member("five", "the five-shilling fee", "at five shillings", .cask),
        member("six", "the six-shilling fee", "at six shillings", .cask),
        member("seven", "the seven-shilling fee", "at seven shillings", .cask),
    ])
}

/// A subject for a plate: what it is called, and the blocks it is cast from. The first block
/// is always the people — the plate's answer is read as their rows — and the last is always
/// the ordered one.
struct Theme {
    let id: String
    let title: String
    let blocks: [CastBlock]
}

enum Themes {
    /// Thirty-two subjects, built out of twelve blocks and four ordered ones. A `Mastery` over
    /// these ids, avoiding the last three, is what keeps a theme from coming round twice in a
    /// week while new ones stay mixed through.
    static let all: [Theme] = [
        Theme(id: "ferry", title: "The Six O'Clock Ferry", blocks: [Cast.hands, Cast.craft, Cast.cargo, Cast.lanes, Cast.hours]),
        Theme(id: "quay", title: "Six Berths and a Tide", blocks: [Cast.hands, Cast.craft, Cast.catches, Cast.lanes, Cast.berths]),
        Theme(id: "packet", title: "The Packet at Bridge End", blocks: [Cast.folk, Cast.craft, Cast.errands, Cast.lanes, Cast.hours]),
        Theme(id: "weighbridge", title: "The Weighbridge Book", blocks: [Cast.hands, Cast.cargo, Cast.craft, Cast.lanes, Cast.weights]),
        Theme(id: "shop", title: "A Morning in the Shop", blocks: [Cast.hands, Cast.tools, Cast.inks, Cast.papers, Cast.hours]),
        Theme(id: "press", title: "Four Plates and a Press", blocks: [Cast.folk, Cast.inks, Cast.papers, Cast.tools, Cast.fees]),
        Theme(id: "chandlery", title: "The Chandler's Ledger", blocks: [Cast.trades, Cast.cargo, Cast.lanes, Cast.errands, Cast.fees]),
        Theme(id: "ropewalk", title: "Next Door to the Ropewalk", blocks: [Cast.trades, Cast.tools, Cast.lanes, Cast.errands, Cast.hours]),
        Theme(id: "keepers", title: "Who Keeps What", blocks: [Cast.folk, Cast.beasts, Cast.lanes, Cast.errands, Cast.hours]),
        Theme(id: "market", title: "Market Day on Cutler's Row", blocks: [Cast.hands, Cast.beasts, Cast.cargo, Cast.lanes, Cast.fees]),
        Theme(id: "catch", title: "The Morning Catch", blocks: [Cast.folk, Cast.catches, Cast.craft, Cast.lanes, Cast.weights]),
        Theme(id: "lamps", title: "The Lamplighter's Round", blocks: [Cast.trades, Cast.lanes, Cast.errands, Cast.beasts, Cast.hours]),
        Theme(id: "kiln", title: "Kiln Yard, Half Past Four", blocks: [Cast.hands, Cast.cargo, Cast.tools, Cast.lanes, Cast.hours]),
        Theme(id: "cooperage", title: "The Cooperage Accounts", blocks: [Cast.trades, Cast.cargo, Cast.papers, Cast.errands, Cast.fees]),
        Theme(id: "tide", title: "Out on the Ebb", blocks: [Cast.hands, Cast.craft, Cast.catches, Cast.cargo, Cast.berths]),
        Theme(id: "proofs", title: "Six Proofs to Pull", blocks: [Cast.folk, Cast.papers, Cast.inks, Cast.tools, Cast.hours]),
        Theme(id: "post", title: "The Evening Post", blocks: [Cast.hands, Cast.errands, Cast.lanes, Cast.craft, Cast.hours]),
        Theme(id: "scales", title: "Nothing on the Scales Agrees", blocks: [Cast.folk, Cast.cargo, Cast.catches, Cast.craft, Cast.weights]),
        Theme(id: "harbour", title: "The Harbour Master's Note", blocks: [Cast.trades, Cast.craft, Cast.cargo, Cast.lanes, Cast.berths]),
        Theme(id: "bindery", title: "The Bindery Upstairs", blocks: [Cast.hands, Cast.papers, Cast.tools, Cast.errands, Cast.fees]),
        Theme(id: "hounds", title: "A Yard Full of Hounds", blocks: [Cast.hands, Cast.beasts, Cast.errands, Cast.lanes, Cast.weights]),
        Theme(id: "oil", title: "Lamp Oil and Rope", blocks: [Cast.trades, Cast.cargo, Cast.craft, Cast.errands, Cast.hours]),
        Theme(id: "colours", title: "Six Inks on the Slab", blocks: [Cast.folk, Cast.inks, Cast.tools, Cast.papers, Cast.weights]),
        Theme(id: "bridge", title: "Under the Bridge at Five", blocks: [Cast.hands, Cast.craft, Cast.lanes, Cast.beasts, Cast.hours]),
        Theme(id: "ledger", title: "The Ledger Nobody Balanced", blocks: [Cast.trades, Cast.errands, Cast.papers, Cast.lanes, Cast.fees]),
        Theme(id: "stalls", title: "Stalls Along the Steps", blocks: [Cast.folk, Cast.cargo, Cast.beasts, Cast.lanes, Cast.fees]),
        Theme(id: "gulls", title: "Sprats, Eels and Gulls", blocks: [Cast.hands, Cast.catches, Cast.craft, Cast.errands, Cast.weights]),
        Theme(id: "mooring", title: "Six Moorings Before Dark", blocks: [Cast.trades, Cast.craft, Cast.lanes, Cast.cargo, Cast.berths]),
        Theme(id: "workshop", title: "What the Bench Held", blocks: [Cast.folk, Cast.tools, Cast.inks, Cast.errands, Cast.hours]),
        Theme(id: "cellar", title: "The Cellar Under the Yard", blocks: [Cast.hands, Cast.cargo, Cast.papers, Cast.beasts, Cast.fees]),
        Theme(id: "night", title: "The Night Round", blocks: [Cast.trades, Cast.lanes, Cast.errands, Cast.craft, Cast.hours]),
        Theme(id: "haul", title: "One Long Haul Up the Quay", blocks: [Cast.folk, Cast.cargo, Cast.beasts, Cast.craft, Cast.berths]),
    ]

    static func theme(id: String) -> Theme { all.first { $0.id == id } ?? all[0] }
    static var ids: [String] { all.map(\.id) }
}

/// Numbers as the engraver would punch them: in words, up to the only sizes this app counts.
enum Spelled {
    private static let words = [
        "zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten",
        "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen",
        "eighteen", "nineteen", "twenty",
    ]
    private static let tens = ["", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety"]

    static func out(_ n: Int) -> String {
        switch n {
        case 0...20: return words[n]
        case 21...99:
            let unit = n % 10
            return unit == 0 ? tens[n / 10] : "\(tens[n / 10])-\(words[unit])"
        case 100...999:
            let rest = n % 100
            let hundreds = "\(words[n / 100]) hundred"
            return rest == 0 ? hundreds : "\(hundreds) and \(out(rest))"
        default: return "\(n)"
        }
    }

    /// A date as the day-book would have it: the eleventh of January.
    static func ordinal(_ n: Int) -> String {
        let irregular = [1: "first", 2: "second", 3: "third", 5: "fifth", 8: "eighth",
                         9: "ninth", 12: "twelfth", 20: "twentieth", 21: "twenty-first",
                         22: "twenty-second", 23: "twenty-third", 25: "twenty-fifth",
                         28: "twenty-eighth", 29: "twenty-ninth", 30: "thirtieth", 31: "thirty-first"]
        if let word = irregular[n] { return word }
        return out(n) + "th"
    }

    /// Sentence case, for a line that starts with a number.
    static func capitalised(_ n: Int) -> String {
        let word = out(n)
        return word.prefix(1).uppercased() + word.dropFirst()
    }
}
