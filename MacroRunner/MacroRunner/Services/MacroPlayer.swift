import Foundation
import CoreGraphics
import AppKit

class MacroPlayer {
    var speed: Double = 1.0
    private(set) var isRunning: Bool = false
    private var stopFlag: Bool = false

    func execute(blocks: [Block], progressCallback: ((Int, Int) -> Void)? = nil) {
        isRunning = true
        stopFlag = false
        let total = countBlocks(blocks: blocks)
        var current = 0

        executeBlocks(blocks: blocks, progressCallback: progressCallback, current: &current, total: total)

        isRunning = false
    }

    func stop() {
        stopFlag = true
    }

    private func executeBlocks(blocks: [Block], progressCallback: ((Int, Int) -> Void)?, current: inout Int, total: Int) {
        for block in blocks {
            if stopFlag { return }

            executeBlock(block: block, current: &current, total: total, progressCallback: progressCallback)

            if block.type == .repeatBlock {
                let count = (block.params["count"]?.value as? Int) ?? 1
                for _ in 0..<count {
                    if stopFlag { return }
                    executeBlocks(blocks: block.children, progressCallback: progressCallback, current: &current, total: total)
                }
            } else if block.type == .custom {
                executeBlocks(blocks: block.children, progressCallback: progressCallback, current: &current, total: total)
            }
        }
    }

    private func executeBlock(block: Block, current: inout Int, total: Int, progressCallback: ((Int, Int) -> Void)?) {
        guard !stopFlag else { return }

        current += 1
        progressCallback?(current, total)

        let delay = (block.params["duration"]?.value as? Double) ?? 0.1

        switch block.type {
        case .click:
            executeClick(params: block.params)
        case .keyPress:
            executeKeyPress(params: block.params)
        case .holdKey:
            executeHoldKey(params: block.params)
        case .releaseKey:
            executeReleaseKey(params: block.params)
        case .moveMouse:
            executeMoveMouse(params: block.params)
        case .wait:
            executeWait(params: block.params)
        case .mouseDown:
            executeMouseDown(params: block.params)
        case .mouseUp:
            executeMouseUp(params: block.params)
        case .scroll:
            executeScroll(params: block.params)
        default:
            break
        }

        Thread.sleep(forTimeInterval: delay / speed)
    }

    private func executeClick(params: [String: AnyCodable]) {
        guard let x = params["x"]?.value as? Int,
              let y = params["y"]?.value as? Int else { return }
        let button = (params["button"]?.value as? String) ?? "left"
        let clicks = (params["clicks"]?.value as? Int) ?? 1

        let mouseButton: CGMouseButton
        switch button {
        case "right": mouseButton = .right
        case "middle": mouseButton = .center
        default: mouseButton = .left
        }

        let ourEvent = CGEvent(mouseEventSource: nil, mouseType: clicks > 1 ? .leftMouseDown : .leftMouseDown, mouseCursorPosition: CGPoint(x: CGFloat(x), y: CGFloat(y)), mouseButton: mouseButton)
        ourEvent?.post(tap: .cghidEventTap)

        if clicks > 1 {
            for _ in 1..<clicks {
                let down = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: CGPoint(x: CGFloat(x), y: CGFloat(y)), mouseButton: mouseButton)
                let up = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: CGPoint(x: CGFloat(x), y: CGFloat(y)), mouseButton: mouseButton)
                down?.post(tap: .cghidEventTap)
                usleep(50000)
                up?.post(tap: .cghidEventTap)
                usleep(50000)
            }
        }

        let upEvent = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: CGPoint(x: CGFloat(x), y: CGFloat(y)), mouseButton: mouseButton)
        upEvent?.post(tap: .cghidEventTap)
    }

    private func executeKeyPress(params: [String: AnyCodable]) {
        guard let key = params["key"]?.value as? String else { return }
        postKey(key: key, keyDown: true)
        usleep(30000)
        postKey(key: key, keyDown: false)
    }

    private func executeHoldKey(params: [String: AnyCodable]) {
        guard let key = params["key"]?.value as? String else { return }
        postKey(key: key, keyDown: true)
    }

    private func executeReleaseKey(params: [String: AnyCodable]) {
        guard let key = params["key"]?.value as? String else { return }
        postKey(key: key, keyDown: false)
    }

    private func postKey(key: String, keyDown: Bool) {
        let keyCode = keyCodeFor(key: key)
        let keyDownType: CGEventType = keyDown ? .keyDown : .keyUp
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(keyCode), keyDown: keyDown) else { return }
        event.post(tap: .cghidEventTap)
    }

    private func keyCodeFor(key: String) -> UInt16 {
        let keyMap: [String: UInt16] = [
            "a": 0, "b": 11, "c": 8, "d": 2, "e": 14, "f": 3, "g": 5, "h": 4,
            "i": 34, "j": 38, "k": 40, "l": 37, "m": 46, "n": 45, "o": 31,
            "p": 35, "q": 12, "r": 15, "s": 1, "t": 17, "u": 32, "v": 9,
            "w": 13, "x": 7, "y": 16, "z": 6,
            "enter": 36, "return": 36, "space": 49, "tab": 48, "esc": 53,
            "shift": 56, "ctrl": 59, "alt": 58, "up": 126, "down": 125,
            "left": 123, "right": 124,
            "f1": 122, "f2": 120, "f3": 99, "f4": 118, "f5": 96, "f6": 97,
            "f7": 98, "f8": 100, "f9": 101, "f10": 109, "f11": 103, "f12": 111,
            "backspace": 51, "delete": 51
        ]
        return keyMap[key.lowercased()] ?? 0
    }

    private func executeMoveMouse(params: [String: AnyCodable]) {
        let x = (params["x"]?.value as? Int) ?? 0
        let y = (params["y"]?.value as? Int) ?? 0
        let duration = (params["move_duration"]?.value as? Double) ?? 0.2

        if duration > 0 {
            let startPos = currentMousePosition()
            let steps = max(Int(duration * 30), 1)
            for i in 1...steps {
                let t = Double(i) / Double(steps)
                let newX = CGFloat(startPos.x) + CGFloat(x - Int(startPos.x)) * t
                let newY = CGFloat(startPos.y) + CGFloat(y - Int(startPos.y)) * t
                if let event = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: CGPoint(x: newX, y: newY), mouseButton: .left) {
                    event.post(tap: .cghidEventTap)
                }
                usleep(UInt32(duration * 1_000_000 / Double(steps)))
            }
        } else {
            if let event = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: CGPoint(x: CGFloat(x), y: CGFloat(y)), mouseButton: .left) {
                event.post(tap: .cghidEventTap)
            }
        }
    }

    private func currentMousePosition() -> CGPoint {
        let event = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: .zero, mouseButton: .left)
        return event?.location ?? .zero
    }

    private func executeWait(params: [String: AnyCodable]) {
        let seconds = (params["seconds"]?.value as? Double) ?? 1.0
        Thread.sleep(forTimeInterval: seconds / speed)
    }

    private func executeMouseDown(params: [String: AnyCodable]) {
        let x = (params["x"]?.value as? Int) ?? 0
        let y = (params["y"]?.value as? Int) ?? 0
        let button = (params["button"]?.value as? String) ?? "left"

        let mouseButton: CGMouseButton
        switch button {
        case "right": mouseButton = .right
        case "middle": mouseButton = .center
        default: mouseButton = .left
        }

        let event = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: CGPoint(x: CGFloat(x), y: CGFloat(y)), mouseButton: mouseButton)
        event?.post(tap: .cghidEventTap)
    }

    private func executeMouseUp(params: [String: AnyCodable]) {
        let x = (params["x"]?.value as? Int) ?? 0
        let y = (params["y"]?.value as? Int) ?? 0
        let button = (params["button"]?.value as? String) ?? "left"

        let mouseButton: CGMouseButton
        switch button {
        case "right": mouseButton = .right
        case "middle": mouseButton = .center
        default: mouseButton = .left
        }

        let event = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: CGPoint(x: CGFloat(x), y: CGFloat(y)), mouseButton: mouseButton)
        event?.post(tap: .cghidEventTap)
    }

    private func executeScroll(params: [String: AnyCodable]) {
        let amount = (params["amount"]?.value as? Int) ?? 3

        // Use CGEventCreateScrollWheelEvent for scrolling
        if let event = CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 1, wheel1: Int32(-amount * 120), wheel2: Int32(0), wheel3: Int32(0)) {
            event.post(tap: .cghidEventTap)
        }
    }

    private func countBlocks(blocks: [Block]) -> Int {
        var count = 0
        for block in blocks {
            if block.type == .repeatBlock {
                let repeatCount = (block.params["count"]?.value as? Int) ?? 1
                count += countBlocks(blocks: block.children) * repeatCount
            } else if block.type == .custom {
                count += countBlocks(blocks: block.children)
            } else {
                count += 1
            }
        }
        return max(count, 1)
    }
}
