import SwiftUI
import PhotosUI
import AVFoundation
import Vision

struct GovLoginView: View {
    @EnvironmentObject var localization: LocalizationManager
    @Environment(\.dismiss) var dismiss

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var capturedImage: UIImage?
    @State private var isSubmitting = false
    @State private var isSubmitted = false

    var body: some View {
        NavigationStack {
            if isSubmitted {
                submittedView
            } else if capturedImage != nil {
                reviewView
            } else {
                scannerView
            }
        }
    }

    // MARK: - Scanner View (live camera)
    private var scannerView: some View {
        ZStack {
            DocumentScannerView(capturedImage: $capturedImage)
                .ignoresSafeArea()

            VStack {
                Spacer()

                // Gallery button at bottom
                HStack(spacing: 16) {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        HStack(spacing: 8) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 16))
                            Text(localization.localized("Галерея", "Gallery"))
                                .font(.subheadline.bold())
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(.ultraThinMaterial, in: Capsule())
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle(localization.localized("Сканер удостоверения", "ID Scanner"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(.ultraThinMaterial, in: Circle())
                }
            }
        }
        .onChange(of: selectedPhoto) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    capturedImage = image
                }
            }
        }
    }

    // MARK: - Review captured photo
    private var reviewView: some View {
        ScrollView {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.indigo.opacity(0.15))
                        .frame(width: 80, height: 80)
                    Image(systemName: "building.columns.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.indigo)
                }
                .padding(.top, 16)

                Text(localization.localized("Проверьте фото", "Review Photo"))
                    .font(.title3.bold())

                if let image = capturedImage {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 280)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.green.opacity(0.6), lineWidth: 2.5)
                            )

                        Button {
                            capturedImage = nil
                            selectedPhoto = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(.white, .red)
                                .shadow(radius: 3)
                        }
                        .padding(10)
                    }
                    .padding(.horizontal, 24)
                }

                // Info
                VStack(alignment: .leading, spacing: 10) {
                    infoRow(icon: "lock.fill", color: .green,
                            text: localization.localized("Данные передаются в зашифрованном виде", "Data is transmitted encrypted"))
                    infoRow(icon: "clock.fill", color: .orange,
                            text: localization.localized("Проверка занимает до 24 часов", "Verification takes up to 24 hours"))
                    infoRow(icon: "checkmark.shield.fill", color: .blue,
                            text: localization.localized("После проверки вы получите статус госслужащего", "After verification you'll receive government employee status"))
                }
                .padding(14)
                .liquidGlassCard(cornerRadius: 14)
                .padding(.horizontal, 24)

                // Buttons
                VStack(spacing: 12) {
                    Button {
                        submitApplication()
                    } label: {
                        HStack(spacing: 8) {
                            if isSubmitting {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.8)
                            }
                            Text(localization.localized("Отправить на проверку", "Submit for Review"))
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(isSubmitting ? Color.gray : Color.indigo)
                        )
                    }
                    .disabled(isSubmitting)

                    Button {
                        capturedImage = nil
                        selectedPhoto = nil
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.counterclockwise")
                            Text(localization.localized("Переснять", "Retake"))
                        }
                        .font(.subheadline)
                        .foregroundStyle(.indigo)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .liquidGlassCard(cornerRadius: 12)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle(localization.localized("Госслужащий", "Gov. Employee"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(localization.cancel) { dismiss() }
            }
        }
    }

    // MARK: - Submitted
    private var submittedView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 100, height: 100)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.green)
            }

            VStack(spacing: 10) {
                Text(localization.localized("Заявка отправлена", "Application Submitted"))
                    .font(.title2.bold())

                Text(localization.localized(
                    "Ваше удостоверение отправлено на проверку. Мы уведомим вас о результате в течение 24 часов.",
                    "Your ID has been submitted for review. We'll notify you of the result within 24 hours."
                ))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            }

            HStack(spacing: 10) {
                Image(systemName: "clock.badge.checkmark")
                    .font(.system(size: 20))
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text(localization.localized("Статус: На рассмотрении", "Status: Under Review"))
                        .font(.subheadline.bold())
                    Text(localization.localized("Ожидайте уведомления", "Await notification"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(14)
            .liquidGlassCard(cornerRadius: 14)
            .padding(.horizontal, 32)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text(localization.done)
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.blue)
                    )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 30)
        }
        .navigationBarBackButtonHidden()
    }

    // MARK: - Helpers
    private func infoRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
                .frame(width: 20)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func submitApplication() {
        isSubmitting = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.spring(response: 0.4)) {
                isSubmitting = false
                isSubmitted = true
            }
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
}

// MARK: - Document Scanner with Live Camera + Vision Detection
struct DocumentScannerView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?

    func makeUIViewController(context: Context) -> DocumentScannerViewController {
        let vc = DocumentScannerViewController()
        vc.onCapture = { image in
            capturedImage = image
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: DocumentScannerViewController, context: Context) {}
}

class DocumentScannerViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate {
    var onCapture: ((UIImage) -> Void)?

    private let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureVideoDataOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer!

    // UI
    private let frameOverlay = UIView()
    private let topLeftCorner = CAShapeLayer()
    private let topRightCorner = CAShapeLayer()
    private let bottomLeftCorner = CAShapeLayer()
    private let bottomRightCorner = CAShapeLayer()
    private let dimLayer = CAShapeLayer()
    private let statusLabel = UILabel()
    private let captureButton = UIButton(type: .system)
    private let hintLabel = UILabel()
    private let detectedRectLayer = CAShapeLayer()

    // State
    private var documentDetected = false
    private var stableFrameCount = 0
    private let requiredStableFrames = 8

    // Frame rect for the ID card cutout (set in viewDidLayoutSubviews)
    private var cardRect: CGRect = .zero

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
        setupOverlay()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
        updateOverlay()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        captureSession.stopRunning()
    }

    // MARK: - Camera Setup
    private func setupCamera() {
        captureSession.sessionPreset = .high

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else { return }

        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }

        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }

        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "video.queue"))
        videoOutput.alwaysDiscardsLateVideoFrames = true
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
    }

    // MARK: - Overlay
    private func setupOverlay() {
        // Dim layer (darkens everything outside the card frame)
        dimLayer.fillRule = .evenOdd
        dimLayer.fillColor = UIColor.black.withAlphaComponent(0.55).cgColor
        view.layer.addSublayer(dimLayer)

        // Detected rect highlight
        detectedRectLayer.strokeColor = UIColor.systemGreen.withAlphaComponent(0.7).cgColor
        detectedRectLayer.fillColor = UIColor.systemGreen.withAlphaComponent(0.08).cgColor
        detectedRectLayer.lineWidth = 2.5
        view.layer.addSublayer(detectedRectLayer)

        // Corner markers
        [topLeftCorner, topRightCorner, bottomLeftCorner, bottomRightCorner].forEach {
            $0.strokeColor = UIColor.white.cgColor
            $0.fillColor = UIColor.clear.cgColor
            $0.lineWidth = 3.5
            $0.lineCap = .round
            view.layer.addSublayer($0)
        }

        // Status label
        statusLabel.textAlignment = .center
        statusLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        statusLabel.textColor = .white
        statusLabel.layer.shadowColor = UIColor.black.cgColor
        statusLabel.layer.shadowOffset = .zero
        statusLabel.layer.shadowRadius = 4
        statusLabel.layer.shadowOpacity = 0.8
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)

        // Hint label at top
        hintLabel.text = ""
        hintLabel.textAlignment = .center
        hintLabel.font = .systemFont(ofSize: 13, weight: .medium)
        hintLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hintLabel)

        // Capture button
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        captureButton.backgroundColor = .white
        captureButton.layer.cornerRadius = 36
        captureButton.layer.borderWidth = 4
        captureButton.layer.borderColor = UIColor.white.withAlphaComponent(0.4).cgColor
        captureButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)

        let innerCircle = UIView()
        innerCircle.backgroundColor = .white
        innerCircle.layer.cornerRadius = 28
        innerCircle.translatesAutoresizingMaskIntoConstraints = false
        innerCircle.isUserInteractionEnabled = false
        captureButton.addSubview(innerCircle)

        view.addSubview(captureButton)

        NSLayoutConstraint.activate([
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -90),
            captureButton.widthAnchor.constraint(equalToConstant: 72),
            captureButton.heightAnchor.constraint(equalToConstant: 72),

            innerCircle.centerXAnchor.constraint(equalTo: captureButton.centerXAnchor),
            innerCircle.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor),
            innerCircle.widthAnchor.constraint(equalToConstant: 56),
            innerCircle.heightAnchor.constraint(equalToConstant: 56),

            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.bottomAnchor.constraint(equalTo: captureButton.topAnchor, constant: -24),

            hintLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hintLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
        ])
    }

    private func updateOverlay() {
        let bounds = view.bounds
        // ID card aspect ratio ~1.586 (CR80 standard)
        let cardW = bounds.width - 48
        let cardH = cardW / 1.586
        let cardX = (bounds.width - cardW) / 2
        let cardY = (bounds.height - cardH) / 2 - 40
        cardRect = CGRect(x: cardX, y: cardY, width: cardW, height: cardH)

        // Dim layer
        let fullPath = UIBezierPath(rect: bounds)
        let cutout = UIBezierPath(roundedRect: cardRect, cornerRadius: 14)
        fullPath.append(cutout)
        dimLayer.path = fullPath.cgPath

        // Corner markers
        let cornerLen: CGFloat = 30
        let r = cardRect

        func cornerPath(_ points: [(CGFloat, CGFloat)]) -> CGPath {
            let p = UIBezierPath()
            p.move(to: CGPoint(x: points[0].0, y: points[0].1))
            for pt in points.dropFirst() { p.addLine(to: CGPoint(x: pt.0, y: pt.1)) }
            return p.cgPath
        }

        topLeftCorner.path = cornerPath([
            (r.minX, r.minY + cornerLen),
            (r.minX, r.minY),
            (r.minX + cornerLen, r.minY)
        ])
        topRightCorner.path = cornerPath([
            (r.maxX - cornerLen, r.minY),
            (r.maxX, r.minY),
            (r.maxX, r.minY + cornerLen)
        ])
        bottomLeftCorner.path = cornerPath([
            (r.minX, r.maxY - cornerLen),
            (r.minX, r.maxY),
            (r.minX + cornerLen, r.maxY)
        ])
        bottomRightCorner.path = cornerPath([
            (r.maxX - cornerLen, r.maxY),
            (r.maxX, r.maxY),
            (r.maxX, r.maxY - cornerLen)
        ])
    }

    // MARK: - Vision Detection
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectRectanglesRequest { [weak self] request, _ in
            guard let self = self else { return }
            let rects = request.results as? [VNRectangleObservation] ?? []

            DispatchQueue.main.async {
                if let best = rects.first {
                    self.handleDetectedRect(best)
                } else {
                    self.handleNoDetection()
                }
            }
        }
        request.minimumAspectRatio = 1.2
        request.maximumAspectRatio = 2.0
        request.minimumSize = 0.15
        request.minimumConfidence = 0.6
        request.maximumObservations = 1

        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right).perform([request])
    }

    private func handleDetectedRect(_ rect: VNRectangleObservation) {
        guard let previewLayer = self.previewLayer else { return }

        // Convert Vision normalized coords to view coords
        let tl = previewLayer.layerPointConverted(fromCaptureDevicePoint: CGPoint(x: rect.topLeft.x, y: 1 - rect.topLeft.y))
        let tr = previewLayer.layerPointConverted(fromCaptureDevicePoint: CGPoint(x: rect.topRight.x, y: 1 - rect.topRight.y))
        let bl = previewLayer.layerPointConverted(fromCaptureDevicePoint: CGPoint(x: rect.bottomLeft.x, y: 1 - rect.bottomLeft.y))
        let br = previewLayer.layerPointConverted(fromCaptureDevicePoint: CGPoint(x: rect.bottomRight.x, y: 1 - rect.bottomRight.y))

        // Draw detected rect
        let path = UIBezierPath()
        path.move(to: tl)
        path.addLine(to: tr)
        path.addLine(to: br)
        path.addLine(to: bl)
        path.close()
        detectedRectLayer.path = path.cgPath

        // Check if the detected rect is within the card frame
        let detectedBounds = path.bounds
        let intersection = cardRect.intersection(detectedBounds)
        let overlapRatio = (intersection.width * intersection.height) / (detectedBounds.width * detectedBounds.height)
        let sizeRatio = (detectedBounds.width * detectedBounds.height) / (cardRect.width * cardRect.height)

        let isAligned = overlapRatio > 0.75 && sizeRatio > 0.35

        if isAligned {
            stableFrameCount += 1
            setCornerColor(.systemGreen)
            detectedRectLayer.strokeColor = UIColor.systemGreen.cgColor
            detectedRectLayer.fillColor = UIColor.systemGreen.withAlphaComponent(0.06).cgColor

            if stableFrameCount >= requiredStableFrames {
                statusLabel.text = "✓ Удостоверение найдено"
                statusLabel.textColor = .systemGreen
                hintLabel.text = "Нажмите кнопку для снимка"
            } else {
                statusLabel.text = "Держите ровно..."
                statusLabel.textColor = .systemYellow
                hintLabel.text = ""
            }
        } else {
            stableFrameCount = max(0, stableFrameCount - 2)
            setCornerColor(.systemYellow)
            detectedRectLayer.strokeColor = UIColor.systemYellow.cgColor
            detectedRectLayer.fillColor = UIColor.systemYellow.withAlphaComponent(0.04).cgColor
            statusLabel.text = "Поместите документ в рамку"
            statusLabel.textColor = .white
            hintLabel.text = ""
        }

        documentDetected = true
    }

    private func handleNoDetection() {
        stableFrameCount = max(0, stableFrameCount - 1)
        detectedRectLayer.path = nil
        documentDetected = false
        setCornerColor(.white)
        statusLabel.text = "Наведите на удостоверение"
        statusLabel.textColor = .white
        hintLabel.text = ""
    }

    private func setCornerColor(_ color: UIColor) {
        [topLeftCorner, topRightCorner, bottomLeftCorner, bottomRightCorner].forEach {
            $0.strokeColor = color.cgColor
        }
    }

    // MARK: - Capture
    @objc private func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)

        // Button animation
        UIView.animate(withDuration: 0.1, animations: {
            self.captureButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.captureButton.transform = .identity
            }
        }
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        captureSession.stopRunning()
        onCapture?(image)
    }
}

// MARK: - Restore Account View
struct RestoreAccountView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var chatService: ChatService
    @Environment(\.dismiss) var dismiss

    @State private var finderID = ""
    @State private var shake: CGFloat = 0
    @State private var restored = false
    @State private var error = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.cyan.opacity(0.15))
                        .frame(width: 90, height: 90)
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                        .font(.system(size: 42))
                        .foregroundStyle(.cyan)
                }

                VStack(spacing: 8) {
                    Text(localization.localized("Восстановить аккаунт", "Restore Account"))
                        .font(.title2.bold())

                    Text(localization.localized(
                        "Введите ваш Finder ID для восстановления доступа к аккаунту",
                        "Enter your Finder ID to restore access to your account"
                    ))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                }

                // Input
                VStack(spacing: 8) {
                    TextField("FID-XXXXXXXX", text: $finderID)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .multilineTextAlignment(.center)
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .padding(16)
                        .liquidGlassCard(cornerRadius: 14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(error ? Color.red.opacity(0.5) : Color.clear, lineWidth: 1.5)
                        )
                        .offset(x: shake)
                        .padding(.horizontal, 32)

                    if error {
                        Text(localization.localized(
                            "Finder ID не найден. Проверьте правильность.",
                            "Finder ID not found. Please check and try again."
                        ))
                        .font(.caption)
                        .foregroundStyle(.red)
                        .transition(.opacity)
                    }
                }

                // Info
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.cyan)
                    Text(localization.localized(
                        "Finder ID был показан при регистрации (формат: FID-XXXXXXXX)",
                        "Finder ID was shown during registration (format: FID-XXXXXXXX)"
                    ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 36)

                Spacer()

                Button {
                    attemptRestore()
                } label: {
                    Text(localization.localized("Восстановить", "Restore"))
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(finderID.isEmpty ? Color.gray : Color.cyan)
                        )
                }
                .disabled(finderID.isEmpty)
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
            }
            .navigationTitle(localization.localized("Восстановление", "Recovery"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(localization.cancel) { dismiss() }
                }
            }
            .alert(
                localization.localized("Аккаунт восстановлен!", "Account Restored!"),
                isPresented: $restored
            ) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text(localization.localized(
                    "Добро пожаловать обратно! Ваш аккаунт успешно восстановлен.",
                    "Welcome back! Your account has been successfully restored."
                ))
            }
        }
    }

    private func attemptRestore() {
        let trimmed = finderID.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if authService.restoreAccount(finderID: trimmed) {
            chatService.loadDemoData()
            restored = true
            error = false
        } else {
            error = true
            withAnimation(.default) { shake = 10 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.default) { shake = -10 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.default) { shake = 0 }
            }
            HapticService.error()
        }
    }
}
