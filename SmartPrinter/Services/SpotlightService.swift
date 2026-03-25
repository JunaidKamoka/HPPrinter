import Foundation
import CoreSpotlight
import UniformTypeIdentifiers
import UIKit

// MARK: - SpotlightService
// Indexes app features and print history into iOS Spotlight Search.
// This is a significant ASO signal — features become discoverable via iPhone search,
// and Siri Suggestions surface the app contextually.

final class SpotlightService {

    static let shared = SpotlightService()
    private init() {}

    // Domain identifiers
    private let featureDomain  = "com.hp.smartprinter.features"
    private let printDomain    = "com.hp.smartprinter.history"
    private let templateDomain = "com.hp.smartprinter.templates"

    // MARK: - Feature Indexing

    /// Index all app features into Spotlight on first launch.
    /// Users can search "print PDF", "sign document", "scan", etc. and find this app.
    func indexAppFeatures() {
        var items: [CSSearchableItem] = []

        let features: [(id: String, title: String, desc: String, keywords: [String])] = [
            // Printing
            ("print-pdf",      "Print PDF",              "Print PDF documents wirelessly via AirPrint to any HP, Canon, Epson, Brother, Lexmark or Samsung printer",
             ["print", "pdf", "airprint", "wireless", "hp", "canon", "epson", "brother", "printer"]),
            ("print-photo",    "Print Photos",           "Print photos from Camera Roll directly to any AirPrint wireless printer",
             ["print", "photos", "pictures", "camera roll", "airprint", "photo printer"]),
            ("print-word",     "Print Word Documents",   "Print DOCX, DOC, Excel and PowerPoint files from your iPhone or iPad",
             ["print", "word", "docx", "excel", "powerpoint", "office", "document"]),

            // PDF Tools
            ("merge-pdf",      "Merge PDF",              "Combine multiple PDF files into one document",
             ["merge", "combine", "join", "pdf", "documents"]),
            ("split-pdf",      "Split PDF",              "Split PDF into separate pages or smaller documents",
             ["split", "separate", "divide", "pdf", "pages"]),
            ("compress-pdf",   "Compress PDF",           "Reduce PDF file size while keeping quality",
             ["compress", "reduce", "shrink", "pdf", "size", "optimize"]),
            ("convert-pdf",    "Convert to PDF",         "Convert Word, Excel, PowerPoint, images and HTML to PDF",
             ["convert", "word to pdf", "image to pdf", "docx to pdf", "jpg to pdf"]),
            ("pdf-to-word",    "PDF to Word",            "Convert PDF documents to editable Word DOCX files",
             ["pdf to word", "convert pdf", "docx", "editable", "extract text"]),
            ("sign-pdf",       "Sign PDF",               "Add digital or handwritten signatures to PDF documents",
             ["sign", "signature", "digital signature", "pdf", "esign", "sign document"]),
            ("protect-pdf",    "Protect PDF",            "Password protect and encrypt PDF files",
             ["protect", "password", "encrypt", "secure", "lock pdf"]),
            ("ocr-pdf",        "OCR — Scan to Text",     "Extract text from scanned PDFs and images using OCR",
             ["ocr", "scan", "text recognition", "extract text", "scanned pdf", "searchable pdf"]),
            ("edit-pdf",       "Edit PDF",               "Edit text, images and content directly in your PDF",
             ["edit pdf", "modify pdf", "change pdf", "pdf editor"]),
            ("annotate-pdf",   "Annotate PDF",           "Add comments, highlights and drawings to PDFs",
             ["annotate", "highlight", "comment", "draw", "markup pdf"]),
            ("rotate-pdf",     "Rotate PDF Pages",       "Rotate, reorder and organise PDF pages",
             ["rotate", "reorder", "flip", "pdf pages", "organise"]),
            ("unlock-pdf",     "Unlock PDF",             "Remove password protection from PDF files",
             ["unlock", "remove password", "decrypt", "unprotect pdf"]),

            // Scan
            ("scan-doc",       "Scan Document",          "Scan physical documents with your camera and save as PDF",
             ["scan", "document scanner", "camera scan", "document to pdf", "digitize"]),

            // Templates
            ("forms",          "Printable Forms",        "Government forms, tax documents, invoices, legal forms ready to print",
             ["forms", "government forms", "tax form", "invoice", "legal form", "printable"]),
            ("printables",     "Printables & Templates", "Print greeting cards, planners, coloring pages, certificates and labels",
             ["printables", "greeting card", "planner", "coloring page", "certificate", "label", "template"]),
            ("writing-paper",  "Writing Paper",          "Print ruled, grid, dot and blank paper sheets",
             ["writing paper", "lined paper", "graph paper", "grid paper", "dot paper", "notebook"]),

            // Discovery
            ("printer-setup",  "Add Wireless Printer",  "Automatically discover and connect to AirPrint printers on your Wi-Fi network",
             ["add printer", "wireless printer setup", "airprint", "wifi printer", "connect printer"]),
            ("print-queue",    "Print Queue",            "Manage and track multiple print jobs in one place",
             ["print queue", "print jobs", "batch print", "track print"]),
        ]

        for f in features {
            let attrs = CSSearchableItemAttributeSet(contentType: .text)
            attrs.title              = f.title
            attrs.contentDescription = f.desc
            attrs.keywords           = f.keywords
            attrs.displayName        = f.title
            attrs.version            = "1"

            let item = CSSearchableItem(
                uniqueIdentifier: "\(featureDomain).\(f.id)",
                domainIdentifier: featureDomain,
                attributeSet: attrs
            )
            item.expirationDate = .distantFuture
            items.append(item)
        }

        CSSearchableIndex.default().indexSearchableItems(items) { error in
            if let error = error {
                NSLog("[Spotlight] Feature indexing error: \(error.localizedDescription)")
            } else {
                NSLog("[Spotlight] ✅ Indexed \(items.count) app features")
            }
        }
    }

    // MARK: - Print History Indexing

    /// Index a completed print job so it appears in Spotlight search.
    func indexPrintJob(id: String, fileName: String, printerName: String, date: Date) {
        let attrs = CSSearchableItemAttributeSet(contentType: .text)
        attrs.title              = fileName
        attrs.contentDescription = "Printed to \(printerName)"
        attrs.keywords           = ["print", "printed", "document", fileName, printerName]
        attrs.displayName        = fileName
        attrs.contentCreationDate = date
        attrs.lastUsedDate       = date

        let item = CSSearchableItem(
            uniqueIdentifier: "\(printDomain).\(id)",
            domainIdentifier: printDomain,
            attributeSet: attrs
        )
        // Keep print history searchable for 30 days
        item.expirationDate = Date().addingTimeInterval(86400 * 30)
        CSSearchableIndex.default().indexSearchableItems([item]) { _ in }
    }

    /// Remove a specific print job from Spotlight index.
    func removePrintJob(id: String) {
        CSSearchableIndex.default().deleteSearchableItems(
            withIdentifiers: ["\(printDomain).\(id)"]
        ) { _ in }
    }

    /// Clear all print history from Spotlight.
    func clearPrintHistory() {
        CSSearchableIndex.default().deleteSearchableItems(
            withDomainIdentifiers: [printDomain]
        ) { _ in }
    }

    // MARK: - NSUserActivity helpers

    /// Create an NSUserActivity for a print action.
    /// Surfaces app in Siri Suggestions when user is about to print something.
    static func printActivity(fileName: String) -> NSUserActivity {
        let activity = NSUserActivity(activityType: "com.hp.smartprinter.print")
        activity.title                   = "Print \(fileName)"
        activity.isEligibleForSearch     = true
        activity.isEligibleForPrediction = true
        activity.persistentIdentifier    = NSUserActivityPersistentIdentifier("print-\(fileName)")
        activity.keywords                = ["print", "airprint", "wireless printer", fileName]

        let attrs = CSSearchableItemAttributeSet(contentType: .text)
        attrs.title              = "Print \(fileName)"
        attrs.contentDescription = "Print documents wirelessly with HP Smart Printer"
        attrs.keywords           = ["print", "airprint", "hp printer", "canon", "epson", "wireless"]
        activity.contentAttributeSet     = attrs
        return activity
    }

    /// Create an NSUserActivity for the PDF tools screen.
    static func pdfToolsActivity() -> NSUserActivity {
        let activity = NSUserActivity(activityType: "com.hp.smartprinter.convert.pdf")
        activity.title                   = "PDF Tools — Merge, Split, Convert, Sign"
        activity.isEligibleForSearch     = true
        activity.isEligibleForPrediction = true
        activity.persistentIdentifier    = NSUserActivityPersistentIdentifier("pdf-tools")
        activity.keywords                = ["pdf", "merge pdf", "split pdf", "convert pdf",
                                            "sign pdf", "compress pdf", "ocr", "pdf editor"]

        let attrs = CSSearchableItemAttributeSet(contentType: .text)
        attrs.title              = "PDF Tools"
        attrs.contentDescription = "50+ PDF tools: merge, split, convert, sign, OCR, compress and more"
        attrs.keywords           = Array(activity.keywords)
        activity.contentAttributeSet     = attrs
        return activity
    }

    /// Create an NSUserActivity for the scanner.
    static func scanActivity() -> NSUserActivity {
        let activity = NSUserActivity(activityType: "com.hp.smartprinter.scan")
        activity.title                   = "Scan Document to PDF"
        activity.isEligibleForSearch     = true
        activity.isEligibleForPrediction = true
        activity.persistentIdentifier    = NSUserActivityPersistentIdentifier("scan-doc")
        activity.keywords                = ["scan", "camera", "document scanner", "scan to pdf", "ocr"]
        return activity
    }
}
