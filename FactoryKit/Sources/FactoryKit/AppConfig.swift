import Foundation

/// Everything an app in the factory needs to identify itself to the shared kit.
public struct AppConfig: Sendable {
    public let name: String
    public let supportURL: URL
    public let privacyURL: URL
    public let termsURL: URL
    /// StoreKit product identifiers, cheapest first is a good habit.
    public let productIDs: [String]
    /// Numeric App Store id once the app exists in App Store Connect; enables Share and Rate links.
    public let appStoreID: String?

    public init(name: String, supportURL: URL, privacyURL: URL, termsURL: URL, productIDs: [String], appStoreID: String? = nil) {
        self.name = name
        self.supportURL = supportURL
        self.privacyURL = privacyURL
        self.termsURL = termsURL
        self.productIDs = productIDs
        self.appStoreID = appStoreID
    }

    public var appStoreURL: URL? {
        appStoreID.flatMap { URL(string: "https://apps.apple.com/app/id\($0)") }
    }

    public var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
}
