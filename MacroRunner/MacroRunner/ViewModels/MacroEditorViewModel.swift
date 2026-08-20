import Foundation
import SwiftUI
import Combine

@MainActor
class MacroEditorViewModel: ObservableObject {
    @Published var macroNames: [String] = []
    @Published var customBlockNames: [String] = []
    @Published var currentMacroName: String?
    @Published var blocks: [Block] = []
    @Published var isRecording: Bool = false
    @Published var statusText: String = "Ready"
    @Published var progress: Double = 0
    @Published var isPlaying: Bool = false
    @Published var speed: Double = 1.0

    private let storage = MacroStorage.shared
    let recorder = MacroRecorder()
    private var player = MacroPlayer()
    private var playThread: Thread?
    private var cancellables = Set<AnyCancellable>()

    init() {
        refreshMacroList()
        refreshCustomBlocks()

        recorder.$isRecording
            .receive(on: DispatchQueue.main)
            .sink { [weak self] recording in
                self?.isRecording = recording
            }
            .store(in: &cancellables)

        // Set up F10 hotkey to toggle recording
        recorder.onHotkeyPressed = { [weak self] in
            Task { @MainActor in
                self?.toggleRecording()
            }
        }

        // Start the global hotkey monitor (always running)
        recorder.startHotkeyMonitor()
    }

    func toggleRecording() {
        if recorder.isRecording {
            stopRecording()
        } else {
            if currentMacroName == nil {
                statusText = "Create or select a macro first"
                return
            }
            startRecording()
        }
    }

    // MARK: - Macro List

    func refreshMacroList() {
        macroNames = storage.listMacros().sorted()
    }

    func refreshCustomBlocks() {
        customBlockNames = storage.listCustomBlocks().sorted()
    }

    func createNewMacro(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        guard !storage.macroExists(name: trimmed) else {
            statusText = "A macro with this name already exists"
            return
        }
        storage.saveMacro(name: trimmed, blocks: [])
        currentMacroName = trimmed
        blocks = []
        refreshMacroList()
        statusText = "Created macro: \(trimmed)"
    }

    func loadMacro(name: String) {
        if let result = storage.loadMacro(name: name) {
            currentMacroName = name
            blocks = result.blocks
            statusText = "Loaded: \(name)"
        }
    }

    func deleteMacro(name: String) {
        if storage.deleteMacro(name: name) {
            if currentMacroName == name {
                currentMacroName = nil
                blocks = []
            }
            refreshMacroList()
            statusText = "Deleted: \(name)"
        }
    }

    func renameMacro(oldName: String, newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if storage.renameMacro(oldName: oldName, newName: trimmed) {
            if currentMacroName == oldName {
                currentMacroName = trimmed
            }
            refreshMacroList()
            statusText = "Renamed to: \(trimmed)"
        }
    }

    // MARK: - Blocks

    func addBlock(_ block: Block) {
        guard currentMacroName != nil else {
            statusText = "Create or select a macro first"
            return
        }
        blocks.append(block)
        saveCurrentMacro()
        statusText = "Added \(block.type.label) block"
    }

    func deleteBlock(at index: Int) {
        guard index >= 0 && index < blocks.count else { return }
        blocks.remove(at: index)
        saveCurrentMacro()
        statusText = "Deleted block #\(index + 1)"
    }

    func moveBlock(from source: IndexSet, to destination: Int) {
        blocks.move(fromOffsets: source, toOffset: destination)
        saveCurrentMacro()
    }

    func saveCurrentMacro() {
        guard let name = currentMacroName else { return }
        storage.saveMacro(name: name, blocks: blocks)
    }

    // MARK: - Custom Blocks

    func addCustomBlockToMacro(name: String) {
        guard currentMacroName != nil else {
            statusText = "Create or select a macro first"
            return
        }
        guard let result = storage.loadCustomBlock(name: name) else { return }
        let block = Block(type: .custom, params: [:], children: result.blocks, name: name)
        blocks.append(block)
        saveCurrentMacro()
        statusText = "Added custom block '\(name)'"
    }

    func saveCustomBlock(name: String, blocks: [Block]) {
        storage.saveCustomBlock(name: name, blocks: blocks)
        refreshCustomBlocks()
        statusText = "Saved custom block '\(name)'"
    }

    func deleteCustomBlock(name: String) {
        if storage.deleteCustomBlock(name: name) {
            refreshCustomBlocks()
            statusText = "Deleted custom block '\(name)'"
        }
    }

    // MARK: - Recording

    func startRecording() {
        recorder.start(mode: .macro)
        statusText = "Recording... Click Stop to finish"
    }

    func startRecordingCustomBlock(name: String) {
        recorder.start(mode: .custom(name: name))
        statusText = "Recording custom block '\(name)'..."
    }

    func stopRecording() {
        let newBlocks = recorder.stop()
        if !newBlocks.isEmpty {
            blocks.append(contentsOf: newBlocks)
            saveCurrentMacro()
            statusText = "Recorded \(newBlocks.count) actions"
        } else {
            statusText = "No actions recorded"
        }
    }

    func stopRecordingCustomBlock() -> (name: String, blocks: [Block])? {
        guard case .custom(let name) = recorder.recordingMode else { return nil }
        let newBlocks = recorder.stop()
        return (name, newBlocks)
    }

    // MARK: - Playback

    func playMacro() {
        guard !blocks.isEmpty else {
            statusText = "No blocks to play"
            return
        }
        isPlaying = true
        progress = 0
        statusText = "Playing macro..."

        player.speed = speed

        playThread = Thread { [weak self] in
            guard let self = self else { return }
            self.player.execute(blocks: self.blocks) { current, total in
                DispatchQueue.main.async {
                    self.progress = Double(current) / Double(total) * 100
                }
            }
            DispatchQueue.main.async {
                self.isPlaying = false
                self.progress = 100
                self.statusText = "Playback complete"
            }
        }
        playThread?.start()
    }

    func stopPlayback() {
        player.stop()
        isPlaying = false
        statusText = "Stopped"
    }
}
