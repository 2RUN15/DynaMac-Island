import re

with open("ViewModels/IslandViewModel.swift", "r") as f:
    text = f.read()

# Replace hardcoded 7 seconds with UserDefaults timeout
timeoutOld = """            idleTask = Task {
                try? await Task.sleep(nanoseconds: 7_000_000_000)
                if !Task.isCancelled {"""

timeoutNew = """            idleTask = Task {
                let userTimeout = UserDefaults.standard.double(forKey: "autoFadeTimeout")
                let delay = userTimeout > 0 ? userTimeout : 7.0
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                if !Task.isCancelled {"""

text = text.replace(timeoutOld, timeoutNew)

with open("ViewModels/IslandViewModel.swift", "w") as f:
    f.write(text)
