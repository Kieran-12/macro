import Foundation

class MacroStorage {
    static let shared = MacroStorage()

    private let storageDir: URL
    private let customBlocksDir: URL

    private init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        storageDir = documentsPath.appendingPathComponent("MacroRunner/macros", isDirectory: true)
        customBlocksDir = storageDir.appendingPathComponent("custom_blocks", isDirectory: true)

        try? FileManager.default.createDirectory(at: storageDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: customBlocksDir, withIntermediateDirectories: true)
    }

    // MARK: - Macros

    func saveMacro(name: String, blocks: [Block]) {
        let fileURL = storageDir.appendingPathComponent("\(name).json")
        let macroFile = MacroFile(name: name, blocks: blocks)
        do {
            let data = try JSONEncoder().encode(macroFile)
            try data.write(to: fileURL)
        } catch {
            print("Error saving macro: \(error)")
        }
    }

    func loadMacro(name: String) -> (blocks: [Block], macroName: String)? {
        let fileURL = storageDir.appendingPathComponent("\(name).json")
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        do {
            let data = try Data(contentsOf: fileURL)
            let macroFile = try JSONDecoder().decode(MacroFile.self, from: data)
            return (macroFile.blocks, macroFile.name)
        } catch {
            print("Error loading macro: \(error)")
            return nil
        }
    }

    func listMacros() -> [String] {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: storageDir, includingPropertiesForKeys: nil)
            return files
                .filter { $0.pathExtension == "json" && $0.lastPathComponent != "custom_blocks_index.json" }
                .map { $0.deletingPathExtension().lastPathComponent }
        } catch {
            return []
        }
    }

    func deleteMacro(name: String) -> Bool {
        let fileURL = storageDir.appendingPathComponent("\(name).json")
        do {
            try FileManager.default.removeItem(at: fileURL)
            return true
        } catch {
            return false
        }
    }

    func renameMacro(oldName: String, newName: String) -> Bool {
        let oldURL = storageDir.appendingPathComponent("\(oldName).json")
        let newURL = storageDir.appendingPathComponent("\(newName).json")
        guard FileManager.default.fileExists(atPath: oldURL.path) else { return false }
        guard !FileManager.default.fileExists(atPath: newURL.path) else { return false }
        do {
            try FileManager.default.moveItem(at: oldURL, to: newURL)
            return true
        } catch {
            return false
        }
    }

    func macroExists(name: String) -> Bool {
        let fileURL = storageDir.appendingPathComponent("\(name).json")
        return FileManager.default.fileExists(atPath: fileURL.path)
    }

    // MARK: - Custom Blocks

    func saveCustomBlock(name: String, blocks: [Block]) {
        let fileURL = customBlocksDir.appendingPathComponent("\(name).json")
        let macroFile = MacroFile(name: name, blocks: blocks)
        do {
            let data = try JSONEncoder().encode(macroFile)
            try data.write(to: fileURL)
        } catch {
            print("Error saving custom block: \(error)")
        }
    }

    func loadCustomBlock(name: String) -> (blocks: [Block], blockName: String)? {
        let fileURL = customBlocksDir.appendingPathComponent("\(name).json")
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        do {
            let data = try Data(contentsOf: fileURL)
            let macroFile = try JSONDecoder().decode(MacroFile.self, from: data)
            return (macroFile.blocks, macroFile.name)
        } catch {
            print("Error loading custom block: \(error)")
            return nil
        }
    }

    func listCustomBlocks() -> [String] {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: customBlocksDir, includingPropertiesForKeys: nil)
            return files
                .filter { $0.pathExtension == "json" }
                .map { $0.deletingPathExtension().lastPathComponent }
        } catch {
            return []
        }
    }

    func deleteCustomBlock(name: String) -> Bool {
        let fileURL = customBlocksDir.appendingPathComponent("\(name).json")
        do {
            try FileManager.default.removeItem(at: fileURL)
            return true
        } catch {
            return false
        }
    }
}
