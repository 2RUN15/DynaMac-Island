import re

with open("ViewModels/IslandViewModel.swift", "r") as f:
    text = f.read()

# Add hasInitializedPlayState
text = text.replace('private var cancellables = Set<AnyCancellable>()', 'private var cancellables = Set<AnyCancellable>()\n    private var hasInitializedPlayState = false')

sink_old = """                // Müzik Durumu değiştiğinde Timeout lojiğini tetikleme
                if state.isPlaying != self.mediaState.isPlaying {
                    self.handlePlayStateChange(state.isPlaying)
                }"""

sink_new = """                // Müzik Durumu değiştiğinde veya uygulama yeni açıldığında Timeout lojiğini tetikleme
                if state.isPlaying != self.mediaState.isPlaying || (!self.hasInitializedPlayState && state.song != "Şu An Çalınmıyor") {
                    self.hasInitializedPlayState = true
                    self.handlePlayStateChange(state.isPlaying)
                }"""

text = text.replace(sink_old, sink_new)

with open("ViewModels/IslandViewModel.swift", "w") as f:
    f.write(text)
