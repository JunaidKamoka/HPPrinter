import Foundation

enum JobStatus: String, Codable { case printing, queued, done, failed, nextUp }

struct PrintJob: Identifiable, Codable {
    var id: String
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
    /// Origin of the print job — "Forms" | "Printables" | "Documents" | "PDF Tools" | "Test Print" | "Queue"
    var source: String

    // MARK: - Memberwise init (source has a default for call sites that don't specify)
    init(
        id: String = UUID().uuidString,
        fileName: String,
        fileType: String,
        pageCount: Int,
        printerName: String,
        colorMode: String,
        duplex: Bool,
        paperSize: String,
        copies: Int,
        status: JobStatus,
        progress: Double,
        date: Date = Date(),
        duration: String? = nil,
        fileBookmark: Data? = nil,
        source: String = "Documents"
    ) {
        self.id           = id
        self.fileName     = fileName
        self.fileType     = fileType
        self.pageCount    = pageCount
        self.printerName  = printerName
        self.colorMode    = colorMode
        self.duplex       = duplex
        self.paperSize    = paperSize
        self.copies       = copies
        self.status       = status
        self.progress     = progress
        self.date         = date
        self.duration     = duration
        self.fileBookmark = fileBookmark
        self.source       = source
    }

    // MARK: - Custom Codable — decodeIfPresent for `source` so old saved jobs load cleanly

    enum CodingKeys: String, CodingKey {
        case id, fileName, fileType, pageCount, printerName, colorMode, duplex
        case paperSize, copies, status, progress, date, duration, fileBookmark, source
    }

    init(from decoder: Decoder) throws {
        let c        = try decoder.container(keyedBy: CodingKeys.self)
        id           = try c.decodeIfPresent(String.self,    forKey: .id)           ?? UUID().uuidString
        fileName     = try c.decode(String.self,             forKey: .fileName)
        fileType     = try c.decode(String.self,             forKey: .fileType)
        pageCount    = try c.decode(Int.self,                forKey: .pageCount)
        printerName  = try c.decode(String.self,             forKey: .printerName)
        colorMode    = try c.decode(String.self,             forKey: .colorMode)
        duplex       = try c.decode(Bool.self,               forKey: .duplex)
        paperSize    = try c.decode(String.self,             forKey: .paperSize)
        copies       = try c.decode(Int.self,                forKey: .copies)
        status       = try c.decode(JobStatus.self,          forKey: .status)
        progress     = try c.decode(Double.self,             forKey: .progress)
        date         = try c.decode(Date.self,               forKey: .date)
        duration     = try c.decodeIfPresent(String.self,    forKey: .duration)
        fileBookmark = try c.decodeIfPresent(Data.self,      forKey: .fileBookmark)
        source       = try c.decodeIfPresent(String.self,    forKey: .source) ?? "Documents"
    }

    // MARK: - Display helpers

    var fileIcon: String {
        switch fileType.lowercased() {
        case "pdf":                                           return "📄"
        case "jpg", "jpeg", "png", "heic", "heif",
             "gif", "tiff", "bmp":                           return "🖼️"
        case "xlsx", "xls", "csv":                           return "📊"
        case "docx", "doc", "rtf", "txt":                    return "📝"
        case "pptx", "ppt":                                  return "📊"
        case "html", "htm":                                  return "🌐"
        case "printer":                                      return "🖨️"
        default:                                             return "📄"
        }
    }

    var isPrinterEvent: Bool { fileType.lowercased() == "printer" }

    var sourceIcon: String {
        switch source {
        case "Forms":         return "doc.text.fill"
        case "Printables":    return "square.grid.2x2.fill"
        case "PDF Tools":     return "wand.and.stars"
        case "Test Print":    return "printer.fill"
        case "Queue":         return "list.bullet"
        case "Printer":       return "printer.fill"
        case "Writing Paper": return "square.grid.3x3.fill"
        case "Scan":          return "camera.fill"
        default:              return "folder.fill"
        }
    }

    /// Full date + time  e.g. "Mar 26 · 10:47 AM"
    var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d · h:mm a"
        return f.string(from: date)
    }

    /// Short time only — used inline where the date header already shows the day
    var formattedTime: String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }
}
