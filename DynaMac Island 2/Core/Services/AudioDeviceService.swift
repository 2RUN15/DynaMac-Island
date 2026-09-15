import Foundation
import CoreAudio
import Combine
import SwiftUI

@MainActor
class AudioDeviceService: ObservableObject {
    @Published var deviceName: String = "MacBook"
    @Published var volume: Double = 50.0
    private var timer: Timer?

    init() {
        startPolling()
    }
    
    private func startPolling() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.fetchAudioState()
        }
        fetchAudioState() // Initial fetch
    }
    
    @objc private func fetchAudioState() {
        DispatchQueue.global(qos: .userInitiated).async {
            let name = self.getDefaultOutputDeviceName()
            let vol = self.getSystemVolume()
            
            DispatchQueue.main.async {
                self.deviceName = name
                self.volume = vol
            }
        }
    }
    
    private func getDefaultOutputDeviceName() -> String {
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
    
    private func getSystemVolume() -> Double {
        let script = "output volume of (get volume settings)"
        if let result = ScriptHelper.run(script), let vol = Double(result) {
            return vol
        }
        return 50.0
    }
    
    // Ses değişimi için tetiklenecek
    func setVolume(_ newVolume: Double) {
        let volInt = Int(newVolume)
        DispatchQueue.global(qos: .userInitiated).async {
            _ = ScriptHelper.run("set volume output volume \(volInt)")
        }
    }
}
