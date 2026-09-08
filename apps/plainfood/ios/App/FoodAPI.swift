import Foundation

/// A food as found in Open Food Facts, normalized per 100 g.
struct FoodItem: Identifiable, Hashable {
    let id: String
    let name: String
    let brand: String?
    let kcalPer100g: Double
    let proteinPer100g: Double
    let carbsPer100g: Double
    let fatPer100g: Double
    let servingGrams: Double?
    let barcode: String?

    func scaled(grams: Double) -> (kcal: Double, p: Double, c: Double, f: Double) {
        let k = grams / 100
        return (kcalPer100g * k, proteinPer100g * k, carbsPer100g * k, fatPer100g * k)
    }
}

/// Open Food Facts client. Free, no key. Requires a descriptive User-Agent.
enum FoodAPI {
    static let userAgent = "Plainfood/1.0 (https://vladmarian20005.github.io/appmonkey/plainfood/support)"

    private static func json(_ url: URL) async throws -> [String: Any] {
        var req = URLRequest(url: url)
        req.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.timeoutInterval = 12
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return (try JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
    }

    static func search(_ query: String, limit: Int = 25) async throws -> [FoodItem] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }
        var c = URLComponents(string: "https://search.openfoodfacts.org/search")!
        c.queryItems = [
            .init(name: "q", value: q),
            .init(name: "page_size", value: String(limit)),
            .init(name: "fields", value: "code,product_name,brands,nutriments,serving_size,serving_quantity"),
        ]
        let obj = try await json(c.url!)
        let hits = obj["hits"] as? [[String: Any]] ?? []
        return hits.compactMap(parse)
    }

    static func product(barcode: String) async throws -> FoodItem? {
        let code = barcode.filter(\.isNumber)
        guard !code.isEmpty else { return nil }
        let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(code).json?fields=code,product_name,brands,nutriments,serving_size,serving_quantity")!
        let obj = try await json(url)
        guard (obj["status"] as? Int) == 1, let p = obj["product"] as? [String: Any] else { return nil }
        return parse(p)
    }

    private static func num(_ v: Any?) -> Double? {
        if let d = v as? Double { return d }
        if let i = v as? Int { return Double(i) }
        if let s = v as? String { return Double(s.replacingOccurrences(of: ",", with: ".")) }
        return nil
    }

    private static func parse(_ p: [String: Any]) -> FoodItem? {
        let name = (p["product_name"] as? String ?? "").trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return nil }
        let n = p["nutriments"] as? [String: Any] ?? [:]
        var kcal = num(n["energy-kcal_100g"])
        if kcal == nil, let kj = num(n["energy_100g"]) { kcal = kj / 4.184 }
        guard let kcal100 = kcal, kcal100 > 0 else { return nil }
        let brand: String? = {
            if let s = p["brands"] as? String { return s.split(separator: ",").first.map { String($0).trimmingCharacters(in: .whitespaces) } }
            if let a = p["brands"] as? [String] { return a.first }
            return nil
        }()
        var serving = num(p["serving_quantity"])
        if serving == nil, let s = p["serving_size"] as? String {
            let digits = s.replacingOccurrences(of: ",", with: ".")
            if let m = digits.range(of: #"[0-9]+(\.[0-9]+)?"#, options: .regularExpression), let g = Double(digits[m]), s.lowercased().contains("g") {
                serving = g
            }
        }
        let code = p["code"] as? String
        return FoodItem(
            id: code ?? "\(name)-\(brand ?? "")-\(kcal100)",
            name: name,
            brand: brand,
            kcalPer100g: kcal100,
            proteinPer100g: num(n["proteins_100g"]) ?? 0,
            carbsPer100g: num(n["carbohydrates_100g"]) ?? 0,
            fatPer100g: num(n["fat_100g"]) ?? 0,
            servingGrams: serving,
            barcode: code
        )
    }
}
