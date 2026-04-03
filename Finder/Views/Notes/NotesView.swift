import SwiftUI

struct NotesView: View {
    @EnvironmentObject var chatService: ChatService
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localization: LocalizationManager

    @State private var showAddNote = false
    @State private var newNoteText = ""
    @State private var selectedCategory: Note.NoteCategory = .general
    @State private var filterCategory: Note.NoteCategory?
    @State private var appear = false

    var filteredNotes: [Note] {
        let sorted = chatService.notes.sorted { a, b in
            if a.isPinned != b.isPinned { return a.isPinned }
            return a.timestamp > b.timestamp
        }
        if let filter = filterCategory {
            return sorted.filter { $0.category == filter }
        }
        return sorted
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    // Category filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            CategoryChip(
                                title: localization.localized("Все", "All"),
                                isSelected: filterCategory == nil
                            ) {
                                withAnimation(.spring(response: 0.3)) { filterCategory = nil }
                            }

                            ForEach(Note.NoteCategory.allCases, id: \.self) { category in
                                CategoryChip(
                                    title: localization.isRussian ? category.rawValue : category.englishName,
                                    isSelected: filterCategory == category
                                ) {
                                    withAnimation(.spring(response: 0.3)) {
                                        filterCategory = filterCategory == category ? nil : category
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }

                    if filteredNotes.isEmpty {
                        VStack(spacing: 16) {
                            Spacer()
                            Image(systemName: "note.text")
                                .font(.system(size: 50))
                                .foregroundStyle(.secondary.opacity(0.5))
                            Text(localization.localized("Нет заметок", "No notes"))
                                .font(.title3)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(Array(filteredNotes.enumerated()), id: \.element.id) { index, note in
                                    NoteCard(note: note, onDelete: {
                                        withAnimation(.spring(response: 0.3)) {
                                            chatService.deleteNote(note.id)
                                        }
                                    }, onTogglePin: {
                                        if let idx = chatService.notes.firstIndex(where: { $0.id == note.id }) {
                                            withAnimation(.spring(response: 0.3)) {
                                                chatService.notes[idx].isPinned.toggle()
                                            }
                                        }
                                    })
                                    .opacity(appear ? 1 : 0)
                                    .offset(y: appear ? 0 : 20)
                                    .animation(
                                        .spring(response: 0.4).delay(Double(index) * 0.05),
                                        value: appear
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
            .navigationTitle(localization.notes)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddNote = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.blue)
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    // Verified badge for Notes
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.blue)
                }
            }
            .sheet(isPresented: $showAddNote) {
                addNoteSheet
            }
        }
        .onAppear {
            withAnimation { appear = true }
        }
    }

    private var addNoteSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Category picker
                Picker(localization.localized("Категория", "Category"), selection: $selectedCategory) {
                    ForEach(Note.NoteCategory.allCases, id: \.self) { category in
                        Text(localization.isRussian ? category.rawValue : category.englishName)
                            .tag(category)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                TextEditor(text: $newNoteText)
                    .padding(12)
                    .liquidGlassCard(cornerRadius: 16)
                    .frame(minHeight: 150)
                    .padding(.horizontal)

                Spacer()
            }
            .padding(.top)
            .navigationTitle(localization.localized("Новая заметка", "New Note"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(localization.cancel) { showAddNote = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(localization.save) {
                        if !newNoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            chatService.addNote(newNoteText, category: selectedCategory)
                            newNoteText = ""
                            showAddNote = false
                        }
                    }
                    .font(.headline)
                    .disabled(newNoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Note Card
struct NoteCard: View {
    let note: Note
    let onDelete: () -> Void
    let onTogglePin: () -> Void
    @EnvironmentObject var localization: LocalizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: categoryIconName)
                    .font(.caption)
                Text(localization.isRussian ? note.category.rawValue : note.category.englishName)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.orange)
                }

                Spacer()

                Text(formatNoteDate(note.timestamp))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text(note.text)
                .font(.body)
                .lineLimit(5)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlassCard(cornerRadius: 16)
        .contextMenu {
            Button {
                onTogglePin()
            } label: {
                Label(
                    note.isPinned
                        ? localization.localized("Открепить", "Unpin")
                        : localization.localized("Закрепить", "Pin"),
                    systemImage: note.isPinned ? "pin.slash" : "pin"
                )
            }

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label(localization.delete, systemImage: "trash")
            }
        }
    }

    private var categoryIconName: String {
        switch note.category {
        case .general: return "doc.text"
        case .important: return "bolt.fill"
        case .ideas: return "lightbulb.fill"
        case .links: return "link"
        case .passwords: return "lock.fill"
        }
    }

    private func formatNoteDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: localization.isRussian ? "ru" : "en")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Category Chip
struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background {
                    if isSelected {
                        Capsule().fill(Color.blue)
                    } else {
                        Capsule().fill(.ultraThinMaterial)
                            .overlay {
                                Capsule().stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                            }
                    }
                }
        }
    }
}

// MARK: - Note Category English Names
extension Note.NoteCategory {
    var englishName: String {
        switch self {
        case .general: return "General"
        case .important: return "Important"
        case .ideas: return "Ideas"
        case .links: return "Links"
        case .passwords: return "Passwords"
        }
    }
}
