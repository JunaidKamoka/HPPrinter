import SwiftUI
import UIKit

// MARK: - FormsView

struct FormsView: View {
    @StateObject private var data = TemplateDataService.shared
    @State private var selectedCountry = "All"
    @State private var searchText      = ""
    @State private var selectedForm: FormItem?

    private var countries: [String] { ["All"] + data.allCountries }

    private var filteredForms: [FormItem] {
        let forms: [FormItem]
        if selectedCountry == "All" {
            forms = data.allForms(search: searchText)
        } else {
            forms = data.forms(for: selectedCountry, search: searchText)
        }
        return forms
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.bg.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14))
                            .foregroundColor(.textTertiary)
                        TextField("Search forms…", text: $searchText)
                            .font(.system(size: 14))
                            .foregroundColor(.textPrimary)
                            .autocorrectionDisabled()
                        if !searchText.isEmpty {
                            Button { searchText = "" } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.textTertiary)
                            }
                        }
                    }
                    .padding(.horizontal, 14).padding(.vertical, 11)
                    .background(Color.bg2)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.cardBorder, lineWidth: 1))
                    .padding(.horizontal).padding(.top, 10).padding(.bottom, 8)

                    // Country filter
                    countryFilterBar
                        .padding(.bottom, 10)

                    // Content
                    if data.isLoading {
                        loadingView
                    } else if let err = data.loadError {
                        errorView(err)
                    } else if filteredForms.isEmpty {
                        emptyState
                    } else {
                        formList
                    }
                }
            }
            .navigationTitle("Forms")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedForm) { FormDetailView(form: $0) }
        }
        .navigationViewStyle(.stack)
        .task { data.fetchAndSync() }
    }

    // MARK: - Country Filter Bar

    var countryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(countries, id: \.self) { country in
                    let isSelected = selectedCountry == country
                    Button { withAnimation(.spring(response: 0.3)) { selectedCountry = country } } label: {
                        HStack(spacing: 5) {
                            if country != "All" {
                                Text(countryFlag(country))
                                    .font(.system(size: 13))
                            }
                            Text(country == "All" ? "All" : shortCountry(country))
                                .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                                .foregroundColor(isSelected ? .white : .textSecondary)
                        }
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(isSelected ? Color.accent : Color.bg2)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(
                            isSelected ? Color.accent.opacity(0.5) : Color.cardBorder,
                            lineWidth: 1
                        ))
                        .shadow(color: isSelected ? Color.accent.opacity(0.3) : .clear, radius: 6, y: 3)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Form List

    var formList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredForms.deduplicated()) { form in
                    FormCard(form: form)
                        .onTapGesture { selectedForm = form }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Loading / Empty

    var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .accent))
                .scaleEffect(1.4)
            Text("Loading forms…")
                .font(.system(size: 14)).foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    func errorView(_ msg: String) -> some View {
        VStack(spacing: 12) {
            Text("⚠️").font(.system(size: 36))
            Text("Data not loaded").font(.system(size: 16, weight: .semibold)).foregroundColor(.textPrimary)
            Text(msg).font(.system(size: 13)).foregroundColor(.textSecondary)
                .multilineTextAlignment(.center).padding(.horizontal, 32)
            SecondaryButton(title: "Retry") { data.load() }.padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var emptyState: some View {
        VStack(spacing: 12) {
            Text("🗂️").font(.system(size: 40))
            Text("No forms found").font(.system(size: 16, weight: .semibold)).foregroundColor(.textPrimary)
            Text(searchText.isEmpty ? "No forms available for this country." : "Try a different search term.")
                .font(.system(size: 13)).foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    func countryFlag(_ country: String) -> String {
        switch country {
        case "Canada":                         return "🇨🇦"
        case "France":                         return "🇫🇷"
        case "Germany":                        return "🇩🇪"
        case "Italy":                          return "🇮🇹"
        case "US", "United States of America": return "🇺🇸"
        case "United Kingdom":                 return "🇬🇧"
        case "india":                          return "🇮🇳"
        default:                               return "🌐"
        }
    }

    func shortCountry(_ country: String) -> String {
        switch country {
        case "United States of America": return "USA"
        case "United Kingdom":           return "UK"
        default:                         return country
        }
    }
}

// MARK: - FormCard

struct FormCard: View {
    let form: FormItem

    var body: some View {
        HStack(alignment: .top, spacing: 13) {
            // Thumbnail — shimmer while loading, placeholder on failure
            FormThumbnail(form: form)

            // Metadata
            VStack(alignment: .leading, spacing: 6) {
                // Country + pages badges
                HStack(spacing: 6) {
                    Text("\(form.countryFlag) \(shortCountry(form.country))")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.textTertiary)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(Color.bg4)
                        .clipShape(Capsule())

                    Text("\(form.pageCount) pg")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.accent2)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(Color.accent.opacity(0.12))
                        .clipShape(Capsule())

                    Spacer()
                }

                // Title
                Text(form.displayTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                // Subtitle
                if !form.subtitle.isEmpty {
                    Text(form.subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.textSecondary)
                        .lineLimit(1)
                }

                // Description
                if !form.description.isEmpty {
                    Text(form.description)
                        .font(.system(size: 11))
                        .foregroundColor(.textTertiary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Tags (max 3)
                if !form.tags.isEmpty {
                    HStack(spacing: 5) {
                        ForEach(form.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.textTertiary)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.bg4)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.top, 1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.textTertiary.opacity(0.5))
                .padding(.top, 4)
        }
        .padding(13)
        .background(Color.bg2)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.cardBorder, lineWidth: 1))
    }

    func shortCountry(_ c: String) -> String {
        switch c {
        case "United States of America": return "USA"
        case "United Kingdom": return "UK"
        default: return c
        }
    }
}

// MARK: - FormThumbnail

struct FormThumbnail: View {
    let form: FormItem
    private let width:  CGFloat = 80
    private let height: CGFloat = 100   // portrait ratio ≈ A4

    var body: some View {
        let url = FirebaseStorageService.thumbnailURL(for: form)
        WebImage(url: url) { image in
            image
                .resizable()
                .scaledToFill()
        } placeholder: {
            // Shown only on actual failure (shimmer shown while loading by WebImage itself)
            thumbnailPlaceholder
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.cardBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
    }

    private var thumbnailPlaceholder: some View {
        ZStack {
            Color.bg3
            VStack(spacing: 5) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.textTertiary.opacity(0.5))
                Text("\(form.pageCount)p")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.textTertiary.opacity(0.7))
            }
        }
    }
}

// MARK: - FormDetailView

struct FormDetailView: View {
    let form: FormItem
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var vm: AppViewModel
    @State private var currentPage = 0
    @State private var isPrinting  = false
    @State private var printError: String?

    var body: some View {
        NavigationView {
            ZStack {
                Color.bg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {

                        // Image Gallery
                        imageGallery
                            .padding(.bottom, 20)

                        VStack(alignment: .leading, spacing: 16) {
                            // Title + badges
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    Text("\(form.countryFlag) \(form.country)")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.textSecondary)
                                        .padding(.horizontal, 10).padding(.vertical, 4)
                                        .background(Color.bg3)
                                        .clipShape(Capsule())

                                    Text("\(form.pageCount) pages")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.accent2)
                                        .padding(.horizontal, 10).padding(.vertical, 4)
                                        .background(Color.accent.opacity(0.12))
                                        .clipShape(Capsule())
                                }

                                Text(form.displayTitle)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.textPrimary)

                                if !form.subtitle.isEmpty {
                                    Text(form.subtitle)
                                        .font(.system(size: 14))
                                        .foregroundColor(.textSecondary)
                                }
                            }

                            // ── PRINT BUTTON ──────────────────────────────────
                            PrintButton(
                                label: "Print This Form",
                                icon: "printer.fill",
                                isLoading: isPrinting,
                                errorMessage: printError
                            ) {
                                printForm()
                            }

                            // Description
                            if !form.description.isEmpty {
                                VStack(alignment: .leading, spacing: 6) {
                                    SectionTitle(text: "About")
                                    Text(form.description)
                                        .font(.system(size: 14))
                                        .foregroundColor(.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }

                            // Tags
                            if !form.tags.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    SectionTitle(text: "Tags")
                                    TagFlow(tags: form.tags)
                                }
                            }

                            // Details card
                            AppCard {
                                detailRow(label: "Country", value: "\(form.countryFlag) \(form.country)")
                                Divider().background(Color.dividerColor).padding(.leading, 16)
                                detailRow(label: "Pages", value: "\(form.pageCount)")
                                Divider().background(Color.dividerColor).padding(.leading, 16)
                                detailRow(label: "Form ID", value: form.id)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle(form.displayTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.textSecondary)
                            .frame(width: 32, height: 32)
                            .background(Color.bg3)
                            .clipShape(Circle())
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        printForm()
                    } label: {
                        Image(systemName: isPrinting ? "hourglass" : "printer.fill")
                            .foregroundColor(.accent)
                    }
                    .disabled(isPrinting)
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Print form — downloads ALL page images → composes a PDF → AirPrint in one job
    private func printForm() {
        NSLog("[Forms] ══════════════════════════════════")
        NSLog("[Forms] ── printForm() ──")
        NSLog("[Forms]   form: %@", form.displayTitle)
        NSLog("[Forms]   isPrinting: %@", isPrinting ? "YES (blocked)" : "NO")

        guard !isPrinting else {
            NSLog("[Forms]   ❌ ABORT — already printing")
            return
        }
        NSLog("[Forms]   checking access...")
        guard vm.checkAccess() else {
            NSLog("[Forms]   ❌ ABORT — access denied (paywall)")
            return
        }
        printError = nil
        isPrinting = true

        let pageCount = form.images.count
        NSLog("[Forms]   pageCount: %d", pageCount)
        guard pageCount > 0 else {
            NSLog("[Forms]   ❌ ABORT — no pages")
            printError = "No pages available to print."
            isPrinting = false
            return
        }

        // Build remote URLs for every page
        let urls: [URL] = (0..<pageCount).compactMap {
            FirebaseStorageService.imageURL(for: form, at: $0)
        }
        guard urls.count == pageCount else {
            printError = "Image URL unavailable."
            isPrinting = false
            return
        }

        // Download all pages in parallel
        let group   = DispatchGroup()
        var images  = [Int: UIImage]()
        var dlError: String?

        for (index, url) in urls.enumerated() {
            group.enter()
            var req = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad,
                                 timeoutInterval: 20)
            req.setValue("image/*", forHTTPHeaderField: "Accept")
            URLSession.shared.dataTask(with: req) { data, response, error in
                defer { group.leave() }
                if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                    dlError = "Server error (\(http.statusCode)) on page \(index + 1)."
                    return
                }
                guard let data, !data.isEmpty, error == nil,
                      let img = UIImage(data: data) else {
                    if dlError == nil { dlError = "Download failed on page \(index + 1)." }
                    return
                }
                images[index] = img
            }.resume()
        }

        group.notify(queue: .global(qos: .userInitiated)) {
            DispatchQueue.main.async {
                isPrinting = false

                if let err = dlError {
                    printError = err
                    return
                }
                guard images.count == pageCount else {
                    printError = "Could not load all pages. Check your connection."
                    return
                }

                // Compose all pages into one in-memory PDF (US Letter)
                let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // 8.5 × 11 pt @ 72 dpi
                let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
                let pdfData  = renderer.pdfData { ctx in
                    for i in 0..<pageCount {
                        guard let img = images[i] else { continue }
                        ctx.beginPage()
                        // Scale image to fill the page while keeping aspect ratio
                        let imgRatio  = img.size.width / img.size.height
                        let pageRatio = pageRect.width / pageRect.height
                        let drawRect: CGRect
                        if imgRatio > pageRatio {
                            let h = pageRect.width / imgRatio
                            drawRect = CGRect(x: 0, y: (pageRect.height - h) / 2,
                                             width: pageRect.width, height: h)
                        } else {
                            let w = pageRect.height * imgRatio
                            drawRect = CGRect(x: (pageRect.width - w) / 2, y: 0,
                                             width: w, height: pageRect.height)
                        }
                        img.draw(in: drawRect)
                    }
                }

                NSLog("[Forms]   PDF composed: %d bytes", pdfData.count)
                guard UIPrintInteractionController.canPrint(pdfData) else {
                    NSLog("[Forms]   ❌ canPrint(pdfData) returned false")
                    printError = "This file cannot be printed."
                    return
                }
                NSLog("[Forms]   ✅ canPrint passed")

                // Save to temp file so PrintJobService can track it
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("form_\(form.id)_all.pdf")
                try? pdfData.write(to: tempURL, options: .atomic)
                NSLog("[Forms]   temp file: %@", tempURL.path)

                let controller = UIPrintInteractionController.shared
                let info       = UIPrintInfo.printInfo()
                info.jobName   = form.displayTitle
                info.outputType = .general
                controller.printInfo                        = info
                controller.printingItem                     = pdfData
                controller.showsNumberOfCopies              = true
                controller.showsPaperSelectionForLoadedPapers = true
                NSLog("[Forms]   presenting print sheet...")
                controller.present(animated: true) { _, completed, _ in
                    NSLog("[Forms]   ── RESULT ──")
                    NSLog("[Forms]   completed: %@", completed ? "YES (printed)" : "NO (cancelled)")
                    if completed {
                        vm.consumeFreeTry()
                        vm.logHistory(
                            fileName: form.displayTitle,
                            fileType: "pdf",
                            pageCount: pageCount,
                            source: "Forms",
                            fileURL: tempURL
                        )
                        vm.showToastMessage("Printed: \(form.displayTitle)")
                        vm.recordActionAndMaybeRate()
                    }
                }
            }
        }
    }

    // MARK: - Image Gallery

    var imageGallery: some View {
        let imageURLs = (0..<form.images.count).map {
            FirebaseStorageService.imageURL(for: form, at: $0)
        }

        return Group {
            if !imageURLs.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    DocumentReaderView(mode: .images(imageURLs))
                        .padding(.horizontal)

                    if form.images.count > 1 {
                        Text("\(form.images.count) pages — pinch to zoom, double-tap to fit")
                            .font(.system(size: 11))
                            .foregroundColor(.textTertiary)
                            .padding(.horizontal)
                    }
                }
            } else {
                // No images decoded yet (unlikely after CodingKeys fix, but safe fallback)
                galleryEmptyPlaceholder
                    .padding(.horizontal)
            }
        }
    }

    var galleryEmptyPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 40))
                .foregroundColor(.textTertiary.opacity(0.35))
            Text("No preview available")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 240)
        .background(Color.bg3)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 14)).foregroundColor(.textPrimary)
            Spacer()
            Text(value).font(.system(size: 14)).foregroundColor(.textSecondary).lineLimit(1)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }
}

// MARK: - PrintButton (reusable across Forms + Printables)

struct PrintButton: View {
    let label: String
    let icon: String
    var isLoading: Bool = false
    var errorMessage: String? = nil
    let action: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Button(action: action) {
                HStack(spacing: 10) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.85)
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Text(isLoading ? "Preparing…" : label)
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    LinearGradient(
                        colors: isLoading
                            ? [Color.bg4, Color.bg4]
                            : [Color.accent, Color.accent2],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(
                    color: isLoading ? .clear : Color.accent.opacity(0.35),
                    radius: 10, y: 5
                )
            }
            .disabled(isLoading)
            .buttonStyle(.plain)

            if let err = errorMessage {
                HStack(spacing: 5) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.appRed)
                    Text(err)
                        .font(.system(size: 12))
                        .foregroundColor(.appRed)
                }
            }
        }
    }
}

// MARK: - Tag Flow (iOS 15 compatible)
// Renders tags in wrapping rows using a GeometryReader-based approach.

struct TagFlow: View {
    let tags: [String]
    var spacing: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            self.buildRows(availableWidth: geo.size.width)
        }
        .frame(height: estimatedHeight())
    }

    private func buildRows(availableWidth: CGFloat) -> some View {
        var rows: [[String]] = [[]]
        var currentRowWidth: CGFloat = 0
        let tagPadding: CGFloat = 32   // horizontal padding inside each chip

        for tag in tags {
            let tagWidth = tagTextWidth(tag) + tagPadding
            if currentRowWidth + tagWidth > availableWidth, !rows[rows.count - 1].isEmpty {
                rows.append([])
                currentRowWidth = 0
            }
            rows[rows.count - 1].append(tag)
            currentRowWidth += tagWidth + spacing
        }

        return VStack(alignment: .leading, spacing: spacing) {
            ForEach(rows.indices, id: \.self) { i in
                HStack(spacing: spacing) {
                    ForEach(rows[i], id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.textSecondary)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(Color.bg3)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.cardBorder, lineWidth: 1))
                    }
                }
            }
        }
    }

    private func tagTextWidth(_ text: String) -> CGFloat {
        let font = UIFont.systemFont(ofSize: 12, weight: .medium)
        return (text as NSString).size(withAttributes: [.font: font]).width
    }

    private func estimatedHeight() -> CGFloat {
        let rowHeight: CGFloat = 30
        let rows = max(1, Int(ceil(Double(tags.count) / 3.0)))
        return CGFloat(rows) * rowHeight + CGFloat(rows - 1) * spacing
    }
}

// MARK: - Data + PDF detection

private extension Data {
    var isPDF: Bool {
        count >= 4 && self[0] == 0x25 && self[1] == 0x50 && self[2] == 0x44 && self[3] == 0x46
    }
}

// MARK: - Deduplication

private extension Array where Element: Identifiable {
    func deduplicated() -> [Element] {
        var seen = Set<AnyHashable>()
        return filter { seen.insert(AnyHashable($0.id)).inserted }
    }
}
