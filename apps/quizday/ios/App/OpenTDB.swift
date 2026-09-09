import Foundation

/// Practice questions come from the Open Trivia Database, a free community API that needs
/// no key. It is only ever called from the Practice screen; the daily round is bundled and
/// works with no network at all.
enum OpenTDB {
    static let attribution = "Practice questions come from the Open Trivia Database (opentdb.com), licensed CC BY-SA 4.0."

    struct Category: Identifiable, Hashable {
        let id: Int
        let name: String
    }

    /// A subset chosen to line up with the categories in the bundled pack.
    static let categories: [Category] = [
        Category(id: 9, name: "General Knowledge"),
        Category(id: 22, name: "Geography"),
        Category(id: 23, name: "History"),
        Category(id: 17, name: "Science & Nature"),
        Category(id: 27, name: "Animals"),
        Category(id: 25, name: "Art"),
        Category(id: 10, name: "Books"),
        Category(id: 12, name: "Music"),
        Category(id: 11, name: "Film"),
        Category(id: 14, name: "Television"),
        Category(id: 21, name: "Sports"),
        Category(id: 18, name: "Computers"),
        Category(id: 20, name: "Mythology"),
    ]

    enum Difficulty: String, CaseIterable, Identifiable {
        case easy, medium, hard
        var id: String { rawValue }
        var label: String { rawValue.capitalized }
    }

    enum Failure: LocalizedError {
        case rateLimited
        case noQuestions
        case offline
        case server

        var errorDescription: String? {
            switch self {
            case .rateLimited: return "The question service allows one request every few seconds. Try again in a moment."
            case .noQuestions: return "That category and difficulty had no questions left. Try another combination."
            case .offline: return "Practice needs a connection. The daily ten always works offline."
            case .server: return "The question service is not responding right now. Try again shortly."
            }
        }
    }

    private struct Response: Decodable {
        let response_code: Int
        let results: [Result]
    }

    private struct Result: Decodable {
        let category: String
        let difficulty: String
        let question: String
        let correct_answer: String
        let incorrect_answers: [String]
    }

    /// Fetches a practice round. Answers arrive percent-encoded so that quotes and accents
    /// survive the trip intact.
    static func fetch(amount: Int = 10, category: Category, difficulty: Difficulty) async throws -> [QuizItem] {
        var components = URLComponents(string: "https://opentdb.com/api.php")!
        components.queryItems = [
            URLQueryItem(name: "amount", value: String(amount)),
            URLQueryItem(name: "category", value: String(category.id)),
            URLQueryItem(name: "difficulty", value: difficulty.rawValue),
            URLQueryItem(name: "type", value: "multiple"),
            URLQueryItem(name: "encode", value: "url3986"),
        ]
        guard let url = components.url else { throw Failure.server }

        var request = URLRequest(url: url)
        request.timeoutInterval = 20

        let data: Data
        do {
            let (payload, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode == 429 { throw Failure.rateLimited }
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) { throw Failure.server }
            data = payload
        } catch let error as Failure {
            throw error
        } catch let error as URLError where error.code == .notConnectedToInternet || error.code == .networkConnectionLost {
            throw Failure.offline
        } catch {
            throw Failure.server
        }

        let decoded: Response
        do {
            decoded = try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw Failure.server
        }

        switch decoded.response_code {
        case 0: break
        case 1: throw Failure.noQuestions
        case 5: throw Failure.rateLimited
        default: throw Failure.server
        }

        let items: [QuizItem] = decoded.results.enumerated().compactMap { index, result in
            guard let question = decode(result.question),
                  let correct = decode(result.correct_answer) else { return nil }
            let wrong = result.incorrect_answers.compactMap(decode)
            guard wrong.count == 3 else { return nil }
            var answers = wrong + [correct]
            answers.shuffle()
            guard let correctIndex = answers.firstIndex(of: correct) else { return nil }
            return QuizItem(
                id: "otdb-\(category.id)-\(difficulty.rawValue)-\(index)-\(UUID().uuidString.prefix(8))",
                question: question,
                answers: answers,
                correct: correctIndex,
                explanation: nil,
                source: "Open Trivia Database",
                category: decode(result.category) ?? category.name,
                difficulty: result.difficulty
            )
        }

        guard !items.isEmpty else { throw Failure.noQuestions }
        return items
    }

    private static func decode(_ value: String) -> String? {
        value.removingPercentEncoding?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
