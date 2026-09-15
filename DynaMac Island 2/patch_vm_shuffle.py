import re

with open("ViewModels/IslandViewModel.swift", "r") as f:
    text = f.read()

text = text.replace("    func togglePlayPause() {", "    func toggleShuffle() {\n        mediaService.toggleShuffle()\n    }\n\n    func togglePlayPause() {")
text = text.replace("dominantColor: .purple)", "dominantColor: .purple, isShuffleEnabled: false)")

with open("ViewModels/IslandViewModel.swift", "w") as f:
    f.write(text)
