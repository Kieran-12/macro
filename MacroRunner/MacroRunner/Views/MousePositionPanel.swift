import AppKit
import SwiftUI

class MousePositionPanel: NSPanel {
    private var coordinateLabel: NSTextField?

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 40),
            styleMask: [.borderless, .nonactivatingPanel, .hudWindow],
            backing: .buffered,
            defer: false
        )

        self.isFloatingPanel = true
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isOpaque = false
        self.backgroundColor = NSColor.black.withAlphaComponent(0.7)
        self.hasShadow = true

        setupUI()
        positionPanel()
    }

    private func setupUI() {
        let stackView = NSStackView()
        stackView.orientation = .horizontal
        stackView.spacing = 20
        stackView.edgeInsets = NSEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)

        let xLabel = NSTextField(labelWithString: "X:")
        xLabel.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .medium)
        xLabel.textColor = .white

        let xValue = NSTextField(labelWithString: "0")
        xValue.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .bold)
        xValue.textColor = .systemGreen
        xValue.identifier = NSUserInterfaceItemIdentifier("xValue")

        let yLabel = NSTextField(labelWithString: "Y:")
        yLabel.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .medium)
        yLabel.textColor = .white

        let yValue = NSTextField(labelWithString: "0")
        yValue.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .bold)
        yValue.textColor = .systemGreen
        yValue.identifier = NSUserInterfaceItemIdentifier("yValue")

        self.coordinateLabel = xValue

        stackView.addArrangedSubview(xLabel)
        stackView.addArrangedSubview(xValue)
        stackView.addArrangedSubview(yLabel)
        stackView.addArrangedSubview(yValue)

        self.contentView = stackView
    }

    private func positionPanel() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let panelSize = self.frame.size

        let x = screenFrame.maxX - panelSize.width - 10
        let y = screenFrame.maxY - panelSize.height - 10

        self.setFrameOrigin(NSPoint(x: x, y: y))
    }

    func updatePosition(x: Int, y: Int) {
        guard let contentView = self.contentView as? NSStackView else { return }

        for view in contentView.arrangedSubviews {
            if let textField = view as? NSTextField {
                if textField.identifier?.rawValue == "xValue" {
                    textField.stringValue = "\(x)"
                } else if textField.identifier?.rawValue == "yValue" {
                    textField.stringValue = "\(y)"
                }
            }
        }
    }
}

class MousePositionMonitor {
    static let shared = MousePositionMonitor()

    private var panel: MousePositionPanel?
    private var isVisible = false

    private init() {}

    func show() {
        if panel == nil {
            panel = MousePositionPanel()
        }
        panel?.orderFront(nil)
        isVisible = true
        startMonitoring()
    }

    func hide() {
        panel?.orderOut(nil)
        isVisible = false
        stopMonitoring()
    }

    func toggle() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }

    private func startMonitoring() {
        // Poll mouse position since global monitors can be unreliable
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.updatePositionFromMouseLocation()
        }
    }

    private func updatePositionFromMouseLocation() {
        guard let screen = NSScreen.main else { return }
        let mouseLoc = NSEvent.mouseLocation
        // Convert to top-left origin (user-friendly coordinates)
        let x = Int(mouseLoc.x)
        let y = Int(screen.frame.height - mouseLoc.y)

        DispatchQueue.main.async { [weak self] in
            self?.panel?.updatePosition(x: x, y: y)
        }
    }

    private func stopMonitoring() {
        // Note: Global monitors cannot be explicitly removed in newer macOS
        // They are automatically removed when the app terminates
    }
}
