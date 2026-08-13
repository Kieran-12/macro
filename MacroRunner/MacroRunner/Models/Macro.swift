import Foundation

struct Macro: Identifiable, Codable {
    let id: UUID
    var name: String
    var blocks: [Block]
    let createdAt: Date
    var updatedAt: Date

    init(name: String, blocks: [Block] = []) {
        self.id = UUID()
        self.name = name
        self.blocks = blocks
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    enum CodingKeys: String, CodingKey {
        case id, name, blocks, createdAt, updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        blocks = try container.decode([Block].self, forKey: .blocks)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(blocks, forKey: .blocks)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

struct MacroFile: Codable {
    var name: String
    var blocks: [Block]
}
