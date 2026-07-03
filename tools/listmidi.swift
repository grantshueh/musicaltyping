import CoreMIDI

var client = MIDIClientRef()
MIDIClientCreate("lister" as CFString, nil, nil, &client)

func name(of obj: MIDIObjectRef) -> String {
    var s: Unmanaged<CFString>?
    MIDIObjectGetStringProperty(obj, kMIDIPropertyDisplayName, &s)
    return (s?.takeRetainedValue() as String?) ?? "?"
}

print("DESTINATIONS (apps can send to these):")
for i in 0..<MIDIGetNumberOfDestinations() {
    print("  - " + name(of: MIDIGetDestination(i)))
}
print("SOURCES (Logic listens to these):")
for i in 0..<MIDIGetNumberOfSources() {
    print("  - " + name(of: MIDIGetSource(i)))
}
