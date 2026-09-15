import SwiftUI

struct SettingsView: View {
    @AppStorage("showCalendarWhenIdle") private var showCalendarWhenIdle = true
    @AppStorage("autoFadeTimeout") private var autoFadeTimeout = 7.0
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .center) {
                Image(systemName: "capsule.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.primary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("DynaMac Island")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("v1.0 (Beta)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Settings Content
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(isOn: $showCalendarWhenIdle) {
                            Text("Boştayken Takvimi Göster (Hover)")
                                .font(.headline)
                        }
                        Text("Müzik çalmıyorken ve fare ile adanın üzerine geldiğinizde yaklaşan etkinliklerinizi gösterir.")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 8)
                }
                
                Divider().padding(.vertical, 8)
                
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Otomatik Gizlenme Süresi")
                                .font(.headline)
                            Spacer()
                            Text("\\(Int(autoFadeTimeout)) saniye")
                                .foregroundColor(.gray)
                        }
                        Slider(value: $autoFadeTimeout, in: 3...15, step: 1)
                        Text("Müzik duraklatıldığında dışarıdaki ikonların kaybolup çentiğin tamamen kapanması için geçecek süre.")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding(20)
            .formStyle(.grouped)
            
            Divider()
            
            // Footer
            HStack {
                Button("Orijinal Apple Çentiğini Maskele") {
                    // Gelecek versiyon işlevi
                }
                .disabled(true)
                
                Spacer()
                
                Button("Tamam") {
                    NSApplication.shared.windows.first { $0.title == "Ayarlar" }?.close()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(width: 450, height: 420)
    }
}
