import Foundation
import UIKit

// MARK: - Firebase Config
// Priority order for credentials:
//   1. Assets.xcassets → GoogleServiceInfo data asset  (safest — bundled, not tracked separately)
//   2. GoogleService-Info.plist in main bundle          (classic Xcode approach)
//   3. Hardcoded fallback values                        (never crashes in development)

struct FirebaseConfig {

    // MARK: - Plist loading chain

    private static let plist: NSDictionary? = {
        // 1️⃣ Try NSDataAsset from Assets catalog (stored as GoogleServiceInfo.dataset)
        if let asset = NSDataAsset(name: "GoogleServiceInfo"),
           let dict = try? PropertyListSerialization.propertyList(from: asset.data,
                                                                   format: nil) as? NSDictionary {
            return dict
        }
        // 2️⃣ Try classic bundle plist
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path) {
            return dict
        }
        // 3️⃣ No plist found — will use hardcoded fallbacks below
        NSLog("[FirebaseConfig] ⚠️ GoogleService-Info not found in Assets or bundle — using fallback values.")
        return nil
    }()

    // MARK: - Accessors (fallback to known project values so the app never crashes)

    /// e.g. "hpprinter-db35b.firebasestorage.app"
    static var storageBucket: String {
        plist?["STORAGE_BUCKET"] as? String ?? "hpprinter-db35b.firebasestorage.app"
    }

    /// e.g. "hpprinter-db35b"
    static var projectID: String {
        plist?["PROJECT_ID"] as? String ?? "hpprinter-db35b"
    }

    /// Firebase API key
    static var apiKey: String {
        plist?["API_KEY"] as? String ?? ""
    }

    /// Google App ID (used by Analytics / Crashlytics)
    static var googleAppID: String {
        plist?["GOOGLE_APP_ID"] as? String ?? ""
    }
}

// MARK: - Firebase Storage Service

struct FirebaseStorageService {

    private static var baseURL: String {
        "https://firebasestorage.googleapis.com/v0/b/\(FirebaseConfig.storageBucket)/o"
    }

    // JSON storagePaths are relative (e.g. "forms/Canada/cra_t1_income_tax_return").
    // The actual Firebase Storage root is "templates/", so we prepend it.
    private static let pathPrefix = "templates"

    /// Builds a public download URL for a file stored in Firebase Storage.
    /// - Parameters:
    ///   - storagePath: Relative folder path from JSON (e.g. `"forms/Canada/20220906T184712613"`)
    ///   - filename:    File name (e.g. `"thumb_20220906T184712613.png"`)
    static func imageURL(storagePath: String, filename: String) -> URL? {
        guard !storagePath.isEmpty, !filename.isEmpty,
              !FirebaseConfig.storageBucket.isEmpty else { return nil }

        // Prepend root prefix so the full path matches Firebase Storage layout
        let fullPath = "\(pathPrefix)/\(storagePath)/\(filename)"

        // Firebase Storage REST API: every "/" must be percent-encoded as "%2F"
        let encoded = fullPath
            .components(separatedBy: "/")
            .map { $0.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0 }
            .joined(separator: "%2F")

        return URL(string: "\(baseURL)/\(encoded)?alt=media")
    }

    /// Builds a public download URL for a PDF file stored in Firebase Storage.
    static func pdfURL(storagePath: String, filename: String) -> URL? {
        imageURL(storagePath: storagePath, filename: filename)
    }

    /// Thumbnail URL for a `FormItem`
    static func thumbnailURL(for form: FormItem) -> URL? {
        imageURL(storagePath: form.storagePath, filename: form.thumbnail)
    }

    /// Thumbnail URL for a `PrintableItem`
    static func thumbnailURL(for item: PrintableItem) -> URL? {
        imageURL(storagePath: item.storagePath, filename: item.thumbnail)
    }

    /// Full-resolution page image URL (by index) for a `FormItem`
    static func imageURL(for form: FormItem, at index: Int) -> URL? {
        guard index < form.images.count else { return nil }
        return imageURL(storagePath: form.storagePath, filename: form.images[index])
    }

    /// Preview image URL for a `PrintableItem` (single preview PNG)
    static func previewURL(for item: PrintableItem) -> URL? {
        imageURL(storagePath: item.storagePath, filename: item.preview)
    }

    /// Page image URL for a `PrintableItem` by index (maps to `item.images`)
    static func imageURL(for item: PrintableItem, at index: Int) -> URL? {
        guard index < item.images.count else { return nil }
        return imageURL(storagePath: item.storagePath, filename: item.images[index])
    }
}
