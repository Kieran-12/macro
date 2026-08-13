import SwiftUI

struct BlockPaletteView: View {
    @ObservedObject var viewModel: MacroEditorViewModel
    @State private var selectedCategory: BlockCategory = .motion
    @State private var showBlockDialog = false
    @State private var selectedBlockType: BlockType?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("SCRIPTS")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .padding(.top, 15)
                .padding(.bottom, 10)

            HStack(spacing: 0) {
                // Categories sidebar
                VStack(spacing: 8) {
                    ForEach(BlockCategory.allCases, id: \.self) { category in
                        CategoryButton(
                            category: category,
                            isSelected: selectedCategory == category,
                            onTap: { selectedCategory = category }
                        )
                    }
                }
                .frame(minWidth: 100, maxWidth: .infinity)

                // Blocks area
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(blocksForCategory(selectedCategory), id: \.self) { blockType in
                            PaletteBlockButton(blockType: blockType) {
                                selectedBlockType = blockType
                                showBlockDialog = true
                            }
                        }
                    }
                    .padding(5)
                }
                .frame(maxWidth: .infinity)
            }

            Divider()
                .background(Color(hex: "#555"))
                .padding(.vertical, 8)

            // Record button with F10 hint
            VStack(spacing: 4) {
                Button(action: toggleRecording) {
                    HStack {
                        Text("REC")
                            .font(.system(size: 12))
                        Text(viewModel.isRecording ? "Stop Rec" : "Record")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(viewModel.isRecording ? Color(hex: "#9C27B0") : Color(hex: "#f44336"))
                    .cornerRadius(4)
                }
                .buttonStyle(PlainButtonStyle())

                Text("F10")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(hex: "#888"))
            }
            .padding(.horizontal, 5)
            .padding(.bottom, 10)
        }
        .frame(maxHeight: .infinity)
        .background(Color(hex: "#333333"))
        .sheet(isPresented: $showBlockDialog) {
            if let blockType = selectedBlockType {
                BlockDialogView(
                    blockType: blockType,
                    existingBlock: nil,
                    onSave: { block in
                        viewModel.addBlock(block)
                        showBlockDialog = false
                    },
                    onCancel: {
                        showBlockDialog = false
                    }
                )
            }
        }
    }

    private func blocksForCategory(_ category: BlockCategory) -> [BlockType] {
        category.blockTypes
    }

    private func toggleRecording() {
        if viewModel.isRecording {
            viewModel.stopRecording()
        } else {
            if viewModel.currentMacroName == nil {
                viewModel.statusText = "Create or select a macro first"
                return
            }
            viewModel.startRecording()
        }
    }
}

enum BlockCategory: String, CaseIterable {
    case motion = "Motion"
    case looks = "Looks"
    case sound = "Sound"
    case events = "Events"
    case control = "Control"
    case input = "Input"

    var color: String {
        switch self {
        case .motion: return "#4A90D9"
        case .looks: return "#9B59B6"
        case .sound: return "#E74C3C"
        case .events: return "#F1C40F"
        case .control: return "#F39C12"
        case .input: return "#2ECC71"
        }
    }

    var blockTypes: [BlockType] {
        switch self {
        case .motion:
            return [.moveMouse]
        case .looks:
            return [.scroll]
        case .sound:
            return [.keyPress]
        case .events:
            return []
        case .control:
            return [.wait, .repeatBlock]
        case .input:
            return [.click, .mouseDown, .mouseUp, .holdKey, .releaseKey]
        }
    }
}

struct CategoryButton: View {
    let category: BlockCategory
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color(hex: category.color).opacity(0.3) : Color.clear)

            VStack(spacing: 6) {
                Text(category.rawValue)
                    .font(.system(size: 11, weight: .bold))

                Circle()
                    .fill(Color(hex: category.color))
                    .frame(width: 12, height: 12)
            }
            .foregroundColor(isSelected ? .white : Color(hex: category.color))
        }
        .frame(width: 100, height: 50)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

struct PaletteBlockButton: View {
    let blockType: BlockType
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Text(blockType.icon)
                    .font(.system(size: 11))
                Text(blockType.label)
                    .font(.system(size: 9, weight: .medium))
                    .lineLimit(1)
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(Color(hex: blockType.color))
            .cornerRadius(4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
