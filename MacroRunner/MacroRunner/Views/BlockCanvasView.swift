import SwiftUI

struct BlockCanvasView: View {
    @ObservedObject var viewModel: MacroEditorViewModel
    @State private var editingBlockId: UUID?
    @State private var isEditing: Bool = false

    private var editingBlock: Block? {
        guard let id = editingBlockId else { return nil }
        return viewModel.blocks.first { $0.id == id }
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            canvasArea
        }
        .sheet(isPresented: $isEditing) {
            BlockEditSheet(
                blockId: editingBlockId,
                blocks: viewModel.blocks,
                onSave: { updatedBlock in
                    if let idx = viewModel.blocks.firstIndex(where: { $0.id == updatedBlock.id }) {
                        viewModel.blocks[idx] = updatedBlock
                        viewModel.saveCurrentMacro()
                    }
                    isEditing = false
                    editingBlockId = nil
                },
                onCancel: {
                    isEditing = false
                    editingBlockId = nil
                }
            )
        }
    }

    private var topBar: some View {
        HStack {
            Text(viewModel.currentMacroName ?? "No macro selected")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
            Spacer()
            if viewModel.isRecording {
                Text("● REC")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(hex: "#2b2b2b"))
    }

    private var canvasArea: some View {
        ScrollView {
            VStack(spacing: 0) {
                StartFlagView(
                    onPlay: { viewModel.playMacro() },
                    isPlaying: viewModel.isPlaying
                )
                .padding(.top, 10)

                if viewModel.blocks.isEmpty {
                    emptyState
                } else {
                    blockList
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
        }
        .background(Color(hex: "#404040"))
        .cornerRadius(4)
        .padding(10)
    }

    private var emptyState: some View {
        VStack(spacing: 15) {
            Image(systemName: "plus.circle.dashed")
                .font(.system(size: 50))
                .foregroundColor(Color(hex: "#555"))
            Text("Click a block type in the palette\nto add it here")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#888"))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
        .padding(.bottom, 40)
    }

    private var blockList: some View {
        LazyVStack(spacing: 8) {
            ForEach(viewModel.blocks) { block in
                BlockRowView(
                    block: block,
                    isRecording: viewModel.isRecording,
                    isPlaying: viewModel.isPlaying,
                    onDelete: {
                        if editingBlockId == block.id {
                            isEditing = false
                            editingBlockId = nil
                        }
                        if let idx = viewModel.blocks.firstIndex(where: { $0.id == block.id }) {
                            viewModel.deleteBlock(at: idx)
                        }
                    },
                    onEdit: {
                        editingBlockId = block.id
                        isEditing = true
                    }
                )
            }
        }
    }
}

struct BlockRowView: View {
    let block: Block
    let isRecording: Bool
    let isPlaying: Bool
    let onDelete: () -> Void
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            // Double-tap target - only the content area, excluding buttons
            ZStack {
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        onEdit()
                    }

                HStack(spacing: 0) {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 12))
                        .foregroundColor(.black.opacity(0.4))
                        .padding(.horizontal, 6)

                    Text(block.type.label)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.black)

                    if block.type == .custom, let name = block.name {
                        Text(": \(name)")
                            .font(.system(size: 10))
                            .foregroundColor(.black.opacity(0.8))
                    }

                    if block.type == .repeatBlock {
                        Text("count = \(block.params["count"]?.value as? Int ?? 1)")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.black.opacity(0.8))
                    }

                    Text(formatBlockParams(block))
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.black.opacity(0.8))
                        .padding(.leading, 8)

                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
            }

            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.system(size: 11))
                    .foregroundColor(.black.opacity(0.6))
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 4)

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.red)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 4)
        }
        .background(Color(hex: block.type.color))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(isPlaying ? Color.yellow : Color.white, lineWidth: isPlaying ? 3 : 2)
        )
        .cornerRadius(4)
    }

    private func formatBlockParams(_ block: Block) -> String {
        var result: [String] = []
        let orderedKeys: [String]
        switch block.type {
        case .moveMouse:
            orderedKeys = ["x", "y", "move_duration"]
        case .click:
            orderedKeys = ["x", "y", "button", "clicks"]
        case .mouseDown, .mouseUp:
            orderedKeys = ["x", "y", "button"]
        case .keyPress, .holdKey, .releaseKey:
            orderedKeys = ["key"]
        case .wait:
            orderedKeys = ["seconds"]
        case .scroll:
            orderedKeys = ["amount", "x", "y"]
        case .custom, .repeatBlock:
            orderedKeys = []
        }
        for key in orderedKeys {
            if let value = block.params[key] {
                result.append("\(key) = \(value.value)")
            }
        }
        for (key, value) in block.params {
            if !orderedKeys.contains(key) && key != "count" {
                result.append("\(key) = \(value.value)")
            }
        }
        if result.isEmpty {
            return "Empty Parameters"
        }
        return result.joined(separator: "  ")
    }
}

struct StartFlagView: View {
    let onPlay: () -> Void
    let isPlaying: Bool

    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: "flag.fill")
                .font(.system(size: 20))
                .foregroundColor(.white)

            Text("START")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)

            Spacer()

            Button(action: onPlay) {
                HStack(spacing: 4) {
                    Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                    Text(isPlaying ? "STOP" : "RUN")
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isPlaying ? Color.red : Color(hex: "#4CAF50"))
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 12)
        .background(Color(hex: "#4CAF50"))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.white, lineWidth: 2)
        )
    }
}

struct BlockEditSheet: View {
    let blockId: UUID?
    let blocks: [Block]
    let onSave: (Block) -> Void
    let onCancel: () -> Void

    private var block: Block? {
        guard let id = blockId else { return nil }
        return blocks.first { $0.id == id }
    }

    var body: some View {
        if let block = block {
            BlockDialogView(
                blockType: block.type,
                existingBlock: block,
                onSave: onSave,
                onCancel: onCancel
            )
        } else {
            Color.clear
                .onAppear {
                    onCancel()
                }
        }
    }
}
