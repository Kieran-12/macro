import SwiftUI

struct BlockCanvasView: View {
    @ObservedObject var viewModel: MacroEditorViewModel
    @State private var showEditDialog = false
    @State private var editingBlock: Block?
    @State private var editingBlockIndex: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            topBar
            canvasArea
        }
        .sheet(isPresented: $showEditDialog) {
            if let block = editingBlock {
                BlockDialogView(
                    blockType: block.type,
                    existingBlock: block,
                    onSave: { updatedBlock in
                        viewModel.blocks[editingBlockIndex] = updatedBlock
                        viewModel.saveCurrentMacro()
                        showEditDialog = false
                    },
                    onCancel: {
                        showEditDialog = false
                    }
                )
            }
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
            ForEach(Array(viewModel.blocks.enumerated()), id: \.element.id) { index, block in
                DraggableBlockView(
                    block: block,
                    index: index,
                    isRecording: viewModel.isRecording,
                    isPlaying: viewModel.isPlaying,
                    onDelete: { viewModel.deleteBlock(at: index) },
                    onEdit: {
                        editingBlock = block
                        editingBlockIndex = index
                        showEditDialog = true
                    },
                    onMoveUp: index > 0 ? { viewModel.moveBlock(from: IndexSet(integer: index), to: index - 1) } : nil,
                    onMoveDown: index < viewModel.blocks.count - 1 ? { viewModel.moveBlock(from: IndexSet(integer: index), to: index + 2) } : nil
                )
            }
        }
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

struct DraggableBlockView: View {
    let block: Block
    let index: Int
    let isRecording: Bool
    let isPlaying: Bool
    let onDelete: () -> Void
    let onEdit: () -> Void
    let onMoveUp: (() -> Void)?
    let onMoveDown: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            mainRow
            if block.type == .repeatBlock {
                repeatIndicator
            }
            if !block.children.isEmpty {
                childrenList
            }
        }
        .background(Color(hex: block.type.color))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(isPlaying ? Color.yellow : Color.white, lineWidth: isPlaying ? 3 : 2)
        )
        .cornerRadius(4)
        .onTapGesture(count: 2) {
            onEdit()
        }
    }

    private var mainRow: some View {
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

            Text(formatParams(block.params))
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.black.opacity(0.8))
                .padding(.leading, 8)

            Spacer()

            Text("#\(index + 1)")
                .font(.system(size: 9))
                .foregroundColor(.black.opacity(0.5))

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
                    .foregroundColor(Color(hex: "#ff6b6b"))
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 4)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
    }

    private var paramsRow: some View {
        Text(formatParams(block.params))
            .font(.system(size: 9, design: .monospaced))
            .foregroundColor(.black.opacity(0.8))
            .padding(.horizontal, 30)
            .padding(.bottom, 4)
    }

    private var repeatIndicator: some View {
        HStack(spacing: 4) {
            Text("↳")
                .font(.system(size: 10))
                .foregroundColor(.black.opacity(0.5))
            Text("Repeat \((block.params["count"]?.value as? Int) ?? 1)×")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.black)
            Spacer()
        }
        .padding(.horizontal, 30)
        .padding(.bottom, 4)
    }

    private var childrenList: some View {
        VStack(spacing: 4) {
            ForEach(Array(block.children.enumerated()), id: \.element.id) { childIndex, child in
                HStack(spacing: 0) {
                    Text("    ↳")
                        .font(.system(size: 10))
                        .foregroundColor(.black.opacity(0.4))
                    Text(child.type.icon)
                        .font(.system(size: 10))
                    Text(child.type.label)
                        .font(.system(size: 9))
                        .foregroundColor(.black.opacity(0.8))
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 3)
            }
        }
        .padding(.bottom, 4)
    }

    private func formatParams(_ params: [String: AnyCodable]) -> String {
        var result: [String] = []

        // Ordered params for each block type
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
            if let value = params[key] {
                result.append("\(key) = \(value.value)")
            }
        }

        // Add any remaining params not in orderedKeys
        for (key, value) in params {
            if !orderedKeys.contains(key) && key != "count" {
                result.append("\(key) = \(value.value)")
            }
        }

        return result.joined(separator: "  ")
    }
}
