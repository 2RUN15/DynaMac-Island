import SwiftUI
import AppKit
import ApplicationServices

// MARK: - CGS Private API Bağlamaları
@_silgen_name("CGSMainConnectionID")
func CGSMainConnectionID() -> Int32

@_silgen_name("CGSSpaceCreate")
func CGSSpaceCreate(_ connection: Int32, _ unknown: Int32, _ options: NSDictionary?) -> Int32

@_silgen_name("CGSSpaceDestroy")
func CGSSpaceDestroy(_ connection: Int32, _ space: Int32)

@_silgen_name("CGSSpaceSetAbsoluteLevel")
func CGSSpaceSetAbsoluteLevel(_ connection: Int32, _ space: Int32, _ level: Int32)

@_silgen_name("CGSAddWindowsToSpaces")
func CGSAddWindowsToSpaces(_ connection: Int32, _ windows: CFArray, _ spaces: CFArray)

@_silgen_name("CGSRemoveWindowsFromSpaces")
func CGSRemoveWindowsFromSpaces(_ connection: Int32, _ windows: CFArray, _ spaces: CFArray)

@_silgen_name("CGSShowSpaces")
func CGSShowSpaces(_ connection: Int32, _ spaces: CFArray)

@_silgen_name("CGSHideSpaces")
func CGSHideSpaces(_ connection: Int32, _ spaces: CFArray)

@_silgen_name("CGSManagedDisplayGetCurrentSpace")
func CGSManagedDisplayGetCurrentSpace(_ connection: Int32, _ displayId: CFString) -> Int32


@main
struct MyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject var lang = LanguageManager.shared

    var body: some Scene {
        MenuBarExtra("DynaMac Island", image: "MenuBarIcon") {
            Button(L("menu_settings")) {
                appDelegate.openSettings()
            }
            .keyboardShortcut(",", modifiers: .command)
            
            Divider()
            
            Button(L("menu_quit")) {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
    }
}

// SwiftUI içerisinden etkileşime girebilmesi (Key olabilmesi) için özel NSPanel sınıfı
class OverlayPanel: NSPanel {
    override var canBecomeKey: Bool {
        return false // boring.notch uses false here to not steal focus, we can still receive clicks if nonactivating
    }
    
    override var canBecomeMain: Bool {
        return false // boring.notch uses false here
    }
}

// MARK: - Özel Space Yöneticisi
class OverlaySpaceManager {
    private var connection: Int32
    private var overlaySpaceID: Int32?
    
    init() {
        self.connection = CGSMainConnectionID()
    }
    
    func setupOverlaySpace(for window: NSWindow) {
        let spaceID = CGSSpaceCreate(connection, 0x1, nil)
        self.overlaySpaceID = spaceID
        
        let spaceIDs = [NSNumber(value: spaceID)] as CFArray
        let windowIDs = [NSNumber(value: window.windowNumber)] as CFArray
        
        CGSAddWindowsToSpaces(connection, windowIDs, spaceIDs)
        
        if let screen = window.screen, let uuid = screen.uuid {
            let currentSpaceID = CGSManagedDisplayGetCurrentSpace(connection, uuid as CFString)
            if currentSpaceID > 0 {
                let spacesToRemove = [NSNumber(value: currentSpaceID)] as CFArray
                CGSRemoveWindowsFromSpaces(connection, windowIDs, spacesToRemove)
            }
        }
        
        CGSShowSpaces(connection, spaceIDs)
        
        let level = Int32(CGWindowLevelForKey(.mainMenuWindow) + 3)
        CGSSpaceSetAbsoluteLevel(connection, spaceID, level)
    }
    
    deinit {
        if let spaceID = overlaySpaceID {
            let spaceIDs = [NSNumber(value: spaceID)] as CFArray
            CGSHideSpaces(connection, spaceIDs)
            CGSSpaceDestroy(connection, spaceID)
        }
    }
}

extension NSScreen {
    var uuid: String? {
        guard let deviceID = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
            return nil
        }
        if let uuidRef = CGDisplayCreateUUIDFromDisplayID(deviceID.uint32Value) {
            return CFUUIDCreateString(nil, uuidRef.takeRetainedValue()) as String
        }
        return nil
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var panel: OverlayPanel!
    var settingsWindow: NSWindow?
    var overlaySpaceManager: OverlaySpaceManager?
    
    private func checkAccessibilityPermissions() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        
        if !accessEnabled {
            print("Erişilebilirlik (Accessibility) izni bekleniyor...")
            // İzin verilene kadar 3 saniyede bir kontrol edip uyarıcı olabilir, 
            // ama kAXTrustedCheckOptionPrompt zaten macOS'un kendi penceresini çıkartır.
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // İzin kontrolü (Ekrandaki ses ve parlaklık tuşlarını yakalayabilmek için)
        checkAccessibilityPermissions()
        
        let contentView = ContentView()
        
        let panelWidth: CGFloat = 400
        let panelHeight: CGFloat = 400
        
        let styleMask: NSWindow.StyleMask = [.borderless, .nonactivatingPanel, .utilityWindow, .hudWindow]
        
        panel = OverlayPanel(
            contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight),
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )
        
        panel.isFloatingPanel = true
        panel.isOpaque = false
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true 
        panel.backgroundColor = .clear
        panel.isMovable = false
        
        panel.hasShadow = false
        let hideFromRecorder = UserDefaults.standard.object(forKey: "hideFromScreenRecorder") as? Bool ?? true
        panel.sharingType = hideFromRecorder ? .none : .readOnly
        panel.animationBehavior = .none
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) + 3)
        
        panel.collectionBehavior = [
            .fullScreenAuxiliary, 
            .stationary, 
            .canJoinAllSpaces, 
            .ignoresCycle
        ]
        panel.isReleasedWhenClosed = false
        
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentView = hostingView
        
        if let screen = NSScreen.main ?? NSScreen.screens.first {
            let screenRect = screen.frame
            let x = screenRect.origin.x + (screenRect.width - panelWidth) / 2
            let y = screenRect.origin.y + (screenRect.height - panelHeight)
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        panel.orderFrontRegardless()
        
        overlaySpaceManager = OverlaySpaceManager()
        overlaySpaceManager?.setupOverlaySpace(for: panel)
        
        NSApp.setActivationPolicy(.accessory)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        overlaySpaceManager = nil
    }
    
    @objc func openSettings() {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 420),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        window.center()
        window.setFrameAutosaveName("Settings")
        window.title = "DynaMac Island" + " - " + L("menu_settings")
        window.contentView = hostingController.view
        window.isReleasedWhenClosed = false
        
        self.settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
