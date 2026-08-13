import SwiftUI

struct PlaybackControlsView: View {
    @ObservedObject var viewModel: MacroEditorViewModel

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color(hex: "#444"))

            HStack {
                // Speed control
                HStack(spacing: 8) {
                    Text("Speed:")
                        .foregroundColor(.white)
                        .font(.system(size: 11))

                    HStack(spacing: 2) {
                        Button(action: { adjustSpeed(-0.1) }) {
                            Text("-")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Color(hex: "#555"))
                                .cornerRadius(4)
                        }
                        .buttonStyle(PlainButtonStyle())

                        Text(String(format: "%.1fx", viewModel.speed))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.white)
                            .frame(width: 40)

                        Button(action: { adjustSpeed(0.1) }) {
                            Text("+")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Color(hex: "#555"))
                                .cornerRadius(4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.leading, 10)

                Spacer()

                // Play/Stop buttons
                HStack(spacing: 10) {
                    Button(action: {
                        if viewModel.isPlaying {
                            viewModel.stopPlayback()
                        } else {
                            viewModel.playMacro()
                        }
                    }) {
                        HStack {
                            Image(systemName: viewModel.isPlaying ? "stop.fill" : "play.fill")
                            Text(viewModel.isPlaying ? "STOP" : "PLAY")
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(viewModel.isPlaying ? Color(hex: "#f44336") : Color(hex: "#4CAF50"))
                        .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.trailing, 10)
            }
            .padding(.vertical, 10)
            .background(Color(hex: "#2b2b2b"))

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(hex: "#444"))
                        .frame(height: 6)

                    Rectangle()
                        .fill(Color(hex: "#4CAF50"))
                        .frame(width: geometry.size.width * CGFloat(viewModel.progress / 100), height: 6)
                }
            }
            .frame(height: 6)

            // Status bar
            HStack {
                Text(viewModel.statusText)
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: "#aaaaaa"))
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(hex: "#1a1a1a"))
        }
    }

    private func adjustSpeed(_ delta: Double) {
        let newSpeed = max(0.1, min(5.0, viewModel.speed + delta))
        viewModel.speed = newSpeed
    }
}
