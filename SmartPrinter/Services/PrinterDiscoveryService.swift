import Foundation
import Combine

/// Discovers AirPrint printers on the local network using Bonjour / NetService.
class PrinterDiscoveryService: NSObject, ObservableObject {
    @Published var discoveredPrinters: [Printer] = []
    @Published var isSearching = false

    private var browser: NetServiceBrowser?
    private var services: [NetService] = []
    private var resolving: [NetService] = []

    func startSearch() {
        stop()
        discoveredPrinters.removeAll()
        services.removeAll()
        resolving.removeAll()
        isSearching = true

        browser = NetServiceBrowser()
        browser?.delegate = self
        // AirPrint uses _ipp._tcp for Internet Printing Protocol
        browser?.searchForServices(ofType: "_ipp._tcp.", inDomain: "local.")
    }

    func stop() {
        browser?.stop()
        browser = nil
        for svc in resolving { svc.stop() }
        resolving.removeAll()
        isSearching = false
    }

    private func printerFrom(service: NetService) -> Printer {
        var txtDict: [String: String] = [:]
        if let txtData = service.txtRecordData() {
            let dict = NetService.dictionary(fromTXTRecord: txtData)
            for (key, value) in dict {
                txtDict[key] = String(data: value, encoding: .utf8) ?? ""
            }
        }

        let model = txtDict["ty"] ?? txtDict["product"] ?? service.name
        let hostName = service.hostName ?? ""

        return Printer(
            id: service.name,
            name: service.name,
            model: model,
            connectionType: "AirPrint",
            hostName: hostName,
            port: service.port,
            status: .online,
            signal: .strong,
            isPrimary: false,
            txtRecord: txtDict
        )
    }
}

extension PrinterDiscoveryService: NetServiceBrowserDelegate {
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        services.append(service)
        service.delegate = self
        resolving.append(service)
        service.resolve(withTimeout: 10)
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        services.removeAll { $0.name == service.name }
        discoveredPrinters.removeAll { $0.id == service.name }
    }

    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        isSearching = false
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        isSearching = false
    }
}

extension PrinterDiscoveryService: NetServiceDelegate {
    func netServiceDidResolveAddress(_ sender: NetService) {
        let printer = printerFrom(service: sender)
        DispatchQueue.main.async {
            if !self.discoveredPrinters.contains(where: { $0.id == printer.id }) {
                self.discoveredPrinters.append(printer)
            }
        }
        resolving.removeAll { $0.name == sender.name }
        if resolving.isEmpty {
            isSearching = false
        }
    }

    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        resolving.removeAll { $0.name == sender.name }
        if resolving.isEmpty {
            isSearching = false
        }
    }
}
