# Macro Runner - Swift macOS App Specification

## 1. Project Overview

- **Name:** MacroRunner
- **Bundle Identifier:** com.macromacro.runner
- **Core Functionality:** A visual, block-based macro editor for macOS. Record, edit, and playback keyboard and mouse automation.
- **Target Users:** Power users automating repetitive tasks on macOS
- **macOS Version Support:** macOS 13.0+ (Ventura and later)
- **Language:** Swift 5.9+
- **UI Framework:** SwiftUI with AppKit integration

## 2. UI/UX Specification

### Window Structure
- **Main Window:** Single window application (NSWindow → SwiftUI ContentView)
- **Window Size:** 1100×750 minimum, resizable
- **Navigation:** Three-column layout

```
┌──────────────────────────────────────────────────────────────┐
│  MACRO RUNNER                              [─] [□] [×]     │
├────────────┬─────────────────────────────────┬──────────────┤
│  SIDEBAR  │       BLOCK CANVAS               │   PALETTE    │
│  200pt    │       (scrollable)               │   170pt      │
│            │                                  │              │
│ MY MACROS │  ┌─────────────────────────┐     │  BLOCKS      │
│ [Create]  │  │  🖱️ Click #1        ✕  │     │  ──────────  │
│ [Delete]  │  │  x=100, y=200, btn=left│     │  🖱️ Click    │
│ [Rename]  │  └─────────────────────────┘     │  ⌨️ Key      │
│            │  ┌─────────────────────────┐     │  🖐️ Move    │
│ ───────── │  │  ⌨️ Key Press #2    ✕  │     │  ⏱️ Wait     │
│            │  └─────────────────────────┘     │  🔁 Repeat   │
│ CUSTOM    │  ┌─────────────────────────┐     │  🔒 Hold    │
│ BLOCKS    │  │  🔁 Repeat #3       ✕  │     │  🔓 Release  │
│ [Record]  │  │  ↳ 2× children         │     │  ⬇️ Mouse Dn │
│ [Delete]  │  └─────────────────────────┘     │  ⬆️ Mouse Up │
│            │                                  │  📜 Scroll   │
├────────────┴─────────────────────────────────┤  🎤 Record   │
│  Speed: [1.0x ▼]    [▶ PLAY]  [■ STOP]       │              │
├──────────────────────────────────────────────┤              │
│  [████████████░░░░░░░░░░░░░] 45%            │              │
├──────────────────────────────────────────────┤              │
│  Ready                       ● REC (red)     │              │
└──────────────────────────────────────────────┘              │
```

### Color Palette
| Element | Color | Hex |
|---|---|---|
| Window Background | Dark Gray | #2b2b2b |
| Sidebar Background | Darker | #1a1a1a |
| Block Palette BG | Charcoal | #333333 |
| Canvas Background | Mid Gray | #404040 |
| Primary Accent | Green | #4CAF50 |
| Recording Red | Red | #f44336 |
| Text Primary | White | #FFFFFF |
| Text Secondary | Light Gray | #AAAAAA |
| Block Border | White | #FFFFFF |

### Block Colors
| Block Type | Color | Icon |
|---|---|---|
| Click | Green | 🖱️ |
| Key Press | Blue | ⌨️ |
| Move Mouse | Orange | 🖐️ |
| Wait | Gray | ⏱️ |
| Repeat | Pink | 🔁 |
| Hold Key | Indigo | 🔒 |
| Release Key | Purple | 🔓 |
| Mouse Down | Cyan | ⬇️ |
| Mouse Up | Teal | ⬆️ |
| Scroll | Brown | 📜 |
| Custom | Purple | ⚡ |

### Typography
- **Window Title:** System Bold, 18pt
- **Sidebar Headers:** System Bold, 12pt
- **Block Labels:** System Bold, 11pt
- **Block Details:** Courier, 9pt
- **Status Bar:** System Regular, 10pt

### Spacing System (8pt grid)
- Sidebar padding: 15pt
- Block spacing: 8pt vertical
- Block internal padding: 12pt
- Canvas margins: 10pt
- Control bar height: 60pt
- Status bar height: 28pt

## 3. Functionality Specification

### Block Types
1. **Click** - params: x (Int), y (Int), button (left/right/middle), clicks (Int)
2. **Key Press** - params: key (String)
3. **Hold Key** - params: key (String)
4. **Release Key** - params: key (String)
5. **Move Mouse** - params: x (Int), y (Int), duration (Double)
6. **Mouse Down** - params: x (Int), y (Int), button (left/right/middle)
7. **Mouse Up** - params: x (Int), y (Int), button (left/right/middle)
8. **Scroll** - params: amount (Int), x (Int?, y (Int?)
9. **Wait** - params: seconds (Double)
10. **Repeat** - params: count (Int), children: [Block]
11. **Custom** - params: name (String), children: [Block]

### Core Features

**Macro Management:**
- Create new macro (prominent button in sidebar)
- Load macro by clicking in sidebar list
- Rename macro via sidebar button
- Delete macro with confirmation dialog
- Auto-save on every change

**Block Editor:**
- Add block from palette (opens parameter dialog)
- Click block to select and drag
- Drag blocks to reorder within canvas
- Delete block via ✕ button on each block
- Repeat blocks show child blocks indented

**Recording:**
- Click "🎤 Record" button to start recording
- Records mouse movements (filtered to >3px movement)
- Records keyboard key presses
- Click "⏹ Stop" to finish recording
- Recorded actions converted to blocks automatically
- Can record to current macro or create custom block

**Custom Blocks:**
- Record reusable sequences as custom blocks
- Double-click custom block in sidebar to add to current macro
- Custom blocks stored in macros/custom_blocks/

**Playback:**
- Play button executes all blocks in sequence
- Stop button halts execution
- Speed slider: 0.1x to 5.0x (0.1 increment)
- Progress bar shows execution progress
- Status bar shows current state

### Architecture Pattern
**MVVM (Model-View-ViewModel)**
- **Models:** Block, Macro, MacroStorage
- **ViewModels:** MacroListViewModel, BlockEditorViewModel, PlayerViewModel
- **Views:** SidebarView, BlockCanvasView, BlockPaletteView, PlaybackControlsView

### Data Flow
```
User Action → View → ViewModel → Model/Service → File System
                ↓
              State Update
                ↓
              View Re-render
```

## 4. Technical Specification

### Dependencies
- **None** — Pure Apple frameworks only

### Frameworks Used
- **SwiftUI** — UI framework
- **AppKit** — NSWorkspace, event handling, window management
- **CoreGraphics** — CGEvent for mouse/keyboard playback and recording
- **ApplicationServices** — Accessibility APIs for event tap
- **Foundation** — JSON encoding/decoding, file management

### File Storage
- **Location:** `macros/` directory (same as Python version)
- **Macro Format:** JSON file per macro
- **Custom Blocks:** `macros/custom_blocks/` directory
- **Existing files preserved** for compatibility

### Event Handling
- **Playback:** CGEvent posting to login session
- **Recording:** CGEvent tap via Accessibility API
- **Requires Accessibility Permission** (prompt user on first launch)

### App Signing
- **Development:** Sign to Run Locally
- **Distribution:** Mac App Store compatible with hardened runtime

### Asset Requirements
- **App Icon:** 1024×1024 PNG (generated programmatically or placeholder)
- **No external fonts** — System fonts only

## 5. File Structure

```
MacroRunner/
├── project.yml                 # XcodeGen configuration
├── MacroRunner/
│   ├── main.swift              # App entry point
│   ├── AppDelegate.swift       # NSApplicationDelegate
│   ├── Info.plist              # App configuration
│   ├── MacroRunner.entitlements # Sandbox + Accessibility
│   ├── Models/
│   │   ├── Block.swift         # Block model
│   │   └── Macro.swift         # Macro model
│   ├── Services/
│   │   ├── MacroStorage.swift  # JSON file persistence
│   │   ├── MacroPlayer.swift   # Block execution engine
│   │   ├── MacroRecorder.swift # Event recording
│   │   └── EventTap.swift      # CGEvent tap manager
│   ├── ViewModels/
│   │   └── MacroEditorViewModel.swift
│   └── Views/
│       ├── ContentView.swift   # Main window content
│       ├── SidebarView.swift   # Macro list & custom blocks
│       ├── BlockCanvasView.swift # Scrollable block editor
│       ├── BlockPaletteView.swift # Block type buttons
│       ├── BlockRowView.swift  # Individual block rendering
│       ├── PlaybackControlsView.swift # Play/Stop/Speed
│       ├── BlockDialogView.swift # Parameter input dialogs
│       └── RecordButtonView.swift # Recording toggle button
└── Resources/
    └── (empty - using system icons)
```
