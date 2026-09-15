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
    private var firstFetchCompleted = false
    private var timer: Timer?

    init() {
        startPolling()
    }
    
    private func startPolling() {
        // Derleyici (Strict Concurrency) uyarılarını kaldırmak için doğrudan çağırım 
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.fetchAudioState()
        }
        fetchAudioState() // Initial fetch
    }
    
    nonisolated private func fetchAudioState() {
        // Nonisolated functions called safely in background
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let name = self.getDefaultOutputDeviceName()
            let vol = self.getSystemVolume()
            
            DispatchQueue.main.async {
                if self.deviceName != "MacBook" && self.deviceName != name && !self.isInitialLoad {
                    self.deviceChangePublisher.send(name)
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
    }
    
    nonisolated private func getDefaultOutputDeviceName() -> String {
        var defaultOutputDeviceID: AudioDeviceID = kAudioObjectUnknown
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        var propertySize = UInt32(MemoryLayout.size(ofValue: defaultOutputDeviceID))
        var status = AudioObjectGetPropertyData(UInt32(kAudioObjectSystemObject), &propertyAddress, 0, nil, &propertySize, &defaultOutputDeviceID)
        
        if status == noErr {
            var deviceName: CFString = "" as CFString
            propertySize = UInt32(MemoryLayout<CFString>.size)
            propertyAddress.mSelector = kAudioObjectPropertyName
            
            status = withUnsafeMutablePointer(to: &deviceName) { ptr in
                ptr.withMemoryRebound(to: Void.self, capacity: 1) { voidPtr in
                    AudioObjectGetPropertyData(defaultOutputDeviceID, &propertyAddress, 0, nil, &propertySize, voidPtr)
                }
            }
            if status == noErr { return deviceName as String }
        }
        return "MacBook"
    }
    
    nonisolated private func getSystemVolume() -> Double {
        let script = "output volume of (get volume settings)"
        if let result = ScriptHelper.run(script), let vol = Double(result) {
            return vol
        }
        return 50.0
    }
    
    // Ses değişimi için tetiklenecek
    nonisolated func setVolume(_ newVolume: Double) {
        let volInt = Int(newVolume)
        DispatchQueue.global(qos: .userInitiated).async {
            _ = ScriptHelper.run("set volume output volume \(volInt)")
        }
    }
}
