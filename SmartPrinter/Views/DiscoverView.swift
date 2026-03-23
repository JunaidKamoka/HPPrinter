import SwiftUI

struct DiscoverView: View {
    @EnvironmentObject var vm: AppViewModel
    @State private var showManualEntry = false
    @State private var manualHost = ""
    @State private var manualPort = "631"

    var body: some View {
        NavigationView {
            ZStack {
                Color.bg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        scannerArea
                            .padding(.horizontal).padding(.bottom, 4)

                        VStack(alignment: .leading, spacing: 10) {
                            // Saved / Connected printers
                            if !vm.connectedPrinters.isEmpty {
                                SectionTitle(text: "Saved Printers")
                                ForEach(vm.connectedPrinters) { printer in
                                    PrinterDiscoverRow(printer: printer, isSaved: true) {
                                        vm.setPrimary(printer)
                                    }
                                    .contextMenu {
                                        Button { vm.setPrimary(printer) } label: { Label("Set as Primary", systemImage: "star") }
                                        Button(role: .destructive) { vm.removePrinter(printer) } label: { Label("Remove", systemImage: "trash") }
                                    }
                                }
                            }

                            // Discovered on network
                            if !vm.networkPrinters.isEmpty {
                                SectionTitle(text: "Found on Network").padding(.top, 8)
                                ForEach(vm.networkPrinters) { printer in
                                    PrinterDiscoverRow(printer: printer, isSaved: false) {
                                        vm.addPrinter(printer)
                                    }
                                }
                            }

                            // Empty states
                            if vm.connectedPrinters.isEmpty && vm.networkPrinters.isEmpty && !vm.isScanning {
                                VStack(spacing: 12) {
                                    Text("📡").font(.system(size: 36))
                                    Text("No printers found").font(.system(size: 15, weight: .medium)).foregroundColor(.textPrimary)
                                    Text("Make sure your printer is turned on and connected to the same Wi-Fi network.")
                                        .font(.system(size: 13)).foregroundColor(.textSecondary)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                            }

                            SectionTitle(text: "Add Manually").padding(.top, 8)
                            SecondaryButton(title: "+ Add Printer by IP Address") {
                                showManualEntry = true
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { vm.startScan() } label: {
                        Image(systemName: vm.isScanning ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
                            .foregroundColor(.textSecondary)
                            .rotationEffect(.degrees(vm.isScanning ? 360 : 0))
                            .animation(vm.isScanning ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: vm.isScanning)
                            .frame(width: 36, height: 36)
                            .background(Color.bg3)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.08), lineWidth: 1))
                    }
                }
            }
            .alert("Add Printer by IP", isPresented: $showManualEntry) {
                TextField("Hostname or IP", text: $manualHost)
                TextField("Port (default 631)", text: $manualPort)
                Button("Add") {
                    guard !manualHost.isEmpty else { return }
                    let port = Int(manualPort) ?? 631
                    let printer = Printer(name: manualHost, model: "Manual", connectionType: "IP",
                                          hostName: manualHost, port: port)
                    vm.addPrinter(printer)
                    manualHost = ""
                    manualPort = "631"
                }
                Button("Cancel", role: .cancel) {}
            }
            .onAppear { vm.startScan() }
            .onDisappear { vm.stopScan() }
        }
        .navigationViewStyle(.stack)
    }

    var scannerArea: some View {
        ZStack {
            Color.bg2
            VStack(spacing: 12) {
                if vm.isScanning {
                    ScannerFrame()
                    Text("Searching for AirPrint printers...")
                        .font(.system(size: 12))
                        .foregroundColor(.textSecondary)
                } else {
                    let count = vm.discoveryService.discoveredPrinters.count
                    Image(systemName: count > 0 ? "checkmark.circle.fill" : "wifi.slash")
                        .font(.system(size: 32))
                        .foregroundColor(count > 0 ? .appGreen : .textTertiary)
                    Text(count > 0 ? "Found \(count) printer\(count == 1 ? "" : "s")" : "Tap refresh to scan")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
}

struct ScannerFrame: View {
    @State private var scanPos: CGFloat = 0
    let cornerSize: CGFloat = 30
    let borderWidth: CGFloat = 3

    var body: some View {
        ZStack {
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                Path { p in p.move(to: CGPoint(x: 0, y: cornerSize)); p.addLine(to: .zero); p.addLine(to: CGPoint(x: cornerSize, y: 0)) }
                    .stroke(Color.accent2, lineWidth: borderWidth)
                Path { p in p.move(to: CGPoint(x: w - cornerSize, y: 0)); p.addLine(to: CGPoint(x: w, y: 0)); p.addLine(to: CGPoint(x: w, y: cornerSize)) }
                    .stroke(Color.accent2, lineWidth: borderWidth)
                Path { p in p.move(to: CGPoint(x: 0, y: h - cornerSize)); p.addLine(to: CGPoint(x: 0, y: h)); p.addLine(to: CGPoint(x: cornerSize, y: h)) }
                    .stroke(Color.accent2, lineWidth: borderWidth)
                Path { p in p.move(to: CGPoint(x: w - cornerSize, y: h)); p.addLine(to: CGPoint(x: w, y: h)); p.addLine(to: CGPoint(x: w, y: h - cornerSize)) }
                    .stroke(Color.accent2, lineWidth: borderWidth)
                LinearGradient(colors: [.clear, Color.accent2, .clear], startPoint: .leading, endPoint: .trailing)
                    .frame(height: 2)
                    .offset(y: scanPos * (h - 4))
            }
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color.accent2))
        }
        .frame(width: 120, height: 100)
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) { scanPos = 1 }
        }
    }
}

struct PrinterDiscoverRow: View {
    let printer: Printer
    let isSaved: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(Color.bg3).frame(width: 48, height: 48)
                    Text("🖨️").font(.system(size: 22))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(printer.name).font(.system(size: 14, weight: .semibold)).foregroundColor(.textPrimary).lineLimit(1)
                    Text("\(printer.connectionType)\(printer.hostName.isEmpty ? "" : " · \(printer.hostName)")")
                        .font(.system(size: 12)).foregroundColor(.textSecondary).lineLimit(1)
                    if printer.isPrimary {
                        Text("● Primary printer").font(.system(size: 11, weight: .medium)).foregroundColor(.accent2)
                    } else if !printer.model.isEmpty {
                        Text(printer.model).font(.system(size: 11)).foregroundColor(.textTertiary).lineLimit(1)
                    }
                }
                Spacer()
                if isSaved {
                    SignalBarsView(strength: printer.signal)
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.accent)
                }
            }
            .padding(16)
            .background(Color.bg2)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(printer.isPrimary ? Color.accent.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct SignalBarsView: View {
    let strength: SignalStrength
    var barColor: Color {
        switch strength { case .strong: return .appGreen; case .medium: return .appAmber; case .weak_: return .appRed }
    }
    var label: String {
        switch strength { case .strong: return "Excellent"; case .medium: return "Good"; case .weak_: return "Weak" }
    }
    let heights: [CGFloat] = [4, 8, 12, 16]

    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(0..<4, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(isActive(i) ? barColor : Color.textTertiary)
                        .frame(width: 3, height: heights[i])
                }
            }
            Text(label).font(.system(size: 10)).foregroundColor(.textTertiary)
        }
    }

    func isActive(_ index: Int) -> Bool {
        switch strength {
        case .strong: return true
        case .medium: return index < 3
        case .weak_: return index < 1
        }
    }
}
