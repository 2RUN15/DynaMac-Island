import Cocoa

class Listener {
    @objc func handleNotif(_ notif: Notification) {
        print("Notif: \(notif.name.rawValue)")
        if let info = notif.userInfo {
            print("Info: \(info)")
        }
    }
}

let listener = Listener()
DistributedNotificationCenter.default().addObserver(listener, selector: #selector(Listener.handleNotif(_:)), name: NSNotification.Name("com.spotify.client.PlaybackStateChanged"), object: nil)
DistributedNotificationCenter.default().addObserver(listener, selector: #selector(Listener.handleNotif(_:)), name: NSNotification.Name("com.apple.Music.playerInfo"), object: nil)
DistributedNotificationCenter.default().addObserver(listener, selector: #selector(Listener.handleNotif(_:)), name: NSNotification.Name("com.apple.iTunes.playerInfo"), object: nil)
print("Listening...")
