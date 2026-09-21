import SwiftUI

struct SettingsView: View {
    @ObservedObject var lang = LanguageManager.shared
    @AppStorage("showCalendarWhenIdle") private var showCalendarWhenIdle = true
    @AppStorage("autoFadeTimeout") private var autoFadeTimeout = 7.0
    @AppStorage("hideFromScreenRecorder") private var hideFromScreenRecorder = true
    
    // Tab seçim state'i
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsView(
                showCalendarWhenIdle: $showCalendarWhenIdle,
                autoFadeTimeout: $autoFadeTimeout,
                hideFromScreenRecorder: $hideFromScreenRecorder
            )
            .tabItem {
                Label(L("tab_general"), systemImage: "gearshape")
            }
            .tag(0)
            
            AppearanceSettingsView()
            .tabItem {
                Label(L("tab_appearance"), systemImage: "paintbrush")
            }
            .tag(1)
            
            AboutSettingsView()
            .tabItem {
                Label(L("tab_about"), systemImage: "info.circle")
            }
            .tag(2)
        }
        .padding(20)
        .frame(width: 500, height: 420)
    }
}

struct GeneralSettingsView: View {
    @ObservedObject var lang = LanguageManager.shared
    @Binding var showCalendarWhenIdle: Bool
    @Binding var autoFadeTimeout: Double
    @Binding var hideFromScreenRecorder: Bool
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Picker(L("language"), selection: $lang.selectedLanguage) {
                        ForEach(AppLanguage.allCases, id: \.self) { lng in
                            Text(lng.displayName).tag(lng)
                        }
                    }
                    .font(.headline)
                    .onChange(of: lang.selectedLanguage) { _, _ in }
                }
                .padding(.vertical, 8)
            }

            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Toggle(L("calendar_idle_title"), isOn: $showCalendarWhenIdle)
                        .font(.headline)
                    Text(L("calendar_idle_desc"))
                        .font(.caption)
                        .foregroundColor(.gray)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 8)
            }
            
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Toggle(L("hide_record_title"), isOn: $hideFromScreenRecorder)
                        .font(.headline)
                        .onChange(of: hideFromScreenRecorder) { _, newValue in
                            if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
                                appDelegate.panel?.sharingType = newValue ? .none : .readOnly
                            }
                        }
                    Text(L("hide_record_desc"))
                        .font(.caption)
                        .foregroundColor(.gray)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 8)
            }

            Section {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(L("auto_hide_title"))
                            .font(.headline)
                        Spacer()
                        Text("\(Int(autoFadeTimeout)) \(L("seconds"))")
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $autoFadeTimeout, in: 3...15, step: 1)
                    Text(L("auto_hide_desc"))
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
    @ObservedObject var lang = LanguageManager.shared
    // İleride eklenebilecek ayarlar için AppStorage buraya eklenebilir
    @AppStorage("maskOriginalNotch") private var maskOriginalNotch = false
    @AppStorage("showMusicVisualizer") private var showMusicVisualizer = true
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Toggle(L("mask_notch_title"), isOn: $maskOriginalNotch)
                        .font(.headline)
                        .disabled(true) // Şimdilik devre dışı
                    Text(L("mask_notch_desc"))
                        .font(.caption)
                        .foregroundColor(.gray)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 8)
            }
            
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Toggle(L("visualizer_title"), isOn: $showMusicVisualizer)
                        .font(.headline)
                        .disabled(true) // İleride ContentView ile bağlanacak
                    Text(L("visualizer_desc"))
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
    @ObservedObject var lang = LanguageManager.shared
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
                Text(L("version", "1.0 (Beta)"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text(L("app_desc"))
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary.opacity(0.8))
                .padding(.horizontal, 30)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
            
            Divider()
            
            HStack {
                Spacer()
                Button(L("ok")) {
                    NSApplication.shared.windows.first { $0.title == "DynaMac Island" + " - " + L("menu_settings") }?.close()
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
