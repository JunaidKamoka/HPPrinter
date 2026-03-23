import SwiftUI

struct HomeView: View {
    @EnvironmentObject var vm: AppViewModel
    @State private var showDocPicker = false
    @State private var showPhotoPicker = false
    @State private var showTestPrintPicker = false
    @State private var showWritingPaper = false
    @State private var showPDFTools = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 0) {
                        heroBanner
                            .padding(.horizontal).padding(.bottom, 16)

                        quickActions
                            .padding(.horizontal).padding(.bottom, 8)

                        VStack(alignment: .leading, spacing: 10) {
                            if !vm.allKnownPrinters.isEmpty {
                                SectionTitle(text: "Printer Status")
                                printerStatusCard
                            }

                            if !vm.history.isEmpty {
                                SectionTitle(text: "Recent Activity").padding(.top, 8)
                                recentActivityCard
                            }

                            if vm.allKnownPrinters.isEmpty && vm.history.isEmpty {
                                emptyState
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Smart Printer")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { vm.startScan() } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.textSecondary)
                            .frame(width: 36, height: 36)
                            .background(Color.bg3)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.08), lineWidth: 1))
                    }
                }
            }
            .sheet(isPresented: $showDocPicker, onDismiss: {
                if let url = vm.selectedFileURL {
                    vm.selectedFileURL = nil
                    vm.printDirectly(url: url)
                }
            }) {
                DocumentPicker { url in vm.handlePickedFile(url: url) }
            }
            .sheet(isPresented: $showPhotoPicker, onDismiss: {
                if let url = vm.selectedFileURL {
                    vm.selectedFileURL = nil
                    vm.printDirectly(url: url)
                }
            }) {
                PhotoPicker { url in vm.handlePickedFile(url: url) }
            }
            .sheet(isPresented: $showTestPrintPicker) {
                TestPrintPickerSheet()
            }
            .fullScreenCover(isPresented: $showWritingPaper) {
                WritingPaperView()
            }
            .fullScreenCover(isPresented: $showPDFTools) {
                PDFToolsView()
            }
            .onAppear { if vm.autoReconnect { vm.startScan() } }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Hero Banner
    var heroBanner: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#1e1b4b"), Color(hex: "#312e81"), Color(hex: "#1e1b4b")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            Circle()
                .fill(Color.accent.opacity(0.15))
                .frame(width: 200, height: 200)
                .offset(x: 80, y: -60)

            VStack(alignment: .leading, spacing: 4) {
                Text("🖨️").font(.system(size: 40)).padding(.bottom, 8)

                if let printer = vm.primaryPrinter {
                    Text(printer.name).font(.system(size: 20, weight: .semibold)).foregroundColor(.white)
                    Text("Connected via \(printer.connectionType)\(printer.hostName.isEmpty ? "" : " · \(printer.hostName)")")
                        .font(.system(size: 13)).foregroundColor(.white.opacity(0.6)).padding(.bottom, 16)
                } else {
                    Text("No Printer Connected").font(.system(size: 20, weight: .semibold)).foregroundColor(.white)
                    Text("Tap Find Printer to discover printers on your network")
                        .font(.system(size: 13)).foregroundColor(.white.opacity(0.6)).padding(.bottom, 16)
                }

                HStack(spacing: 8) {
                    HeroStat(value: "\(vm.queue.count)", label: "In Queue")
                    HeroStat(value: "\(vm.totalPagesPrinted)", label: "Printed")
                    HeroStat(value: "\(vm.todayJobCount)", label: "Today")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.accent.opacity(0.3), lineWidth: 1))
    }

    // MARK: - Quick Actions
    var quickActions: some View {
        VStack(spacing: 10) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                QuickActionButton(icon: "📂", title: "Print File", subtitle: "PDF, DOCX, JPG...") {
                    showDocPicker = true
                }
                QuickActionButton(icon: "🖼️", title: "Print Photo", subtitle: "Camera roll") {
                    showPhotoPicker = true
                }
                QuickActionButton(icon: "📡", title: "Find Printer", subtitle: "Wi-Fi & Bluetooth") {
                    vm.startScan()
                }
                QuickActionButton(icon: "🖨️", title: "Test Print", subtitle: "B&W, Color, Label...") {
                    showTestPrintPicker = true
                }
            }
            // PDF Tools — full-width
            Button { showPDFTools = true } label: {
                HStack(spacing: 12) {
                    Text("📄").font(.system(size: 24))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("PDF Tools")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        Text("95 tools — merge, convert, sign, OCR...")
                            .font(.system(size: 11))
                            .foregroundColor(.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.textTertiary)
                }
                .padding(16)
                .background(Color.bg2)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.accent.opacity(0.3), lineWidth: 1))
            }
            .buttonStyle(.plain)
            // Writing Paper — full-width
            Button { showWritingPaper = true } label: {
                HStack(spacing: 12) {
                    Text("📝").font(.system(size: 24))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Writing Paper Generator")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        Text("Grid, dot, lined — generate & print")
                            .font(.system(size: 11))
                            .foregroundColor(.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.textTertiary)
                }
                .padding(16)
                .background(Color.bg2)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.accent.opacity(0.3), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Printer Status Card
    var printerStatusCard: some View {
        AppCard {
            let printers = vm.allKnownPrinters
            ForEach(Array(printers.enumerated()), id: \.element.id) { idx, printer in
                PrinterStatusRow(printer: printer)
                if idx < printers.count - 1 {
                    Divider().background(Color.white.opacity(0.08)).padding(.leading, 64)
                }
            }
        }
    }

    // MARK: - Recent Activity Card
    var recentActivityCard: some View {
        AppCard {
            let recent = Array(vm.history.prefix(5))
            ForEach(Array(recent.enumerated()), id: \.element.id) { idx, job in
                RecentActivityRow(job: job)
                if idx < recent.count - 1 {
                    Divider().background(Color.white.opacity(0.08)).padding(.leading, 64)
                }
            }
        }
    }

    // MARK: - Empty State
    var emptyState: some View {
        VStack(spacing: 16) {
            Text("🖨️").font(.system(size: 48))
            Text("Get Started").font(.system(size: 18, weight: .semibold)).foregroundColor(.textPrimary)
            Text("Find a printer on your network, then pick a file to print.")
                .font(.system(size: 14)).foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)

            PrimaryButton(title: "Find Printers") { vm.startScan() }
                .padding(.top, 8)
        }
        .padding(24)
    }
}

// MARK: - Subviews

struct HeroStat: View {
    let value: String
    let label: String
    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 18, weight: .bold)).foregroundColor(.white)
            Text(label).font(.system(size: 10, weight: .medium)).foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(icon).font(.system(size: 24))
                Text(title).font(.system(size: 13, weight: .semibold)).foregroundColor(.textPrimary)
                Text(subtitle).font(.system(size: 11)).foregroundColor(.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.bg2)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct PrinterStatusRow: View {
    let printer: Printer
    var badgeColor: Color {
        switch printer.status { case .online: return .appGreen; case .warning: return .appAmber; case .offline: return .textTertiary }
    }
    var badgeBg: Color {
        switch printer.status { case .online: return .greenBg; case .warning: return .amberBg; case .offline: return .bg4 }
    }
    var statusDescription: String {
        switch printer.status {
        case .online: return "Ready · \(printer.connectionType)"
        case .warning: return "Warning · Check printer"
        case .offline: return "Offline"
        }
    }
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(printer.status == .online ? Color.greenBg : printer.status == .warning ? Color.amberBg : Color.bg4)
                    .frame(width: 36, height: 36)
                Text(printer.status.icon).font(.system(size: 16))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(printer.name).font(.system(size: 14, weight: .medium)).foregroundColor(.textPrimary).lineLimit(1)
                Text(statusDescription).font(.system(size: 12)).foregroundColor(.textSecondary)
            }
            Spacer()
            BadgeView(text: printer.status.label, fg: badgeColor, bg: badgeBg)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }
}

struct RecentActivityRow: View {
    let job: PrintJob
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(job.status == .done ? Color.blueBg : job.status == .failed ? Color.redBg : Color.amberBg)
                    .frame(width: 36, height: 36)
                Text(job.fileIcon).font(.system(size: 16))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(job.fileName).font(.system(size: 14, weight: .medium)).foregroundColor(.textPrimary).lineLimit(1)
                Text("\(job.pageCount) pages · \(job.colorMode) · \(job.formattedDate)")
                    .font(.system(size: 12)).foregroundColor(.textSecondary)
            }
            Spacer()
            if job.status == .done {
                BadgeView(text: "Done", fg: .appGreen, bg: .greenBg)
            } else if job.status == .failed {
                BadgeView(text: "Failed", fg: .appRed, bg: .redBg)
            } else {
                BadgeView(text: "Printing", fg: .appAmber, bg: .amberBg)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }
}

struct TestPrintPickerSheet: View {
    @EnvironmentObject var vm: AppViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 10) {
                        Text("Select a test print to send to your printer via the native print sheet.")
                            .font(.system(size: 13))
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .padding(.top, 8)

                        ForEach(AppViewModel.testPrints) { tp in
                            Button {
                                dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    vm.sendTestPrint(tp)
                                }
                            } label: {
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.bg3)
                                            .frame(width: 48, height: 48)
                                        Text(tp.icon).font(.system(size: 22))
                                    }
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(tp.name)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.textPrimary)
                                        Text(tp.subtitle)
                                            .font(.system(size: 12))
                                            .foregroundColor(.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "printer.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.accent)
                                }
                                .padding(14)
                                .background(Color.bg2)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            .disabled(vm.isDownloadingTestPrint)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Test Prints")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.accent)
                }
            }
        }
    }
}
