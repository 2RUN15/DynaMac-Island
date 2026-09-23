import Foundation
import CoreAudio
import Combine
import SwiftUI

@MainActor
class AudioDeviceService: ObservableObject {
    @Published var deviceName: String = "MacBook"
    @Published var volume: Double = 50.0
    @Published var isInitialLoad: Bool = true
    let deviceChangePublisher = PassthroughSubject<(String, Int?), Never>()
    let volumeChangePublisher = PassthroughSubject<Double, Never>()
    
    private var firstFetchCompleted = false
    private var timer: Timer?
    var isInternalVolumeChange = false
    private var internalVolumeResetTimer: Timer?
    private var lastAppleScriptFetch: Date = Date.distantPast
    private var lastDeviceChangeTime: Date = Date.distantPast

    init() {
        startPolling()
    }
    
    private func startPolling() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.fetchAudioState()
            }
        }
        fetchAudioState()
    }
    
    nonisolated private func getBluetoothBattery() -> Int? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
        task.arguments = ["SPBluetoothDataType"]
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let lines = output.components(separatedBy: .newlines)
                var batL: Int?
                var batR: Int?
                var batMain: Int?
                
                for line in lines {
                    if line.contains("Left Battery Level:") {
                        let str = line.replacingOccurrences(of: "Left Battery Level:", with: "").trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "%", with: "")
                        batL = Int(str)
                    } else if line.contains("Right Battery Level:") {
                        let str = line.replacingOccurrences(of: "Right Battery Level:", with: "").trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "%", with: "")
                        batR = Int(str)
                    } else if line.contains("Battery Level:") && !line.contains("Case") {
                        let str = line.replacingOccurrences(of: "Battery Level:", with: "").trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "%", with: "")
                        if batMain == nil { batMain = Int(str) }
                    }
                }
                
                if let l = batL, let r = batR {
                    return (l + r) / 2
                }
                if let m = batMain {
                    return m
                }
            }
        } catch {
            return nil
        }
        return nil
    }
    
    private func fetchAudioState() {
        Task {
            let deviceID = self.getDefaultOutputDeviceID()
            let name = self.getDeviceName(deviceID: deviceID)
            var vol = self.getNativeSystemVolume(deviceID: deviceID)
            
            if vol < 0 {
                let now = Date()
                if now.timeIntervalSince(self.lastAppleScriptFetch) >= 3.0 {
                    vol = await Task.detached { self.getSystemVolumeAppleScript() }.value
                    self.lastAppleScriptFetch = now
                } else {
                    return
                }
            }
            
            let deviceChanged = (self.deviceName != name)
            
            if deviceChanged && !self.isInitialLoad {
                self.lastDeviceChangeTime = Date()
                
                if name.lowercased().contains("macbook") || name.lowercased().contains("hoparlör") || name.lowercased().contains("speakers") {
                    // Sessiz tutulacak
                } else {
                    // AirPods bağlandığında UI Scripting ile Apple'ın kendi OSD bannerını acımasızca ekrandan yok eden scripti çalıştır
                    ScriptHelper.dismissSystemNotifications()
                    
                    let batLevel = await Task.detached { self.getBluetoothBattery() }.value
                    self.deviceChangePublisher.send((name, batLevel))
                }
            }
            
            let timeSinceDeviceChange = Date().timeIntervalSince(self.lastDeviceChangeTime)
            
            if !self.isInitialLoad && !deviceChanged && timeSinceDeviceChange > 1.5 {
                if abs(self.volume - vol) > 0.5 { 
                    if !self.isInternalVolumeChange {
                        self.volumeChangePublisher.send(vol)
                    }
                }
            }
            
            self.deviceName = name
            self.volume = vol
            
            if !self.firstFetchCompleted {
                self.firstFetchCompleted = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.isInitialLoad = false
                }
            }
        }
    }
    
    nonisolated private func getDefaultOutputDeviceID() -> AudioDeviceID {
        var defaultOutputDeviceID: AudioDeviceID = kAudioObjectUnknown
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        var propertySize = UInt32(MemoryLayout.size(ofValue: defaultOutputDeviceID))
        
        if AudioObjectHasProperty(UInt32(kAudioObjectSystemObject), &propertyAddress) {
            let status = AudioObjectGetPropertyData(UInt32(kAudioObjectSystemObject), &propertyAddress, 0, nil, &propertySize, &defaultOutputDeviceID)
            if status == noErr { return defaultOutputDeviceID }
        }
        return kAudioObjectUnknown
    }
    
    nonisolated private func getDeviceName(deviceID: AudioDeviceID) -> String {
        guard deviceID != kAudioObjectUnknown else { return "MacBook" }
        var deviceName: CFString = "" as CFString
        var propertySize = UInt32(MemoryLayout<CFString>.size)
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        
        if AudioObjectHasProperty(deviceID, &propertyAddress) {
            let status = withUnsafeMutablePointer(to: &deviceName) { ptr in
                ptr.withMemoryRebound(to: Void.self, capacity: 1) { voidPtr in
                    AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &propertySize, voidPtr)
                }
            }
            if status == noErr { return deviceName as String }
        }
        return "MacBook"
    }

    nonisolated private func getNativeSystemVolume(deviceID: AudioDeviceID) -> Double {
        guard deviceID != kAudioObjectUnknown else { return -1.0 }
        var volume: Float32 = 0.0
        var propertySize = UInt32(MemoryLayout.size(ofValue: volume))
        
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        if AudioObjectHasProperty(deviceID, &propertyAddress) {
            let status = AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &propertySize, &volume)
            if status == noErr { return Double(volume * 100.0) }
        }
        
        propertyAddress.mElement = 1
        if AudioObjectHasProperty(deviceID, &propertyAddress) {
            let status = AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &propertySize, &volume)
            if status == noErr { return Double(volume * 100.0) }
        }
        
        propertyAddress.mElement = 2
        if AudioObjectHasProperty(deviceID, &propertyAddress) {
            let status = AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &propertySize, &volume)
            if status == noErr { return Double(volume * 100.0) }
        }
        
        return -1.0
    }
    
    nonisolated private func getSystemVolumeAppleScript() -> Double {
        let script = "output volume of (get volume settings)"
        var err: NSDictionary? = nil
        let task = NSAppleScript(source: script)
        let eventResult = task?.executeAndReturnError(&err)
        if err == nil, let val = eventResult?.stringValue, let vol = Double(val) {
            return vol
        } else if err == nil, let val = eventResult?.int32Value {
            return Double(val)
        }
        return 50.0
    }
    
    func setVolume(_ newVolume: Double) {
        let volInt = Int(newVolume)
        self.isInternalVolumeChange = true
        
        internalVolumeResetTimer?.invalidate()
        internalVolumeResetTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
            Task { @MainActor in
                self.isInternalVolumeChange = false
            }
        }
        
        Task.detached {
            _ = ScriptHelper.run("set volume output volume \(volInt)")
        }
    }
}
