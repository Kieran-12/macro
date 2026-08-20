import SwiftUI

struct SidebarView: View {
    @ObservedObject var viewModel: MacroEditorViewModel
    @State private var showNewMacroDialog = false
    @State private var newMacroName = ""
    @State private var showRenameDialog = false
    @State private var renameMacroName = ""
    @State private var selectedMacroForRename: String?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("MACRO RUNNER")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 15)
            .padding(.top, 15)
            .padding(.bottom, 10)
            .background(Color(hex: "#1a1a1a"))

            // My Macros Section
            VStack(alignment: .leading, spacing: 5) {
                Text("MY MACROS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "#4CAF50"))
                    .padding(.horizontal, 15)
                    .padding(.top, 10)

                // Create New Button
                Button(action: { showNewMacroDialog = true }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Create New Macro")
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(hex: "#4CAF50"))
                    .cornerRadius(4)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 15)
                .padding(.top, 5)

                // Macro List
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(viewModel.macroNames, id: \.self) { name in
                            MacroListItem(
                                name: name,
                                isSelected: viewModel.currentMacroName == name,
                                onSelect: { viewModel.loadMacro(name: name) }
                            )
                        }
                    }
                    .padding(.horizontal, 15)
                }
                .frame(maxHeight: .infinity)

                // Delete/Rename buttons
                HStack(spacing: 5) {
                    Button(action: deleteSelectedMacro) {
                        Text("Delete")
                            .font(.system(size: 9))
                            .foregroundColor(.black)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Color(hex: "#f44336"))
                            .cornerRadius(4)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: {
                        renameMacroName = viewModel.currentMacroName ?? ""
                        showRenameDialog = true
                    }) {
                        Text("Rename")
                            .font(.system(size: 9))
                            .foregroundColor(.black)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Color(hex: "#ff9800"))
                            .cornerRadius(4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 15)
                .padding(.bottom, 10)
            }
            .background(Color(hex: "#1a1a1a"))

            Divider()
                .background(Color(hex: "#333"))

            // Custom Blocks Section
            VStack(alignment: .leading, spacing: 5) {
                Text("CUSTOM BLOCKS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(hex: "#9C27B0"))
                    .padding(.horizontal, 15)
                    .padding(.top, 10)

                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(viewModel.customBlockNames, id: \.self) { name in
                            CustomBlockListItem(
                                name: name,
                                onDoubleClick: { viewModel.addCustomBlockToMacro(name: name) }
                            )
                        }
                    }
                    .padding(.horizontal, 15)
                }
                .frame(maxHeight: 120)

                HStack(spacing: 5) {
                    Button(action: { }) {
                        Text("Delete Block")
                            .font(.system(size: 9))
                            .foregroundColor(.black)
                            .padding(.vertical, 3)
                            .padding(.horizontal, 8)
                            .background(Color(hex: "#666"))
                            .cornerRadius(4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 15)
                .padding(.bottom, 10)
            }
            .background(Color(hex: "#1a1a1a"))
        }
        .background(Color(hex: "#1a1a1a"))
        .alert("New Macro", isPresented: $showNewMacroDialog) {
            TextField("Macro name", text: $newMacroName)
            Button("Cancel", role: .cancel) {
                newMacroName = ""
            }
            Button("Create") {
                if !newMacroName.isEmpty {
                    viewModel.createNewMacro(name: newMacroName)
                    newMacroName = ""
                }
            }
        }
        .alert("Rename Macro", isPresented: $showRenameDialog) {
            TextField("New name", text: $renameMacroName)
            Button("Cancel", role: .cancel) {
                renameMacroName = ""
            }
            Button("Rename") {
                if let oldName = viewModel.currentMacroName, !renameMacroName.isEmpty {
                    viewModel.renameMacro(oldName: oldName, newName: renameMacroName)
                    renameMacroName = ""
                }
            }
        }
    }

    private func deleteSelectedMacro() {
        guard let name = viewModel.currentMacroName else { return }
        viewModel.deleteMacro(name: name)
    }
}

struct MacroListItem: View {
    let name: String
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                Image(systemName: "doc.text")
                    .font(.system(size: 10))
                Text(name)
                    .font(.system(size: 10))
                    .lineLimit(1)
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(isSelected ? Color(hex: "#4CAF50") : Color(hex: "#2b2b2b"))
            .cornerRadius(4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CustomBlockListItem: View {
    let name: String
    let onDoubleClick: () -> Void

    var body: some View {
        Button(action: onDoubleClick) {
            HStack {
                Text("*")
                    .font(.system(size: 10))
                Text(name)
                    .font(.system(size: 9))
                    .lineLimit(1)
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.vertical, 4)
            .padding(.horizontal, 6)
            .background(Color(hex: "#2b2b2b"))
            .cornerRadius(4)
        }
        .buttonStyle(PlainButtonStyle())
        .onTapGesture(count: 2) {
            onDoubleClick()
        }
    }
}
