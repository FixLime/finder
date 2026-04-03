import SwiftUI

struct ReportUserView: View {
    let reportedUser: FinderUser
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var localization: LocalizationManager
    @Environment(\.dismiss) var dismiss

    @State private var selectedCategory: ReportCategory?
    @State private var descriptionText = ""
    @State private var includeConversation = false
    @State private var showConfirmation = false
    @State private var showSuccess = false
    @State private var showConversationWarning = false

    var body: some View {
        NavigationStack {
            if showSuccess {
                reportSuccessView
            } else {
                reportFormView
            }
        }
    }

    // MARK: - Report Form
    private var reportFormView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // User being reported
                HStack(spacing: 12) {
                    AvatarView(user: reportedUser, size: 44)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(reportedUser.displayName)
                            .font(.subheadline.bold())
                        Text("@\(reportedUser.username)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }
                .padding(14)
                .liquidGlassCard(cornerRadius: 14)
                .padding(.horizontal)

                // Categories
                VStack(alignment: .leading, spacing: 8) {
                    Text(localization.localized("Причина жалобы", "Reason for Report"))
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 20)

                    VStack(spacing: 0) {
                        ForEach(ReportCategory.allCases) { category in
                            if category.isPublicSafety {
                                // Special divider before public safety
                                Rectangle()
                                    .fill(Color.red.opacity(0.3))
                                    .frame(height: 1)
                                    .padding(.horizontal, 14)
                            }

                            reportCategoryRow(category)

                            if category != .other && !category.isPublicSafety {
                                Divider().padding(.leading, 56)
                            }
                        }
                    }
                    .liquidGlassCard(cornerRadius: 16)
                    .padding(.horizontal)
                }

                // Description
                if selectedCategory != nil {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(localization.localized("Описание", "Description"))
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)

                        TextEditor(text: $descriptionText)
                            .frame(minHeight: 80)
                            .padding(10)
                            .liquidGlassCard(cornerRadius: 14)
                            .padding(.horizontal)
                            .overlay(
                                Group {
                                    if descriptionText.isEmpty {
                                        Text(localization.localized(
                                            "Опишите ситуацию подробнее...",
                                            "Describe the situation in detail..."
                                        ))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary.opacity(0.5))
                                        .padding(.horizontal, 30)
                                        .padding(.top, 18)
                                        .allowsHitTesting(false)
                                    }
                                },
                                alignment: .topLeading
                            )
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Conversation disclosure (for public safety threat)
                if selectedCategory?.isPublicSafety == true {
                    publicSafetySection
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Submit
                if selectedCategory != nil {
                    Button {
                        showConfirmation = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(localization.localized("Отправить жалобу", "Submit Report"))
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.red)
                        )
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .transition(.opacity)
                }

                Spacer(minLength: 100)
            }
            .padding(.top, 8)
        }
        .navigationTitle(localization.localized("Пожаловаться", "Report User"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(localization.cancel) { dismiss() }
            }
        }
        .alert(
            localization.localized("Подтвердите жалобу", "Confirm Report"),
            isPresented: $showConfirmation
        ) {
            Button(localization.localized("Отправить", "Submit"), role: .destructive) {
                submitReport()
            }
            Button(localization.cancel, role: .cancel) {}
        } message: {
            if selectedCategory?.isPublicSafety == true && includeConversation {
                Text(localization.localized(
                    "Жалоба будет отправлена вместе с перепиской для тщательной проверки и возможной передачи в соответствующие органы.",
                    "The report will be sent along with the conversation for thorough review and possible transfer to relevant authorities."
                ))
            } else {
                Text(localization.localized(
                    "Жалоба на @\(reportedUser.username) будет отправлена на рассмотрение.",
                    "Report against @\(reportedUser.username) will be sent for review."
                ))
            }
        }
    }

    // MARK: - Public Safety Section
    private var publicSafetySection: some View {
        VStack(spacing: 12) {
            // Warning banner
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.shield.fill")
                        .font(.title3)
                        .foregroundStyle(.red)
                    Text(localization.localized(
                        "Угроза общественной безопасности",
                        "Public Safety Threat"
                    ))
                    .font(.subheadline.bold())
                    .foregroundStyle(.red)
                }

                Text(localization.localized(
                    "Если вы считаете, что действия этого пользователя представляют реальную угрозу жизни или безопасности людей, вы можете раскрыть переписку для тщательной проверки и последующей передачи в соответствующие органы.",
                    "If you believe this user's actions pose a real threat to human life or safety, you can disclose the conversation for thorough review and subsequent transfer to relevant authorities."
                ))
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(Color.red.opacity(0.08))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal)

            // Conversation disclosure toggle
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.red.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 14))
                        .foregroundStyle(.red)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(localization.localized(
                        "Раскрыть переписку",
                        "Disclose Conversation"
                    ))
                    .font(.subheadline)

                    Text(localization.localized(
                        "Вся переписка будет передана для проверки",
                        "Full conversation will be submitted for review"
                    ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Toggle("", isOn: $includeConversation)
                    .labelsHidden()
                    .tint(.red)
            }
            .padding(14)
            .liquidGlassCard(cornerRadius: 14)
            .padding(.horizontal)

            if includeConversation {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .font(.caption)
                    Text(localization.localized(
                        "Переписка будет передана в зашифрованном виде только уполномоченным сотрудникам для проверки и, при необходимости, в соответствующие органы.",
                        "The conversation will be transferred in encrypted form only to authorized personnel for review and, if necessary, to relevant authorities."
                    ))
                    .font(.caption2)
                }
                .foregroundStyle(.red.opacity(0.8))
                .padding(.horizontal, 20)
                .transition(.opacity)
            }
        }
    }

    // MARK: - Category Row
    private func reportCategoryRow(_ category: ReportCategory) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                selectedCategory = category
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(category.color.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: category.icon)
                        .font(.system(size: 14))
                        .foregroundStyle(category.color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(category.localizedName(isRussian: localization.isRussian))
                        .font(.subheadline)
                        .foregroundStyle(category.isPublicSafety ? .red : .primary)
                        .fontWeight(category.isPublicSafety ? .bold : .regular)

                    Text(category.localizedDescription(isRussian: localization.isRussian))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if selectedCategory == category {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(category.color)
                } else {
                    Circle()
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                category.isPublicSafety && selectedCategory == category
                    ? Color.red.opacity(0.05)
                    : Color.clear
            )
        }
    }

    // MARK: - Success View
    private var reportSuccessView: some View {
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
                Text(localization.localized("Жалоба отправлена", "Report Submitted"))
                    .font(.title2.bold())

                Text(localization.localized(
                    "Спасибо за обращение. Мы рассмотрим вашу жалобу в ближайшее время.",
                    "Thank you for reporting. We will review your report shortly."
                ))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

                if selectedCategory?.isPublicSafety == true && includeConversation {
                    Text(localization.localized(
                        "Переписка передана для проверки уполномоченным сотрудникам.",
                        "Conversation has been submitted for review by authorized personnel."
                    ))
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 4)
                }
            }

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

    // MARK: - Submit
    private func submitReport() {
        guard let category = selectedCategory else { return }

        ReportService.shared.submitReport(
            reporterUsername: authService.currentUsername,
            reportedUsername: reportedUser.username,
            category: category,
            description: descriptionText,
            includeConversation: includeConversation
        )

        withAnimation(.spring(response: 0.4)) {
            showSuccess = true
        }

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}
