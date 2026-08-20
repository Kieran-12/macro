import SwiftUI
import AppKit

struct BlockDialogView: View {
    let blockType: BlockType
    var existingBlock: Block?
    let onSave: (Block) -> Void
    let onCancel: () -> Void

    @State private var x: String = ""
    @State private var y: String = ""
    @State private var button: String = "left"
    @State private var clicks: String = "1"
    @State private var key: String = ""
    @State private var duration: String = "0.2"
    @State private var seconds: String = "1"
    @State private var count: String = "3"
    @State private var amount: String = "3"

    private let mouseButtons = ["left", "right", "middle"]

    var body: some View {
        VStack(spacing: 15) {
            Text(blockType.label)
                .font(.system(size: 16, weight: .bold))

            VStack(alignment: .leading, spacing: 10) {
                switch blockType {
                case .click, .mouseDown, .mouseUp:
                    mouseBlockFields

                case .keyPress, .holdKey, .releaseKey:
                    keyBlockFields

                case .moveMouse:
                    moveMouseFields

                case .wait:
                    waitFields

                case .repeatBlock:
                    repeatFields

                case .scroll:
                    scrollFields

                case .custom:
                    Text("Custom blocks are created from recordings")
                        .foregroundColor(.secondary)
                }
            }

            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                Button(existingBlock != nil ? "Save" : "Add") {
                    let block = createBlock()
                    onSave(block)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(6)
            }
        }
        .padding(25)
        .frame(width: 320)
        .onAppear {
            loadExistingValues()
        }
    }

    private var mouseBlockFields: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button("Use Current Mouse Position") {
                let mouseLoc = NSEvent.mouseLocation
                if let screen = NSScreen.main {
                    let screenHeight = screen.frame.height
                    x = String(Int(mouseLoc.x))
                    y = String(Int(screenHeight - mouseLoc.y))
                }
            }
            .font(.system(size: 11))

            HStack {
                Text("X:")
                    .frame(width: 50, alignment: .leading)
                TextField("0", text: $x)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 80)
                Text("Y:")
                    .frame(width: 30, alignment: .leading)
                TextField("0", text: $y)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 80)
            }

            HStack {
                Text("Button:")
                    .frame(width: 50, alignment: .leading)
                Picker("", selection: $button) {
                    ForEach(mouseButtons, id: \.self) { btn in
                        Text(btn).tag(btn)
                    }
                }
                .frame(width: 100)
            }

            if blockType == .click {
                HStack {
                    Text("Clicks:")
                        .frame(width: 50, alignment: .leading)
                    TextField("1", text: $clicks)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                }
            }
        }
    }

    private var keyBlockFields: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Key:")
                    .frame(width: 50, alignment: .leading)
                TextField("a", text: $key)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 120)
            }
            Text("Examples: a, enter, space, tab, shift, ctrl, up, down, left, right, f1-f12")
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
    }

    private var moveMouseFields: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button("Use Current Mouse Position") {
                let mouseLoc = NSEvent.mouseLocation
                if let screen = NSScreen.main {
                    let screenHeight = screen.frame.height
                    x = String(Int(mouseLoc.x))
                    y = String(Int(screenHeight - mouseLoc.y))
                }
            }
            .font(.system(size: 11))

            HStack {
                Text("X:")
                    .frame(width: 50, alignment: .leading)
                TextField("0", text: $x)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 80)
                Text("Y:")
                    .frame(width: 30, alignment: .leading)
                TextField("0", text: $y)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 80)
            }

            HStack {
                Text("Duration:")
                    .frame(width: 50, alignment: .leading)
                TextField("0.2", text: $duration)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 80)
                Text("sec")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
    }

    private var waitFields: some View {
        HStack {
            Text("Seconds:")
                .frame(width: 60, alignment: .leading)
            TextField("1", text: $seconds)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 80)
        }
    }

    private var repeatFields: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Count:")
                    .frame(width: 60, alignment: .leading)
                TextField("3", text: $count)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 80)
            }
            Text("Child blocks will repeat this many times")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
    }

    private var scrollFields: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Amount:")
                    .frame(width: 60, alignment: .leading)
                TextField("3", text: $amount)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 80)
                Text("(+up/-down)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
    }

    private func loadExistingValues() {
        guard let block = existingBlock else { return }

        if let xVal = block.params["x"]?.value as? Int {
            x = String(xVal)
        }
        if let yVal = block.params["y"]?.value as? Int {
            y = String(yVal)
        }
        if let btn = block.params["button"]?.value as? String {
            button = btn
        }
        if let clicksVal = block.params["clicks"]?.value as? Int {
            clicks = String(clicksVal)
        }
        if let keyVal = block.params["key"]?.value as? String {
            key = keyVal
        }
        if let durVal = block.params["move_duration"]?.value as? Double {
            duration = String(durVal)
        }
        if let secVal = block.params["seconds"]?.value as? Double {
            seconds = String(secVal)
        }
        if let cntVal = block.params["count"]?.value as? Int {
            count = String(cntVal)
        }
        if let amtVal = block.params["amount"]?.value as? Int {
            amount = String(amtVal)
        }
    }

    private func createBlock() -> Block {
        var params: [String: AnyCodable] = [:]

        switch blockType {
        case .click, .mouseDown, .mouseUp:
            if !x.isEmpty, let xVal = Int(x) {
                params["x"] = AnyCodable(xVal)
            }
            if !y.isEmpty, let yVal = Int(y) {
                params["y"] = AnyCodable(yVal)
            }
            params["button"] = AnyCodable(button)
            if blockType == .click, let clicksVal = Int(clicks), clicksVal > 0 {
                params["clicks"] = AnyCodable(clicksVal)
            }

        case .keyPress, .holdKey, .releaseKey:
            params["key"] = AnyCodable(key.isEmpty ? "a" : key)

        case .moveMouse:
            if !x.isEmpty, let xVal = Int(x) {
                params["x"] = AnyCodable(xVal)
            }
            if !y.isEmpty, let yVal = Int(y) {
                params["y"] = AnyCodable(yVal)
            }
            if let durVal = Double(duration) {
                params["move_duration"] = AnyCodable(durVal)
            }

        case .wait:
            params["seconds"] = AnyCodable(Double(seconds) ?? 1.0)

        case .repeatBlock:
            params["count"] = AnyCodable(Int(count) ?? 1)

        case .scroll:
            params["amount"] = AnyCodable(Int(amount) ?? 3)
            if !x.isEmpty, let xVal = Int(x) {
                params["x"] = AnyCodable(xVal)
            }
            if !y.isEmpty, let yVal = Int(y) {
                params["y"] = AnyCodable(yVal)
            }

        case .custom:
            break
        }

        if let existing = existingBlock {
            // Preserve the original block's ID when saving
            return Block(id: existing.id, type: blockType, params: params, children: existing.children, name: existing.name)
        }
        return Block(type: blockType, params: params)
    }
}
