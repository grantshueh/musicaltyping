import CoreMIDI
import Foundation

// Send a short arpeggio to Logic Pro Virtual In to prove the path works.

var client = MIDIClientRef()
MIDIClientCreate("sendtest" as CFString, nil, nil, &client)
var port = MIDIPortRef()
MIDIOutputPortCreate(client, "out" as CFString, &port)

func displayName(_ obj: MIDIObjectRef) -> String {
    var s: Unmanaged<CFString>?
    MIDIObjectGetStringProperty(obj, kMIDIPropertyDisplayName, &s)
    return (s?.takeRetainedValue() as String?) ?? "?"
}

var dest: MIDIEndpointRef = 0
for i in 0..<MIDIGetNumberOfDestinations() {
    let d = MIDIGetDestination(i)
    if displayName(d).lowercased().contains("logic pro virtual in") { dest = d }
}
guard dest != 0 else {
    print("FAIL: Logic Pro Virtual In not found — is Logic running?")
    exit(1)
}

func send(_ bytes: [UInt8]) {
    var packetList = MIDIPacketList()
    let packet = MIDIPacketListInit(&packetList)
    _ = MIDIPacketListAdd(&packetList, 1024, packet, 0, bytes.count, bytes)
    MIDISend(port, dest, &packetList)
}

let notes: [UInt8] = [60, 64, 67, 72] // C4 E4 G4 C5
for n in notes {
    send([0x90, n, 100])
    usleep(180_000)
    send([0x80, n, 0])
}
usleep(100_000)
print("OK: sent 4-note arpeggio to Logic Pro Virtual In")
