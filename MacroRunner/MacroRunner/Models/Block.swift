import Foundation

enum BlockType: String, Codable, CaseIterable {
    case click = "click"
    case keyPress = "key_press"
    case moveMouse = "move_mouse"
    case wait = "wait"
    case repeatBlock = "repeat"
    case holdKey = "hold_key"
    case releaseKey = "release_key"
    case mouseDown = "mouse_down"
    case mouseUp = "mouse_up"
    case scroll = "scroll"
    case custom = "custom"

    var label: String {
        switch self {
        case .click: return "Click"
        case .keyPress: return "Key Press"
        case .moveMouse: return "Move Mouse"
        case .wait: return "Wait"
        case .repeatBlock: return "Repeat"
        case .holdKey: return "Hold Key"
        case .releaseKey: return "Release Key"
        case .mouseDown: return "Mouse Down"
        case .mouseUp: return "Mouse Up"
        case .scroll: return "Scroll"
        case .custom: return "Custom Block"
        }
    }

    var color: String {
        switch self {
        case .click: return "#4CAF50"
        case .keyPress: return "#2196F3"
        case .moveMouse: return "#FF9800"
        case .wait: return "#9E9E9E"
        case .repeatBlock: return "#E91E63"
        case .holdKey: return "#3F51B5"
        case .releaseKey: return "#673AB7"
        case .mouseDown: return "#00BCD4"
        case .mouseUp: return "#009688"
        case .scroll: return "#795548"
        case .custom: return "#9C27B0"
        }
    }

    var icon: String {
        switch self {
        case .click: return "🖱️"
        case .keyPress: return "⌨️"
        case .moveMouse: return "🖐️"
        case .wait: return "⏱️"
        case .repeatBlock: return "🔁"
        case .holdKey: return "🔒"
        case .releaseKey: return "🔓"
        case .mouseDown: return "⬇️"
        case .mouseUp: return "⬆️"
        case .scroll: return "📜"
        case .custom: return "⚡"
        }
    }

    var isContainer: Bool {
        return self == .repeatBlock || self == .custom
    }
}

struct Block: Identifiable, Codable, Equatable {
    let id: UUID
    var type: BlockType
    var params: [String: AnyCodable]
    var children: [Block]
    var name: String?

    init(type: BlockType, params: [String: AnyCodable] = [:], children: [Block] = [], name: String? = nil) {
        self.id = UUID()
        self.type = type
        self.params = params
        self.children = children
        self.name = name
    }

    static func == (lhs: Block, rhs: Block) -> Bool {
        return lhs.id == rhs.id
    }

    enum CodingKeys: String, CodingKey {
        case id, type, params, children, name
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        type = try container.decode(BlockType.self, forKey: .type)
        params = try container.decode([String: AnyCodable].self, forKey: .params)
        children = try container.decode([Block].self, forKey: .children)
        name = try container.decodeIfPresent(String.self, forKey: .name)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(params, forKey: .params)
        try container.encode(children, forKey: .children)
        try container.encodeIfPresent(name, forKey: .name)
    }
}

struct AnyCodable: Codable, Equatable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intVal = try? container.decode(Int.self) {
            value = intVal
        } else if let doubleVal = try? container.decode(Double.self) {
            value = doubleVal
        } else if let stringVal = try? container.decode(String.self) {
            value = stringVal
        } else if let boolVal = try? container.decode(Bool.self) {
            value = boolVal
        } else if let arrayVal = try? container.decode([AnyCodable].self) {
            value = arrayVal.map { $0.value }
        } else if let dictVal = try? container.decode([String: AnyCodable].self) {
            value = dictVal.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let intVal = value as? Int {
            try container.encode(intVal)
        } else if let doubleVal = value as? Double {
            try container.encode(doubleVal)
        } else if let stringVal = value as? String {
            try container.encode(stringVal)
        } else if let boolVal = value as? Bool {
            try container.encode(boolVal)
        } else {
            try container.encodeNil()
        }
    }

    static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        switch (lhs.value, rhs.value) {
        case (let l as Int, let r as Int): return l == r
        case (let l as Double, let r as Double): return l == r
        case (let l as String, let r as String): return l == r
        case (let l as Bool, let r as Bool): return l == r
        default: return false
        }
    }
}
