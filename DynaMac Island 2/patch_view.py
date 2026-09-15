import re

with open("ViewModels/IslandViewModel.swift", "r") as f:
    text = f.read()

if "var hasActiveMusic: Bool" not in text:
    text = text.replace('var isExpanded: Bool {\\n        return isHovered\\n    }', 
                        'var hasActiveMusic: Bool {\\n        return mediaState.song != "Şu An Çalınmıyor" && !mediaState.song.isEmpty\\n    }\\n\\n    var isExpanded: Bool {\\n        return isHovered && hasActiveMusic\\n    }')

with open("ViewModels/IslandViewModel.swift", "w") as f:
    f.write(text)
