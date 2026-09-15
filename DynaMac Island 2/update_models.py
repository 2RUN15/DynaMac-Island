import re

with open("Core/Models/MediaState.swift", "r") as f:
    text = f.read()

text = text.replace('var artworkImage: NSImage?', 
                    'var artworkImage: NSImage?\n    var dominantColor: Color = .purple\n')

text = text.replace('import AppKit', 'import AppKit\nimport SwiftUI')

with open("Core/Models/MediaState.swift", "w") as f:
    f.write(text)
