import re

with open("ContentView.swift", "r") as f:
    text = f.read()

# REVERT CALENDAR
old_cal = """    private var expandedCalendarView: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Sol ve Sağ Kulaklar (Kamera İçi Boşluk)
            HStack(alignment: .top) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.red)
                    Text("Bugün")
                        .font(.system(size: 16, weight: .bold, design: .default))
                        .foregroundColor(.white)
                }
                .padding(.top, 4)
                
                Spacer() // Orta Kamera (Notch)
                
                Text(Date(), formatter: Self.dateFormatter)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.gray)
                    .padding(.top, 6)
            }
            .padding(.top, 16)
            .padding(.bottom, 6)"""
            
new_cal = """    private var expandedCalendarView: some View {
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
            .padding(.bottom, 4)"""
text = text.replace(old_cal, new_cal)
text = text.replace("""        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24) // Top is handled inside (16)
        .frame(width: 360)""", """        }
        .padding(.horizontal, 24)
        .padding(.vertical, 24)
        .frame(width: 360)""")

# REVERT MEDIA
old_media = """    private var expandedMediaView: some View {
        VStack(spacing: 12) {
            // Sol ve Sağ Kulaklar
            HStack(alignment: .top) {
                // Sol Kulak: Album Artwork
                if let nsImage = viewModel.mediaState.artworkImage {
                    Image(nsImage: nsImage)
                        .resizable()
                        .id(songKey + "-ex")
                        .scaledToFill()
                        .frame(width: 56, height: 56)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                } else {
                    Image(systemName: viewModel.mediaState.coverIcon)
                        .resizable()
                        .id(songKey + "-sfex")
                        .scaledToFit()
                        .padding(12)
                        .frame(width: 56, height: 56)
                        .background(
                            LinearGradient(gradient: Gradient(colors: [viewModel.mediaState.dominantColor, .indigo]), startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: viewModel.mediaState.dominantColor.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                
                Spacer() // Orta Notch Kamera bölgesi
                
                // Sağ Kulak: Ses Dalgası
                if #available(macOS 12.0, *) {
                    AudioVisualizerView(isPlaying: viewModel.mediaState.isPlaying, color: viewModel.mediaState.dominantColor)
                        .frame(height: 24)
                        .padding(.top, 16)
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 16)
            
            // Kamera Altı Güvenli Bölge
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 22)
            .padding(.top, 4)"""
            
new_media = """    private var expandedMediaView: some View {
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
            .padding(.top, 22)"""
text = text.replace(old_media, new_media)


# REVERT BATTERY (ALMOST ORIGINAL, BUT SHIFTED DOWN)
old_batt = """    private func expandedBatteryView(level: Int, isCharging: Bool) -> some View {
        VStack(spacing: 12) {
            // Sol ve Sağ Kulaklar (Kamera Boşluğu)
            HStack(alignment: .top) {
                // Sol Kulak: İkon
                ZStack {
                    Circle()
                        .fill(isCharging ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: isCharging ? "bolt.fill" : "battery.50")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(isCharging ? .green : .orange)
                }
                
                Spacer() // Orta Notch Kamera bölgesi
                
                // Sağ Kulak: Yüzde
                Text("%\\(level)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(isCharging ? .green : .white)
                    .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            // Kamera Altı Güvenli Alan
            VStack(alignment: .leading, spacing: 4) {
                Text(isCharging ? "Şarj Ediliyor" : "Pilde Çalışıyor")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Text(isCharging ? "Güç bağlantısı kuruldu" : "Kablodan çıkarıldı")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.bottom, 22)
        }
        .frame(width: 360)
    }"""

new_batt = """    private func expandedBatteryView(level: Int, isCharging: Bool) -> some View {
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
        .padding(.top, 30) // Şarj animasyonu kameradan kurtulsun diye çok az aşağı alındı (Eski 22 -> 30)
        .padding(.bottom, 16)
        .frame(width: 360)
    }"""
text = text.replace(old_batt, new_batt)

with open("ContentView.swift", "w") as f:
    f.write(text)
