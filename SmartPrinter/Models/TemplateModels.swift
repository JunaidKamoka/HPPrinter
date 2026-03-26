import Foundation

// MARK: - Form Models

struct FormItem: Identifiable, Codable {
    let id: String
    let title: String
    let subtitle: String
    let description: String
    let country: String
    let pageCount: Int
    let thumbnail: String
    let images: [String]
    let pdfs: [String]
    let storagePath: String
    let tags: [String]

    // JSON uses "pages" for page images and "sourceFiles" for PDFs
    enum CodingKeys: String, CodingKey {
        case id, title, subtitle, description, country
        case pageCount, thumbnail, storagePath, tags
        case images = "pages"
        case pdfs   = "sourceFiles"
    }

    var countryFlag: String {
        switch country {
        case "Canada":                              return "🇨🇦"
        case "France":                              return "🇫🇷"
        case "Germany":                             return "🇩🇪"
        case "Italy":                               return "🇮🇹"
        case "United States", "US",
             "United States of America":            return "🇺🇸"
        case "United Kingdom":                      return "🇬🇧"
        case "india", "India":                      return "🇮🇳"
        default:                                    return "🌐"
        }
    }

    var displayTitle: String { title.isEmpty ? id : title }
}

// MARK: - Printable Models

struct PrintableItem: Identifiable, Codable {
    let id: String
    let category: String
    let categoryName: String
    let thumbnail: String
    /// Single preview image filename (e.g. "qp_0_20220507T131630669.png")
    let preview: String
    let pdfs: [String]
    let storagePath: String
    let hasPdf: Bool

    // JSON uses "preview" for the preview image and "sourceFiles" for PDFs
    enum CodingKeys: String, CodingKey {
        case id, category, categoryName, thumbnail, preview, storagePath, hasPdf
        case pdfs = "sourceFiles"
    }

    /// Single-element array wrapping `preview` so views can treat printables like multi-page forms.
    var images: [String] { [preview] }
}

struct PrintableCategory: Identifiable, Codable {
    let categoryCode: String
    let categoryName: String
    let icon: String
    let itemCount: Int
    let items: [PrintableItem]

    var id: String { categoryCode }

    var emoji: String {
        switch icon {
        case "anniversary":   return "💍"
        case "baby_shower":   return "👶"
        case "best_wishes":   return "⭐"
        case "congratulations": return "🎉"
        case "christmas":     return "🎄"
        case "coloring":      return "🎨"
        case "earth_day":     return "🌍"
        case "fathers_day":   return "👨"
        case "famous_places": return "🏛️"
        case "friendship":    return "🤝"
        case "graduation":    return "🎓"
        case "gift_tags":     return "🏷️"
        case "get_well":      return "💊"
        case "easter":        return "🐣"
        case "halloween":     return "🎃"
        case "inspiration":   return "💡"
        case "life_quotes":   return "📖"
        case "mothers_day":   return "💐"
        case "note_tags":     return "📝"
        case "planners":      return "📅"
        case "save_the_date": return "📆"
        case "valentines":    return "❤️"
        default:              return "📄"
        }
    }

    var gradientColors: [String] {
        switch icon {
        case "anniversary":   return ["#e879f9", "#a21caf"]
        case "baby_shower":   return ["#60a5fa", "#2563eb"]
        case "best_wishes":   return ["#fbbf24", "#d97706"]
        case "congratulations": return ["#34d399", "#059669"]
        case "christmas":     return ["#f87171", "#dc2626"]
        case "coloring":      return ["#c084fc", "#9333ea"]
        case "earth_day":     return ["#4ade80", "#16a34a"]
        case "fathers_day":   return ["#38bdf8", "#0284c7"]
        case "famous_places": return ["#fb923c", "#ea580c"]
        case "friendship":    return ["#f472b6", "#be185d"]
        case "graduation":    return ["#818cf8", "#4f46e5"]
        case "gift_tags":     return ["#fda4af", "#e11d48"]
        case "get_well":      return ["#6ee7b7", "#10b981"]
        case "easter":        return ["#a78bfa", "#7c3aed"]
        case "halloween":     return ["#fdba74", "#c2410c"]
        case "inspiration":   return ["#fcd34d", "#b45309"]
        case "life_quotes":   return ["#67e8f9", "#0891b2"]
        case "mothers_day":   return ["#f9a8d4", "#db2777"]
        case "note_tags":     return ["#d1d5db", "#6b7280"]
        case "planners":      return ["#6c63ff", "#4338ca"]
        case "save_the_date": return ["#7dd3fc", "#0369a1"]
        case "valentines":    return ["#fb7185", "#e11d48"]
        default:              return ["#9ca3af", "#4b5563"]
        }
    }
}
