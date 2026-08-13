import SwiftUI

struct BlockDialogView: View {
    let blockType: BlockType
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
    private let commonKeys = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
                              "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
                              "enter", "space", "tab", "esc", "shift", "ctrl", "alt",
                              "up", "down", "left", "right", "f1", "f2", "f3", "f4", "backspace"]

    var body: some View {
        VStack(spacing: 15) {
            Text("\(blockType.icon) \(blockType.label) Block")
                .font(.system(size: 16, weight: .bold))

            VStack(alignment: .leading, spacing: 10) {
                switch blockType {
                case .click, .mouseDown, .mouseUp:
                    HStack {
                        Text("X:")
                            .frame(width: 80, alignment: .leading)
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
                            .frame(width: 80, alignment: .leading)
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
                                .frame(width: 80, alignment: .leading)
                            TextField("1", text: $clicks)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 80)
                        }
                    }

                case .keyPress, .holdKey, .releaseKey:
                    HStack {
                        Text("Key:")
                            .frame(width: 80, alignment: .leading)
                        Picker("", selection: $key) {
                            ForEach(commonKeys, id: \.self) { k in
                                Text(k).tag(k)
                            }
                        }
                        .frame(width: 150)
                    }

                case .moveMouse:
                    HStack {
                        Text("X:")
                            .frame(width: 80, alignment: .leading)
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
                        Text("Duration (s):")
                            .frame(width: 80, alignment: .leading)
                        TextField("0.2", text: $duration)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                    }

                case .wait:
                    HStack {
                        Text("Seconds:")
                            .frame(width: 80, alignment: .leading)
                        TextField("1", text: $seconds)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                    }

                case .repeatBlock:
                    HStack {
                        Text("Repeat count:")
                            .frame(width: 100, alignment: .leading)
                        TextField("3", text: $count)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                    }
                    Text("(Add child blocks after)")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)

                case .scroll:
                    HStack {
                        Text("Amount:")
                            .frame(width: 80, alignment: .leading)
                        TextField("3", text: $amount)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                        Text("(+up/-down)")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("X (opt):")
                            .frame(width: 80, alignment: .leading)
                        TextField("", text: $x)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                    }
                    HStack {
                        Text("Y (opt):")
                            .frame(width: 80, alignment: .leading)
                        TextField("", text: $y)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                    }

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

                Button("Add Block") {
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
    }

    private func createBlock() -> Block {
        var params: [String: AnyCodable] = [:]

        switch blockType {
        case .click, .mouseDown, .mouseUp:
            if let xVal = Int(x) { params["x"] = AnyCodable(xVal) }
            if let yVal = Int(y) { params["y"] = AnyCodable(yVal) }
            params["button"] = AnyCodable(button)
            if blockType == .click, let clicksVal = Int(clicks) {
                params["clicks"] = AnyCodable(clicksVal)
            }

        case .keyPress, .holdKey, .releaseKey:
            params["key"] = AnyCodable(key)

        case .moveMouse:
            params["x"] = AnyCodable(Int(x) ?? 0)
            params["y"] = AnyCodable(Int(y) ?? 0)
            if let durVal = Double(duration) { params["move_duration"] = AnyCodable(durVal) }

        case .wait:
            params["seconds"] = AnyCodable(Double(seconds) ?? 1.0)

        case .repeatBlock:
            params["count"] = AnyCodable(Int(count) ?? 1)

        case .scroll:
            params["amount"] = AnyCodable(Int(amount) ?? 3)
            if let xVal = Int(x) { params["x"] = AnyCodable(xVal) }
            if let yVal = Int(y) { params["y"] = AnyCodable(yVal) }

        case .custom:
            break
        }

        return Block(type: blockType, params: params)
    }
}
