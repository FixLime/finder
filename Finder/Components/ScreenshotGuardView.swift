import SwiftUI
import UIKit

// MARK: - Screenshot Guard
// Uses iOS secure text field trick to hide content from screenshots/screen recording

struct ScreenshotGuardView<Content: View>: UIViewRepresentable {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    func makeUIView(context: Context) -> UIView {
        let secureField = UITextField()
        secureField.isSecureTextEntry = true
        secureField.isUserInteractionEnabled = false

        // Get the secure container from the text field
        guard let secureContainer = secureField.subviews.first else {
            return UIView()
        }

        // Host the SwiftUI content inside the secure container
        let hostController = UIHostingController(rootView: content)
        hostController.view.backgroundColor = .clear
        hostController.view.translatesAutoresizingMaskIntoConstraints = false

        secureContainer.subviews.forEach { $0.removeFromSuperview() }
        secureContainer.addSubview(hostController.view)
        secureContainer.translatesAutoresizingMaskIntoConstraints = false

        let containerView = UIView()
        containerView.addSubview(secureContainer)

        NSLayoutConstraint.activate([
            secureContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            secureContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            secureContainer.topAnchor.constraint(equalTo: containerView.topAnchor),
            secureContainer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            hostController.view.leadingAnchor.constraint(equalTo: secureContainer.leadingAnchor),
            hostController.view.trailingAnchor.constraint(equalTo: secureContainer.trailingAnchor),
            hostController.view.topAnchor.constraint(equalTo: secureContainer.topAnchor),
            hostController.view.bottomAnchor.constraint(equalTo: secureContainer.bottomAnchor),
        ])

        context.coordinator.hostController = hostController
        return containerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.hostController?.rootView = content
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var hostController: UIHostingController<Content>?
    }
}
