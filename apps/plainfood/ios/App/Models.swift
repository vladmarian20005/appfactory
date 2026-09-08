import Foundation
import SwiftData
import SwiftUI

enum Meal: String, CaseIterable, Identifiable, Codable {
    case breakfast, lunch, dinner, snacks
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var symbol: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .snacks: return "leaf.fill"
        }
    }
    static func forNow(_ date: Date = .now) -> Meal {
        let h = Calendar.current.component(.hour, from: date)
        switch h {
        case 4..<11: return .breakfast
        case 11..<15: return .lunch
        case 17..<22: return .dinner
        default: return .snacks
        }
    }
}

@Model
final class FoodEntry {
    var id: UUID
    var date: Date
    var mealRaw: String
    var name: String
    var brand: String?
    /// Per single serving.
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var servings: Double
    var servingLabel: String
    var barcode: String?

    init(date: Date = .now, meal: Meal, name: String, brand: String? = nil, calories: Double, protein: Double, carbs: Double, fat: Double, servings: Double = 1, servingLabel: String = "serving", barcode: String? = nil) {
        self.id = UUID()
        self.date = date
        self.mealRaw = meal.rawValue
        self.name = name
        self.brand = brand
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.servings = servings
        self.servingLabel = servingLabel
        self.barcode = barcode
    }

    var meal: Meal {
        get { Meal(rawValue: mealRaw) ?? .snacks }
        set { mealRaw = newValue.rawValue }
    }
    var totalCalories: Double { calories * servings }
    var totalProtein: Double { protein * servings }
    var totalCarbs: Double { carbs * servings }
    var totalFat: Double { fat * servings }
}

struct Goals {
    @AppStorage("goal.calories") static var calories: Int = 2000
    @AppStorage("goal.protein") static var protein: Int = 150
    @AppStorage("goal.carbs") static var carbs: Int = 200
    @AppStorage("goal.fat") static var fat: Int = 65
}

struct DayTotals {
    var calories = 0.0
    var protein = 0.0
    var carbs = 0.0
    var fat = 0.0
    init(_ entries: [FoodEntry]) {
        for e in entries {
            calories += e.totalCalories
            protein += e.totalProtein
            carbs += e.totalCarbs
            fat += e.totalFat
        }
    }
}

extension Double {
    var kcal: String { "\(Int(rounded()))" }
    var grams: String { "\(Int(rounded()))g" }
}

enum SampleData {
    /// Thirty days of believable entries, used for screenshots and QA (`-sampleData`).
    static func seed(into context: ModelContext) {
        let cal = Calendar.current
        let foods: [(Meal, String, String?, Double, Double, Double, Double)] = [
            (.breakfast, "Greek Yogurt, Nonfat", "Chobani", 90, 16, 6, 0),
            (.breakfast, "Granola", "Nature Valley", 210, 4, 33, 7),
            (.breakfast, "Banana", nil, 105, 1.3, 27, 0.4),
            (.lunch, "Chicken Caesar Salad", "Sweetgreen", 520, 38, 22, 30),
            (.lunch, "Sourdough Slice", nil, 120, 4, 24, 0.8),
            (.dinner, "Salmon Fillet", nil, 367, 40, 0, 22),
            (.dinner, "Jasmine Rice, cooked", nil, 205, 4.2, 45, 0.4),
            (.dinner, "Roasted Broccoli", nil, 55, 3.7, 11, 0.6),
            (.snacks, "Apple", nil, 95, 0.5, 25, 0.3),
            (.snacks, "Almonds, 28g", "Blue Diamond", 160, 6, 6, 14),
            (.snacks, "Protein Bar", "RXBAR", 210, 12, 23, 9),
        ]
        for dayOffset in 0..<30 {
            guard let day = cal.date(byAdding: .day, value: -dayOffset, to: cal.startOfDay(for: .now)) else { continue }
            // vary the day: skip two random days for a realistic streak, drop an item or two
            if dayOffset == 12 || dayOffset == 19 { continue }
            let picks = foods.enumerated().filter { i, _ in (i + dayOffset) % 5 != 0 || dayOffset == 0 }
            for (i, f) in picks {
                let hour: Int
                switch f.0 {
                case .breakfast: hour = 8
                case .lunch: hour = 13
                case .dinner: hour = 19
                case .snacks: hour = 16
                }
                let date = cal.date(bySettingHour: hour, minute: (i * 7) % 60, second: 0, of: day) ?? day
                if dayOffset == 0 && f.0 == .dinner { continue } // today's dinner not logged yet
                let entry = FoodEntry(date: date, meal: f.0, name: f.1, brand: f.2, calories: f.3, protein: f.4, carbs: f.5, fat: f.6, servings: f.1 == "Granola" ? 1.5 : 1)
                context.insert(entry)
            }
        }
        try? context.save()
    }
}
