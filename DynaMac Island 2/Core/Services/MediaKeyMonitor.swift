import Cocoa
import CoreGraphics
import Combine

typealias DisplayServicesSetBrightnessType = @convention(c) (CGDirectDisplayID, Float) -> Int32
typealias DisplayServicesGetBrightnessType = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32

class DisplayBrightnessHelper {
    static let shared = DisplayBrightnessHelper()
    
    private var setBrightnessFunc: DisplayServicesSetBrightnessType?
    private var getBrightnessFunc: DisplayServicesGetBrightnessType?
    
    init() {
        let handle = dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_NOW)
        if let handle = handle {
            if let sym = dlsym(handle, "DisplayServicesSetBrightness") {
                setBrightnessFunc = unsafeBitCast(sym, to: DisplayServicesSetBrightnessType.self)
            }
            if let sym = dlsym(handle, "DisplayServicesGetBrightness") {
                getBrightnessFunc = unsafeBitCast(sym, to: DisplayServicesGetBrightnessType.self)
            }
        }
    }
    
    func getBrightness() -> Float {
        guard let getFunc = getBrightnessFunc else { return 0.5 }
        var b: Float = 0.0
        let display = CGMainDisplayID()
        _ = getFunc(display, &b)
        return b
    }
    
    func setBrightness(_ b: Float) {
        guard let setFunc = setBrightnessFunc else { return }
        let display = CGMainDisplayID()
        _ = setFunc(display, b)
    }
}

class MediaKeyMonitor {
    static let shared = MediaKeyMonitor()
    
    private var eventPort: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    weak var audioService: AudioDeviceService?
    weak var viewModel: IslandViewModel?
    
    static let volumeStep: Double = 100.0 / 16.0 
    static let brightnessStep: Float = 1.0 / 16.0

    func start(audioService: AudioDeviceService, viewModel: IslandViewModel) {
        self.audioService = audioService
        self.viewModel = viewModel
        
        let sysDefinedEventValue = UInt32(14) 
        let mask = CGEventMask(1 << sysDefinedEventValue)
        let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                if type.rawValue == 14 { 
                    guard let nsEvent = NSEvent(cgEvent: event) else { return Unmanaged.passUnretained(event) }
                    
                    if nsEvent.subtype.rawValue == 8 {
                        let keyCode = (nsEvent.data1 & 0xFFFF0000) >> 16
                        let keyFlags = (nsEvent.data1 & 0x0000FFFF)
                        let keyState = (((keyFlags & 0xFF00) >> 8)) == 0xA
                        let repeatState = (((keyFlags & 0x1)) == 0x1)
                        
                        let isDown = keyState || repeatState
                        
                        if isDown {
                            let unmanagedSelf = Unmanaged<MediaKeyMonitor>.fromOpaque(refcon!)
                            let monitor = unmanagedSelf.takeUnretainedValue()
                            
                            if keyCode == 0 { // Volume Up
                                DispatchQueue.main.async { monitor.handleVolumeChange(direction: 1) }
                                return nil 
                            } else if keyCode == 1 { // Volume Down
                                DispatchQueue.main.async { monitor.handleVolumeChange(direction: -1) }
                                return nil 
                            } else if keyCode == 7 { // Mute
                                DispatchQueue.main.async { monitor.handleMute() }
                                return nil 
                            } else if keyCode == 2 { // Brightness Up
                                DispatchQueue.main.async { monitor.handleBrightnessChange(direction: 1) }
                                return nil
                            } else if keyCode == 3 { // Brightness Down
                                DispatchQueue.main.async { monitor.handleBrightnessChange(direction: -1) }
                                return nil
                            }
                        } else {
                            if keyCode == 0 || keyCode == 1 || keyCode == 7 || keyCode == 2 || keyCode == 3 {
                                return nil 
                            }
                        }
                    }
                }
                return Unmanaged.passUnretained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )
        
        guard let validTap = tap else {
            print("Failed to create event tap. Make sure you have Accessibility permissions enabled.")
            return
        }
        
        self.eventPort = validTap
        self.runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, validTap, 0)
        
        if let source = self.runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
            CGEvent.tapEnable(tap: validTap, enable: true)
        }
    }
    
    func stop() {
        if let validTap = eventPort {
            CGEvent.tapEnable(tap: validTap, enable: false)
            if let runLoopSource = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            }
            CFMachPortInvalidate(validTap)
            self.eventPort = nil
            self.runLoopSource = nil
        }
    }
    
    @MainActor
    private func handleVolumeChange(direction: Double) {
        guard let service = audioService else { return }
        let currentVol = service.volume
        var newVol = currentVol + (direction * MediaKeyMonitor.volumeStep)
        
        if newVol > 100.0 { newVol = 100.0 }
        if newVol < 0.0 { newVol = 0.0 }
        
        service.setVolume(newVol)
        service.volumeChangePublisher.send(newVol)
    }
    
    @MainActor
    private func handleMute() {
        guard let service = audioService else { return }
        let wasMuted = service.volume <= 0.0
        
        if wasMuted {
            let defaultVol = 50.0
            service.setVolume(defaultVol)
            service.volume = defaultVol
            service.volumeChangePublisher.send(defaultVol)
        } else {
            service.setVolume(0.0)
            service.volume = 0.0
            service.volumeChangePublisher.send(0.0)
        }
    }
    
    @MainActor
    private func handleBrightnessChange(direction: Float) {
        let current = DisplayBrightnessHelper.shared.getBrightness()
        var newB = current + (direction * MediaKeyMonitor.brightnessStep)
        
        if newB > 1.0 { newB = 1.0 }
        if newB < 0.0 { newB = 0.0 }
        
        DisplayBrightnessHelper.shared.setBrightness(newB)
        viewModel?.triggerBrightnessEvent(level: Double(newB * 100))
    }
}
