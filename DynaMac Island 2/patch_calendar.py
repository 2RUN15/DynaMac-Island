import re

with open("ContentView.swift", "r") as f:
    text = f.read()

# 1. Expand logic: 
old_expand = """                if viewModel.hasActiveMusic {
                    expandedMediaView
                        .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .top)))
                } else {
                    expandedCalendarView
                        .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .top)))
                }"""

new_expand = """                if viewModel.hasActiveMusic && !viewModel.isIdleTimeout {
                    expandedMediaView
                        .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .top)))
                } else {
                    expandedCalendarView
                        .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .top)))
                }"""

text = text.replace(old_expand, new_expand)

# 2. onHover logic: remove the isIdleTimeout reset
old_hover = """        .onHover { hovering in
            if hovering && viewModel.isIdleTimeout {
                withAnimation { viewModel.isIdleTimeout = false }
            }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7, blendDuration: 0)) {
                viewModel.isHovered = hovering
            }
        }"""

new_hover = """        .onHover { hovering in
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7, blendDuration: 0)) {
                viewModel.isHovered = hovering
            }
        }"""

text = text.replace(old_hover, new_hover)

# Write back
with open("ContentView.swift", "w") as f:
    f.write(text)
