import re

with open("ContentView.swift", "r") as f:
    text = f.read()

islandContainer_old = """    private var islandContainer: some View {
        VStack(spacing: 0) {
            if viewModel.isExpanded {
                if viewModel.hasActiveMusic && !viewModel.isIdleTimeout {
                    expandedMediaView
                        .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .top)))
                } else {
                    expandedCalendarView
                        .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .top)))
                }
            } else {
                idleIslandView
            }
        }
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: viewModel.isExpanded ? 44 : 9, style: .continuous))
        .shadow(color: .black.opacity(0.4), radius: 15, x: 0, y: 10)
        .onHover { hovering in
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7, blendDuration: 0)) {
                viewModel.isHovered = hovering
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.7, blendDuration: 0), value: viewModel.isExpanded)
        .animation(.spring(response: 0.45, dampingFraction: 0.7, blendDuration: 0), value: viewModel.hasActiveMusic)
    }"""

islandContainer_new = """    private var islandContainer: some View {
        VStack(spacing: 0) {
            if viewModel.isExpanded {
                if case .battery(let level, let isCharging) = viewModel.activeTransientEvent {
                    expandedBatteryView(level: level, isCharging: isCharging)
                        .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .top)))
                } else if viewModel.hasActiveMusic && !viewModel.isIdleTimeout {
                    expandedMediaView
                        .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .top)))
                } else {
                    expandedCalendarView
                        .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .top)))
                }
            } else {
                idleIslandView
            }
        }
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: viewModel.isExpanded ? 44 : 9, style: .continuous))
        .shadow(color: .black.opacity(0.4), radius: 15, x: 0, y: 10)
        .onHover { hovering in
            if viewModel.activeTransientEvent == nil {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.7, blendDuration: 0)) {
                    viewModel.isHovered = hovering
                }
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.7, blendDuration: 0), value: viewModel.isExpanded)
        .animation(.spring(response: 0.45, dampingFraction: 0.7, blendDuration: 0), value: viewModel.hasActiveMusic)
    }
    
    private func expandedBatteryView(level: Int, isCharging: Bool) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(isCharging ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                    .frame(width: 48, height: 48)
                
                Image(systemName: isCharging ? "bolt.fill" : "battery.50")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(isCharging ? .green : .orange)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(isCharging ? "Şarj Ediliyor" : "Pilde Çalışıyor")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Text(isCharging ? "Güç bağlantısı kuruldu" : "Kablodan çıkarıldı")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text("%\\(level)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(isCharging ? .green : .white)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 22)
        .frame(width: 360)
    }"""

text = text.replace(islandContainer_old, islandContainer_new)

with open("ContentView.swift", "w") as f:
    f.write(text)
