// Cursor_Test/Models/WordCard.swift

import Foundation
import SwiftData

@Model
final class WordCard {
    var id: UUID
    var frontText: String
    var backText: String
    var createdAt: Date
    var lastReviewedAt: Date? // 最後に復習した日時
    var status: LearningStatus // 現在の状態 (新規、学習中、習得済み)

    // --- 分散学習(SRS)用プロパティを追加 ---
    var nextReviewDate: Date? // 次回復習予定日
    var interval: Int // 復習間隔 (日数)
    var easeFactor: Double // 難易度係数 (例: 1.3 ~ 2.5)
    // var repetitions: Int // 連続正解回数 (アルゴリズムによる)
    // ------------------------------------

    // var image: Data?
    // var pronunciation: String?
    // var tags: [String]?

    var wordbook: Wordbook? // Relationship back

    // --- イニシャライザを更新 ---
    init(id: UUID = UUID(),
         frontText: String = "",
         backText: String = "",
         createdAt: Date = Date(),
         status: LearningStatus = .new,
         // SRSプロパティの初期値
         nextReviewDate: Date? = Date(), // 最初は未定 4/12変更
         interval: Int = 0,           // 最初の間隔
         easeFactor: Double = 2.5) {  // 標準的な初期値
        self.id = id
        self.frontText = frontText
        self.backText = backText
        self.createdAt = createdAt
        self.status = status
        self.nextReviewDate = nextReviewDate // 新規カードは最初 nil または Date() でも良い
        self.interval = interval
        self.easeFactor = easeFactor
    }
    // ---------------------------
}