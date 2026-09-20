import Cocoa

let rect = NSRect(x: 0, y: 0, width: 200, height: 200)
let window = NSWindow(contentRect: rect, styleMask: [.borderless], backing: .buffered, defer: false)
print("Borderless safe area:", window.contentView?.safeAreaInsets ?? NSEdgeInsets())

let window2 = NSWindow(contentRect: rect, styleMask: [.titled, .fullSizeContentView], backing: .buffered, defer: false)
print("Titled fullsize safe area:", window2.contentView?.safeAreaInsets ?? NSEdgeInsets())
