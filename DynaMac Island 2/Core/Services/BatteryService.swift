import Foundation
import Swift
import Combine
import IOKit.ps

struct BatteryState: Equatable {
    var level: Int
    var isPlugged: Bool
}

@MainActor
class BatteryService: ObservableObject {
    @Published var state: BatteryState
    let powerChangePublisher = PassthroughSubject<BatteryState, Never>()
    
    private var runLoopSource: CFRunLoopSource?
    
    init() {
        self.state = BatteryState(level: 100, isPlugged: true)
        self.state = fetchCurrentState()
        setupPowerSourceMonitoring()
    }
    
    private func setupPowerSourceMonitoring() {
        let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        let callback: IOPowerSourceCallbackType = { context in
            guard let context = context else { return }
            let mySelf = Unmanaged<BatteryService>.fromOpaque(context).takeUnretainedValue()
            
            DispatchQueue.main.async {
                let newState = mySelf.fetchCurrentState()
                
                // Priz takıldı / Çıkarıldı logiği
                if newState.isPlugged != mySelf.state.isPlugged {
                    mySelf.state = newState
                    mySelf.powerChangePublisher.send(newState)
                } else if newState.level != mySelf.state.level {
                    mySelf.state = newState
                }
            }
        }
        
        runLoopSource = IOPSNotificationCreateRunLoopSource(callback, context).takeRetainedValue()
        if let runLoopSource = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)
        }
    }
    
    private func fetchCurrentState() -> BatteryState {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array
        
        for ps in sources {
            let info = IOPSGetPowerSourceDescription(snapshot, ps).takeUnretainedValue() as! [String: Any]
            
            // "Power Source State" can be "AC Power" or "Battery Power"
            let psState = info["Power Source State"] as? String ?? ""
            let isPlugged = (psState == "AC Power")
            
            let capacity = info["Current Capacity"] as? Int ?? 100
            
            return BatteryState(level: capacity, isPlugged: isPlugged)
        }
        
        // Masaüstü Mac varsayılanı (Pil yoksa hep prize takılı farz edilir)
        return BatteryState(level: 100, isPlugged: true)
    }
}
