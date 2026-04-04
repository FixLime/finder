import Foundation
import SwiftUI

enum ReportCategory: String, CaseIterable, Identifiable {
    case spam = "spam"
    case harassment = "harassment"
    case inappropriateContent = "inappropriate_content"
    case scam = "scam"
    case fakeAccount = "fake_account"
    case violence = "violence"
    case publicSafetyThreat = "public_safety_threat"
    case other = "other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .spam: return "envelope.badge.fill"
        case .harassment: return "hand.raised.fill"
        case .inappropriateContent: return "eye.slash.fill"
        case .scam: return "creditcard.trianglebadge.exclamationmark"
        case .fakeAccount: return "person.crop.circle.badge.questionmark"
        case .violence: return "bolt.trianglebadge.exclamationmark.fill"
        case .publicSafetyThreat: return "exclamationmark.shield.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .spam: return .orange
        case .harassment: return .red
        case .inappropriateContent: return .purple
        case .scam: return .yellow
        case .fakeAccount: return .indigo
        case .violence: return .red
        case .publicSafetyThreat: return .red
        case .other: return .gray
        }
    }

    func localizedName(isRussian: Bool) -> String {
        switch self {
        case .spam: return isRussian ? "Спам" : "Spam"
        case .harassment: return isRussian ? "Оскорбления и травля" : "Harassment & Bullying"
        case .inappropriateContent: return isRussian ? "Неприемлемый контент" : "Inappropriate Content"
        case .scam: return isRussian ? "Мошенничество" : "Scam & Fraud"
        case .fakeAccount: return isRussian ? "Фейковый аккаунт" : "Fake Account"
        case .violence: return isRussian ? "Призывы к насилию" : "Violence & Threats"
        case .publicSafetyThreat: return isRussian ? "Угроза общественной безопасности" : "Public Safety Threat"
        case .other: return isRussian ? "Другое" : "Other"
        }
    }

    func localizedDescription(isRussian: Bool) -> String {
        switch self {
        case .spam: return isRussian ? "Нежелательные сообщения, реклама" : "Unwanted messages, advertising"
        case .harassment: return isRussian ? "Угрозы, запугивание, буллинг" : "Threats, intimidation, bullying"
        case .inappropriateContent: return isRussian ? "Порнография, шок-контент" : "Pornography, shock content"
        case .scam: return isRussian ? "Попытка выманить деньги или данные" : "Attempting to steal money or data"
        case .fakeAccount: return isRussian ? "Выдаёт себя за другого человека" : "Impersonating another person"
        case .violence: return isRussian ? "Угрозы физического насилия" : "Threats of physical violence"
        case .publicSafetyThreat: return isRussian ? "Терроризм, экстремизм, угроза жизни людей" : "Terrorism, extremism, threat to human life"
        case .other: return isRussian ? "Опишите причину жалобы" : "Describe the reason for your report"
        }
    }

    var isPublicSafety: Bool {
        self == .publicSafetyThreat
    }
}

struct UserReport: Codable, Identifiable {
    let id: UUID
    let reporterUsername: String
    let reportedUsername: String
    let category: String
    let description: String
    let includeConversation: Bool
    let timestamp: Date
}

class ReportService: ObservableObject {
    static let shared = ReportService()

    @Published var reports: [UserReport] = []

    private init() {}

    func submitReport(
        reporterUsername: String,
        reportedUsername: String,
        category: ReportCategory,
        description: String,
        includeConversation: Bool
    ) {
        let report = UserReport(
            id: UUID(),
            reporterUsername: reporterUsername,
            reportedUsername: reportedUsername,
            category: category.rawValue,
            description: description,
            includeConversation: includeConversation,
            timestamp: Date()
        )

        reports.append(report)

        // Send to server in background
        Task {
            do {
                try await sendReportToServer(report)
            } catch {
                print("[Report] Failed to send report: \(error)")
            }
        }
    }

    func dismissReport(_ id: UUID) {
        reports.removeAll { $0.id == id }
    }

    private func sendReportToServer(_ report: UserReport) async throws {
        // Server integration placeholder
        // In production: POST to /api/reports with report data
        print("[Report] Report submitted: \(report.category) against @\(report.reportedUsername)")
    }
}
