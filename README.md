# Musical Typing — MIDI Controller for Logic Pro

A musical typing keyboard for macOS that plays software instruments in
Logic Pro (or any DAW). Your computer keyboard becomes a four-octave
diatonic MIDI controller with selectable keys and scales.

It runs two ways from the same `index.html`:

- **Native macOS app** (recommended) — a Swift shell that publishes a
  virtual CoreMIDI source named **"Musical Typing Keyboard"**. DAWs see it
  as a plugged-in controller. No browser, no server, no setup.
- **Browser app** — the same page served over `localhost` in a Chromium
  browser, sending MIDI via the Web MIDI API.

> Why not an actual Audio Unit plugin? Plugins inside Logic can't reliably
> capture typing — the host owns keyboard focus (that's why Apple built
> Musical Typing into Logic itself, not as a plugin). A separate window
> that pipes MIDI in is the standard approach and works with every
> instrument and DAW.

## Native app

Build (requires Xcode Command Line Tools):

```sh
./build.sh
```

This compiles the Swift shell, bundles `index.html` into
`build/Musical Typing.app`, and ad-hoc signs it. Then:

1. Launch **Musical Typing.app** (move it to `/Applications` if you like).
2. In Logic, select or record-arm a Software Instrument track.
3. Keep the Musical Typing window focused and play. Closing the window
   quits the app.

The app is a thin WKWebView wrapper: keystrokes hit the same HTML UI, and
note events cross a JS→Swift message bridge into CoreMIDI
([app/main.swift](app/main.swift)). The virtual source has a stable unique
ID, so DAW input mappings survive relaunches.

## Browser version

Web MIDI needs a `localhost` page (not `file://`) and a Chromium browser
(Chrome, Edge, Arc, Brave — Safari does not support Web MIDI):

```sh
cd "~/midi keyboard"
python3 -m http.server 8642
```

Then, with **Logic Pro already running**:

1. Open <http://localhost:8642> and click **Allow** when the browser asks
   for MIDI permission.
2. The app auto-selects **Logic Pro Virtual In** — Logic's own virtual MIDI
   input, no setup required. (It only exists while Logic is running; the
   app grabs it automatically whenever it appears.)
3. In Logic, select or record-arm a **Software Instrument** track.
4. Keep the browser window focused and play.

No Logic handy? Choose **Built-in synth (test)** in the dropdown to hear
the keyboard directly in the browser.

### Fallback: IAC Driver

If you want the keyboard to reach other DAWs, or a port that exists even
before Logic launches, enable the IAC bus (the app prefers Logic's port,
then IAC, then the synth):

- Open **Audio MIDI Setup** → **Window → Show MIDI Studio**
- Double-click **IAC Driver**, check **"Device is online"**, ensure at
  least one port exists (e.g. "Bus 1"), click Apply.

## Layout

All four keyboard rows are **diatonic** — each row is one octave of the
selected key, giving four octaves under your fingers at once. Within a row,
each key is the next scale degree, and rows longer than seven keys spill
into the next octave (so `,` = `A`, `K` = `Q`, `I` = `1`).

| Row | Keys | Default range (C major) |
| --- | --- | --- |
| 🟠 `Z X C V B N M , . /` | octave 1 | C2–E3 |
| 🩵 `A S D F G H J K L ; '` | octave 2 | C3–F4 |
| 🔵 `Q W E R T Y U I O P [ ]` | octave 3 | C4–G5 |
| 🟣 `1 2 3 4 5 6 7 8 9 0 - =` | octave 4 | C5–G6 |

The colored strips above and below the piano show where each row sits,
mirroring the physical keyboard's row order. Letter labels on the piano
keys are tinted the same colors, and they move when you change key or
scale — in E major, for example, the labels shift onto the sharps.

### Controls

| Key | Action |
| --- | --- |
| `↑` / `↓` | Change key (C → C# → D … wraps around) |
| `Space` (hold) | Sharpen — notes struck while held sound a semitone higher, for accidentals and chromatic passing tones |
| Key / scale dropdowns | Pick any root and scale: major, natural/harmonic/Hungarian/Romanian minor, double harmonic major, Persian, enigmatic, Lydian augmented, Dorian, Mixolydian, half-whole diminished, Prometheus, pentatonics, hirajoshi, Iwato, Insen |
| `←` / `→` | Shift all four rows down / up one octave |
| `Shift` + `↑` / `↓` | Velocity +10 / −10 (also a slider in the toolbar) |
| `Tab` (hold) | Sustain pedal (CC64). Click the green button to latch it. |
| `Esc` | Panic — all notes off |
| Mouse / trackpad | Click keys to play; drag for glissando |

Held notes are never stranded by a key or octave change — each keypress
remembers the pitch it started, and releases that same pitch.

## Repository layout

| Path | What it is |
| --- | --- |
| `index.html` | The entire keyboard: UI, key mapping, scales, and both MIDI backends (Web MIDI + native bridge) |
| `app/main.swift` | Native macOS shell: window, WKWebView, JS→CoreMIDI bridge, virtual MIDI source |
| `app/Info.plist` | App bundle metadata |
| `build.sh` | Builds and signs `build/Musical Typing.app` |
| `tools/` | Standalone CoreMIDI diagnostics (run with `swift <file>`) |

## MIDI debugging tools

- `tools/listmidi.swift` — list every MIDI source and destination on the
  system (check whether the virtual port or an IAC bus is visible)
- `tools/sendtest.swift` — send a C-major arpeggio directly to Logic Pro's
  virtual input, bypassing the app (isolates Logic-side problems)
- `tools/sniffer.swift` — attach to the "Musical Typing Keyboard" virtual
  source like a DAW would and print every packet it emits (isolates
  app-side problems)
