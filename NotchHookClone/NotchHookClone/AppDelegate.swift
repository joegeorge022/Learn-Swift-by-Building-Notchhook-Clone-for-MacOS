//
//  AppDelegate.swift
//  NotchHookClone
//
//  Created by Joe George on 11/2/24.
//



import Cocoa
import IOKit.ps
import SystemConfiguration.CaptiveNetwork

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var statusItem: NSStatusItem!
    var isBatteryMonitoringEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "BatteryMonitoringEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "BatteryMonitoringEnabled") }
    }
    var isWiFiMonitoringEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "WiFiMonitoringEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "WiFiMonitoringEnabled") }
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setupMenuBarIcon()
        if isBatteryMonitoringEnabled { monitorBatteryStatus() }
        if isWiFiMonitoringEnabled { monitorWiFiStatus() }
    }

    func setupMenuBarIcon() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "📶"
        
        let menu = NSMenu()
        
        let toggleBatteryItem = NSMenuItem(
            title: "Toggle Battery Monitoring",
            action: #selector(toggleBatteryMonitoring),
            keyEquivalent: "B"
        )
        menu.addItem(toggleBatteryItem)
        
        let toggleWiFiItem = NSMenuItem(
            title: "Toggle Wi-Fi Monitoring",
            action: #selector(toggleWiFiMonitoring),
            keyEquivalent: "W"
        )
        menu.addItem(toggleWiFiItem)
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "Q"))
        
        statusItem.menu = menu
    }

    @objc func toggleBatteryMonitoring() {
        isBatteryMonitoringEnabled.toggle()
        if isBatteryMonitoringEnabled {
            monitorBatteryStatus()
        }
    }

    @objc func toggleWiFiMonitoring() {
        isWiFiMonitoringEnabled.toggle()
        if isWiFiMonitoringEnabled {
            monitorWiFiStatus()
        }
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(self)
    }


    func getBatteryLevel() -> Int? {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array

        guard let source = sources.first else { return nil }
        if let info = IOPSGetPowerSourceDescription(snapshot, source).takeUnretainedValue() as? [String: Any] {
            if let capacity = info[kIOPSCurrentCapacityKey as String] as? Int,
               let max = info[kIOPSMaxCapacityKey as String] as? Int {
                return (capacity * 100) / max
            }
        }
        return nil
    }

    func monitorBatteryStatus() {
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            if self.isBatteryMonitoringEnabled, let batteryLevel = self.getBatteryLevel() {
                print("Battery Level: \(batteryLevel)%")
                if batteryLevel < 20 {
                    self.showBatteryNotification(level: batteryLevel)
                }
            }
        }
    }

    func showBatteryNotification(level: Int) {
        let notification = NSUserNotification()
        notification.title = "Battery Alert"
        notification.informativeText = "Battery is low: \(level)%"
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(notification)
    }


    func getWiFiSSID() -> String? {
        if let interfaces = CNCopySupportedInterfaces() as? [String],
           let interfaceName = interfaces.first as CFString? {
            if let info = CNCopyCurrentNetworkInfo(interfaceName) as? [String: AnyObject] {
                return info[kCNNetworkInfoKeySSID as String] as? String
            }
        }
        return nil
    }

    func monitorWiFiStatus() {
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            if self.isWiFiMonitoringEnabled {
                if let ssid = self.getWiFiSSID() {
                    print("Connected to Wi-Fi: \(ssid)")
                } else {
                    self.showWiFiNotification()
                }
            }
        }
    }

    func showWiFiNotification() {
        let notification = NSUserNotification()
        notification.title = "Wi-Fi Alert"
        notification.informativeText = "Wi-Fi is disconnected."
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(notification)
    }
}
