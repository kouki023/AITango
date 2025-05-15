// Views/Learning/LearningTabView.swift
import SwiftUI
import SwiftData

// 学習モードを定義するEnum (変更なし)
enum LearningMode: String, CaseIterable, Identifiable {
    case normal = "フラッシュカード"
    case spacedRepetition = "分散学習"
    var id: String { self.rawValue }
}

struct LearningTabView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Wordbook.createdAt, order: .reverse)]) private var wordbooks: [Wordbook]
    @Query private var allCards: [WordCard]

    @State var selectedMode: LearningMode = .normal

    // --- ▼▼▼ アニメーション用のNamespaceをここで宣言 ▼▼▼ ---
    @Namespace private var learningTabNamespace
    // --- ▲▲▲ ---

    @State private var showSpacedRepetitionLearning = false
    @State private var cardsForReviewSession: [WordCard] = []

    var dueCardsToday: [WordCard] {
        let todayStart = Calendar.current.startOfDay(for: Date())
        return allCards.filter { card in
            guard let nextReviewDate = card.nextReviewDate else { return false }
            return nextReviewDate <= todayStart
        }
    }

    // Style 構造体は削除 (CapsuleSegmentedControlへ移動)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                
                CapsuleSegmentedControl(
                    items: Array(LearningMode.allCases),
                    selection: $selectedMode,
                    namespace: learningTabNamespace,
                    highlightColor: .blue,
                    font: .subheadline// ★ 再度追加
                )
                .padding(.horizontal)
                .padding(.top)
                .frame(maxHeight: 50)
                .padding(.bottom, 15)
                

                // --- 選択されたモードに応じたコンテンツ ---
                if selectedMode == .normal {
                    // ... (通常学習モードのコンテンツ) ...
                     if wordbooks.isEmpty {
                         ContentUnavailableView(
                             "学習できる単語帳がありません",
                             systemImage: "book.closed",
                             description: Text("まずは「単語帳」タブから単語帳とカードを作成しましょう。")
                         )
                         .padding(.top, 40)
                     } else {
                         List {
                             Section("単語帳を選んで学習") {
                                 ForEach(wordbooks) { wordbook in
                                     NavigationLink(value: wordbook) {
                                         HStack {
                                             VStack(alignment: .leading) {
                                                 Text(wordbook.title)
                                                     .font(.headline)
                                                 Text("\(wordbook.wordCount) カード / 進捗 \(Int(wordbook.learningProgress * 100))%")
                                                     .font(.caption)
                                                     .foregroundColor(.secondary)
                                             }
                                             Spacer()
                                             if wordbook.wordCount == 0 {
                                                  Text("カードなし")
                                                      .font(.caption)
                                                      .foregroundColor(.gray)
                                                      .padding(.trailing)
                                             }
                                         }
                                     }
                                     .disabled(wordbook.wordCount == 0)
                                 }
                             }
                         }
                         .listStyle(.insetGrouped)
                     }
                } else {
                    // ... (分散学習モードのコンテンツ) ...
                    VStack {
                        if dueCardsToday.isEmpty {
                            ContentUnavailableView(
                                "復習カードなし",
                                systemImage: "checkmark.circle",
                                description: Text("今日復習するカードはありません。\n新しいカードを学習しましょう。")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    
                            )
                            .padding(.top, 40)
                        } else {
                            Text("今日復習するカード： \(dueCardsToday.count) 枚")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.top)
                                

                            Button {
                                //startReviewSession()
                                showSpacedRepetitionLearning = true
                            } label: {
                                Label("復習を開始する", systemImage: "play.circle.fill")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .padding()

                            List {
                                Section("今日の復習カード") {
                                    ForEach(dueCardsToday) { card in
                                        HStack {
                                            Text(card.frontText)
                                            Spacer()
                                            if let nextReview = card.nextReviewDate {
                                                 Text("復習日: \(formattedDate(from: nextReview))")
                                                     .font(.caption)
                                                     .foregroundColor(.orange)
                                            }
                                             Text(card.wordbook?.title ?? "所属なし")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                            }
                            .listStyle(.insetGrouped)
                        }
                        Spacer()
                    }
                    .sheet(isPresented: $showSpacedRepetitionLearning) {
                        NavigationView {
                            SpacedRepetitionLearningView(cardsToReview: cardsForReviewSession)
                                .environment(\.modelContext, modelContext)
                        }
                    }
                    // ★★★ ここから追加 ★★★
                    .onChange(of: showSpacedRepetitionLearning) { _, newValue in
                    // showSpacedRepetitionLearning が true になった時だけ実行
                        if newValue {
                            // sheet が表示される直前に復習カードリストを準備する
                            cardsForReviewSession = dueCardsToday.shuffled()
                            // もしシャッフル後のリストが空だったら sheet を表示しないようにする (任意)
                            // if cardsForReviewSession.isEmpty {
                            //     showSpacedRepetitionLearning = false
                            // }
                        }
                    }
            // ★★★ ここまで追加 ★★★
                }
            }
            .navigationTitle("学習")
            .navigationDestination(for: Wordbook.self) { selectedWordbook in
                LearningView(wordbook: selectedWordbook)
            }
        } // End NavigationStack
    }


    private func formattedDate(from date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy/MM/dd"  // フォーマットを指定
    formatter.locale = Locale(identifier: "en_US_POSIX")  // ロケールを固定 (任意)
    formatter.timeZone = TimeZone.current  // 現在のタイムゾーンを使用 (任意)
    return formatter.string(from: date)
  }

    // private func startReviewSession() {
    //     cardsForReviewSession = dueCardsToday.shuffled()
    // }
}

// プレビューコード (変更なし、新しいコンポーネントが反映される)
#Preview("Learning Tab View - Using CapsuleSegmentedControl") {
    LearningTabView(selectedMode: .normal)
        .modelContainer(PreviewContainer.previewInMemoryWithLinkedData)
}
