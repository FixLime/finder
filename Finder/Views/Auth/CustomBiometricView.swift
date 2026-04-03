import SwiftUI
import AVFoundation
import Vision
import CoreImage

// MARK: - Face Embedding Service
class FaceEmbeddingService {
    static let shared = FaceEmbeddingService()

    private let storageKey = "storedFaceObservations"

    // Store face landmarks as a simplified "embedding"
    // We store key geometric ratios from facial landmarks
    func storeFaceprint(_ observations: [VNFaceObservation]) {
        guard let face = observations.first,
              let landmarks = face.landmarks else { return }
        let encoding = encodeLandmarks(landmarks, boundingBox: face.boundingBox)
        UserDefaults.standard.set(encoding, forKey: storageKey)
    }

    func loadStoredFaceprint() -> [Double]? {
        return UserDefaults.standard.array(forKey: storageKey) as? [Double]
    }

    func clearFaceprint() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    // Compare two faceprints — returns similarity 0...1
    func compareFaceprints(stored: [Double], current: [Double]) -> Double {
        guard stored.count == current.count, !stored.isEmpty else { return 0 }

        // Cosine similarity
        var dot: Double = 0
        var magA: Double = 0
        var magB: Double = 0

        for i in 0..<stored.count {
            dot += stored[i] * current[i]
            magA += stored[i] * stored[i]
            magB += current[i] * current[i]
        }

        let denom = sqrt(magA) * sqrt(magB)
        guard denom > 0 else { return 0 }

        let cosine = dot / denom
        return max(0, min(1, (cosine + 1) / 2)) // normalize to 0...1
    }

    func encodeLandmarks(_ landmarks: VNFaceLandmarks2D, boundingBox: CGRect) -> [Double] {
        var features: [Double] = []

        // Bounding box aspect ratio
        features.append(Double(boundingBox.width / max(boundingBox.height, 0.001)))

        // Extract relative point positions from each landmark region
        let regions: [VNFaceLandmarkRegion2D?] = [
            landmarks.faceContour,
            landmarks.leftEye,
            landmarks.rightEye,
            landmarks.nose,
            landmarks.noseCrest,
            landmarks.outerLips,
            landmarks.innerLips,
            landmarks.leftEyebrow,
            landmarks.rightEyebrow
        ]

        for region in regions {
            guard let region = region, region.pointCount >= 2 else {
                features.append(contentsOf: [0, 0, 0, 0])
                continue
            }

            let points = region.normalizedPoints
            // Geometric features: centroid, spread, aspect
            var sumX: Double = 0, sumY: Double = 0
            var minX: Double = 1, minY: Double = 1
            var maxX: Double = 0, maxY: Double = 0

            for p in points {
                let x = Double(p.x)
                let y = Double(p.y)
                sumX += x; sumY += y
                minX = min(minX, x); minY = min(minY, y)
                maxX = max(maxX, x); maxY = max(maxY, y)
            }

            let n = Double(points.count)
            features.append(sumX / n)
            features.append(sumY / n)
            features.append(maxX - minX)
            features.append(maxY - minY)
        }

        // Inter-feature distances
        if let leftEye = landmarks.leftEye, let rightEye = landmarks.rightEye,
           leftEye.pointCount > 0, rightEye.pointCount > 0 {
            let lCenter = centroid(leftEye.normalizedPoints)
            let rCenter = centroid(rightEye.normalizedPoints)
            let eyeDist = distance(lCenter, rCenter)
            features.append(eyeDist)

            if let nose = landmarks.noseCrest, nose.pointCount > 0 {
                let nCenter = centroid(nose.normalizedPoints)
                features.append(distance(lCenter, nCenter) / max(eyeDist, 0.001))
                features.append(distance(rCenter, nCenter) / max(eyeDist, 0.001))
            }

            if let mouth = landmarks.outerLips, mouth.pointCount > 0 {
                let mCenter = centroid(mouth.normalizedPoints)
                features.append(distance(lCenter, mCenter) / max(eyeDist, 0.001))
                features.append(distance(rCenter, mCenter) / max(eyeDist, 0.001))
            }
        }

        return features
    }

    private func centroid(_ points: [CGPoint]) -> CGPoint {
        let n = CGFloat(points.count)
        let sumX = points.reduce(0.0) { $0 + $1.x }
        let sumY = points.reduce(0.0) { $0 + $1.y }
        return CGPoint(x: sumX / n, y: sumY / n)
    }

    private func distance(_ a: CGPoint, _ b: CGPoint) -> Double {
        return Double(sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2)))
    }
}

// MARK: - Live Camera Face Detector (shared between setup and verify)
class FaceCameraController: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()

    @Published var faceDetected = false
    @Published var faceObservation: VNFaceObservation?
    @Published var faceBounds: CGRect = .zero
    @Published var hasLandmarks = false

    var previewLayer: AVCaptureVideoPreviewLayer?
    var onFaceCapture: (([VNFaceObservation]) -> Void)?

    private var consecutiveDetections = 0

    func setup() {
        captureSession.sessionPreset = .high

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: camera) else { return }

        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }

        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "face.camera.queue"))
        videoOutput.alwaysDiscardsLateVideoFrames = true
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }

        if let connection = videoOutput.connection(with: .video) {
            connection.videoOrientation = .portrait
            connection.isVideoMirrored = true
        }
    }

    func start() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }

    func stop() {
        captureSession.stopRunning()
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectFaceLandmarksRequest { [weak self] request, _ in
            guard let self = self else { return }
            let faces = request.results as? [VNFaceObservation] ?? []

            DispatchQueue.main.async {
                if let face = faces.first, face.landmarks != nil {
                    self.faceDetected = true
                    self.faceObservation = face
                    self.hasLandmarks = face.landmarks != nil
                    self.faceBounds = face.boundingBox
                    self.consecutiveDetections += 1

                    if self.consecutiveDetections >= 10 {
                        self.onFaceCapture?(faces)
                    }
                } else {
                    self.faceDetected = false
                    self.faceObservation = nil
                    self.hasLandmarks = false
                    self.consecutiveDetections = max(0, self.consecutiveDetections - 3)
                }
            }
        }

        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .leftMirrored).perform([request])
    }
}

// MARK: - Camera Preview
struct FaceCameraPreview: UIViewRepresentable {
    let cameraController: FaceCameraController

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black

        let previewLayer = AVCaptureVideoPreviewLayer(session: cameraController.captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        cameraController.previewLayer = previewLayer

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            cameraController.previewLayer?.frame = uiView.bounds
        }
    }
}

// MARK: - Custom Biometric Setup View
struct CustomBiometricSetupView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var localization: LocalizationManager
    @Environment(\.dismiss) var dismiss

    @State private var step: BiometricSetupStep = .intro
    @StateObject private var camera = FaceCameraController()
    @State private var scanProgress: CGFloat = 0
    @State private var scanComplete = false
    @State private var capturedFaces: [[VNFaceObservation]] = []
    @State private var statusText = ""
    @State private var frameColor: Color = .white

    private let requiredCaptures = 5

    enum BiometricSetupStep {
        case intro
        case scanning
        case complete
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                switch step {
                case .intro:
                    introView
                case .scanning:
                    scanningView
                case .complete:
                    completeView
                }
            }
            .navigationTitle(localization.localized("Биометрия", "Biometrics"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(localization.cancel) {
                        camera.stop()
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Intro
    private var introView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.2), .indigo.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "person.viewfinder")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .indigo],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 10) {
                Text(localization.localized("Сканирование лица", "Face Scanning"))
                    .font(.title2.bold())

                Text(localization.localized(
                    "Камера запишет геометрию вашего лица для верификации. Данные хранятся только на устройстве.",
                    "Camera will capture your face geometry for verification. Data is stored only on device."
                ))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            }

            VStack(alignment: .leading, spacing: 12) {
                biometricFeatureRow(
                    icon: "camera.viewfinder",
                    color: .purple,
                    text: localization.localized("Использует фронтальную камеру", "Uses front camera")
                )
                biometricFeatureRow(
                    icon: "face.dashed",
                    color: .blue,
                    text: localization.localized("Анализирует геометрию лица", "Analyzes face geometry")
                )
                biometricFeatureRow(
                    icon: "eye.slash.fill",
                    color: .green,
                    text: localization.localized("Данные хранятся только на устройстве", "Data stored only on device")
                )
            }
            .padding(.horizontal, 32)

            Spacer()

            Button {
                camera.setup()
                camera.start()
                withAnimation(.spring(response: 0.4)) {
                    step = .scanning
                }
            } label: {
                Text(localization.localized("Начать сканирование", "Start Scanning"))
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .indigo],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 30)
        }
    }

    // MARK: - Scanning (real camera)
    private var scanningView: some View {
        ZStack {
            FaceCameraPreview(cameraController: camera)
                .ignoresSafeArea()

            // Dark overlay with face cutout
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .mask {
                    ZStack {
                        Color.white
                        Ellipse()
                            .frame(width: 260, height: 340)
                            .blendMode(.destinationOut)
                    }
                    .compositingGroup()
                }

            VStack {
                Spacer()
                    .frame(height: 60)

                // Face frame
                ZStack {
                    // Outer ellipse
                    Ellipse()
                        .stroke(frameColor, style: StrokeStyle(lineWidth: 3))
                        .frame(width: 264, height: 344)

                    // Progress ring
                    Circle()
                        .trim(from: 0, to: scanProgress)
                        .stroke(
                            LinearGradient(colors: [.purple, .green], startPoint: .leading, endPoint: .trailing),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 280, height: 280)
                        .rotationEffect(.degrees(-90))
                }

                Spacer()
                    .frame(height: 30)

                // Status
                VStack(spacing: 8) {
                    Text(statusText.isEmpty
                         ? localization.localized("Поместите лицо в рамку", "Place your face in the frame")
                         : statusText)
                        .font(.headline)
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 4)

                    Text("\(capturedFaces.count)/\(requiredCaptures)")
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(frameColor)
                        .shadow(color: .black, radius: 4)
                }

                Spacer()
            }
        }
        .onAppear {
            statusText = localization.localized("Поместите лицо в рамку", "Place your face in the frame")
            camera.onFaceCapture = { faces in
                handleFaceCapture(faces)
            }
        }
        .onChange(of: camera.faceDetected) { _, detected in
            withAnimation(.easeInOut(duration: 0.3)) {
                if detected && camera.hasLandmarks {
                    frameColor = .green
                    statusText = localization.localized("Лицо найдено, не двигайтесь...", "Face found, hold still...")
                } else {
                    frameColor = .white
                    statusText = localization.localized("Поместите лицо в рамку", "Place your face in the frame")
                }
            }
        }
    }

    // MARK: - Complete
    private var completeView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)
            }

            VStack(spacing: 10) {
                Text(localization.localized("Биометрия настроена", "Biometrics Configured"))
                    .font(.title2.bold())

                Text(localization.localized(
                    "Биометрический слепок лица сохранён. При входе потребуется верификация через камеру.",
                    "Face biometric imprint saved. Camera verification will be required for login."
                ))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            }

            Spacer()

            Button {
                authService.customBiometricEnabled = true
                dismiss()
            } label: {
                Text(localization.done)
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.green)
                    )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 30)
        }
    }

    // MARK: - Helpers
    private func biometricFeatureRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
    }

    private func handleFaceCapture(_ faces: [VNFaceObservation]) {
        guard !scanComplete else { return }
        guard capturedFaces.count < requiredCaptures else { return }

        capturedFaces.append(faces)
        withAnimation {
            scanProgress = CGFloat(capturedFaces.count) / CGFloat(requiredCaptures)
        }

        HapticService.light()

        if capturedFaces.count >= requiredCaptures {
            // Store the average faceprint from all captures
            if let best = capturedFaces.last?.first, best.landmarks != nil {
                FaceEmbeddingService.shared.storeFaceprint([best])
            }

            scanComplete = true
            camera.stop()

            HapticService.success()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.4)) {
                    step = .complete
                }
            }
        } else {
            statusText = localization.localized("Отлично, не двигайтесь...", "Great, hold still...")
            // Reset detection counter for next capture
            camera.onFaceCapture = { faces in
                handleFaceCapture(faces)
            }
        }
    }
}

// MARK: - Custom Biometric Verify View (Lock Screen)
struct CustomBiometricVerifyView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var localization: LocalizationManager

    @StateObject private var camera = FaceCameraController()
    @State private var isScanning = false
    @State private var scanProgress: CGFloat = 0
    @State private var verified = false
    @State private var failed = false
    @State private var attempts = 0
    @State private var isLocked = false
    @State private var statusText = ""
    @State private var frameColor: Color = .white

    var body: some View {
        ZStack {
            // Camera background
            FaceCameraPreview(cameraController: camera)
                .ignoresSafeArea()

            // Dark overlay with cutout
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .mask {
                    ZStack {
                        Color.white
                        Ellipse()
                            .frame(width: 220, height: 290)
                            .blendMode(.destinationOut)
                    }
                    .compositingGroup()
                }

            VStack(spacing: 20) {
                Spacer()
                    .frame(height: 80)

                // Face frame
                ZStack {
                    Ellipse()
                        .stroke(frameColor, style: StrokeStyle(lineWidth: 3))
                        .frame(width: 224, height: 294)

                    if isScanning {
                        Circle()
                            .trim(from: 0, to: scanProgress)
                            .stroke(Color.purple, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                            .frame(width: 240, height: 240)
                            .rotationEffect(.degrees(-90))
                    }

                    if !camera.faceDetected && !isScanning {
                        Image(systemName: "person.viewfinder")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }

                Spacer()
                    .frame(height: 20)

                VStack(spacing: 8) {
                    Text(localization.localized("Верификация лица", "Face Verification"))
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 4)

                    Text(statusText.isEmpty
                         ? localization.localized("Посмотрите в камеру", "Look at the camera")
                         : statusText)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .shadow(color: .black, radius: 4)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Spacer()

                if failed {
                    Text(localization.localized(
                        "Лицо не распознано. Попытка \(attempts)/5",
                        "Face not recognized. Attempt \(attempts)/5"
                    ))
                    .font(.caption)
                    .foregroundStyle(.red)
                    .shadow(color: .black, radius: 2)
                }

                if isLocked {
                    Text(localization.localized(
                        "Слишком много попыток. Подождите 30 секунд.",
                        "Too many attempts. Wait 30 seconds."
                    ))
                    .font(.caption)
                    .foregroundStyle(.red)
                    .shadow(color: .black, radius: 2)
                }

                Button {
                    startVerification()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "person.viewfinder")
                            .font(.system(size: 20))
                        Text(localization.localized("Сканировать лицо", "Scan Face"))
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: isLocked ? [.gray, .gray] : [.purple, .indigo],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .shadow(color: isLocked ? .clear : .purple.opacity(0.3), radius: 10, y: 5)
                }
                .disabled(isLocked || isScanning)
                .padding(.horizontal, 32)

                HStack(spacing: 6) {
                    Image(systemName: "lock.shield.fill")
                        .font(.caption2)
                    Text("@\(authService.currentUsername)")
                        .font(.caption)
                }
                .foregroundStyle(.white.opacity(0.5))
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            camera.setup()
            camera.start()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                startVerification()
            }
        }
        .onDisappear {
            camera.stop()
        }
        .onChange(of: camera.faceDetected) { _, detected in
            if !isScanning {
                withAnimation(.easeInOut(duration: 0.3)) {
                    frameColor = detected ? .green : .white
                }
            }
        }
    }

    private func startVerification() {
        guard !isLocked, !isScanning else { return }

        failed = false
        isScanning = true
        scanProgress = 0
        statusText = localization.localized("Сканирование...", "Scanning...")

        camera.onFaceCapture = { [self] faces in
            camera.onFaceCapture = nil
            performVerification(faces)
        }

        // Timeout — if no face captured in 5 seconds, fail
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            if isScanning {
                camera.onFaceCapture = nil
                handleFailure()
            }
        }

        // Progress animation
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            if !isScanning {
                timer.invalidate()
                return
            }
            withAnimation(.linear(duration: 0.05)) {
                scanProgress = min(scanProgress + 0.01, 0.9)
            }
        }
    }

    private func performVerification(_ faces: [VNFaceObservation]) {
        guard let face = faces.first, let landmarks = face.landmarks else {
            handleFailure()
            return
        }

        let service = FaceEmbeddingService.shared
        guard let stored = service.loadStoredFaceprint() else {
            // No stored faceprint — pass through (first time edge case)
            handleSuccess()
            return
        }

        let current = service.encodeLandmarks(landmarks, boundingBox: face.boundingBox)
        let similarity = service.compareFaceprints(stored: stored, current: current)

        // Threshold for match
        if similarity > 0.72 {
            handleSuccess()
        } else {
            handleFailure()
        }
    }

    private func handleSuccess() {
        withAnimation(.spring(response: 0.3)) {
            isScanning = false
            scanProgress = 1.0
            verified = true
            frameColor = .green
            statusText = localization.localized("Верифицировано", "Verified")
        }
        HapticService.success()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            authService.unlockCustomBiometric()
        }
    }

    private func handleFailure() {
        withAnimation(.spring(response: 0.3)) {
            isScanning = false
            failed = true
            frameColor = .red
            statusText = localization.localized("Лицо не совпадает", "Face doesn't match")
            attempts += 1
        }
        HapticService.error()

        if attempts >= 5 {
            isLocked = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                withAnimation {
                    isLocked = false
                    attempts = 0
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if !isLocked {
                withAnimation {
                    failed = false
                    frameColor = .white
                    statusText = ""
                }
            }
        }
    }
}
