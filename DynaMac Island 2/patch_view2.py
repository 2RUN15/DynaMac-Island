import re

with open("ViewModels/IslandViewModel.swift", "r") as f:
    text = f.read()

text = text.replace('var isExpanded: Bool {\\n        return isHovered\\n    }', 
                    '@Published var hasActiveMusic: Bool = false\\n\\n    var isExpanded: Bool {\\n        return isHovered && hasActiveMusic\\n    }')

with open("ViewModels/IslandViewModel.swift", "w") as f:
    f.write(text)
