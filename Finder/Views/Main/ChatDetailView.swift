import SwiftUI
import PhotosUI
import AVFoundation
import UIKit

struct ChatDetailView: View {
    @Binding var chat: Chat
    @EnvironmentObject var chatService: ChatService
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localization: LocalizationManager

    @State private var messageText = ""
    @State private var showProfile = false
    @State private var replyingTo: Message?
    @State private var showAttachSheet = false
    @State private var showFilePicker = false
    @State private var showActiveCall = false
    @State private var showVideoRecorder = false
    @State private var showScreenshotAlert = false
    @State private var selectedPhoto: PhotosPickerItem?
    @StateObject private var audioRecorder = AudioRecorderService()
    @StateObject private var audioPlayer = AudioPlayerService()

    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 4) {
                        // Encryption banner
                        VStack(spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 10))
                                Text(localization.localized(
                                    "Сообщения защищены сквозным шифрованием.",
                                    "Messages are end-to-end encrypted."
                                ))
                                .font(.system(size: 11))
                            }
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 32)
                        .padding(.vertical, 10)

                        ForEach(chat.messages.sorted(by: { $0.timestamp < $1.timestamp })) { message in
                            if message.messageType == .voice {
                                VoiceMessageBubble(
                                    message: message,
                                    audioPlayer: audioPlayer,
                                    onReply: { replyingTo = message },
                                    onDelete: { deleteMessage(message) }
                                )
                                .id(message.id)
                            } else {
                                MessageBubble(
                                    message: message,
                                    chat: chat,
                                    onReply: { replyingTo = message },
                                    onDelete: { deleteMessage(message) }
                                )
                                .id(message.id)
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                }
                .onChange(of: chat.messages.count) { _, _ in
                    withAnimation(.spring(response: 0.3)) {
                        proxy.scrollTo(chat.messages.sorted(by: { $0.timestamp < $1.timestamp }).last?.id, anchor: .bottom)
                    }
                }
                .onAppear {
                    proxy.scrollTo(chat.messages.sorted(by: { $0.timestamp < $1.timestamp }).last?.id, anchor: .bottom)
                }
            }

            // Reply bar
            if let reply = replyingTo {
                HStack {
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: 3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(localization.localized("Ответ", "Reply"))
                            .font(.caption.bold())
                            .foregroundStyle(.blue)
                        Text(reply.text)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Button {
                        withAnimation { replyingTo = nil }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.secondarySystemBackground))
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Voice recording overlay
            if audioRecorder.isRecording {
                voiceRecordingBar
            } else {
                // Input bar
                HStack(spacing: 8) {
                    // Attach button
                    Button {
                        showAttachSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.blue)
                    }

                    TextField(localization.typeMessage, text: $messageText, axis: .vertical)
                        .lineLimit(1...5)
                        .liquidGlassTextField()

                    if messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        // Voice message button
                        Button {
                            audioRecorder.startRecording()
                        } label: {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(.blue)
                        }
                    } else {
                        // Send button
                        Button {
                            sendMessage()
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 34))
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
            }
        }
        .navigationTitle(chat.isNotes ? localization.notes : chat.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if !chat.isNotes && !chat.isSupport && !chat.isGroup {
                    // Voice call
                    Button {
                        if let user = chat.otherUser {
                            CallManager.shared.startCall(user: user, chatId: chat.id, isVideo: false)
                            showActiveCall = true
                        }
                    } label: {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.blue)
                    }

                    // Video call
                    Button {
                        if let user = chat.otherUser {
                            CallManager.shared.startCall(user: user, chatId: chat.id, isVideo: true)
                            showActiveCall = true
                        }
                    } label: {
                        Image(systemName: "video.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.blue)
                    }
                }

                if !chat.isNotes {
                    Button {
                        showProfile = true
                    } label: {
                        AvatarView(
                            user: chat.otherUser,
                            isGroup: chat.isGroup,
                            size: 32
                        )
                    }
                }
            }
        }
        .sheet(isPresented: $showProfile) {
            if let user = chat.participants.first {
                UserProfileView(user: user)
                    .environmentObject(themeManager)
                    .environmentObject(localization)
            }
        }
        .fullScreenCover(isPresented: $showActiveCall) {
            ActiveCallView()
                .environmentObject(localization)
        }
        .sheet(isPresented: $showAttachSheet) {
            AttachMenuSheet(
                onFilePicker: {
                    showAttachSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showFilePicker = true
                    }
                },
                onPhotoPicked: { data, filename in
                    showAttachSheet = false
                    sendPhotoData(data, filename: filename)
                },
                onVideoCircle: {
                    showAttachSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showVideoRecorder = true
                    }
                }
            )
            .presentationDetents([.height(280)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showFilePicker) {
            FilePickerView { url in
                sendFile(url: url)
            }
        }
        .fullScreenCover(isPresented: $showVideoRecorder) {
            VideoCircleRecorderView { url in
                sendVideoCircle(url: url)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification)) { _ in
            handleScreenshot()
        }
        .alert(
            localization.localized("Ой-ой", "Oops"),
            isPresented: $showScreenshotAlert
        ) {
            Button(localization.localized("Ладно-ладно", "Okay okay"), role: .cancel) { }
        } message: {
            Text(localization.localized(
                "Привет! Прости, но собеседник запретил скриншоты. Если хочешь конфиденциальности — соблюдай её и сам, хе-хе",
                "Hey! Sorry, but the other person doesn't allow screenshots. If you want privacy — respect it yourself too, hehe"
            ))
        }
    }

    // MARK: - Voice Recording Bar
    private var voiceRecordingBar: some View {
        HStack(spacing: 12) {
            Button {
                audioRecorder.cancelRecording()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.red)
            }

            HStack(spacing: 2) {
                ForEach(Array(audioRecorder.audioLevels.enumerated()), id: \.offset) { _, level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.red)
                        .frame(width: 3, height: max(4, level * 30))
                }
            }
            .frame(height: 30)

            Spacer()

            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
            Text(audioRecorder.formattedTime)
                .font(.system(size: 15, design: .monospaced))
                .foregroundStyle(.primary)

            Button {
                if let url = audioRecorder.stopRecording() {
                    sendVoiceMessage(url: url)
                }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(.blue)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    // MARK: - Actions

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        HapticService.impact(.light)
        messageText = ""
        replyingTo = nil
        chatService.sendMessage(to: chat.id, text: text)
    }

    private func handleScreenshot() {
        guard !chat.isNotes else { return }

        HapticService.warning()
        showScreenshotAlert = true

        // Add system message to chat notifying about screenshot
        let currentName = AuthService.shared.currentDisplayName
        let systemText = localization.localized(
            "\(currentName) сделал(а) скриншот переписки",
            "\(currentName) took a screenshot of the chat"
        )
        let msg = Message.system(systemText, chatId: chat.id)
        if let index = chatService.chats.firstIndex(where: { $0.id == chat.id }) {
            chatService.chats[index].messages.append(msg)
        }
    }

    private func sendVoiceMessage(url: URL) {
        HapticService.impact(.light)
        let msgId = UUID()
        // Store voice file URL for playback
        AudioFileStore.shared.store(url: url, for: msgId)

        let duration = audioDuration(url: url)
        let durationText = formatDuration(duration)

        let message = Message(
            id: msgId,
            senderId: AuthService.shared.currentUserId,
            chatId: chat.id,
            text: durationText,
            timestamp: Date(),
            isRead: false,
            isDelivered: true,
            isEdited: false,
            replyToId: nil,
            messageType: .voice,
            isPhantom: false,
            selfDestructTime: nil,
            isForwardable: true
        )
        if let index = chatService.chats.firstIndex(where: { $0.id == chat.id }) {
            chatService.chats[index].messages.append(message)
        }

        if chatService.isServerMode {
            Task {
                do {
                    let data = try Data(contentsOf: url)
                    let result = try await NetworkService.shared.uploadFile(data: data, filename: url.lastPathComponent, mimeType: "audio/m4a")
                    _ = try await NetworkService.shared.sendMessage(chatId: chat.id.uuidString, text: result.url, messageType: "voice")
                } catch {
                    print("Voice upload failed: \(error)")
                }
            }
        }
    }

    private func sendPhotoData(_ data: Data, filename: String) {
        HapticService.impact(.light)
        let message = Message(
            id: UUID(),
            senderId: AuthService.shared.currentUserId,
            chatId: chat.id,
            text: "📷 " + localization.localized("Фото", "Photo"),
            timestamp: Date(),
            isRead: false,
            isDelivered: true,
            isEdited: false,
            replyToId: nil,
            messageType: .image,
            isPhantom: false,
            selfDestructTime: nil,
            isForwardable: true
        )
        if let index = chatService.chats.firstIndex(where: { $0.id == chat.id }) {
            chatService.chats[index].messages.append(message)
        }

        if chatService.isServerMode {
            Task {
                do {
                    let result = try await NetworkService.shared.uploadFile(data: data, filename: filename, mimeType: "image/jpeg")
                    _ = try await NetworkService.shared.sendMessage(chatId: chat.id.uuidString, text: result.url, messageType: "image")
                } catch {
                    print("Photo upload failed: \(error)")
                }
            }
        }
    }

    private func sendVideoCircle(url: URL) {
        HapticService.impact(.light)
        let message = Message(
            id: UUID(),
            senderId: AuthService.shared.currentUserId,
            chatId: chat.id,
            text: "⭕ " + localization.localized("Кружок", "Video circle"),
            timestamp: Date(),
            isRead: false,
            isDelivered: true,
            isEdited: false,
            replyToId: nil,
            messageType: .voice,
            isPhantom: false,
            selfDestructTime: nil,
            isForwardable: true
        )
        if let index = chatService.chats.firstIndex(where: { $0.id == chat.id }) {
            chatService.chats[index].messages.append(message)
        }

        if chatService.isServerMode {
            Task {
                do {
                    let data = try Data(contentsOf: url)
                    let result = try await NetworkService.shared.uploadFile(data: data, filename: "circle.mp4", mimeType: "video/mp4")
                    _ = try await NetworkService.shared.sendMessage(chatId: chat.id.uuidString, text: result.url, messageType: "voice")
                } catch {
                    print("Video circle upload failed: \(error)")
                }
            }
        }
    }

    private func sendFile(url: URL) {
        HapticService.impact(.light)
        let message = Message(
            id: UUID(),
            senderId: AuthService.shared.currentUserId,
            chatId: chat.id,
            text: "📎 " + url.lastPathComponent,
            timestamp: Date(),
            isRead: false,
            isDelivered: true,
            isEdited: false,
            replyToId: nil,
            messageType: .text,
            isPhantom: false,
            selfDestructTime: nil,
            isForwardable: true
        )
        if let index = chatService.chats.firstIndex(where: { $0.id == chat.id }) {
            chatService.chats[index].messages.append(message)
        }

        if chatService.isServerMode {
            Task {
                do {
                    _ = url.startAccessingSecurityScopedResource()
                    let data = try Data(contentsOf: url)
                    url.stopAccessingSecurityScopedResource()
                    let result = try await NetworkService.shared.uploadFile(data: data, filename: url.lastPathComponent, mimeType: "application/octet-stream")
                    _ = try await NetworkService.shared.sendMessage(chatId: chat.id.uuidString, text: result.url, messageType: "text")
                } catch {
                    print("File upload failed: \(error)")
                }
            }
        }
    }

    private func deleteMessage(_ message: Message) {
        guard let chatIndex = chatService.chats.firstIndex(where: { $0.id == chat.id }) else { return }
        withAnimation(.spring(response: 0.3)) {
            chatService.chats[chatIndex].messages.removeAll { $0.id == message.id }
        }
    }

    private func audioDuration(url: URL) -> TimeInterval {
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return 0 }
        return player.duration
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Audio File Store (maps message IDs to local file URLs)
class AudioFileStore {
    static let shared = AudioFileStore()
    private var files: [UUID: URL] = [:]

    func store(url: URL, for messageId: UUID) {
        files[messageId] = url
    }

    func url(for messageId: UUID) -> URL? {
        files[messageId]
    }
}

// MARK: - Voice Message Bubble
struct VoiceMessageBubble: View {
    let message: Message
    @ObservedObject var audioPlayer: AudioPlayerService
    let onReply: () -> Void
    let onDelete: () -> Void

    var isPlaying: Bool {
        audioPlayer.isPlaying && audioPlayer.playingMessageId == message.id
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            if message.isFromCurrentUser { Spacer(minLength: 60) }

            HStack(spacing: 10) {
                // Play/Stop button
                Button {
                    if isPlaying {
                        audioPlayer.stop()
                    } else if let url = AudioFileStore.shared.url(for: message.id) {
                        audioPlayer.play(url: url, messageId: message.id)
                    }
                } label: {
                    Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(message.isFromCurrentUser ? .white : .blue)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(message.isFromCurrentUser ? .white.opacity(0.2) : .blue.opacity(0.15))
                        )
                }

                // Waveform placeholder
                HStack(spacing: 2) {
                    ForEach(0..<20, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(message.isFromCurrentUser ? .white.opacity(0.7) : .blue.opacity(0.5))
                            .frame(width: 2, height: CGFloat.random(in: 4...16))
                    }
                }

                Text(message.text)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(message.isFromCurrentUser ? .white.opacity(0.8) : .secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background {
                if message.isFromCurrentUser {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(LinearGradient(colors: [.blue, .blue.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing))
                } else {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.ultraThinMaterial)
                }
            }
            .contextMenu {
                Button { onReply() } label: { Label("Reply", systemImage: "arrowshape.turn.up.left") }
                Divider()
                Button(role: .destructive) { onDelete() } label: { Label("Delete", systemImage: "trash") }
            }

            if !message.isFromCurrentUser { Spacer(minLength: 60) }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
    }
}

// MARK: - Attach Menu Sheet
struct AttachMenuSheet: View {
    let onFilePicker: () -> Void
    let onPhotoPicked: (Data, String) -> Void
    let onVideoCircle: () -> Void

    @State private var selectedItem: PhotosPickerItem?
    @EnvironmentObject var localization: LocalizationManager

    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 20)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                // Photo
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    AttachMenuItem(
                        icon: "photo.fill",
                        title: localization.localized("Фото", "Photo"),
                        color: .purple
                    )
                }

                // File
                Button(action: onFilePicker) {
                    AttachMenuItem(
                        icon: "doc.fill",
                        title: localization.localized("Файл", "File"),
                        color: .blue
                    )
                }

                // Video circle
                Button(action: onVideoCircle) {
                    AttachMenuItem(
                        icon: "record.circle",
                        title: localization.localized("Кружок", "Circle"),
                        color: .red
                    )
                }
            }
            .padding(.horizontal, 30)

            Spacer()
        }
        .onChange(of: selectedItem) { _, newItem in
            guard let newItem = newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        onPhotoPicked(data, "photo_\(UUID().uuidString.prefix(8)).jpg")
                    }
                }
            }
        }
    }
}

struct AttachMenuItem: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 60, height: 60)
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(color)
            }
            Text(title)
                .font(.caption)
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Video Circle Recorder
struct VideoCircleRecorderView: View {
    let onRecorded: (URL) -> Void
    @Environment(\.dismiss) var dismiss
    @StateObject private var recorder = VideoRecorderService()
    @State private var isRecording = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                Spacer()

                // Circle preview area
                ZStack {
                    Circle()
                        .stroke(isRecording ? Color.red : Color.white.opacity(0.3), lineWidth: 4)
                        .frame(width: 250, height: 250)

                    if isRecording {
                        Text(recorder.formattedTime)
                            .font(.system(size: 40, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "record.circle")
                                .font(.system(size: 50))
                                .foregroundStyle(.white.opacity(0.5))
                            Text("Tap to record")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                }

                Spacer()

                HStack(spacing: 60) {
                    // Cancel
                    Button {
                        recorder.cleanup()
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .foregroundStyle(.white)
                    }

                    // Record / Stop
                    Button {
                        if isRecording {
                            recorder.stopTimer()
                            isRecording = false
                            if let url = recorder.getRecordingURL() {
                                onRecorded(url)
                            }
                            dismiss()
                        } else {
                            _ = recorder.prepareRecordingURL()
                            recorder.startTimer()
                            isRecording = true
                            // Simulate recording with timer
                            DispatchQueue.main.asyncAfter(deadline: .now() + recorder.maxDuration) {
                                if isRecording {
                                    recorder.stopTimer()
                                    isRecording = false
                                    if let url = recorder.getRecordingURL() {
                                        onRecorded(url)
                                    }
                                    dismiss()
                                }
                            }
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .stroke(Color.white, lineWidth: 4)
                                .frame(width: 80, height: 80)
                            Circle()
                                .fill(isRecording ? Color.red : Color.red.opacity(0.8))
                                .frame(width: isRecording ? 30 : 68, height: isRecording ? 30 : 68)
                                .clipShape(RoundedRectangle(cornerRadius: isRecording ? 6 : 34))
                        }
                    }
                }
                .padding(.bottom, 60)
            }
        }
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: Message
    let chat: Chat
    let onReply: () -> Void
    let onDelete: () -> Void

    @EnvironmentObject var localization: LocalizationManager
    @State private var showTime = false

    var body: some View {
        if message.messageType == .system {
            systemMessage
        } else {
            chatMessage
        }
    }

    private var systemMessage: some View {
        Text(message.text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.vertical, 4)
            .padding(.horizontal, 12)
            .background(Capsule().fill(.ultraThinMaterial))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
    }

    private var chatMessage: some View {
        HStack(alignment: .bottom, spacing: 6) {
            if message.isFromCurrentUser { Spacer(minLength: 60) }

            VStack(alignment: message.isFromCurrentUser ? .trailing : .leading, spacing: 2) {
                if chat.isGroup && !message.isFromCurrentUser {
                    if let sender = chat.participants.first(where: { $0.id == message.senderId }) {
                        HStack(spacing: 3) {
                            if sender.isUntrusted || AdminService.shared.isUntrusted(sender.username) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.orange)
                            }
                            Text(sender.displayName)
                                .font(.caption2.bold())
                                .foregroundStyle(.blue)
                        }
                    }
                }

                Text(message.text)
                    .font(.body)
                    .foregroundColor(message.isFromCurrentUser ? .white : .primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background {
                        if message.isFromCurrentUser {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue, Color.blue.opacity(0.85)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        } else {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(Color.white.opacity(0.1))
                                }
                                .overlay {
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                                }
                        }
                    }
                    .contextMenu {
                        Button { onReply() } label: {
                            Label(localization.localized("Ответить", "Reply"), systemImage: "arrowshape.turn.up.left")
                        }
                        Button {
                            UIPasteboard.general.string = message.text
                        } label: {
                            Label(localization.localized("Копировать", "Copy"), systemImage: "doc.on.doc")
                        }
                        if message.isForwardable {
                            Button {} label: {
                                Label(localization.localized("Переслать", "Forward"), systemImage: "arrowshape.turn.up.right")
                            }
                        }
                        Divider()
                        Button(role: .destructive) { onDelete() } label: {
                            Label(localization.localized("Удалить", "Delete"), systemImage: "trash")
                        }
                    } preview: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(message.text)
                                .font(.body)
                                .padding(16)
                            HStack(spacing: 4) {
                                Text(formatMessageTime(message.timestamp))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if message.isFromCurrentUser {
                                    Image(systemName: message.isRead ? "checkmark.circle.fill" : "checkmark.circle")
                                        .font(.caption)
                                        .foregroundStyle(message.isRead ? .blue : .secondary)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 12)
                        }
                        .frame(width: 280)
                    }

                if showTime {
                    HStack(spacing: 4) {
                        Text(formatMessageTime(message.timestamp))
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        if message.isFromCurrentUser {
                            Image(systemName: message.isRead ? "checkmark.circle.fill" : "checkmark.circle")
                                .font(.system(size: 11))
                                .foregroundStyle(message.isRead ? .blue : .secondary)
                        }
                        if message.isPhantom {
                            Image(systemName: "timer")
                                .font(.system(size: 10))
                                .foregroundStyle(.orange)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .onTapGesture {
                withAnimation(.spring(response: 0.3)) {
                    showTime.toggle()
                }
            }

            if !message.isFromCurrentUser { Spacer(minLength: 60) }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
    }

    private func formatMessageTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
