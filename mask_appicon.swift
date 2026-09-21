import Cocoa

let args = CommandLine.arguments
guard args.count >= 3 else { exit(1) }
let inputPath = args[1]
let outputPath = args[2]

guard let img = NSImage(contentsOfFile: inputPath) else { exit(1) }

let size = NSSize(width: 1024, height: 1024)
let targetRect = NSRect(origin: .zero, size: size)

let result = NSImage(size: size)
result.lockFocus()

NSGraphicsContext.current?.imageInterpolation = .high

let path = NSBezierPath(roundedRect: targetRect, xRadius: 226, yRadius: 226)
path.addClip()

img.draw(in: targetRect)

result.unlockFocus()

guard let tiffData = result.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData),
      let pngData = bitmap.representation(using: .png, properties: [:]) else { exit(1) }

try? pngData.write(to: URL(fileURLWithPath: outputPath))
