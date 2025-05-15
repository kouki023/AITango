import Foundation
import SwiftData

@Model
final class Wordbook {
    @Attribute(.unique) var id: UUID
    var title: String
    var createdAt: Date
    var lastStudiedAt: Date?
    @Relationship(deleteRule: .cascade, inverse: \WordCard.wordbook)
    var words: [WordCard]? = []

    init(id: UUID = UUID(), title: String = "", createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
    }

    var wordCount: Int {
        words?.count ?? 0
    }

    var learningProgress: Double {
        guard let words = words, !words.isEmpty else { return 0.0 }
        let learnedCount = words.filter { $0.status != .new }.count
        return Double(learnedCount) / Double(words.count)
    }
}

// Enum for Learning Status (Wordbook.swift または別のファイルに定義してもOK)
enum LearningStatus: String, Codable, CaseIterable {
    case new = "New"
    case learning = "Learning"
    case mastered = "Mastered"

    // 表示用のラベル (必要に応じて)
    var label: String {
        self.rawValue
    }
}