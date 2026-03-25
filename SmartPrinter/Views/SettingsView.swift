import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var vm: AppViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showTestPrintPicker = false

    let paperSizes = ["A4 (210×297mm)", "Letter (8.5×11\")", "A3 (297×420mm)", "Legal (8.5×14\")", "A5 (148×210mm)", "4×6\" Photo"]
    let qualities  = ["Best", "Normal", "Draft", "Economy"]

    var body: some View {
        NavigationView {
            ZStack {
                Color.bg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {

                        // ── Appearance ────────────────────────────────────
                        SectionTitle(text: "Appearance").padding(.horizontal).padding(.top, 8)
                        AppCard {
                            VStack(spacing: 0) {
                                HStack {
                                    Label("Theme", systemImage: themeManager.current.icon)
                                        .font(.system(size: 14))
                                        .foregroundColor(.textPrimary)
                                    Spacer()
                                }
                                .padding(.horizontal, 16).padding(.vertical, 12)
                                Divider().background(Color.dividerColor).padding(.leading, 16)
                                HStack(spacing: 6) {
                                    ForEach(AppTheme.allCases, id: \.self) { theme in
                                        Button {
                                            withAnimation(.spring(response: 0.3)) {
                                                themeManager.current = theme
                                            }
                                        } label: {
                                            HStack(spacing: 5) {
                                                Image(systemName: theme.icon)
                                                    .font(.system(size: 12))
                                                Text(theme.displayName)
                                                    .font(.system(size: 13, weight: .medium))
                                            }
                                            .foregroundColor(themeManager.current == theme ? .white : .textSecondary)
                                            .padding(.horizontal, 12).padding(.vertical, 7)
                                            .background(themeManager.current == theme ? Color.accent : Color.clear)
                                            .clipShape(RoundedRectangle(cornerRadius: 9))
                                            .frame(maxWidth: .infinity)
                                        }
                                    }
                                }
                                .padding(4)
                                .background(Color.bg4)
                                .clipShape(RoundedRectangle(cornerRadius: 13))
                                .padding(.horizontal, 16).padding(.vertical, 10)
                            }
                        }
                        .padding(.horizontal).padding(.bottom, 16)

                        // ── Preview ───────────────────────────────────────
                        SectionTitle(text: "Preview").padding(.horizontal)
                        DocumentPreview(orientation: vm.orientation).padding(.horizontal).padding(.bottom, 16)

                        VStack(alignment: .leading, spacing: 10) {
                            // Copies
                            SectionTitle(text: "Copies")
                            AppCard {
                                HStack {
                                    Text("Number of copies").font(.system(size: 14)).foregroundColor(.textPrimary)
                                    Spacer()
                                    StepperControl(value: $vm.copies, min: 1)
                                }.padding(.horizontal, 16).padding(.vertical, 14)
                            }

                            // Paper & Layout
                            SectionTitle(text: "Paper & Layout").padding(.top, 8)
                            AppCard {
                                HStack {
                                    Text("Paper Size").font(.system(size: 14)).foregroundColor(.textPrimary)
                                    Spacer()
                                    Picker("", selection: $vm.paperSize) {
                                        ForEach(paperSizes, id: \.self) { Text($0).tag($0) }
                                    }
                                    .pickerStyle(.menu).tint(.textSecondary)
                                }
                                .padding(.horizontal, 16).padding(.vertical, 10)
                                Divider().background(Color.dividerColor).padding(.leading, 16)
                                SegmentRow(label: "Orientation", options: ["Portrait", "Landscape"], selection: $vm.orientation)
                                Divider().background(Color.dividerColor).padding(.leading, 16)
                                SegmentRowInt(label: "Pages per Sheet", options: [1, 2, 4], selection: $vm.pagesPerSheet)
                            }

                            // Color & Quality
                            SectionTitle(text: "Color & Quality").padding(.top, 8)
                            AppCard {
                                SegmentRow(label: "Color Mode", options: ["Color", "B&W"], selection: $vm.colorMode)
                                Divider().background(Color.dividerColor).padding(.leading, 16)
                                HStack {
                                    Text("Print Quality").font(.system(size: 14)).foregroundColor(.textPrimary)
                                    Spacer()
                                    Picker("", selection: $vm.printQuality) {
                                        ForEach(qualities, id: \.self) { Text($0).tag($0) }
                                    }
                                    .pickerStyle(.menu).tint(.textSecondary)
                                }
                                .padding(.horizontal, 16).padding(.vertical, 10)
                                Divider().background(Color.dividerColor).padding(.leading, 16)
                                ToggleRow(label: "Two-sided (Duplex)", isOn: $vm.duplexEnabled)
                                Divider().background(Color.dividerColor).padding(.leading, 16)
                                ToggleRow(label: "Collate", isOn: $vm.collateEnabled)
                            }

                            // Advanced
                            SectionTitle(text: "Advanced").padding(.top, 8)
                            AppCard {
                                ToggleRow(label: "Print in Background", isOn: $vm.printInBackground)
                                Divider().background(Color.dividerColor).padding(.leading, 16)
                                ToggleRow(label: "Notifications", isOn: $vm.notificationsEnabled)
                                Divider().background(Color.dividerColor).padding(.leading, 16)
                                ToggleRow(label: "Auto-reconnect", isOn: $vm.autoReconnect)
                                Divider().background(Color.dividerColor).padding(.leading, 16)
                                ToggleRow(label: "Save to History", isOn: $vm.saveHistory)
                            }

                            // Printer info
                            if let printer = vm.primaryPrinter {
                                SectionTitle(text: "Primary Printer").padding(.top, 8)
                                AppCard {
                                    HStack {
                                        Text("Name").font(.system(size: 14)).foregroundColor(.textPrimary)
                                        Spacer()
                                        Text(printer.name).font(.system(size: 14)).foregroundColor(.textSecondary).lineLimit(1)
                                    }.padding(.horizontal, 16).padding(.vertical, 14)
                                    Divider().background(Color.dividerColor).padding(.leading, 16)
                                    HStack {
                                        Text("Connection").font(.system(size: 14)).foregroundColor(.textPrimary)
                                        Spacer()
                                        Text(printer.connectionType).font(.system(size: 14)).foregroundColor(.textSecondary)
                                    }.padding(.horizontal, 16).padding(.vertical, 14)
                                    if !printer.hostName.isEmpty {
                                        Divider().background(Color.dividerColor).padding(.leading, 16)
                                        HStack {
                                            Text("Host").font(.system(size: 14)).foregroundColor(.textPrimary)
                                            Spacer()
                                            Text(printer.hostName).font(.system(size: 14)).foregroundColor(.textSecondary).lineLimit(1)
                                        }.padding(.horizontal, 16).padding(.vertical, 14)
                                    }
                                    if !printer.model.isEmpty {
                                        Divider().background(Color.dividerColor).padding(.leading, 16)
                                        HStack {
                                            Text("Model").font(.system(size: 14)).foregroundColor(.textPrimary)
                                            Spacer()
                                            Text(printer.model).font(.system(size: 14)).foregroundColor(.textSecondary).lineLimit(1)
                                        }.padding(.horizontal, 16).padding(.vertical, 14)
                                    }
                                }
                            }

                            // Actions
                            PrimaryButton(title: "Print Test Page") { showTestPrintPicker = true }.padding(.top, 8)
                            SecondaryButton(title: "Reset to Defaults") { vm.resetSettings() }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { vm.saveSettings() } label: {
                        Image(systemName: "checkmark")
                            .foregroundColor(.textSecondary)
                            .frame(width: 36, height: 36)
                            .background(Color.bg3)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.cardBorder, lineWidth: 1))
                    }
                }
            }
            .sheet(isPresented: $showTestPrintPicker) {
                TestPrintPickerSheet()
            }
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Subviews

struct DocumentPreview: View {
    var orientation: String

    var body: some View {
        let isLandscape = orientation == "Landscape"
        VStack(alignment: .leading, spacing: 10) {
            RoundedRectangle(cornerRadius: 4).fill(Color(hex: "#9ca3af")).frame(width: 120, height: 14)
            ForEach(0..<4, id: \.self) { i in
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "#d1d5db"))
                    .frame(height: 8)
                    .frame(maxWidth: i % 2 == 0 ? .infinity : UIScreen.main.bounds.width * 0.5)
            }
            Spacer(minLength: 8)
            ForEach(0..<3, id: \.self) { i in
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "#d1d5db"))
                    .frame(height: 8)
                    .frame(maxWidth: i % 2 == 0 ? .infinity : UIScreen.main.bounds.width * 0.55)
            }
        }
        .padding(20)
        .frame(height: isLandscape ? 180 : 260)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
    }
}

struct ToggleRow: View {
    let label: String
    @Binding var isOn: Bool
    var body: some View {
        HStack {
            Text(label).font(.system(size: 14)).foregroundColor(.textPrimary)
            Spacer()
            AppToggle(isOn: $isOn)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }
}

struct SegmentRow: View {
    let label: String
    let options: [String]
    @Binding var selection: String
    var body: some View {
        HStack {
            Text(label).font(.system(size: 14)).foregroundColor(.textPrimary)
            Spacer()
            HStack(spacing: 3) {
                ForEach(options, id: \.self) { opt in
                    Button(opt) { selection = opt }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(selection == opt ? .white : .textSecondary)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(selection == opt ? Color.accent : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(3)
            .background(Color.bg4)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
    }
}

struct SegmentRowInt: View {
    let label: String
    let options: [Int]
    @Binding var selection: Int
    var body: some View {
        HStack {
            Text(label).font(.system(size: 14)).foregroundColor(.textPrimary)
            Spacer()
            HStack(spacing: 3) {
                ForEach(options, id: \.self) { opt in
                    Button("\(opt)") { selection = opt }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(selection == opt ? .white : .textSecondary)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(selection == opt ? Color.accent : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(3)
            .background(Color.bg4)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
    }
}

// MARK: - Reusable Controls

struct AppToggle: View {
    @Binding var isOn: Bool
    var body: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule()
                .fill(isOn ? Color.accent : Color.bg4)
                .frame(width: 46, height: 26)
                .overlay(Capsule().stroke(isOn ? Color.accent : Color.btnBorder, lineWidth: 1))
            Circle()
                .fill(Color.white)
                .frame(width: 20, height: 20)
                .shadow(radius: 2)
                .padding(3)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isOn)
        .onTapGesture { isOn.toggle() }
    }
}

struct StepperControl: View {
    @Binding var value: Int
    let min: Int
    var body: some View {
        HStack(spacing: 12) {
            Button { if value > min { value -= 1 } } label: {
                Text("−").font(.system(size: 18))
                    .foregroundColor(.textPrimary)
                    .frame(width: 30, height: 30)
                    .background(Color.bg4)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.btnBorder, lineWidth: 1))
            }
            Text("\(value)").font(.system(size: 16, weight: .semibold)).foregroundColor(.textPrimary).frame(minWidth: 24)
            Button { value += 1 } label: {
                Text("+").font(.system(size: 18))
                    .foregroundColor(.textPrimary)
                    .frame(width: 30, height: 30)
                    .background(Color.bg4)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.btnBorder, lineWidth: 1))
            }
        }
    }
}
