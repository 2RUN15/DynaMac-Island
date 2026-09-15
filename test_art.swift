import AppKit

let script = "tell application \"Music\" to get raw data of artwork 1 of current track"
var err: NSDictionary?
if let appleScript = NSAppleScript(source: script) {
    let desc = appleScript.executeAndReturnError(&err)
    if err == nil {
        if let img = NSImage(data: desc.data) {
            print("Successfully loaded NSImage: \(img.size.width)x\(img.size.height)")
            // Let's write it to disk just to check
            if let tiff = img.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff) {
                let pngData = rep.representation(using: .png, properties: [:])
                try? pngData?.write(to: URL(fileURLWithPath: "test.png"))
                print("Wrote test.png")
            }
        } else {
            print("NSImage could not be created from data.")
        }
    }
}
