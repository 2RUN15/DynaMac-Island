import SwiftUI

struct SettingsView: View {
    @AppStorage("showCalendarWhenIdle") private var showCalendarWhenIdle = true
    @AppStorage("autoFadeTimeout") private var autoFadeTimeout = 7.0
    
    // Tab seçim state'i
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsView(
                showCalendarWhenIdle: $showCalendarWhenIdle,
                autoFadeTimeout: $autoFadeTimeout
            )
            .tabItem {
                Label("Genel", systemImage: "gearshape")
            }
            .tag(0)
            
            AppearanceSettingsView()
            .tabItem {
                Label("Görünüm", systemImage: "paintbrush")
            }
            .tag(1)
            
            AboutSettingsView()
            .tabItem {
                Label("Hakkında", systemImage: "info.circle")
            }
            .tag(2)
        }
        .padding(20)
        .frame(width: 500, height: 420)
    }
}

struct GeneralSettingsView: View {
    @Binding var showCalendarWhenIdle: Bool
    @Binding var autoFadeTimeout: Double
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Toggle("Boştayken Takvimi Göster (Hover)", isOn: $showCalendarWhenIdle)
                        .font(.headline)
                    Text("Müzik çalmıyorken ve fare ile adanın üzerine geldiğinizde yaklaşan etkinliklerinizi gösterir.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 8)
            }
            
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Otomatik Gizlenme Süresi")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(autoFadeTimeout)) saniye")
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $autoFadeTimeout, in: 3...15, step: 1)
                    Text("Müzik duraklatıldığında dışarıdaki ikonların kaybolup çentiğin tamamen kapanması için geçecek süre.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 8)
            }
        }
        .formStyle(.grouped)
    }
}

struct AppearanceSettingsView: View {
    // İleride eklenebilecek ayarlar için AppStorage buraya eklenebilir
    @AppStorage("maskOriginalNotch") private var maskOriginalNotch = false
    @AppStorage("showMusicVisualizer") private var showMusicVisualizer = true
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Toggle("Orijinal Apple Çentiğini Maskele", isOn: $maskOriginalNotch)
                        .font(.headline)
                        .disabled(true) // Şimdilik devre dışı
                    Text("Gerçek kamerası olmayan ekranlarda donanımsal bir çentik simülasyonu yaratır. (Yakında eklenecek)")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 8)
            }
            
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Toggle("Müzik Çalarken Ses Dalgası Göster", isOn: $showMusicVisualizer)
                        .font(.headline)
                        .disabled(true) // İleride ContentView ile bağlanacak
                    Text("Müzik dinlerken albüm rengine uyumlu animasyonlu ses dalgasını (visualizer) gösterir.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 8)
            }
        }
        .formStyle(.grouped)
    }
}

struct AboutSettingsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "macwindow.badge.plus")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .foregroundColor(.primary)
                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
            
            VStack(spacing: 6) {
                Text("DynaMac Island")
                    .font(.system(size: 24, weight: .bold))
                Text("Sürüm 1.0 (Beta)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text("Mac ekranınız için geliştirilmiş akıllı ve dinamik ada deneyimi. Apple'ın Dynamic Island tasarımını cihazınıza getirir.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary.opacity(0.8))
                .padding(.horizontal, 30)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
            
            Divider()
            
            HStack {
                Spacer()
                Button("Tamam") {
                    NSApplication.shared.windows.first { $0.title == "DynaMac Island Ayarları" }?.close()
                }
                .keyboardShortcut(.defaultAction)
                .controlSize(.large)
            }
            .padding(.bottom, 10)
        }
        .padding(.top, 10)
        .padding(.horizontal, 20)
    }
}
