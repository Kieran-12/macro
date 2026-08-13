# Macro Runner Desktop App

A visual, block-based macro editor for macOS. Record, edit, and playback keyboard and mouse automation.

## Tech Stack
- **Swift 5.9** with SwiftUI for the GUI
- **CoreGraphics** for mouse/keyboard control
- **AppKit** integration via NSApplication
- **JSON** for macro storage

## Project Structure
```
MacroRunner/
├── MacroRunner.xcodeproj     # Xcode project
├── project.yml               # XcodeGen config
└── MacroRunner/
    ├── main.swift             # App entry point
    ├── AppDelegate.swift      # macOS app delegate
    ├── Models/                # Data models
    ├── Services/              # Business logic
    ├── ViewModels/            # SwiftUI view models
    └── Views/                 # SwiftUI views

```

## Running
```bash
# Open in Xcode
open MacroRunner/MacroRunner.xcodeproj

# Or build from command line
xcodebuild -project MacroRunner.xcodeproj -scheme MacroRunner -configuration Debug build
```

## Features

### Block-Based Editor
Visual blocks that snap together like Scratch:
- 🖱️ **Click** - Mouse click at coordinates (M1/M2/M3)
- ⌨️ **Key Press** - Single key press
- 🔒 **Hold Key** - Hold a key down
- 🔓 **Release Key** - Release a held key
- 🖐️ **Move Mouse** - Smooth mouse movement
- ⬇️ **Mouse Down** - Hold mouse button down
- ⬆️ **Mouse Up** - Release mouse button
- 📜 **Scroll** - Mouse wheel scroll
- ⏱️ **Wait** - Pause between actions
- 🔁 **Repeat** - Loop child blocks N times
- ⚡ **Custom Block** - Reusable recorded sequences

### Recording
- Click "🎤 Record Actions" to capture live mouse movements and key presses
- Recorded actions are automatically converted to blocks
- Creates custom blocks that can be reused across macros

### Macro Management
- Create, rename, delete macros
- Each macro saved as a JSON file in `~/Documents/MacroRunner/macros/`
- Load any saved macro by clicking in the sidebar

### Playback Controls
- Speed slider (0.1x to 5x)
- Stop button to halt execution mid-macro
- Progress bar shows execution status

### Drag & Drop
- Drag blocks to reorder them
- Delete blocks with the ✕ button

## Permissions
The app requires **Accessibility permissions** to record and playback macros:
- Go to **System Settings > Privacy & Security > Accessibility**
- Add and enable MacroRunner
