import SwiftUI

struct BlockPaletteView: View {
    @ObservedObject var viewModel: MacroEditorViewModel
    @State private var showBlockDialog = false
    @State private var selectedBlockType: BlockType?
    @State private var showRecordDialog = false
    @State private var customBlockName = ""

    var body: some View {
        VStack(spacing: 0) {
            Text("BLOCKS")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .padding(.top, 15)
                .padding(.bottom, 10)

            ScrollView {
                VStack(spacing: 4) {
                    ForEach(BlockType.allCases.filter { $0 != .custom }, id: \.self) { blockType in
                        Button(action: {
                            selectedBlockType = blockType
                            showBlockDialog = true
                        }) {
                            HStack {
                                Text(blockType.icon)
                                    .font(.system(size: 12))
                                Text(blockType.label)
                                    .font(.system(size: 9))
                                    .lineLimit(1)
                                Spacer()
                            }
                            .foregroundColor(.black)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 8)
                            .background(Color(hex: blockType.color))
                            .cornerRadius(4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 5)
            }

            Divider()
                .background(Color(hex: "#555"))
                .padding(.vertical, 10)

            // Record Button
            Button(action: toggleRecording) {
                HStack {
                    Text("🎤")
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
            .padding(.horizontal, 5)
            .padding(.bottom, 15)
        }
        .frame(maxHeight: .infinity)
        .background(Color(hex: "#333333"))
        .sheet(isPresented: $showBlockDialog) {
            if let blockType = selectedBlockType {
                BlockDialogView(
                    blockType: blockType,
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
        .sheet(isPresented: $showRecordDialog) {
            RecordCustomBlockDialog(
                blockName: $customBlockName,
                onSave: { name, blocks in
                    viewModel.saveCustomBlock(name: name, blocks: blocks)
                    showRecordDialog = false
                    customBlockName = ""
                },
                onCancel: {
                    showRecordDialog = false
                    customBlockName = ""
                }
            )
        }
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

struct RecordCustomBlockDialog: View {
    @Binding var blockName: String
    let onSave: (String, [Block]) -> Void
    let onCancel: () -> Void

    @State private var blocks: [Block] = []
    @State private var recorder = MacroRecorder()
    @State private var isRecording = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Record Custom Block")
                .font(.system(size: 16, weight: .bold))

            TextField("Block name", text: $blockName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 200)

            HStack {
                Button(action: {
                    if isRecording {
                        blocks = recorder.stop()
                        isRecording = false
                    } else {
                        recorder.start(mode: .custom(name: blockName))
                        isRecording = true
                    }
                }) {
                    Text(isRecording ? "Stop Recording" : "Start Recording")
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(isRecording ? Color.red : Color.green)
                        .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
            }

            if !blocks.isEmpty {
                Text("Recorded \(blocks.count) blocks")
                    .foregroundColor(.green)
            }

            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                Button("Save") {
                    onSave(blockName, blocks)
                }
                .disabled(blockName.isEmpty || blocks.isEmpty)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(blockName.isEmpty || blocks.isEmpty ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(6)
            }
        }
        .padding(30)
        .frame(width: 350)
    }
}
