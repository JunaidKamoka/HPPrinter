import Foundation

enum JobStatus: String, Codable { case printing, queued, done, failed, nextUp }

struct PrintJob: Identifiable, Codable {
    var id: String = UUID().uuidString
    var fileName: String
    var fileType: String
    var pageCount: Int
    var printerName: String
    var colorMode: String
    var duplex: Bool
    var paperSize: String
    var copies: Int
    var status: JobStatus
    var progress: Double
    var date: Date
    var duration: String?
    var fileBookmark: Data?

    var fileIcon: String {
        switch fileType.lowercased() {
        case "pdf": return "📄"
        case "jpg", "jpeg", "png", "heic", "heif", "gif", "tiff", "bmp": return "🖼️"
        case "xlsx", "xls", "csv": return "📊"
        case "docx", "doc", "rtf", "txt": return "📝"
        case "pptx", "ppt": return "📊"
        case "html", "htm": return "🌐"
        default: return "📄"
        }
    }

    var formattedDate: String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }
}
