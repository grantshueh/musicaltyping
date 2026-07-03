import Cocoa
import WebKit
import CoreMIDI

// Publishes a virtual MIDI source that DAWs see as a hardware controller.
final class MIDIBridge {
    private var client = MIDIClientRef()
    private var source = MIDIEndpointRef()

    init() {
        MIDIClientCreate("Musical Typing" as CFString, nil, nil, &client)
        MIDISourceCreate(client, "Musical Typing Keyboard" as CFString, &source)
        // stable unique ID so DAW input mappings survive relaunches
        MIDIObjectSetIntegerProperty(source, kMIDIPropertyUniqueID, 0x4D545970)
    }

    func send(_ bytes: [UInt8]) {
        guard !bytes.isEmpty else { return }
        var packetList = MIDIPacketList()
        let packet = MIDIPacketListInit(&packetList)
        _ = MIDIPacketListAdd(&packetList, 1024, packet, 0, bytes.count, bytes)
        MIDIReceived(source, &packetList)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, WKScriptMessageHandler, WKNavigationDelegate {
    var window: NSWindow!
    var webView: WKWebView!
    let midi = MIDIBridge()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let config = WKWebViewConfiguration()
        config.userContentController.add(self, name: "midi")

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1280, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered, defer: false)
        window.title = "Musical Typing"
        window.contentView = webView
        window.minSize = NSSize(width: 900, height: 420)
        window.center()
        window.makeKeyAndOrderFront(nil)

        buildMenu()
        NSApp.activate(ignoringOtherApps: true)

        guard let url = Bundle.main.url(forResource: "index", withExtension: "html") else {
            fatalError("index.html missing from app bundle")
        }
        webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
    }

    // JS bridge: the page posts raw MIDI byte arrays here
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        guard message.name == "midi", let raw = message.body as? [Any] else { return }
        midi.send(raw.compactMap { ($0 as? NSNumber)?.uint8Value })
    }

    // MT_SELFTEST=1: play a short arpeggio through the full JS→bridge→CoreMIDI
    // path a few seconds after load, so an external sniffer can verify it
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard ProcessInfo.processInfo.environment["MT_SELFTEST"] != nil else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak webView] in
            let js = """
            [60,64,67,72].forEach((n,i) => {
              setTimeout(() => noteOn(n, 'selftest'), i*150);
              setTimeout(() => noteOff(n, 'selftest'), i*150+120);
            });
            """
            webView?.evaluateJavaScript(js, completionHandler: nil)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool { true }

    private func buildMenu() {
        let mainMenu = NSMenu()
        let appItem = NSMenuItem()
        mainMenu.addItem(appItem)
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Quit Musical Typing",
                        action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        NSApp.mainMenu = mainMenu
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
