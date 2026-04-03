import SwiftUI
import PhotosUI

struct GovLoginView: View {
    @EnvironmentObject var localization: LocalizationManager
    @Environment(\.dismiss) var dismiss

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var capturedImage: UIImage?
    @State private var isSubmitting = false
    @State private var isSubmitted = false
    @State private var showCamera = false

    var body: some View {
        NavigationStack {
            if isSubmitted {
                submittedView
            } else {
                formView
            }
        }
    }

    // MARK: - Form
    private var formView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                ZStack {
                    Circle()
                        .fill(Color.indigo.opacity(0.15))
                        .frame(width: 90, height: 90)
                    Image(systemName: "building.columns.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.indigo)
                }
                .padding(.top, 20)

                VStack(spacing: 8) {
                    Text(localization.localized("Вход для госслужащих", "Government Employee Login"))
                        .font(.title3.bold())

                    Text(localization.localized(
                        "Для подтверждения статуса прикрепите фото вашего служебного удостоверения",
                        "To verify your status, attach a photo of your official ID"
                    ))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                }

                // Photo capture area
                VStack(spacing: 12) {
                    Text(localization.localized("Фото удостоверения", "ID Photo"))
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)

                    if let image = capturedImage {
                        // Show captured image
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 220)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.green.opacity(0.5), lineWidth: 2)
                                )

                            Button {
                                capturedImage = nil
                                selectedPhoto = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(.white, .red)
                                    .shadow(radius: 3)
                            }
                            .padding(8)
                        }
                    } else {
                        // Document frame
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                                .foregroundStyle(.indigo.opacity(0.4))
                                .frame(height: 200)
                                .overlay(
                                    VStack(spacing: 16) {
                                        // Corner markers
                                        ZStack {
                                            // Top-left
                                            CornerMark()
                                                .position(x: 30, y: 30)
                                            // Top-right
                                            CornerMark()
                                                .rotationEffect(.degrees(90))
                                                .position(x: 270, y: 30)
                                            // Bottom-left
                                            CornerMark()
                                                .rotationEffect(.degrees(-90))
                                                .position(x: 30, y: 170)
                                            // Bottom-right
                                            CornerMark()
                                                .rotationEffect(.degrees(180))
                                                .position(x: 270, y: 170)

                                            VStack(spacing: 10) {
                                                Image(systemName: "doc.viewfinder")
                                                    .font(.system(size: 36))
                                                    .foregroundStyle(.indigo.opacity(0.5))

                                                Text(localization.localized(
                                                    "Разместите удостоверение\nв рамке",
                                                    "Place your ID\nwithin the frame"
                                                ))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .multilineTextAlignment(.center)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    }
                                )

                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.indigo.opacity(0.03))
                                .frame(height: 200)
                        }
                    }

                    // Buttons
                    HStack(spacing: 12) {
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            HStack(spacing: 6) {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 14))
                                Text(localization.localized("Галерея", "Gallery"))
                                    .font(.subheadline)
                            }
                            .foregroundStyle(.indigo)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .liquidGlassCard(cornerRadius: 12)
                        }

                        Button {
                            showCamera = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 14))
                                Text(localization.localized("Камера", "Camera"))
                                    .font(.subheadline)
                            }
                            .foregroundStyle(.indigo)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .liquidGlassCard(cornerRadius: 12)
                        }
                    }
                }
                .padding(.horizontal, 24)

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

                // Submit button
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
                            .fill(capturedImage == nil || isSubmitting ? Color.gray : Color.indigo)
                    )
                }
                .disabled(capturedImage == nil || isSubmitting)
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
        .onChange(of: selectedPhoto) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    capturedImage = image
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPickerView(image: $capturedImage)
                .ignoresSafeArea()
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

            // Status card
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
        // Simulate submission
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

// MARK: - Corner Mark
struct CornerMark: View {
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 20))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 20, y: 0))
        }
        .stroke(Color.indigo.opacity(0.6), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        .frame(width: 20, height: 20)
    }
}

// MARK: - Camera Picker
struct CameraPickerView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerView

        init(_ parent: CameraPickerView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
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
