import Foundation

enum PrinterStatus: String, Codable {
    case online, warning, offline
    var label: String {
        switch self { case .online: return "Online"; case .warning: return "Warning"; case .offline: return "Offline" }
    }
    var icon: String {
        switch self { case .online: return "🟢"; case .warning: return "⚠️"; case .offline: return "📴" }
    }
}

enum SignalStrength: String, Codable { case strong, medium, weak_ }

struct Printer: Identifiable, Codable {
    var id: String
    var name: String
    var model: String
    var connectionType: String
    var hostName: String
    var port: Int
    var status: PrinterStatus
    var signal: SignalStrength
    var isPrimary: Bool
    var txtRecord: [String: String]

    var displayAddress: String {
        hostName.isEmpty ? "" : "\(hostName):\(port)"
    }

    init(id: String = UUID().uuidString, name: String, model: String = "", connectionType: String = "AirPrint",
         hostName: String = "", port: Int = 631, status: PrinterStatus = .online,
         signal: SignalStrength = .strong, isPrimary: Bool = false, txtRecord: [String: String] = [:]) {
        self.id = id; self.name = name; self.model = model; self.connectionType = connectionType
        self.hostName = hostName; self.port = port; self.status = status; self.signal = signal
        self.isPrimary = isPrimary; self.txtRecord = txtRecord
    }
}
