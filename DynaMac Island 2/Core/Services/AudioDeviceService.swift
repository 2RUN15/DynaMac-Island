import Foundation
import CoreAudio
import Combine
import SwiftUI

@MainActor
class AudioDeviceService: ObservableObject {
    @Published var deviceName: String = "MacBook"
    @Published var volume: Double = 50.0
    @Published var isInitialLoad: Bool = true
    let deviceChangePublisher = PassthroughSubject<String, Never>()
    let volumeChangePublisher = PassthroughSubject<Double, Never>()
    
    private var firstFetchCompleted = false
    private var timer: Timer?
    var isInternalVolumeChange = false
    private var internalVolumeResetTimer: Timer?
    private var lastAppleScriptFetch: Date = Date.distantPast

    init() {
        startPolling()
    }
    
    private func startPolling() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.fetchAudioState()
            }
        }
        fetchAudioState()
    }
    
    private func fetchAudioState() {
        Task {
            // Hızlı native C-API okumaları direkt main thread üzerinde (µs sürer)
            let deviceID = self.getDefaultOutputDeviceID()
            let name = self.getDeviceName(deviceID: deviceID)
            var vol = self.getNativeSystemVolume(deviceID: deviceID)
            
            // Eğer CoreAudio desteklemiyorsa (vol < 0) AppleScript ile arka planda çek
            if vol < 0 {
                let now = Date()
                if now.timeIntervalSince(self.lastAppleScriptFetch) >= 1.0 {
                    // AppleScript'i arka plana (detached) at, MainActor'ı kitlemesin!
                    vol = await Task.detached { self.getSystemVolumeAppleScript() }.value
                    self.lastAppleScriptFetch = now
                } else {
                    return // Saniye dolmadan tekrar AppleScript sorma (CPU'yu koru)
                }
            }
            
            if self.deviceName != "MacBook" && self.deviceName != name && !self.isInitialLoad {
                self.deviceChangePublisher.send(name)
            }
            
            if !self.isInitialLoad && abs(self.volume - vol) > 0.5 { 
                if !self.isInternalVolumeChange {
                    self.volumeChangePublisher.send(vol)
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
        
        // Log spam ("HALC_ShellObject... call to the proxy failed") oluşmaması için önce property'nin desteklendiğine emin ol
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
        if let result = ScriptHelper.run(script), let vol = Double(result) {
            return vol
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
