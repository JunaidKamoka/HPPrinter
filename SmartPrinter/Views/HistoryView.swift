import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var vm: AppViewModel

    var groupedHistory: [(String, [PrintJob])] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        var groups: [String: [PrintJob]] = [:]
        for job in vm.history {
            let key = formatter.string(from: job.date)
            groups[key, default: []].append(job)
        }
        return groups.sorted { a, b in
            formatter.date(from: a.key) ?? .distantPast > formatter.date(from: b.key) ?? .distantPast
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.bg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        statsRow.padding(.horizontal).padding(.bottom, 16)

                        if vm.history.isEmpty {
                            emptyHistoryView.padding(.horizontal)
                        } else {
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(groupedHistory, id: \.0) { group in
                                    SectionTitle(text: sectionLabel(group.0)).padding(.top, 4)
                                    AppCard {
                                        ForEach(Array(group.1.enumerated()), id: \.element.id) { idx, job in
                                            HistoryRow(job: job)
                                            if idx < group.1.count - 1 {
                                                Divider().background(Color.dividerColor).padding(.leading, 70)
                                            }
                                        }
                                    }
                                }

                                SecondaryButton(title: "Clear All History") { vm.clearHistory() }
                                    .padding(.top, 8)
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(.stack)
    }

    var statsRow: some View {
        HStack(spacing: 8) {
            StatBox(value: "\(vm.totalPagesPrinted)", label: "Total Pages", color: .textPrimary)
            StatBox(value: vm.history.isEmpty ? "—" : "\(Int(vm.successRate * 100))%", label: "Success Rate", color: .appGreen)
            StatBox(value: "\(vm.todayJobCount)", label: "Today", color: .accent2)
        }
    }

    var emptyHistoryView: some View {
        VStack(spacing: 12) {
            Text("🕐").font(.system(size: 36))
            Text("No print history").font(.system(size: 15, weight: .medium)).foregroundColor(.textPrimary)
            Text("Your completed print jobs will appear here.")
                .font(.system(size: 13)).foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    func sectionLabel(_ dateStr: String) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        guard let date = formatter.date(from: dateStr) else { return dateStr }
        if Calendar.current.isDateInToday(date) { return "Today — \(dateStr)" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday — \(dateStr)" }
        return dateStr
    }
}

struct HistoryRow: View {
    @EnvironmentObject var vm: AppViewModel
    let job: PrintJob

    var dayStr: String { "\(Calendar.current.component(.day, from: job.date))" }
    var monStr: String {
        let f = DateFormatter(); f.dateFormat = "MMM"
        return f.string(from: job.date).uppercased()
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(spacing: 2) {
                Text(dayStr).font(.system(size: 18, weight: .bold)).foregroundColor(.textPrimary).lineLimit(1)
                Text(monStr).font(.system(size: 9, weight: .semibold)).foregroundColor(.textTertiary)
            }
            .frame(width: 38)
            .padding(.vertical, 6)
            .background(Color.bg3)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Tap to reprint
            Button {
                vm.reprintFromHistory(job)
            } label: {
                VStack(alignment: .leading, spacing: 3) {
                    Text(job.fileName).font(.system(size: 13, weight: .medium)).foregroundColor(.textPrimary).lineLimit(1)
                    Text("\(job.pageCount) pages · \(job.copies) cop\(job.copies > 1 ? "ies" : "y") · \(job.colorMode) · \(job.printerName)")
                        .font(.system(size: 11)).foregroundColor(.textSecondary).lineLimit(1)
                    Text("\(job.formattedDate)\(job.duration != nil ? " · \(job.duration!)" : "")")
                        .font(.system(size: 11)).foregroundColor(.textTertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            if job.status == .done {
                BadgeView(text: "✓", fg: .appGreen, bg: .greenBg)
            } else {
                BadgeView(text: "✗", fg: .appRed, bg: .redBg)
            }

            // Per-item delete
            Button {
                vm.removeFromHistory(job)
            } label: {
                Text("✕")
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal, 8).padding(.vertical, 5)
                    .background(Color.bg3)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.cardBorder, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }
}
