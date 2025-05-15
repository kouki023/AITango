// Cursor_Test/Preview Content/PreviewContainer.swift

import SwiftData
import SwiftUI // @MainActor のために必要

// プレビュー用のコンテナとサンプルデータを管理するクラス/構造体
@MainActor // プレビューはメインスレッドで実行されるため
struct PreviewContainer {

    // 1. サンプルデータ (それぞれのモデルに対応)
    static let sampleWordbooks: [Wordbook] = { // 即時実行クロージャに変更
        let book1 = Wordbook(title: "基本英単語", createdAt: Date())
        let book2 = Wordbook(title: "旅行用フレーズ", createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
        let book3 = Wordbook(title: "ビジネス用語", createdAt: Calendar.current.date(byAdding: .day, value: -2, to: Date())!)
        book3.lastStudiedAt = Calendar.current.date(byAdding: .hour, value: -5, to: Date())!
        return [book1, book2, book3]
    }()

    static let sampleCards: [WordCard] = [
        // SRSプロパティに初期値が設定される
        WordCard(frontText: "Apple", backText: "りんご", status: .mastered),
        WordCard(frontText: "Book", backText: "本", status: .learning),
        WordCard(frontText: "Hello", backText: "こんにちは", status: .new),
        WordCard(frontText: "Thank you", backText: "ありがとう", status: .new),
        WordCard(frontText: "Excuse me", backText: "すみません", status: .learning)
    ]

    // 2. インメモリ ModelContainer (データのみ、関連なし)
    static var previewInMemory: ModelContainer = {
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: Wordbook.self, WordCard.self, configurations: config)
            let context = container.mainContext
            for book in sampleWordbooks { context.insert(book) }
            for card in sampleCards { context.insert(card) }
            return container
        } catch { fatalError("Failed to create preview container: \(error)") }
    }()

    // 3. インメモリ ModelContainer (データ間に関連あり)
    static var previewInMemoryWithLinkedData: ModelContainer = {
         do {
             let config = ModelConfiguration(isStoredInMemoryOnly: true)
             let container = try ModelContainer(for: Wordbook.self, WordCard.self, configurations: config)
             let context = container.mainContext

             // --- 単語帳インスタンス作成 ---
             let book1 = Wordbook(title: "基本英単語", createdAt: Date())
             let book2 = Wordbook(title: "旅行用フレーズ", createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
             let book3 = Wordbook(title: "ビジネス用語", createdAt: Calendar.current.date(byAdding: .day, value: -2, to: Date())!)
             book3.lastStudiedAt = Calendar.current.date(byAdding: .hour, value: -5, to: Date())!

             // --- カードインスタンス作成 (SRS初期値付き) ---
             let card1 = WordCard(frontText: "Apple", backText: "りんご", status: .mastered)
             let card2 = WordCard(frontText: "Book", backText: "本", status: .learning, nextReviewDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())!) // 明日復習
             let card3 = WordCard(frontText: "Hello", backText: "こんにちは", status: .new, nextReviewDate: Date()) // 今日復習
             let card4 = WordCard(frontText: "Thank you", backText: "ありがとう", status: .new) // 復習日未定
             let card5 = WordCard(frontText: "Excuse me", backText: "すみません", status: .learning, nextReviewDate: Calendar.current.date(byAdding: .day, value: -2, to: Date())!) // 2日前=今日復習

             // --- データをコンテキストに挿入 ---
             context.insert(book1)
             context.insert(book2)
             context.insert(book3) // データのないWordbookも挿入

             context.insert(card1)
             context.insert(card2)
             context.insert(card3)
             context.insert(card4)
             context.insert(card5)

             // --- 関連付け ---
             book1.words = [card1, card2]
             book2.words = [card3, card4, card5]

             // WordCardからWordbookへの参照も設定（通常は片方向で十分な場合も）
             card1.wordbook = book1
             card2.wordbook = book1
             card3.wordbook = book2
             card4.wordbook = book2
             card5.wordbook = book2
             // --- 関連付けここまで ---

             // --- (Option) さらにカードを追加する場合 ---
             let card6 = WordCard(frontText: "Train", backText: "電車", status: .new, nextReviewDate: Calendar.current.date(byAdding: .day, value: -5, to: Date())!) // 5日前=今日復習
             context.insert(card6)
             book1.words?.append(card6)
             card6.wordbook = book1


             return container
         } catch {
             fatalError("Failed to create linked preview container: \(error)")
         }
     }()

    // 4. 空のインメモリ ModelContainer
    static var empty: ModelContainer = {
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: Wordbook.self, WordCard.self, configurations: config)
            return container
        } catch {
            fatalError("Failed to create empty preview container: \(error)")
        }
    }()
}


// --- PreviewContainer に復習用サンプルデータを追加するヘルパー (例) ---
extension PreviewContainer {
    @MainActor // MainActor上で実行
    static func sampleCardsForReview() -> [WordCard] {
        // `previewInMemoryWithLinkedData` コンテナからカードを取得して日付を調整
        let context = previewInMemoryWithLinkedData.mainContext
        // nextReviewDateが今日以前のカードを取得するFetchDescriptor
        let todayStart = Calendar.current.startOfDay(for: Date())
        let predicate = #Predicate<WordCard> { card in
            card.nextReviewDate != nil && card.nextReviewDate! <= todayStart
        }
        let request = FetchDescriptor<WordCard>(predicate: predicate, sortBy: [SortDescriptor(\.nextReviewDate)])

        guard let cards = try? context.fetch(request), !cards.isEmpty else {
            // 十分なカードがない場合は、サンプルの新しいカードを返す (プレビュー用フォールバック)
             print("⚠️ PreviewContainer: No due cards found in linked data for review preview. Returning fallback sample.")
             return [
                 WordCard(frontText: "Preview Review 1", backText: "プレビュー復習1", nextReviewDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())!), // 昨日
                 WordCard(frontText: "Preview Review 2", backText: "プレビュー復習2", nextReviewDate: Calendar.current.startOfDay(for: Date())), // 今日の始まり
                 WordCard(frontText: "Preview Review 3", backText: "プレビュー復習3", nextReviewDate: Calendar.current.date(byAdding: .day, value: -3, to: Date())!) // 3日前
             ]
         }
        // 取得できたカードを返す
        print("✅ PreviewContainer: Found \(cards.count) due cards for review preview.")
        return cards
    }
}