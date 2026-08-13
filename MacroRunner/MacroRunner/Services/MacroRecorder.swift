import Foundation
import CoreGraphics
import AppKit

class MacroRecorder: ObservableObject {
    @Published var isRecording: Bool = false
    @Published var recordingMode: RecordingMode = .none

    enum RecordingMode {
        case none
        case macro
        case custom(name: String)
    }

    // F10 key code - used to toggle recording
    static let hotkeyCode: Int = 109

    // Callback when F10 is pressed during recording
    var onHotkeyPressed: (() -> Void)?

    private var actions: [(type: BlockType, params: [String: AnyCodable], timestamp: TimeInterval)] = []
    private var startTime: Date?
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var lastMousePos: CGPoint?
    private var lastRecordTime: Date?
    private var globalMonitor: Any?
    private var localMonitor: Any?

    struct RecordedAction {
        let type: BlockType
        let params: [String: AnyCodable]
        let timestamp: TimeInterval
    }

    func start(mode: RecordingMode) {
        guard !isRecording else { return }

        isRecording = true
        recordingMode = mode
        actions = []
        startTime = Date()
        lastMousePos = currentMousePosition()
        lastRecordTime = Date()

        startEventTap()
        // Global monitor should already be running from init
    }

    func startHotkeyMonitor() {
        // Start the hotkey monitors - should be called once at app start
        if globalMonitor == nil {
            startGlobalMonitor()
        }
        if localMonitor == nil {
            startLocalMonitor()
        }
    }

    private func startGlobalMonitor() {
        // Monitor for F10 globally (works even when app is not focused)
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return }
            let keyCode = Int(event.keyCode)
            if keyCode == MacroRecorder.hotkeyCode {
                DispatchQueue.main.async {
                    self.onHotkeyPressed?()
                }
            }
        }
    }

    private func startLocalMonitor() {
        // Monitor for F10 locally (works when app is focused)
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            let keyCode = Int(event.keyCode)
            if keyCode == MacroRecorder.hotkeyCode {
                DispatchQueue.main.async {
                    self.onHotkeyPressed?()
                }
                return nil // Consume the event
            }
            return event
        }
    }

    private func stopGlobalMonitor() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
    }

    private func stopLocalMonitor() {
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }

    func stop() -> [Block] {
        isRecording = false
        recordingMode = .none
        stopEventTap()
        // Don't stop monitors - they should keep running

        return convertToBlocks()
    }

    private func startEventTap() {
        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue) |
                                      (1 << CGEventType.leftMouseDown.rawValue) |
                                      (1 << CGEventType.rightMouseDown.rawValue) |
                                      (1 << CGEventType.otherMouseDown.rawValue) |
                                      (1 << CGEventType.leftMouseDragged.rawValue) |
                                      (1 << CGEventType.rightMouseDragged.rawValue) |
                                      (1 << CGEventType.otherMouseDragged.rawValue)

        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            guard let refcon = refcon else { return Unmanaged.passRetained(event) }
            let recorder = Unmanaged<MacroRecorder>.fromOpaque(refcon).takeUnretainedValue()
            recorder.handleEvent(type: type, event: event)
            return Unmanaged.passRetained(event)
        }

        let refcon = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: callback,
            userInfo: refcon
        )

        guard let eventTap = eventTap else {
            print("Failed to create event tap. Make sure Accessibility is enabled.")
            return
        }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }

    private func stopEventTap() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }

    private func handleEvent(type: CGEventType, event: CGEvent) {
        guard isRecording, let startTime = startTime else { return }

        let timestamp = Date().timeIntervalSince(startTime)

        switch type {
        case .keyDown:
            let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
            // Filter out F10 (hotkey to stop recording)
            if keyCode == MacroRecorder.hotkeyCode {
                onHotkeyPressed?()
                return
            }
            let keyName = keyNameForCode(keyCode)
            addAction(type: .keyPress, params: ["key": AnyCodable(keyName)], timestamp: timestamp)

        case .leftMouseDown:
            let pos = event.location
            addAction(type: .click, params: [
                "x": AnyCodable(Int(pos.x)),
                "y": AnyCodable(Int(pos.y)),
                "button": AnyCodable("left"),
                "clicks": AnyCodable(1)
            ], timestamp: timestamp)

        case .rightMouseDown:
            let pos = event.location
            addAction(type: .click, params: [
                "x": AnyCodable(Int(pos.x)),
                "y": AnyCodable(Int(pos.y)),
                "button": AnyCodable("right"),
                "clicks": AnyCodable(1)
            ], timestamp: timestamp)

        case .otherMouseDown:
            let pos = event.location
            addAction(type: .click, params: [
                "x": AnyCodable(Int(pos.x)),
                "y": AnyCodable(Int(pos.y)),
                "button": AnyCodable("middle"),
                "clicks": AnyCodable(1)
            ], timestamp: timestamp)

        case .leftMouseDragged, .rightMouseDragged, .otherMouseDragged:
            let pos = event.location
            if let lastPos = lastMousePos {
                let distance = sqrt(pow(pos.x - lastPos.x, 2) + pow(pos.y - lastPos.y, 2))
                if distance > 3 {
                    addAction(type: .moveMouse, params: [
                        "x": AnyCodable(Int(pos.x)),
                        "y": AnyCodable(Int(pos.y))
                    ], timestamp: timestamp)
                    lastMousePos = pos
                }
            }

        default:
            break
        }
    }

    private func addAction(type: BlockType, params: [String: AnyCodable], timestamp: TimeInterval) {
        actions.append((type: type, params: params, timestamp: timestamp))
    }

    private func convertToBlocks() -> [Block] {
        var blocks: [Block] = []
        var lastX: Int?
        var lastY: Int?
        var accumulatedWait: TimeInterval = 0

        for action in actions {
            let actionType = action.type
            let params = action.params
            let timestamp = action.timestamp

            if actionType == .moveMouse {
                if let x = params["x"]?.value as? Int,
                   let y = params["y"]?.value as? Int,
                   let lastX = lastX,
                   let lastY = lastY {
                    if abs(x - lastX) < 5 && abs(y - lastY) < 5 {
                        continue
                    }
                }
                lastX = params["x"]?.value as? Int
                lastY = params["y"]?.value as? Int
            }

            if actionType == .moveMouse || actionType == .click || actionType == .mouseDown || actionType == .mouseUp {
                blocks.append(Block(type: actionType, params: params))
                accumulatedWait = 0
            } else if actionType == .keyPress {
                blocks.append(Block(type: actionType, params: params))
                accumulatedWait = 0
            } else if actionType == .wait {
                accumulatedWait += (params["seconds"]?.value as? Double) ?? 0.1
                if accumulatedWait >= 0.1 {
                    blocks.append(Block(type: .wait, params: ["seconds": AnyCodable(round(accumulatedWait * 100) / 100)]))
                    accumulatedWait = 0
                }
            } else if actionType == .scroll {
                blocks.append(Block(type: actionType, params: params))
            }
        }

        if accumulatedWait > 0 {
            blocks.append(Block(type: .wait, params: ["seconds": AnyCodable(round(accumulatedWait * 100) / 100)]))
        }

        return blocks
    }

    private func currentMousePosition() -> CGPoint {
        let event = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: .zero, mouseButton: .left)
        return event?.location ?? .zero
    }

    private func keyNameForCode(_ code: Int) -> String {
        let keyMap: [Int: String] = [
            0: "a", 11: "b", 8: "c", 2: "d", 14: "e", 3: "f", 5: "g", 4: "h",
            34: "i", 38: "j", 40: "k", 37: "l", 46: "m", 45: "n", 31: "o",
            35: "p", 12: "q", 15: "r", 1: "s", 17: "t", 32: "u", 9: "v",
            13: "w", 7: "x", 16: "y", 6: "z",
            36: "enter", 49: "space", 48: "tab", 53: "esc",
            56: "shift", 59: "ctrl", 58: "alt", 126: "up", 125: "down",
            123: "left", 124: "right",
            122: "f1", 120: "f2", 99: "f3", 118: "f4", 96: "f5", 97: "f6",
            98: "f7", 100: "f8", 101: "f9", 109: "f10", 103: "f11", 111: "f12",
            51: "backspace"
        ]
        return keyMap[code] ?? "unknown"
    }
}
