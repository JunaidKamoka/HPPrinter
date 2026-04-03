import SwiftUI
import UIKit

// MARK: - PrintablesView

struct PrintablesView: View {
    @StateObject private var data = TemplateDataService.shared
    @State private var selectedCategory: PrintableCategory?
    @State private var selectedItem: PrintableItem?
    @State private var searchText = ""

    private var filteredCategories: [PrintableCategory] {
        guard !searchText.isEmpty else { return data.categories }
        return data.categories.filter {
            $0.categoryName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.bg.ignoresSafeArea()

                if data.isLoading {
                    loadingView
                } else if let category = selectedCategory {
                    // Show items inside selected category
                    categoryItemsView(category: category)
                } else {
                    // Show category grid
                    categoryGridView
                }
            }
            .navigationTitle(selectedCategory?.categoryName ?? "Printables")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        withAnimation(.spring(response: 0.35)) { selectedCategory = nil }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Printables")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(.accent2)
                    }
                    .opacity(selectedCategory != nil ? 1 : 0)
                    .disabled(selectedCategory == nil)
                }
            }
            .sheet(item: $selectedItem) { PrintableDetailView(item: $0) }
        }
        .navigationViewStyle(.stack)
        .task { data.fetchAndSync() }
    }

    // MARK: - Category Grid

    var categoryGridView: some View {
        VStack(spacing: 0) {
            // Search
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundColor(.textTertiary)
                TextField("Search categories…", text: $searchText)
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
            .padding(.horizontal).padding(.top, 10).padding(.bottom, 12)

            // Stats bar
            HStack(spacing: 16) {
                statChip(value: "\(data.categories.count)", label: "Categories", icon: "square.grid.2x2.fill", color: .accent)
                statChip(value: "\(data.categories.reduce(0) { $0 + $1.itemCount })", label: "Printables", icon: "photo.stack.fill", color: .appGreen)
            }
            .padding(.horizontal)
            .padding(.bottom, 14)

            if filteredCategories.isEmpty {
                emptyCategoryState
            } else {
                ScrollView {
                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                        spacing: 12
                    ) {
                        ForEach(filteredCategories) { cat in
                            CategoryTile(category: cat) {
                                withAnimation(.spring(response: 0.35)) { selectedCategory = cat }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
        }
    }

    // MARK: - Category Items View

    func categoryItemsView(category: PrintableCategory) -> some View {
        VStack(spacing: 0) {
            // Category header
            HStack(spacing: 12) {
                Text(category.emoji)
                    .font(.system(size: 28))
                    .frame(width: 52, height: 52)
                    .background(
                        LinearGradient(
                            colors: category.gradientColors.map { Color(hex: $0) },
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 3) {
                    Text(category.categoryName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.textPrimary)
                    Text("\(category.itemCount) printables")
                        .font(.system(size: 12))
                        .foregroundColor(.textSecondary)
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            ScrollView {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10)
                    ],
                    spacing: 10
                ) {
                    ForEach(category.items.deduplicated()) { item in
                        PrintableItemCard(item: item) {
                            selectedItem = item
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
    }

    // MARK: - Loading

    var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .accent))
                .scaleEffect(1.4)
            Text("Loading printables…")
                .font(.system(size: 14)).foregroundColor(.textSecondary)
        }
    }

    var emptyCategoryState: some View {
        VStack(spacing: 12) {
            Text("🎨").font(.system(size: 40))
            Text("No categories found").font(.system(size: 16, weight: .semibold)).foregroundColor(.textPrimary)
            Text("Try a different search term.")
                .font(.system(size: 13)).foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 60)
    }

    func statChip(value: String, label: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.textPrimary)
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(Color.bg2)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.cardBorder, lineWidth: 1))
    }
}

// MARK: - CategoryTile

struct CategoryTile: View {
    let category: PrintableCategory
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Gradient header with emoji
                ZStack {
                    LinearGradient(
                        colors: category.gradientColors.map { Color(hex: $0) },
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    VStack(spacing: 6) {
                        Text(category.emoji)
                            .font(.system(size: 36))
                        Text("\(category.itemCount)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 8).padding(.vertical, 2)
                            .background(Color.black.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
                .frame(height: 100)

                // Category name
                VStack(spacing: 3) {
                    Text(category.categoryName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("\(category.itemCount) items")
                        .font(.system(size: 10))
                        .foregroundColor(.textSecondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(Color.bg2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.cardBorder, lineWidth: 1))
            .shadow(color: Color(hex: category.gradientColors[0]).opacity(0.25), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - PrintableItemCard

struct PrintableItemCard: View {
    let item: PrintableItem
    let onTap: () -> Void
    private let size: CGFloat = (UIScreen.main.bounds.width - 52) / 3

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                // Thumbnail — shimmer while loading
                WebImage(url: FirebaseStorageService.thumbnailURL(for: item)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    ZStack {
                        Color.bg3
                        Image(systemName: "photo.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.textTertiary.opacity(0.5))
                    }
                }
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cardBorder, lineWidth: 1))

                // PDF badge
                if item.hasPdf {
                    Text("PDF")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(Color.appRed.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .padding(5)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - PrintableDetailView

struct PrintableDetailView: View {
    let item: PrintableItem
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var vm: AppViewModel
    @State private var currentPage  = 0
    @State private var isPrinting   = false
    @State private var printError: String?

    var body: some View {
        NavigationView {
            ZStack {
                Color.bg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {

                        // Image Gallery
                        printableGallery
                            .padding(.bottom, 20)

                        VStack(alignment: .leading, spacing: 16) {
                            // Badges
                            HStack(spacing: 8) {
                                Text(item.categoryName)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.accent2)
                                    .padding(.horizontal, 10).padding(.vertical, 4)
                                    .background(Color.accent.opacity(0.12))
                                    .clipShape(Capsule())

                                if item.hasPdf {
                                    HStack(spacing: 4) {
                                        Image(systemName: "doc.fill")
                                            .font(.system(size: 10))
                                        Text("PDF")
                                    }
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.appRed)
                                    .padding(.horizontal, 10).padding(.vertical, 4)
                                    .background(Color.appRed.opacity(0.12))
                                    .clipShape(Capsule())
                                }

                                Text("\(item.images.count) page\(item.images.count != 1 ? "s" : "")")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.textTertiary)
                                    .padding(.horizontal, 10).padding(.vertical, 4)
                                    .background(Color.bg3)
                                    .clipShape(Capsule())
                            }

                            // ── PRINT BUTTON ──────────────────────────────────
                            PrintButton(
                                label: item.hasPdf ? "Print PDF" : "Print Image",
                                icon: item.hasPdf ? "doc.fill" : "printer.fill",
                                isLoading: isPrinting,
                                errorMessage: printError
                            ) {
                                printItem()
                            }

                            // Details card
                            AppCard {
                                detailRow(label: "Category", value: item.categoryName)
                                Divider().background(Color.dividerColor).padding(.leading, 16)
                                detailRow(label: "Pages", value: "\(item.images.count)")
                                Divider().background(Color.dividerColor).padding(.leading, 16)
                                detailRow(label: "Format", value: item.hasPdf ? "PDF + Image" : "Image only")
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle(item.categoryName)
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
                    Button { printItem() } label: {
                        Image(systemName: isPrinting ? "hourglass" : "printer.fill")
                            .foregroundColor(.accent)
                    }
                    .disabled(isPrinting)
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Print: prefers PDF, falls back to current page image

    private func printItem() {
        NSLog("[Printables] ══════════════════════════════════")
        NSLog("[Printables] ── printItem() ──")
        NSLog("[Printables]   item: %@", item.categoryName)
        NSLog("[Printables]   isPrinting: %@", isPrinting ? "YES (blocked)" : "NO")

        guard !isPrinting else {
            NSLog("[Printables]   ❌ ABORT — already printing")
            return
        }
        NSLog("[Printables]   checking template access...")
        guard vm.checkTemplateAccess() else {
            NSLog("[Printables]   ❌ ABORT — template access denied (paywall)")
            return
        }
        printError = nil
        isPrinting = true

        let jobName = item.categoryName
        NSLog("[Printables]   hasPdf: %@", item.hasPdf ? "YES" : "NO")

        if item.hasPdf, let pdfName = item.pdfs.first,
           let url = FirebaseStorageService.pdfURL(storagePath: item.storagePath, filename: pdfName) {
            downloadAndPrint(remoteURL: url, jobName: jobName)
        } else {
            // Print first page (all pages visible in the reader above)
            guard let url = FirebaseStorageService.imageURL(for: item, at: 0) else {
                printError = "Image URL unavailable."
                isPrinting = false
                return
            }
            downloadAndPrint(remoteURL: url, jobName: jobName)
        }
    }

    /// Downloads the file and sends it directly to the print controller from memory.
    /// Avoids disk I/O so `canPrint` never gets a missing-file URL.
    private func downloadAndPrint(remoteURL: URL, jobName: String) {
        NSLog("[Printables]   downloading: %@", remoteURL.absoluteString)
        var request = URLRequest(url: remoteURL, cachePolicy: .returnCacheDataElseLoad,
                                 timeoutInterval: 20)
        request.setValue("application/pdf, image/*, */*", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isPrinting = false

                guard let data, !data.isEmpty, error == nil else {
                    NSLog("[Printables]   ❌ Download failed: %@", error?.localizedDescription ?? "no data")
                    printError = "Download failed. Check your connection."
                    return
                }
                NSLog("[Printables]   downloaded %d bytes", data.count)
                if let http = response as? HTTPURLResponse {
                    NSLog("[Printables]   HTTP status: %d", http.statusCode)
                    if http.statusCode != 200 {
                        printError = "Server error (\(http.statusCode))."
                        return
                    }
                }

                // Print directly from data — no temp-file needed
                let canPrintResult = UIPrintInteractionController.canPrint(data)
                NSLog("[Printables]   canPrint(data): %@", canPrintResult ? "YES" : "NO")
                guard canPrintResult else {
                    printError = "This file type cannot be printed."
                    return
                }

                let controller  = UIPrintInteractionController.shared
                let info        = UIPrintInfo.printInfo()
                info.jobName    = jobName
                info.outputType = data.isPDF ? .general : .photo
                controller.printInfo  = info
                controller.printingItem = data
                controller.showsNumberOfCopies = true
                controller.showsPaperSelectionForLoadedPapers = true
                NSLog("[Printables]   presenting print sheet...")
                controller.present(animated: true) { _, completed, _ in
                    NSLog("[Printables]   ── RESULT: %@", completed ? "PRINTED" : "CANCELLED")
                    if completed {
                        vm.consumeFreeTry()
                        let ext     = data.isPDF ? "pdf" : "png"
                        let tempURL = FileManager.default.temporaryDirectory
                            .appendingPathComponent("\(jobName).\(ext)")
                        try? data.write(to: tempURL, options: .atomic)
                        let pages: Int = {
                            guard data.isPDF else { return 1 }
                            return CGPDFDocument(tempURL as CFURL)?.numberOfPages ?? 1
                        }()
                        vm.logHistory(
                            fileName: jobName,
                            fileType: ext,
                            pageCount: pages,
                            source: "Printables",
                            fileURL: tempURL
                        )
                        vm.showToastMessage("Printed: \(jobName)")
                        vm.recordActionAndMaybeRate()
                    }
                }
            }
        }.resume()
    }

    // MARK: - Document Gallery

    var printableGallery: some View {
        Group {
            if item.hasPdf, let pdfName = item.pdfs.first,
               let pdfURL = FirebaseStorageService.pdfURL(storagePath: item.storagePath, filename: pdfName) {
                // PDF printable → show with PDFKit continuous reader
                VStack(alignment: .leading, spacing: 8) {
                    DocumentReaderView(mode: .pdf(pdfURL))
                        .frame(minHeight: 420)
                        .padding(.horizontal)

                    HStack(spacing: 6) {
                        Image(systemName: "doc.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color.accent)
                        Text("PDF · scroll to browse all pages · pinch to zoom")
                            .font(.system(size: 11))
                            .foregroundColor(.textTertiary)
                    }
                    .padding(.horizontal)
                }

            } else if !item.images.isEmpty {
                // Image-based printable → zoomable stacked pages
                let imageURLs = (0..<item.images.count).map {
                    FirebaseStorageService.imageURL(for: item, at: $0)
                }
                VStack(alignment: .leading, spacing: 8) {
                    DocumentReaderView(mode: .images(imageURLs))
                        .padding(.horizontal)

                    if item.images.count > 1 {
                        Text("\(item.images.count) pages — pinch to zoom, double-tap to fit")
                            .font(.system(size: 11))
                            .foregroundColor(.textTertiary)
                            .padding(.horizontal)
                    }
                }

            } else {
                galleryEmptyPlaceholder
                    .padding(.horizontal)
            }
        }
    }

    var galleryEmptyPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo")
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
            Text(value).font(.system(size: 14)).foregroundColor(.textSecondary)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }
}

// MARK: - Helpers

private extension Data {
    /// Returns true if the data begins with the PDF magic bytes `%PDF`.
    var isPDF: Bool {
        count >= 4 && self[0] == 0x25 && self[1] == 0x50 && self[2] == 0x44 && self[3] == 0x46
    }
}

private extension Array where Element: Identifiable {
    /// Removes duplicate elements, keeping the first occurrence of each unique id.
    func deduplicated() -> [Element] {
        var seen = Set<AnyHashable>()
        return filter { seen.insert(AnyHashable($0.id)).inserted }
    }
}
