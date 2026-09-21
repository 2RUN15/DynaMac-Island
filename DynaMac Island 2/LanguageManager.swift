import Foundation
import SwiftUI
import Combine

enum AppLanguage: String, CaseIterable {
    case system = "system"
    case english = "en"
    case turkish = "tr"
    
    var displayName: String {
        switch self {
        case .system: return L("sistem_varsayilani")
        case .english: return L("ingilizce")
        case .turkish: return L("turkce")
        }
    }
}

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @AppStorage("appLanguage") var selectedLanguage: AppLanguage = .system {
        didSet {
            objectWillChange.send()
        }
    }
    
    var currentCode: String {
        if selectedLanguage == .system {
            let locale = Locale.current.languageCode ?? "en"
            return locale.starts(with: "tr") ? "tr" : "en"
        }
        return selectedLanguage.rawValue
    }
}

func L(_ key: String, _ args: CVarArg...) -> String {
    let code = LanguageManager.shared.currentCode
    let dict = localizations[code] ?? localizations["en"]!
    let format = dict[key] ?? localizations["en"]?[key] ?? key
    if args.isEmpty { return format }
    return String(format: format, arguments: args)
}

private let localizations: [String: [String: String]] = [
    "en": [
        "menu_settings": "Settings...",
        "menu_quit": "Quit DynaMac",
        "tab_general": "General",
        "tab_appearance": "Appearance",
        "tab_about": "About",
        "today": "Today",
        "device_connected": "%@ Connected",
        "calendar_idle_title": "Show Calendar on Idle (Hover)",
        "calendar_idle_desc": "Shows your upcoming events when no music is playing and you hover over the island.",
        "auto_hide_title": "Auto-Hide Timeout",
        "seconds": "seconds",
        "auto_hide_desc": "The time it takes for external icons to disappear and the notch to fully close when music is paused.",
        "hide_record_title": "Hide from Screen Recorders",
        "hide_record_desc": "When enabled, DynaMac Island becomes invisible in screen recordings or broadcasting apps (OBS, QuickTime, etc.).",
        "mask_notch_title": "Mask Original Apple Notch",
        "mask_notch_desc": "Creates a hardware notch simulation on screens without a real camera. (Coming soon)",
        "visualizer_title": "Show Audio Visualizer while Playing Music",
        "visualizer_desc": "Shows an animated audio visualizer matching the album color when listening to music.",
        "app_desc": "An intelligent and dynamic island experience for your Mac screen. Brings Apple's Dynamic Island design to your device.",
        "ok": "OK",
        "language": "Language",
        "sistem_varsayilani": "System Default",
        "ingilizce": "English",
        "turkce": "Turkish",
        "version": "Version %@"
    ],
    "tr": [
        "menu_settings": "Ayarlar...",
        "menu_quit": "DynaMac'ten Çık",
        "tab_general": "Genel",
        "tab_appearance": "Görünüm",
        "tab_about": "Hakkında",
        "today": "Bugün",
        "device_connected": "%@ Bağlandı",
        "calendar_idle_title": "Boştayken Takvimi Göster (Hover)",
        "calendar_idle_desc": "Müzik çalmıyorken ve fare ile adanın üzerine geldiğinizde yaklaşan etkinliklerinizi gösterir.",
        "auto_hide_title": "Otomatik Gizlenme Süresi",
        "seconds": "saniye",
        "auto_hide_desc": "Müzik duraklatıldığında dışarıdaki ikonların kaybolup çentiğin tamamen kapanması için geçecek süre.",
        "hide_record_title": "Ekran Kaydedicilerde Gizle",
        "hide_record_desc": "Etkinleştirildiğinde, DynaMac Island ekran kayıtlarında veya yayın programlarında (OBS, QuickTime vb.) görünmez hale gelir.",
        "mask_notch_title": "Orijinal Apple Çentiğini Maskele",
        "mask_notch_desc": "Gerçek kamerası olmayan ekranlarda donanımsal bir çentik simülasyonu yaratır. (Yakında eklenecek)",
        "visualizer_title": "Müzik Çalarken Ses Dalgası Göster",
        "visualizer_desc": "Müzik dinlerken albüm rengine uyumlu animasyonlu ses dalgasını (visualizer) gösterir.",
        "app_desc": "Mac ekranınız için geliştirilmiş akıllı ve dinamik ada deneyimi. Apple'ın Dynamic Island tasarımını cihazınıza getirir.",
        "ok": "Tamam",
        "language": "Dil",
        "sistem_varsayilani": "Sistem Varsayılanı",
        "ingilizce": "İngilizce",
        "turkce": "Türkçe",
        "version": "Sürüm %@"
    ]
]
