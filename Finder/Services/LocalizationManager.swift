import SwiftUI

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @AppStorage("appLanguage") var currentLanguage: String = "ru"

    @Published var isRussian: Bool = true

    private init() {
        isRussian = currentLanguage == "ru"
    }

    func toggleLanguage() {
        currentLanguage = isRussian ? "en" : "ru"
        isRussian = !isRussian
    }

    func localized(_ ruText: String, _ enText: String) -> String {
        isRussian ? ruText : enText
    }

    // MARK: - Onboarding
    var onboardingTitle1: String { localized("Добро пожаловать\nв Finder", "Welcome\nto Finder") }
    var onboardingDesc1: String { localized("Мессенджер нового поколения\nс максимальной конфиденциальностью", "Next-generation messenger\nwith maximum privacy") }

    var onboardingTitle2: String { localized("Шифрование\nот начала до конца", "End-to-End\nEncryption") }
    var onboardingDesc2: String { localized("Все сообщения защищены\nсквозным шифрованием.\nНикто не может прочитать ваши данные", "All messages are protected\nwith end-to-end encryption.\nNo one can read your data") }

    var onboardingTitle3: String { localized("Ghost Mode", "Ghost Mode") }
    var onboardingDesc3: String { localized("Станьте невидимым.\nНикто не узнает, что вы онлайн,\nчитаете сообщения или печатаете", "Become invisible.\nNo one will know you're online,\nreading messages, or typing") }

    var onboardingTitle4: String { localized("Фантомные\nсообщения", "Phantom\nMessages") }
    var onboardingDesc4: String { localized("Сообщения, которые исчезают\nпосле прочтения.\nНе оставляйте следов", "Messages that disappear\nafter reading.\nLeave no trace") }

    var onboardingTitle5: String { localized("Протокол Fenix", "Fenix Protocol") }
    var onboardingDesc5: String { localized("Одно нажатие — и все ваши данные\nбудут безвозвратно удалены\nс наших серверов", "One tap — and all your data\nwill be permanently deleted\nfrom our servers") }

    var onboardingTitle6: String { localized("FinderID", "FinderID") }
    var onboardingDesc6: String { localized("Никаких телефонов и почты.\nТолько ваш уникальный FinderID\nи PIN-код для входа", "No phone numbers or emails.\nOnly your unique FinderID\nand PIN code for login") }

    // MARK: - General
    var chats: String { localized("Чаты", "Chats") }
    var settings: String { localized("Настройки", "Settings") }
    var profile: String { localized("Профиль", "Profile") }
    var notes: String { localized("Заметки", "Notes") }
    var search: String { localized("Поиск", "Search") }
    var cancel: String { localized("Отмена", "Cancel") }
    var delete: String { localized("Удалить", "Delete") }
    var save: String { localized("Сохранить", "Save") }
    var done: String { localized("Готово", "Done") }
    var next: String { localized("Далее", "Next") }
    var back: String { localized("Назад", "Back") }
    var start: String { localized("Начать", "Start") }
    var continueText: String { localized("Продолжить", "Continue") }
    var typeMessage: String { localized("Сообщение...", "Message...") }
    var online: String { localized("в сети", "online") }
    var offline: String { localized("не в сети", "offline") }
    var lastSeenText: String { localized("был(а)", "last seen") }

    // MARK: - Settings
    var privacy: String { localized("Конфиденциальность", "Privacy") }
    var appearance: String { localized("Внешний вид", "Appearance") }
    var language: String { localized("Язык", "Language") }
    var darkMode: String { localized("Тёмная тема", "Dark Mode") }
    var fenixProtocol: String { localized("Протокол Fenix", "Fenix Protocol") }
    var ghostMode: String { localized("Режим призрака", "Ghost Mode") }
    var phantomMessages: String { localized("Фантомные сообщения", "Phantom Messages") }
    var autoDelete: String { localized("Автоудаление", "Auto-Delete") }
    var screenshots: String { localized("Скриншоты", "Screenshots") }
    var readReceipts: String { localized("Отчёты о прочтении", "Read Receipts") }
    var onlineStatus: String { localized("Статус онлайн", "Online Status") }
    var typingIndicator: String { localized("Индикатор набора", "Typing Indicator") }
    var antiForward: String { localized("Запрет пересылки", "Anti-Forward") }
    var ipMask: String { localized("Маскировка IP", "IP Masking") }
    var decoyPinTitle: String { localized("Decoy PIN", "Decoy PIN") }
    var logout: String { localized("Выйти", "Log Out") }

    // MARK: - Rating
    var rating: String { localized("Рейтинг", "Rating") }
    var ratingPoints: String { localized("очков", "points") }
    var tier: String { localized("Уровень", "Tier") }

    // MARK: - Admin
    var adminPanel: String { localized("Админ-панель", "Admin Panel") }
    var verifyUser: String { localized("Верифицировать", "Verify") }
    var banUser: String { localized("Забанить", "Ban") }
    var unbanUser: String { localized("Разбанить", "Unban") }
    var deleteAccount: String { localized("Удалить аккаунт", "Delete Account") }
    var username: String { localized("Юзернейм", "Username") }

    // MARK: - Support
    var support: String { localized("Поддержка", "Support") }
    var supportRequests: String { localized("Обращения в поддержку", "Support Requests") }

    // MARK: - Groups & Channels
    var createGroup: String { localized("Создать группу", "Create Group") }
    var createChannel: String { localized("Создать канал", "Create Channel") }
    var groupName: String { localized("Название группы", "Group Name") }
    var channelName: String { localized("Название канала", "Channel Name") }
    var addParticipants: String { localized("Добавить участников", "Add Participants") }
    var create: String { localized("Создать", "Create") }
    var channels: String { localized("Каналы", "Channels") }
    var groups: String { localized("Группы", "Groups") }

    // MARK: - Account
    var switchAccount: String { localized("Сменить аккаунт", "Switch Account") }
    var searchByUsername: String { localized("Поиск по юзернейму", "Search by username") }

    // MARK: - Rating Lock
    var featureLocked: String { localized("Функция заблокирована", "Feature Locked") }
    var tier2Required: String { localized("Требуется 2 уровень рейтинга", "Tier 2 rating required") }
}
