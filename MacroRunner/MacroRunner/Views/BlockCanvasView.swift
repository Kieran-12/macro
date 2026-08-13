import SwiftUI

struct BlockCanvasView: View {
    @ObservedObject var viewModel: MacroEditorViewModel
    @State private var editingBlockIndex: Int?
    @State private var draggedBlockIndex: Int?
    @State private var dragOffset: CGSize = .zero

    var body: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                Text(viewModel.currentMacroName.map { "Editing: \($0)" } ?? "No macro selected")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)

                if viewModel.isRecording {
                    Text("● REC")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#f44336"))
                        .padding(.horizontal, 8)
                }

                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color(hex: "#2b2b2b"))

            // Canvas
            ScrollView {
                LazyVStack(spacing: 8) {
                    if viewModel.blocks.isEmpty {
                        Text("Add blocks to start building your macro...")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#888888"))
                            .padding(.top, 100)
                    } else {
                        ForEach(Array(viewModel.blocks.enumerated()), id: \.element.id) { index, block in
                            BlockRowView(
                                block: block,
                                index: index,
                                isRecording: viewModel.isRecording,
                                onDelete: {
                                    viewModel.deleteBlock(at: index)
                                },
                                onAddChild: { childBlock in
                                    viewModel.blocks[index].children.append(childBlock)
                                    viewModel.saveCurrentMacro()
                                }
                            )
                        }
                    }
                }
                .padding(10)
                .frame(minHeight: 400)
            }
            .background(Color(hex: "#404040"))
            .cornerRadius(4)
            .padding(10)
        }
    }
}

struct BlockRowView: View {
    let block: Block
    let index: Int
    let isRecording: Bool
    let onDelete: () -> Void
    let onAddChild: (Block) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 0) {
                Text(block.type.icon)
                    .font(.system(size: 14))

                Text(block.type.label)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.black)

                if block.type == .custom, let name = block.name {
                    Text(": \(name)")
                        .font(.system(size: 11))
                        .foregroundColor(.black.opacity(0.8))
                }

                Spacer()

                Text("#\(index + 1)")
                    .font(.system(size: 9))
                    .foregroundColor(.black.opacity(0.6))

                Button(action: onDelete) {
                    Text("✕")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "#ff6b6b"))
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.leading, 8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            // Params
            if !block.params.isEmpty {
                Text(formatParams(block.params))
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
            }

            // Repeat indicator
            if block.type == .repeatBlock {
                let count = (block.params["count"]?.value as? Int) ?? 1
                Text("↳ Repeat \(count)×")
                    .font(.system(size: 9).italic())
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 4)
            }

            // Children
            if !block.children.isEmpty {
                VStack(spacing: 4) {
                    ForEach(Array(block.children.enumerated()), id: \.element.id) { childIndex, child in
                        HStack(spacing: 0) {
                            Text("  ↳")
                                .font(.system(size: 10))
                                .foregroundColor(.black.opacity(0.5))
                            Text(child.type.icon)
                                .font(.system(size: 10))
                            Text(child.type.label)
                                .font(.system(size: 9))
                                .foregroundColor(.black)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 4)
                    }
                }
                .padding(.bottom, 4)
            }
        }
        .background(Color(hex: block.type.color))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.white, lineWidth: 2)
        )
        .cornerRadius(4)
    }

    private func formatParams(_ params: [String: AnyCodable]) -> String {
        params.map { key, value in
            if key == "count" { return nil }
            return "\(key)=\(value.value)"
        }
        .compactMap { $0 }
        .joined(separator: ", ")
    }
}
