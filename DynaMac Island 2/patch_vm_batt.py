import re

with open("ViewModels/IslandViewModel.swift", "r") as f:
    text = f.read()

# Replace triggerBatteryEvent
old_trigger = """    private func triggerBatteryEvent(state: BatteryState) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.7, blendDuration: 0)) {
            self.activeTransientEvent = .battery(level: state.level, isCharging: state.isCharging)
        }"""

new_trigger = """    private func triggerBatteryEvent(state: BatteryState) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.7, blendDuration: 0)) {
            self.activeTransientEvent = .battery(level: state.level, isCharging: state.isPlugged)
        }"""

text = text.replace(old_trigger, new_trigger)

with open("ViewModels/IslandViewModel.swift", "w") as f:
    f.write(text)
