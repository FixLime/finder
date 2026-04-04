import SwiftUI
import UIKit

// MARK: - Screenshot Guard
// Wraps content in a secure container that hides from screenshots and screen recording

struct ScreenshotGuardView<Content: View>: UIViewRepresentable {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    func makeUIView(context: Context) -> ScreenshotGuardUIView<Content> {
        let view = ScreenshotGuardUIView(content: content)
        return view
    }

    func updateUIView(_ uiView: ScreenshotGuardUIView<Content>, context: Context) {
        uiView.updateContent(content)
    }
}

class ScreenshotGuardUIView<Content: View>: UIView {
    private var hostController: UIHostingController<Content>?
    private let secureField = UITextField()

    init(content: Content) {
        super.init(frame: .zero)
        setupSecureContent(content)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSecureContent(_ content: Content) {
        // Create a secure text field — its layer hides content from screenshots
        secureField.isSecureTextEntry = true
        secureField.isUserInteractionEnabled = false
        secureField.alpha = 0.01 // nearly invisible but keeps secure layer active
        addSubview(secureField)

        // Find the secure container layer
        if let secureLayer = secureField.layer.sublayers?.first {
            // Host SwiftUI content
            let host = UIHostingController(rootView: content)
            host.view.backgroundColor = .clear
            host.view.translatesAutoresizingMaskIntoConstraints = false

            addSubview(host.view)
            NSLayoutConstraint.activate([
                host.view.leadingAnchor.constraint(equalTo: leadingAnchor),
                host.view.trailingAnchor.constraint(equalTo: trailingAnchor),
                host.view.topAnchor.constraint(equalTo: topAnchor),
                host.view.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])

            // Apply the secure layer mask to the hosting view
            host.view.layer.mask = secureLayer

            self.hostController = host
        } else {
            // Fallback: just add hosting controller without secure masking
            let host = UIHostingController(rootView: content)
            host.view.backgroundColor = .clear
            host.view.translatesAutoresizingMaskIntoConstraints = false

            addSubview(host.view)
            NSLayoutConstraint.activate([
                host.view.leadingAnchor.constraint(equalTo: leadingAnchor),
                host.view.trailingAnchor.constraint(equalTo: trailingAnchor),
                host.view.topAnchor.constraint(equalTo: topAnchor),
                host.view.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])

            self.hostController = host
        }
    }

    func updateContent(_ content: Content) {
        hostController?.rootView = content
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        secureField.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
    }
}
