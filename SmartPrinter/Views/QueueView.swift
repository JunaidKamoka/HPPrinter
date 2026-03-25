import SwiftUI

struct QueueView: View {
    @EnvironmentObject var vm: AppViewModel
    @State private var showDocPicker = false
    @State private var showPhotoPicker = false
    @State private var showSourcePicker = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 0) {
                        statsRow.padding(.horizontal).padding(.bottom, 16)

                        if vm.queue.isEmpty {
                            emptyQueueView.padding(.horizontal)
                        } else {
                            VStack(spacing: 10) {
                                ForEach(vm.queue) { job in
                                    QueueJobCard(job: job) {
                                        vm.removeFromQueue(job)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }

                        VStack(spacing: 8) {
                            PrimaryButton(title: "Add Print Job") { showSourcePicker = true }
                            if !vm.queue.isEmpty {
                                SecondaryButton(title: "Clear Queue") { vm.clearQueue() }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Print Queue")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showSourcePicker = true } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.textSecondary)
                            .frame(width: 36, height: 36)
                            .background(Color.bg3)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.cardBorder, lineWidth: 1))
                    }
                }
            }
            .confirmationDialog("Add Print Job", isPresented: $showSourcePicker) {
                Button("Files App") { showDocPicker = true }
                Button("Photos") { showPhotoPicker = true }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showDocPicker, onDismiss: {
                if let url = vm.selectedFileURL {
                    vm.selectedFileURL = nil
                    vm.addToQueue(url: url)
                    vm.printDirectly(url: url)
                }
            }) {
                DocumentPicker { url in vm.handlePickedFile(url: url) }
            }
            .sheet(isPresented: $showPhotoPicker, onDismiss: {
                if let url = vm.selectedFileURL {
                    vm.selectedFileURL = nil
                    vm.addToQueue(url: url)
                    vm.printDirectly(url: url)
                }
            }) {
                PhotoPicker { url in vm.handlePickedFile(url: url) }
            }
        }
        .navigationViewStyle(.stack)
    }

    var statsRow: some View {
        HStack(spacing: 8) {
            StatBox(value: "\(vm.queue.count)", label: "Queued", color: .textPrimary)
            StatBox(value: "\(vm.queue.filter { $0.status == .printing }.count)", label: "Printing", color: .appAmber)
            StatBox(value: "\(vm.todayJobCount)", label: "Today", color: .appGreen)
        }
    }

    var emptyQueueView: some View {
        VStack(spacing: 12) {
            Text("📋").font(.system(size: 36))
            Text("Queue is empty").font(.system(size: 15, weight: .medium)).foregroundColor(.textPrimary)
            Text("Add files to print from the Files app or Photos.")
                .font(.system(size: 13)).foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

struct StatBox: View {
    let value: String; let label: String; let color: Color
    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 22, weight: .bold)).foregroundColor(color)
            Text(label).font(.system(size: 11)).foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.bg2)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cardBorder, lineWidth: 1))
    }
}

struct QueueJobCard: View {
    @EnvironmentObject var vm: AppViewModel
    let job: PrintJob
    let onRemove: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.bg3)
                    .frame(width: 42, height: 52)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.cardBorder, lineWidth: 1))
                Text(job.fileIcon).font(.system(size: 20)).offset(x: -3, y: 14)
                Path { p in
                    p.move(to: CGPoint(x: 30, y: 0))
                    p.addLine(to: CGPoint(x: 42, y: 0))
                    p.addLine(to: CGPoint(x: 42, y: 12))
                }
                .fill(Color.bg4)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(job.fileName)
                    .font(.system(size: 13, weight: .medium)).foregroundColor(.textPrimary)
                    .lineLimit(1)
                Text("\(job.pageCount) pg · \(job.copies) cop\(job.copies > 1 ? "ies" : "y") · \(job.colorMode) · \(job.printerName)")
                    .font(.system(size: 11)).foregroundColor(.textSecondary).lineLimit(1)

                HStack(spacing: 8) {
                    BadgeView(text: job.status == .printing ? "Printing" : "Queued",
                              fg: job.status == .printing ? .appAmber : .textTertiary,
                              bg: job.status == .printing ? .amberBg : .bg4)

                    // Print button
                    Button {
                        vm.printFromQueue(job)
                    } label: {
                        Text("Print Now")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.accent2)
                    }
                }
                .padding(.top, 4)
            }

            Spacer(minLength: 4)

            Button(action: onRemove) {
                Text("✕")
                    .font(.system(size: 14))
                    .foregroundColor(.textPrimary)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Color.bg3)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.btnBorder, lineWidth: 1))
            }
        }
        .padding(16)
        .background(Color.bg2)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.cardBorder, lineWidth: 1))
    }
}

struct ProgressBar: View {
    let value: Double
    let color: Color
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2).fill(Color.bg4)
                RoundedRectangle(cornerRadius: 2).fill(color).frame(width: geo.size.width * value)
            }
        }
        .frame(height: 4)
    }
}
