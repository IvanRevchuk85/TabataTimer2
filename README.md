# TabataTimer

A small Tabata timer app written in Swift / SwiftUI with a clear **Core → ViewModel → UI** separation and full unit / integration tests.

> Personal learning project: architecture, async/await, actors, `AsyncStream`, MVVM, and UI testing.

---

## Features

- **Configurable Tabata sessions**
  - Prepare, Work, Rest durations
  - Cycles per set, Sets count
  - Rest between sets
- **Deterministic interval plan**
  - Config → `TabataPlan` → ordered list of intervals (`TabataInterval`)
  - Explicit phases: `prepare`, `work`, `rest`, `restBetweenSets`, `finished`
- **Actor-based timer engine**
  - `TimerEngine` implements `TimerEngineProtocol`
  - Uses `AsyncStream<TimerEvent>` to emit:
    - `.tick(remaining:)`
    - `.phaseChanged(phase:index:)`
    - `.completed`
  - Safe state management via `actor` + `Task` + cancellation
- **Session state aggregation**
  - `TabataSessionState` keeps:
    - current phase & time
    - set / cycle / total cycles
    - elapsed / total time
    - progress 0…1 for UI
- **Active training screen (Stage 5)**
  - Big timer (`mm:ss`)
  - Current phase title
  - “Set x/y • Cycle a/b” indicator
  - Circular progress view
  - Control buttons: **Start / Pause / Resume / Reset**
- **Tests**
  - Core models & plan generation
  - Timer engine behaviour
  - Protocols & helpers
  - ViewModel & UI integration

---

## Architecture

High-level architecture:

```text
Core (pure logic, no UI)
 ├─ Models
 │   ├─ TabataConfig          // user configuration
 │   ├─ TabataInterval        // single interval in a plan
 │   ├─ TabataPhase           // enum of phases
 │   ├─ TabataPlan            // builds [TabataInterval] from config
 │   ├─ TabataSessionState    // aggregated state for UI
 │   ├─ TimerEvent            // tick / phaseChanged / completed
 │   └─ TimerState            // idle / running / paused / finished
 ├─ Protocols
 │   └─ TimerEngineProtocol   // contract for the engine
 └─ Services
     └─ TimerEngine (actor)   // concrete engine implementation
Features
 └─ ActiveTimer
     ├─ ActiveTimerViewModel  // ObservableObject, bridges Core ↔ UI
     └─ Views                 // SwiftUI views for active training
App
 └─ TabataTimerApp            // entry point
Tests
 └─ TabataTimerTests          // unit & integration tests
```

### Core

- **`TabataConfig`**
  - Input configuration from the user/preset.
- **`TabataPlan`**
  - Static method `build(from:)` converts `TabataConfig` into `[TabataInterval]`.
  - Plan is deterministic and easy to test.
- **`TabataSessionState`**
  - Single source of truth for the UI.
  - Stores everything needed to render the active session screen.

### Timer engine (`TimerEngine`)

- `actor TimerEngine: TimerEngineProtocol`
- Responsibilities:
  - Own current plan, index, remaining seconds.
  - Start / pause / resume / reset session.
  - Emit `TimerEvent` values via `AsyncStream`.
- Internals:
  - `tickTask: Task<Void, Never>?` runs a loop with `Task.sleep`.
  - On each tick:
    - decrement remaining seconds
    - emit `.tick`
    - advance interval on 0 and emit `.phaseChanged` / `.completed`.

### Active timer feature (Stage 4–5)

- **`ActiveTimerViewModel`**
  - `ObservableObject` (actor / class) that:
    - owns `TabataSessionState`
    - subscribes to `TimerEngine.events`
    - maps `TimerEvent` → `TabataSessionState`
    - exposes computed properties for the UI: formatted time, phase title, progress, set/cycle labels.
  - Public control methods: `start()`, `pause()`, `resume()`, `reset()`.

- **Views (Stage 5)**
  - `ActiveTimerView`
    - Main screen for an active Tabata session.
    - Injects `ActiveTimerViewModel`.
    - Shows:
      - big timer label (`mm:ss`)
      - current phase
      - set / cycle indicator
      - circular progress
      - control bar with buttons.
  - `PhaseTitleView`
    - Simple view for the current phase title.
  - `CircularProgressView`
    - Circular progress visualization with animation.
  - `ControlsBar`
    - Panel with Start / Pause / Resume / Reset.

---

## Folder structure

```text
TabataTimer/
├─ TabataTimer/
│  ├─ App/
│  │  └─ TabataTimerApp.swift
│  ├─ Core/
│  │  ├─ Models/
│  │  │  ├─ TabataConfig.swift
│  │  │  ├─ TabataInterval.swift
│  │  │  ├─ TabataPhase.swift
│  │  │  ├─ TabataPlan.swift
│  │  │  ├─ TabataSessionState.swift
│  │  │  ├─ TimerEvent.swift
│  │  │  └─ TimerState.swift
│  │  ├─ Protocols/
│  │  │  └─ TimerEngineProtocol.swift
│  │  └─ Services/
│  │     └─ TimerEngine.swift
│  ├─ Features/
│  │  ├─ ActiveTimer/
│  │  │  ├─ ActiveTimerViewModel.swift
│  │  │  └─ Views/
│  │  │     ├─ ActiveTimerView.swift
│  │  │     ├─ CircularProgressView.swift
│  │  │     ├─ ControlsBar.swift
│  │  │     └─ PhaseTitleView.swift
│  │  └─ Root/
│  │     └─ ContentView.swift   // entry screen (tabs / routing, WIP)
│  └─ Assets/
└─ TabataTimerTests/
   ├─ Features/
   │  └─ ActiveTimer/
   │     └─ Views/
   │        ├─ ActiveTimerViewIntegrationTests.swift
   │        ├─ CircularProgressViewTests.swift
   │        ├─ ControlsBarTests.swift
   │        └─ PhaseTitleViewTests.swift
   ├─ ActiveTimerViewModelTests.swift
   ├─ TabataModelsTests.swift
   ├─ TimerEngineTests.swift
   ├─ TimerProtocolsTests.swift
   └─ TabataTimerUITests/
      ├─ TabataTimerUITests.swift
      └─ TabataTimerUITestsLaunchTests.swift
```

---

## Requirements

- macOS with Xcode (version matching project settings; e.g. Xcode 16+).
- iOS 17+ simulator or device (adjust to your actual deployment target).
- Swift Concurrency (`async/await`, `actor`, `AsyncStream`).

---

## Getting started

1. **Clone the repository**

   ```bash
   git clone https://github.com/<your-username>/TabataTimer2.git
   cd TabataTimer2/TabataTimer
   ```

2. **Open in Xcode**

   - Open `TabataTimer.xcodeproj` or `.xcworkspace` (if you add one later).
   - Select the **TabataTimer** scheme.
   - Choose an iOS simulator (e.g. iPhone 17 Pro).

3. **Run the app**

   - Press `Cmd+R` in Xcode.

4. **Try the timer**

   - Start a session with default config (or presets, if added later).
   - Use Start / Pause / Resume / Reset to see `TimerEngine` in action.

---

## Running tests

All core and feature tests are under **TabataTimerTests**.

From Xcode:

1. Select the `TabataTimer` scheme.
2. Press `Cmd+U` to run the full test suite.

Or run a specific group:

- `TabataModelsTests` – plan generation & models.
- `TimerProtocolsTests` – protocol contracts & basic state helpers.
- `TimerEngineTests` – engine behaviour and events (`tick`, `phaseChanged`, `completed`).
- `ActiveTimerViewModelTests` – mapping of engine events to `TabataSessionState`.
- `ActiveTimerViewIntegrationTests` & subview tests – verify the active screen wiring and layout.

---

## Roadmap / next steps

Planned or possible next stages:

- **Root navigation**
  - `RootView` with `TabView`: *Training*, *Presets*, *Settings*.
  - Integrate `ActiveTimerView` into the Training tab.
- **Presets & storage**
  - Persist multiple Tabata presets.
  - Inject presets into `TabataConfig`.
- **Settings**
  - Sounds, haptics, theme, default config.
- **Accessibility & localisation**
  - Dynamic Type, VoiceOver labels.
  - Localised strings (EN / RU).

---

## Notes

- Comments in the code are bilingual (EN + RU) to simplify learning.
- Project is used for practising:
  - Swift Concurrency
  - MVVM / feature modules
  - Writing clear, focused tests.

---

## License

This repository is currently used for personal learning and experiments.  
If you plan to reuse it in a public / commercial project, add an explicit license (e.g. MIT) first.
