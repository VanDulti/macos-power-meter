import SwiftUI
import Foundation

@main
struct MacOsPowerMeter: App {
    @StateObject private var powerManager = PowerManager()
    
    // Hide Dock Icon and Prevent Main App Window
    init() {
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.accessory) // Hide Dock icon
        }
    }
    
    var body: some Scene {
        MenuBarExtra("\(printDouble(value: powerManager.systemLoad))w") {
            Text("System Load: \(printDouble(value: powerManager.systemLoad))w")
            Text("Adapter Usage: \(printDouble(value: powerManager.systemPowerIn))w")
            Text("Battery Output: \(printDouble(value: powerManager.batteryPower))w")
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
    
    func printDouble(value: Double?) -> String{
        return String(format: "%.3f", (value ?? 0.0) / 1000.0);
    }
}

class PowerManager: ObservableObject {
    @Published var systemLoad: Double?
    @Published var systemPowerIn: Double? // ~ adapter usage
    @Published var batteryPower: Double?
    
    let interval = Double.pi * 2
    
    private var timer: Timer?
    
    init() {
        startUpdating()
    }
    
    func startUpdating() {
        self.refreshData()
        if timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                self.refreshData()
            }
        }
    }
    
    func stopUpdating() {
        timer?.invalidate()
        timer = nil
    }
    
    func refreshData() {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceNameMatching("AppleSmartBattery"))
        defer { IOObjectRelease(service) }
        
        if let telemetryData = IORegistryEntryCreateCFProperty(service, "PowerTelemetryData" as CFString, nil, 0)?.takeRetainedValue() as? [String: Any] {
            DispatchQueue.main.async {
                self.systemLoad = telemetryData["SystemLoad"] as? Double
                self.systemPowerIn = telemetryData["SystemPowerIn"] as? Double
                self.batteryPower = (self.systemLoad ?? 0.0) - (self.systemPowerIn ?? 0.0)
            }
        }
    }
}
