import SwiftUI
import AppKit

@available(macOS 12.0, *)
struct AudioVisualizerView: View {
    var isPlaying: Bool
    var color: Color
    
    let frequencies: [Double] = [2.0, 3.5, 2.5, 4.0]
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.04, paused: !isPlaying)) { timeline in
            HStack(spacing: 3) {
                ForEach(0..<4, id: \.self) { index in
                    Capsule()
                        .fill(isPlaying ? color : Color.gray.opacity(0.3))
                        .frame(
                            width: 3.5, 
                            height: barHeight(for: index, date: timeline.date)
                        )
                        .animation(.linear(duration: 0.1), value: isPlaying)
                }
            }
        }
    }
    
    private func barHeight(for index: Int, date: Date) -> CGFloat {
        guard isPlaying else { return 4.0 }
        let time = date.timeIntervalSince1970
        let freq = frequencies[index]
        let sine = sin(time * .pi * freq)
        let normalized = (sine + 1.0) / 2.0
        return 4.0 + CGFloat(normalized * 11.0)
    }
}

struct ContentView: View {
    @StateObject private var viewModel = IslandViewModel()
    @StateObject private var audioService = AudioDeviceService()
    @State private var showVolumeSlider = false
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.clear.edgesIgnoringSafeArea(.all)
            
            islandContainer
                .padding(.top, 0)
        }
        .frame(minWidth: 400, minHeight: 300, alignment: .top)
    }
    
    private var islandContainer: some View {
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
                if !hovering {
                    withAnimation { showVolumeSlider = false } // adadan çıkınca volume gizlensin
                }
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.7, blendDuration: 0), value: viewModel.isExpanded)
        .animation(.spring(response: 0.45, dampingFraction: 0.7, blendDuration: 0), value: viewModel.hasActiveMusic)
        .animation(.spring(response: 0.3), value: showVolumeSlider)
    }
    
    private var songKey: String {
        return "\(viewModel.mediaState.song)-\(viewModel.mediaState.artist)"
    }
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter
    }()
    
    private var expandedCalendarView: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.red)
                Text("Bugün")
                    .font(.system(size: 18, weight: .bold, design: .default))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(Date(), formatter: Self.dateFormatter)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.gray)
            }
            .padding(.bottom, 4)
            
            if viewModel.calendarEvents.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "cup.and.saucer.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("Bugün yaklaşan etkinlik yok.")
                            .foregroundColor(.gray)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .padding(.vertical, 8)
                    Spacer()
                }
            } else {
                ForEach(viewModel.calendarEvents) { event in
                    HStack(spacing: 14) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(event.color)
                            .frame(width: 4)
                            .frame(maxHeight: .infinity)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.title)
                                .font(.system(size: 15, weight: .semibold, design: .default))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            Text(event.timeString)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                    }
                    .frame(height: 40)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 24)
        .frame(width: 360)
    }
    
    private var expandedMediaView: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center, spacing: 16) {
                if let nsImage = viewModel.mediaState.artworkImage {
                    Image(nsImage: nsImage)
                        .resizable()
                        .id(songKey + "-ex")
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .cornerRadius(14)
                        .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                } else {
                    Image(systemName: viewModel.mediaState.coverIcon)
                        .resizable()
                        .id(songKey + "-sfex")
                        .scaledToFit()
                        .padding(14)
                        .frame(width: 60, height: 60)
                        .background(
                            LinearGradient(gradient: Gradient(colors: [viewModel.mediaState.dominantColor, .indigo]), startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(14)
                        .shadow(color: viewModel.mediaState.dominantColor.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.mediaState.song)
                        .font(.system(size: 16, weight: .bold, design: .default))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(viewModel.mediaState.artist)
                        .font(.system(size: 14, weight: .medium, design: .default))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if #available(macOS 12.0, *) {
                    AudioVisualizerView(isPlaying: viewModel.mediaState.isPlaying, color: viewModel.mediaState.dominantColor)
                        .frame(height: 24)
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 22)
            
            HStack(spacing: 12) {
                Text(viewModel.formatTime(viewModel.editingTime))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
                
                Slider(value: $viewModel.editingTime, in: 0...viewModel.mediaState.duration, onEditingChanged: { editing in
                    viewModel.isScrubbing = editing
                    if !editing {
                        viewModel.seekTime(to: viewModel.editingTime)
                    }
                })
                .tint(viewModel.mediaState.dominantColor)
                .frame(height: 12)
                
                Text("-" + viewModel.formatTime(viewModel.mediaState.duration - viewModel.editingTime))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 22)
            
            VStack(spacing: 16) {
                HStack(spacing: 28) {
                    // Mix / Shuffle Button
                    Button(action: {
                        withAnimation { viewModel.toggleShuffle() }
                    }) {
                        Image(systemName: "shuffle")
                            .font(.system(size: 18, weight: viewModel.mediaState.isShuffleEnabled ? .bold : .regular))
                            .foregroundColor(viewModel.mediaState.isShuffleEnabled ? viewModel.mediaState.dominantColor : .white.opacity(0.6))
                    }
                    
                    Button(action: {
                        withAnimation { viewModel.previousTrack() }
                    }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 22))
                    }
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { 
                            viewModel.togglePlayPause() 
                        }
                    }) {
                        Image(systemName: viewModel.mediaState.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 30))
                    }
                    
                    Button(action: {
                        withAnimation { viewModel.nextTrack() }
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 22))
                    }
                    
                    // Device Source Button
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { 
                            showVolumeSlider.toggle() 
                        }
                    }) {
                        Image(systemName: deviceIcon(for: audioService.deviceName))
                            .font(.system(size: 18, weight: showVolumeSlider ? .bold : .regular))
                            .foregroundColor(showVolumeSlider ? viewModel.mediaState.dominantColor : .white.opacity(0.6))
                    }
                }
                .foregroundColor(.white)
                .buttonStyle(.plain)
                
                if showVolumeSlider {
                    HStack(spacing: 12) {
                        Image(systemName: "speaker.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Slider(value: Binding(get: { audioService.volume }, set: { val in
                            audioService.volume = val
                            audioService.setVolume(val)
                        }), in: 0...100)
                        .tint(Color(red: 250/255, green: 36/255, blue: 60/255))
                        
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.horizontal, 32)
                    .frame(height: 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(.bottom, showVolumeSlider ? 22 : 22)
            .padding(.top, 4)
        }
        .frame(width: 360)
    }
    
    private func deviceIcon(for deviceName: String) -> String {
        let name = deviceName.lowercased()
        if name.contains("pro") && (name.contains("airpod") || name.contains("airpods")) { return "airpodspro" }
        if name.contains("max") && (name.contains("airpod") || name.contains("airpods")) { return "airpodsmax" }
        if name.contains("airpod") || name.contains("airpods") { return "airpods" }
        if name.contains("beats") { return "beats.headphones" }
        return "macbook"
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
            
            Text("%\(level)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(isCharging ? .green : .white)
        }
        .padding(.horizontal, 24)
        .padding(.top, 30) // Şarj animasyonu kameradan kurtulsun diye çok az aşağı alındı (Eski 22 -> 30)
        .padding(.bottom, 16)
        .frame(width: 360)
    }
    
    private var idleIslandView: some View {
        HStack(spacing: 0) {
            if viewModel.hasActiveMusic {
                Group {
                    if let nsImage = viewModel.mediaState.artworkImage {
                        Image(nsImage: nsImage)
                            .resizable()
                            .id(songKey + "-id")
                            .scaledToFill()
                            .frame(width: 20, height: 20)
                            .cornerRadius(5)
                    } else {
                        Image(systemName: "music.note")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(viewModel.mediaState.dominantColor)
                    }
                }
                .padding(.leading, 12)
                .blur(radius: viewModel.isIdleTimeout ? 12 : 0)
                .opacity(viewModel.isIdleTimeout ? 0 : 1)
                
                Spacer() 
                
                if #available(macOS 12.0, *) {
                    AudioVisualizerView(isPlaying: viewModel.mediaState.isPlaying, color: viewModel.mediaState.dominantColor)
                        .padding(.trailing, 12)
                        .blur(radius: viewModel.isIdleTimeout ? 12 : 0)
                        .opacity(viewModel.isIdleTimeout ? 0 : 1)
                } else {
                    Spacer().frame(width: 20).padding(.trailing, 12)
                }
            } else {
                Spacer() 
            }
        }
        .frame(
            width: viewModel.hasActiveMusic && !viewModel.isIdleTimeout ? viewModel.hardwareNotchWidth + 72 : viewModel.hardwareNotchWidth, 
            height: viewModel.hardwareNotchHeight
        )
        .animation(.easeInOut(duration: 1.2), value: viewModel.isIdleTimeout)
        .animation(.easeInOut(duration: 0.6), value: viewModel.hasActiveMusic) 
    }
}

#Preview {
    ContentView()
}
