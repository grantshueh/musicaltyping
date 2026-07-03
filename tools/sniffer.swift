import CoreMIDI
import Foundation

// Connects to the "Musical Typing Keyboard" virtual source (like a DAW
// would) and prints every MIDI packet it emits.

var client = MIDIClientRef()
MIDIClientCreate("sniffer" as CFString, nil, nil, &client)

var inPort = MIDIPortRef()
MIDIInputPortCreateWithBlock(client, "in" as CFString, &inPort) { packetListPtr, _ in
    let packets = packetListPtr.pointee
    var packet = packets.packet
    for _ in 0..<packets.numPackets {
        let len = Int(packet.length)
        var bytes = [UInt8]()
        withUnsafeBytes(of: packet.data) { raw in
            for i in 0..<min(len, 256) { bytes.append(raw[i]) }
        }
        print("RECV: " + bytes.map { String(format: "%02X", $0) }.joined(separator: " "))
        packet = MIDIPacketNext(&packet).pointee
    }
    fflush(stdout)
}

func displayName(_ obj: MIDIObjectRef) -> String {
    var s: Unmanaged<CFString>?
    MIDIObjectGetStringProperty(obj, kMIDIPropertyDisplayName, &s)
    return (s?.takeRetainedValue() as String?) ?? "?"
}

func tryConnect() -> Bool {
    for i in 0..<MIDIGetNumberOfSources() {
        let src = MIDIGetSource(i)
        if displayName(src).contains("Musical Typing") {
            MIDIPortConnectSource(inPort, src, nil)
            print("CONNECTED: \(displayName(src))")
            fflush(stdout)
            return true
        }
    }
    return false
}

// poll briefly in case the app is still starting up
var attempts = 0
while !tryConnect() {
    attempts += 1
    if attempts > 20 { print("SOURCE NOT FOUND"); exit(1) }
    usleep(250_000)
}

RunLoop.current.run()
