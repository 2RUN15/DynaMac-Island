import re

with open("Core/Services/MediaService.swift", "r") as f:
    text = f.read()

text = text.replace('if err == nil, let descData = eventResult.data {\\n            return NSImage(data: descData)\\n        }', 
                    'if err == nil {\\n            return NSImage(data: eventResult.data)\\n        }')

with open("Core/Services/MediaService.swift", "w") as f:
    f.write(text)

