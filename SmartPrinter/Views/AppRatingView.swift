import SwiftUI

struct AppRatingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage: RatingPage = .features
    @State private var selectedEmoji: Int? = nil
    @State private var showThankYou = false
    @State private var animateIn = false
    @State private var categoryIndex = 0
    @State private var featureOffset = 0

    private enum RatingPage {
        case features, rate
    }

    private let emojis = ["😡", "😕", "😐", "😊", "🥰"]
    private let labels = ["Hate it", "Not great", "It's okay", "Love it!", "Amazing!"]

    // MARK: - Feature Data

    private struct Feature {
        let icon: String
        let title: String
        let subtitle: String
        let color: Color
    }

    private struct FeatureCategory {
        let name: String
        let icon: String
        let badge: String
        let color: Color
        let features: [Feature]
    }

    private let categories: [FeatureCategory] = [
        // 1 — PDF Conversion (To PDF)
        FeatureCategory(name: "Convert to PDF", icon: "arrow.right.doc.on.clipboard", badge: "22+", color: .accent, features: [
            Feature(icon: "photo.fill", title: "Image to PDF", subtitle: "JPG, PNG, BMP, SVG, WebP, TIFF, HEIC & PSD to PDF", color: .accent),
            Feature(icon: "doc.text.fill", title: "Office to PDF", subtitle: "Word, Excel, PowerPoint & RTF to PDF", color: .appBlue),
            Feature(icon: "text.book.closed.fill", title: "eBook to PDF", subtitle: "EPUB, MOBI, FB2, CBZ & DjVu to PDF", color: .appGreen),
            Feature(icon: "chevron.left.forwardslash.chevron.right", title: "Code & Data to PDF", subtitle: "JSON, Markdown, TXT, HTML & Email to PDF", color: .appAmber),
            Feature(icon: "doc.viewfinder.fill", title: "XPS to PDF", subtitle: "Convert Microsoft XPS documents to PDF", color: .accent2),
        ]),
        // 2 — PDF Conversion (From PDF)
        FeatureCategory(name: "Convert from PDF", icon: "arrow.left.doc.on.clipboard", badge: "14+", color: .appBlue, features: [
            Feature(icon: "doc.richtext.fill", title: "PDF to Office", subtitle: "Convert PDF to Word, Excel & PowerPoint", color: .appBlue),
            Feature(icon: "photo.on.rectangle", title: "PDF to Images", subtitle: "PDF to JPG, PNG, BMP, SVG, TIFF & WebP", color: .appGreen),
            Feature(icon: "archivebox.fill", title: "PDF to ZIP", subtitle: "Package PDF pages into a ZIP archive", color: .appAmber),
            Feature(icon: "text.badge.checkmark", title: "PDF to PDF/A", subtitle: "Convert to archival-quality PDF/A format", color: .accent),
            Feature(icon: "circle.lefthalf.filled", title: "PDF to Greyscale", subtitle: "Convert color PDFs to black & white", color: .textSecondary),
        ]),
        // 3 — PDF Editing & Enhancement
        FeatureCategory(name: "Edit & Enhance", icon: "pencil.and.outline", badge: "18+", color: .appGreen, features: [
            Feature(icon: "pencil.tip.crop.circle", title: "Edit PDF", subtitle: "Edit text, images & content directly in your PDF", color: .appGreen),
            Feature(icon: "crop", title: "Crop PDF", subtitle: "Crop, rotate, deskew & fix page dimensions", color: .appAmber),
            Feature(icon: "drop.fill", title: "Watermark & Stamps", subtitle: "Add watermarks, stamps & background colors", color: .appBlue),
            Feature(icon: "textformat.123", title: "Page Numbers", subtitle: "Add page numbers, headers & footers", color: .accent),
            Feature(icon: "paintbrush.fill", title: "Text & Colors", subtitle: "Change text color, invert colors & posterize PDF", color: .accent2),
        ]),
        // 4 — PDF Pages & Organization
        FeatureCategory(name: "Pages & Organize", icon: "rectangle.stack.fill", badge: "15+", color: .appAmber, features: [
            Feature(icon: "plus.rectangle.on.rectangle", title: "Merge PDF", subtitle: "Combine multiple PDFs into one document", color: .accent),
            Feature(icon: "scissors", title: "Split & Extract", subtitle: "Split PDF, extract or delete specific pages", color: .appBlue),
            Feature(icon: "arrow.up.arrow.down", title: "Organize Pages", subtitle: "Reverse, divide, add blank pages & reorder", color: .appGreen),
            Feature(icon: "rectangle.split.2x2.fill", title: "Grid & N-Up", subtitle: "Grid combine, N-up layout & booklet creation", color: .appAmber),
            Feature(icon: "arrow.triangle.merge", title: "Alternate Merge", subtitle: "Interleave pages from two PDF documents", color: .accent2),
        ]),
        // 5 — PDF Security
        FeatureCategory(name: "Security & Sign", icon: "lock.shield.fill", badge: "8+", color: .accent2, features: [
            Feature(icon: "lock.fill", title: "Encrypt PDF", subtitle: "Password-protect & encrypt your PDF files", color: .accent),
            Feature(icon: "lock.open.fill", title: "Decrypt & Unlock", subtitle: "Remove passwords & restrictions from PDFs", color: .appBlue),
            Feature(icon: "signature", title: "Sign PDF", subtitle: "Add handwritten & digital signatures to PDFs", color: .appGreen),
            Feature(icon: "checkmark.shield.fill", title: "Validate Signature", subtitle: "Verify digital signatures on PDF documents", color: .appAmber),
            Feature(icon: "eye.slash.fill", title: "Sanitize PDF", subtitle: "Remove hidden data & change permissions", color: .appRed),
        ]),
        // 6 — PDF Text & OCR
        FeatureCategory(name: "Text & OCR", icon: "text.viewfinder", badge: "5+", color: .appBlue, features: [
            Feature(icon: "doc.text.magnifyingglass", title: "OCR PDF", subtitle: "Extract text from scanned documents & images", color: .appBlue),
            Feature(icon: "eye.slash.circle.fill", title: "Find & Redact", subtitle: "Search text and permanently redact sensitive info", color: .appRed),
            Feature(icon: "textformat.abc", title: "Font to Outline", subtitle: "Convert fonts to vector outlines for compatibility", color: .appAmber),
            Feature(icon: "text.justify.left", title: "Extract Tables", subtitle: "Pull tables from PDF into structured data", color: .appGreen),
            Feature(icon: "doc.text.fill", title: "PDF Reader", subtitle: "Full-featured PDF viewer with annotations", color: .accent),
        ]),
        // 7 — PDF Advanced Tools
        FeatureCategory(name: "Advanced Tools", icon: "wrench.and.screwdriver.fill", badge: "12+", color: .appAmber, features: [
            Feature(icon: "wrench.fill", title: "Repair PDF", subtitle: "Fix corrupted or damaged PDF files", color: .appAmber),
            Feature(icon: "square.stack.3d.up.fill", title: "Flatten & Rasterize", subtitle: "Flatten forms & rasterize vector content", color: .accent),
            Feature(icon: "bolt.fill", title: "Linearize PDF", subtitle: "Optimize for fast web viewing & streaming", color: .appBlue),
            Feature(icon: "doc.on.doc.fill", title: "Compare PDFs", subtitle: "Compare two PDFs side-by-side for differences", color: .appGreen),
            Feature(icon: "slider.horizontal.3", title: "PDF Multi-Tool", subtitle: "Batch operations on multiple PDF files at once", color: .accent2),
        ]),
        // 8 — PDF Forms & Metadata
        FeatureCategory(name: "Forms & Metadata", icon: "list.clipboard.fill", badge: "8+", color: .appGreen, features: [
            Feature(icon: "rectangle.and.pencil.and.ellipsis", title: "Form Creator", subtitle: "Design fillable PDF forms with input fields", color: .appGreen),
            Feature(icon: "pencil.line", title: "Form Filler", subtitle: "Fill out existing PDF forms digitally", color: .appBlue),
            Feature(icon: "info.circle.fill", title: "Edit Metadata", subtitle: "View & edit PDF title, author, subject & keywords", color: .appAmber),
            Feature(icon: "bookmark.fill", title: "Bookmarks & TOC", subtitle: "Add bookmarks, table of contents & OCG layers", color: .accent),
            Feature(icon: "paperclip", title: "Attachments", subtitle: "Add, edit & extract file attachments from PDFs", color: .accent2),
        ]),
        // 9 — PDF Extraction & Cleanup
        FeatureCategory(name: "Extract & Clean", icon: "tray.and.arrow.up.fill", badge: "7+", color: .appRed, features: [
            Feature(icon: "photo.stack.fill", title: "Extract Images", subtitle: "Pull all embedded images from a PDF document", color: .appGreen),
            Feature(icon: "doc.badge.gearshape.fill", title: "Extract Attachments", subtitle: "Download files attached inside a PDF", color: .appBlue),
            Feature(icon: "rectangle.badge.minus", title: "Remove Blank Pages", subtitle: "Auto-detect & remove empty pages from PDF", color: .appAmber),
            Feature(icon: "text.badge.minus", title: "Remove Annotations", subtitle: "Strip all comments & annotations from PDF", color: .appRed),
            Feature(icon: "xmark.shield.fill", title: "Remove Metadata", subtitle: "Delete hidden metadata for privacy", color: .accent),
        ]),
        // 10 — Printing Features
        FeatureCategory(name: "Smart Printing", icon: "printer.fill", badge: "10+", color: .accent, features: [
            Feature(icon: "printer.fill", title: "One-Tap AirPrint", subtitle: "Print documents, photos & files instantly to any printer", color: .accent),
            Feature(icon: "wifi", title: "Auto Printer Discovery", subtitle: "Finds HP, Canon, Epson, Brother & 50+ brands on Wi-Fi", color: .appBlue),
            Feature(icon: "photo.fill", title: "Camera Roll Print", subtitle: "Print photos directly from your Camera Roll", color: .appGreen),
            Feature(icon: "checkmark.seal.fill", title: "5 Pro Test Prints", subtitle: "Color, B&W, photo, A4 vector & label test pages", color: .appAmber),
            Feature(icon: "network", title: "Manual IP Connect", subtitle: "Add any printer by IP for full network control", color: .accent2),
        ]),
        // 11 — Queue, History & Settings
        FeatureCategory(name: "Queue & History", icon: "tray.full.fill", badge: "8+", color: .appBlue, features: [
            Feature(icon: "tray.full.fill", title: "Smart Print Queue", subtitle: "Queue multiple files for batch printing", color: .appBlue),
            Feature(icon: "clock.fill", title: "Print History & Stats", subtitle: "Track pages printed, success rate & daily count", color: .appGreen),
            Feature(icon: "gearshape.2.fill", title: "Custom Settings", subtitle: "Paper size, orientation, duplex, quality & color", color: .appAmber),
            Feature(icon: "doc.richtext.fill", title: "All File Types", subtitle: "PDF, DOCX, XLSX, PPTX, images, HTML, TXT & more", color: .accent),
            Feature(icon: "lock.shield.fill", title: "100% Private", subtitle: "No account needed — everything stays on device", color: .appGreen),
        ]),
        // 12 — Writing Paper
        FeatureCategory(name: "Writing Paper", icon: "square.grid.3x3.fill", badge: "4+", color: .appGreen, features: [
            Feature(icon: "squareshape.split.3x3", title: "Grid Paper", subtitle: "Generate printable grid paper with adjustable size", color: .appGreen),
            Feature(icon: "circle.grid.3x3.fill", title: "Dot Paper", subtitle: "Create dot matrix paper for bullet journaling", color: .appBlue),
            Feature(icon: "line.3.horizontal", title: "Lined Paper", subtitle: "Ruled paper with customizable line spacing", color: .appAmber),
            Feature(icon: "rectangle.fill", title: "Blank Paper", subtitle: "Clean blank paper templates ready to print", color: .accent),
            Feature(icon: "doc.text.fill", title: "Document Scan", subtitle: "Scan physical documents with your camera", color: .accent2),
        ]),
    ]

    // Flat list for the "Did you know?" section
    private var allFeatures: [Feature] {
        categories.flatMap { $0.features }
    }

    private var totalToolCount: Int {
        categories.reduce(0) { total, cat in
            let num = Int(cat.badge.replacingOccurrences(of: "+", with: "")) ?? 0
            return total + num
        }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(animateIn ? 0.6 : 0)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 0) {
                if showThankYou {
                    thankYouContent
                } else if currentPage == .features {
                    featuresContent
                } else {
                    ratingContent
                }
            }
            .frame(maxWidth: 340)
            .background(Color.bg2)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.accent.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: Color.accent.opacity(0.15), radius: 30, y: 10)
            .scaleEffect(animateIn ? 1 : 0.8)
            .opacity(animateIn ? 1 : 0)
            .padding(.horizontal, 24)
        }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                animateIn = true
            }
            startAutoRotation()
        }
    }

    // MARK: - Features Showcase

    private var featuresContent: some View {
        VStack(spacing: 12) {
            closeButton

            // App icon
            ZStack {
                Circle()
                    .fill(Color.accent.opacity(0.12))
                    .frame(width: 60, height: 60)
                Image(systemName: "printer.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.accent)
            }

            VStack(spacing: 4) {
                Text("HP Smart Printer")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.textPrimary)

                Text("\(totalToolCount)+ Tools — Your All-in-One Print & PDF Suite")
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Category pill
            let cat = categories[categoryIndex]
            HStack(spacing: 6) {
                Image(systemName: cat.icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(cat.name)
                    .font(.system(size: 12, weight: .semibold))
                Text(cat.badge)
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Capsule())
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(cat.color)
            .clipShape(Capsule())
            .id("cat-\(categoryIndex)")
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .animation(.easeInOut(duration: 0.35), value: categoryIndex)

            // Feature rows (show 3 from current category)
            VStack(spacing: 6) {
                let feats = cat.features
                let count = min(3, feats.count)
                ForEach(0..<count, id: \.self) { offset in
                    let idx = (featureOffset + offset) % feats.count
                    featureRow(feats[idx])
                        .id("feat-\(categoryIndex)-\(idx)-\(featureOffset)")
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
            }
            .padding(.horizontal, 14)
            .animation(.easeInOut(duration: 0.4), value: categoryIndex)
            .animation(.easeInOut(duration: 0.4), value: featureOffset)

            // Category dots
            HStack(spacing: 4) {
                ForEach(0..<categories.count, id: \.self) { i in
                    Circle()
                        .fill(categoryIndex == i ? Color.accent : Color.textTertiary.opacity(0.3))
                        .frame(width: 5, height: 5)
                }
            }
            .padding(.top, 2)

            // CTA button
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    currentPage = .rate
                }
            } label: {
                HStack(spacing: 8) {
                    Text("Rate Your Experience")
                        .font(.system(size: 15, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Color.accent)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 18)

            Button { dismiss() } label: {
                Text("Maybe Later")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.textTertiary)
            }

            Spacer().frame(height: 12)
        }
    }

    private func featureRow(_ feature: Feature) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .fill(feature.color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: feature.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(feature.color)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(feature.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.textPrimary)
                Text(feature.subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(.textSecondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.bg3)
        .clipShape(RoundedRectangle(cornerRadius: 11))
    }

    // MARK: - Rating Content

    private var ratingContent: some View {
        VStack(spacing: 18) {
            closeButton

            ZStack {
                Circle()
                    .fill(Color.accent.opacity(0.15))
                    .frame(width: 64, height: 64)
                Image(systemName: "star.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.accent)
            }

            Text("Are you enjoying\nHP Smart Printer?")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)

            Text("Tap an emoji to let us know!")
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)

            HStack(spacing: 10) {
                ForEach(0..<5) { index in
                    emojiButton(index: index)
                }
            }
            .padding(.horizontal, 16)

            if let selected = selectedEmoji {
                Text(labels[selected])
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.accent2)
                    .transition(.opacity)
            }

            if selectedEmoji != nil {
                Button {
                    submitRating()
                } label: {
                    Text("Submit")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Spacer().frame(height: 18)
        }
    }

    // MARK: - Thank You Content

    private var thankYouContent: some View {
        VStack(spacing: 14) {
            Spacer().frame(height: 28)

            let isPositive = (selectedEmoji ?? 0) >= 3

            ZStack {
                Circle()
                    .fill(isPositive ? Color.appGreen.opacity(0.15) : Color.accent.opacity(0.15))
                    .frame(width: 64, height: 64)
                Text(isPositive ? "🎉" : "🙏")
                    .font(.system(size: 32))
            }

            Text(isPositive ? "Thank you!" : "Thanks for your feedback")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.textPrimary)

            Text(isPositive
                 ? "Your support means a lot!\nPlease rate us on the App Store."
                 : "We'll work hard to improve\nyour experience.")
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)

            if !isPositive {
                VStack(spacing: 6) {
                    Text("Did you know we have \(totalToolCount)+ tools?")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Show PDF tools they might not know about
                    let discoverFeatures = [
                        allFeatures[0],  // Image to PDF
                        allFeatures[10], // Edit PDF
                        allFeatures[25], // Encrypt PDF
                    ]
                    ForEach(0..<discoverFeatures.count, id: \.self) { i in
                        featureRow(discoverFeatures[i])
                    }
                }
                .padding(.horizontal, 14)
            }

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(isPositive ? Color.appGreen : Color.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 20)

            Spacer().frame(height: 20)
        }
    }

    // MARK: - Shared Components

    private var closeButton: some View {
        HStack {
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textTertiary)
                    .frame(width: 30, height: 30)
                    .background(Color.bg3)
                    .clipShape(Circle())
            }
        }
        .padding(.top, 16)
        .padding(.trailing, 16)
    }

    private func emojiButton(index: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedEmoji = index
            }
        } label: {
            Text(emojis[index])
                .font(.system(size: selectedEmoji == index ? 36 : 28))
                .frame(width: 48, height: 48)
                .background(
                    selectedEmoji == index
                    ? Color.accent.opacity(0.2)
                    : Color.bg3
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            selectedEmoji == index ? Color.accent : Color.clear,
                            lineWidth: 2
                        )
                )
                .scaleEffect(selectedEmoji == index ? 1.1 : 1.0)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func startAutoRotation() {
        Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { timer in
            if currentPage != .features || !animateIn {
                timer.invalidate()
                return
            }
            withAnimation {
                let cat = categories[categoryIndex]
                let nextOffset = featureOffset + 3
                if nextOffset >= cat.features.count {
                    // Move to next category
                    featureOffset = 0
                    categoryIndex = (categoryIndex + 1) % categories.count
                } else {
                    featureOffset = nextOffset
                }
            }
        }
    }

    private func submitRating() {
        let rating = RatingService.shared
        let selected = selectedEmoji ?? 2

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showThankYou = true
        }

        if selected >= 3 {
            rating.handlePositiveRating()
        } else if selected == 2 {
            rating.handleNeutralRating()
        } else {
            rating.handleNegativeRating()
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.25)) {
            animateIn = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            isPresented = false
        }
    }
}
