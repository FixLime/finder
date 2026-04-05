import SwiftUI

struct LegalSheetView: View {
    let type: String // "terms" or "privacy"
    let localization: LocalizationManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                Text(content)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineSpacing(6)
                    .padding()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(localization.localized("Закрыть", "Close")) {
                        dismiss()
                    }
                }
            }
        }
    }

    private var title: String {
        if type == "terms" {
            return localization.localized("Условия использования", "Terms of Service")
        } else {
            return localization.localized("Политика конфиденциальности", "Privacy Policy")
        }
    }

    private var content: String {
        if type == "terms" {
            return localization.localized(termsRU, termsEN)
        } else {
            return localization.localized(privacyRU, privacyEN)
        }
    }
}

// MARK: - Terms of Service

private let termsRU = """
Условия использования Finder

Последнее обновление: 5 апреля 2026

1. Общие положения

1.1. Настоящие Условия использования (далее — «Условия») регулируют отношения между пользователем (далее — «Пользователь») и разработчиками мессенджера Finder (далее — «Finder», «мы», «нас»).

1.2. Используя приложение Finder, Пользователь подтверждает, что ознакомился с настоящими Условиями и принимает их в полном объёме.

1.3. Finder — мессенджер, ориентированный на конфиденциальность и безопасность общения.

2. Регистрация и аккаунт

2.1. Для использования Finder необходимо создать аккаунт с уникальным именем пользователя и PIN-кодом.

2.2. Finder не требует номер телефона, адрес электронной почты или иные персональные данные для регистрации.

2.3. Пользователь несёт полную ответственность за сохранность своего FinderID и PIN-кода. В случае утраты доступа восстановление может быть невозможно.

2.4. Один пользователь может иметь только один активный аккаунт.

3. Правила поведения

3.1. Пользователь обязуется не использовать Finder для:
• распространения незаконного контента;
• угроз, оскорблений и травли других пользователей;
• мошенничества и обмана;
• распространения спама и нежелательной рекламы;
• распространения вредоносного программного обеспечения;
• нарушения прав третьих лиц.

3.2. Нарушение правил может привести к временной или постоянной блокировке аккаунта.

4. Контент и сообщения

4.1. Пользователь несёт ответственность за содержание своих сообщений.

4.2. Сообщения передаются с использованием сквозного шифрования. Мы не имеем технической возможности читать содержимое переписок.

4.3. Функции самоуничтожения сообщений и «Протокол Fenix» удаляют данные безвозвратно.

5. Система рейтинга

5.1. Finder использует систему рейтинга для поощрения активных пользователей.

5.2. Некоторые функции доступны только пользователям определённого уровня рейтинга.

5.3. Мы оставляем за собой право изменять требования к рейтингу.

6. Ограничение ответственности

6.1. Finder предоставляется «как есть». Мы не гарантируем бесперебойную работу сервиса.

6.2. Мы не несём ответственности за утрату данных, связанную с использованием функций самоуничтожения.

6.3. Мы не несём ответственности за действия пользователей и контент, который они передают через Finder.

7. Изменения условий

7.1. Мы оставляем за собой право изменять настоящие Условия в любое время.

7.2. Продолжение использования Finder после изменения Условий означает согласие с новой редакцией.

8. Прекращение использования

8.1. Пользователь может в любой момент удалить свой аккаунт, в том числе с помощью «Протокола Fenix».

8.2. Мы оставляем за собой право заблокировать или удалить аккаунт пользователя при нарушении Условий.
"""

private let termsEN = """
Finder Terms of Service

Last updated: April 5, 2026

1. General Provisions

1.1. These Terms of Service (hereinafter — "Terms") govern the relationship between the user (hereinafter — "User") and the developers of the Finder messenger (hereinafter — "Finder," "we," "us").

1.2. By using Finder, the User confirms that they have read and fully accept these Terms.

1.3. Finder is a messenger focused on privacy and secure communication.

2. Registration and Account

2.1. To use Finder, you must create an account with a unique username and PIN code.

2.2. Finder does not require a phone number, email address, or other personal data for registration.

2.3. The User is fully responsible for the security of their FinderID and PIN code. Recovery may not be possible if access is lost.

2.4. Each user may have only one active account.

3. Code of Conduct

3.1. Users agree not to use Finder for:
• distributing illegal content;
• threats, insults, and harassment of other users;
• fraud and deception;
• distributing spam and unwanted advertising;
• distributing malicious software;
• violating the rights of third parties.

3.2. Violations may result in temporary or permanent account suspension.

4. Content and Messages

4.1. Users are responsible for the content of their messages.

4.2. Messages are transmitted using end-to-end encryption. We have no technical ability to read the content of conversations.

4.3. Self-destructing message features and "Fenix Protocol" permanently delete data.

5. Rating System

5.1. Finder uses a rating system to reward active users.

5.2. Some features are only available to users with a certain rating level.

5.3. We reserve the right to modify rating requirements.

6. Limitation of Liability

6.1. Finder is provided "as is." We do not guarantee uninterrupted service.

6.2. We are not responsible for data loss related to the use of self-destruct features.

6.3. We are not responsible for user actions or content transmitted through Finder.

7. Changes to Terms

7.1. We reserve the right to modify these Terms at any time.

7.2. Continued use of Finder after changes to the Terms constitutes acceptance of the new version.

8. Termination

8.1. Users may delete their account at any time, including through "Fenix Protocol."

8.2. We reserve the right to suspend or delete a user's account for violations of these Terms.
"""

private let privacyRU = """
Политика конфиденциальности Finder

Последнее обновление: 5 апреля 2026

1. Введение

Мы в Finder уважаем вашу конфиденциальность и стремимся защитить ваши персональные данные. Настоящая Политика конфиденциальности описывает, как мы собираем, используем и защищаем вашу информацию.

2. Какие данные мы собираем

2.1. Данные при регистрации:
• имя пользователя (username);
• отображаемое имя;
• FinderID (генерируется автоматически).

2.2. Мы НЕ собираем:
• номер телефона;
• адрес электронной почты;
• геолокацию;
• контакты из телефонной книги;
• фотографии из галереи (без явного разрешения).

3. Шифрование и безопасность

3.1. Все сообщения в Finder защищены сквозным шифрованием (end-to-end encryption).

3.2. Мы не имеем технической возможности прочитать содержимое ваших сообщений.

3.3. PIN-коды хранятся в хешированном виде и не могут быть восстановлены нами.

3.4. Биометрические данные обрабатываются исключительно на вашем устройстве и никогда не передаются на наши серверы.

4. Хранение данных

4.1. Ваши сообщения и заметки хранятся локально на вашем устройстве.

4.2. Минимальные метаданные (имя пользователя, FinderID, настройки) могут храниться на сервере для обеспечения работы сервиса.

4.3. Функция «Протокол Fenix» удаляет все ваши данные безвозвратно — как с устройства, так и с серверов.

5. Функции конфиденциальности

5.1. Режим призрака — полная невидимость вашей активности.

5.2. Фантомные сообщения — автоматическое удаление сообщений после прочтения.

5.3. Защита от скриншотов — предотвращение захвата экрана собеседником.

5.4. Маскировка IP — скрытие вашего IP-адреса.

5.5. Запрет пересылки — запрет на пересылку ваших сообщений.

5.6. Decoy PIN — ввод специального PIN-кода показывает пустой аккаунт.

6. Передача данных третьим лицам

6.1. Мы не продаём, не передаём и не предоставляем ваши данные третьим лицам.

6.2. Мы не используем рекламные трекеры и аналитические системы третьих сторон.

6.3. Мы можем раскрыть информацию только по требованию закона, если это технически возможно с учётом сквозного шифрования.

7. Права пользователя

7.1. Вы имеете право:
• удалить свой аккаунт в любой момент;
• активировать «Протокол Fenix» для полного удаления данных;
• управлять настройками конфиденциальности;
• запросить информацию о хранимых данных.

8. Изменения политики

8.1. Мы можем обновлять настоящую Политику. Существенные изменения будут доведены до сведения пользователей через приложение.

9. Контакты

По вопросам конфиденциальности обращайтесь через чат поддержки Finder Support в приложении.
"""

private let privacyEN = """
Finder Privacy Policy

Last updated: April 5, 2026

1. Introduction

At Finder, we respect your privacy and are committed to protecting your personal data. This Privacy Policy describes how we collect, use, and protect your information.

2. Data We Collect

2.1. Registration data:
• username;
• display name;
• FinderID (automatically generated).

2.2. We do NOT collect:
• phone numbers;
• email addresses;
• geolocation;
• contacts from your phone book;
• photos from your gallery (without explicit permission).

3. Encryption and Security

3.1. All messages in Finder are protected by end-to-end encryption.

3.2. We have no technical ability to read the content of your messages.

3.3. PIN codes are stored in hashed form and cannot be recovered by us.

3.4. Biometric data is processed exclusively on your device and is never transmitted to our servers.

4. Data Storage

4.1. Your messages and notes are stored locally on your device.

4.2. Minimal metadata (username, FinderID, settings) may be stored on our server to ensure service operation.

4.3. The "Fenix Protocol" feature permanently deletes all your data — both from your device and from our servers.

5. Privacy Features

5.1. Ghost Mode — complete invisibility of your activity.

5.2. Phantom Messages — automatic deletion of messages after reading.

5.3. Screenshot Protection — preventing screen capture by the other party.

5.4. IP Masking — hiding your IP address.

5.5. Anti-Forward — preventing forwarding of your messages.

5.6. Decoy PIN — entering a special PIN code shows an empty account.

6. Third-Party Data Sharing

6.1. We do not sell, transfer, or provide your data to third parties.

6.2. We do not use advertising trackers or third-party analytics systems.

6.3. We may disclose information only as required by law, if technically possible given end-to-end encryption.

7. User Rights

7.1. You have the right to:
• delete your account at any time;
• activate "Fenix Protocol" for complete data deletion;
• manage your privacy settings;
• request information about stored data.

8. Policy Changes

8.1. We may update this Policy. Significant changes will be communicated to users through the application.

9. Contact

For privacy-related questions, please contact us through the Finder Support chat in the application.
"""
