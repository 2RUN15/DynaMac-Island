import AppKit

let screen = NSScreen.main
if #available(macOS 12.0, *) {
    let left = screen?.auxiliaryTopLeftArea
    let right = screen?.auxiliaryTopRightArea
    print("Left: \(String(describing: left))")
    print("Right: \(String(describing: right))")
    if let lw = left?.width, let rw = right?.width, let sw = screen?.frame.width {
        let notchWidth = sw - lw - rw
        print("Notch Width: \(notchWidth)")
    } else {
        print("Not a notched screen")
    }
}
