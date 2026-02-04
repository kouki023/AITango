// Cursor_Test/Views/Learning/LearningView.swift

import SwiftUI
import SwiftData

struct LearningView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var wordbook: Wordbook // @Bindable で変更を直接反映

    @State private var cardsToLearn: [WordCard] = [] // 学習対象のカード配列
    @State private var currentIndex: Int = 0
    @State private var showBack: Bool = false
    // @State private var showCompletion: Bool = false // 完了画面フラグは不要になる

    // 学習対象とするカードの条件 (修正済み: 全カード対象)
    private func loadCards() {
         // wordbook.wordsがnilの場合や空の場合の処理
         guard let allCards = wordbook.words, !allCards.isEmpty else {
             // 学習するカードがない場合、即座に戻る
             dismiss() // カードがない場合はすぐに画面を閉じる
             return
         }
         // --- 修正箇所: ステータスに関わらず全てのカードを対象とする ---
         let filteredCards = allCards // 以前のfilterを削除

         // 対象のカードがない場合 (基本的にallCards.isEmptyでチェック済みだが念のため)
         if filteredCards.isEmpty {
             dismiss() // フィルター結果が空でも画面を閉じる
         } else {
             // シャッフルして学習順序をランダムにする
             cardsToLearn = filteredCards.shuffled()
             currentIndex = 0
             showBack = false
             // showCompletion = false // 不要になった
             // 学習開始時に単語帳の最終学習日時を更新
             wordbook.lastStudiedAt = Date()
         }
     }


    var body: some View {
        VStack {
            // --- 変更点：完了画面の分岐 (if showCompletion) を削除 ---

            if currentIndex < cardsToLearn.count {
                 // 現在の学習カード
                 let currentCard = cardsToLearn[currentIndex]

                 VStack {
                     // カード表示部分
                     ZStack {
                         RoundedRectangle(cornerRadius: 20)
                             .fill(.background) // 背景色を利用
                             .shadow(color: .gray.opacity(0.4), radius: 8, x: 0, y: 4)
                             // 表面/裏面で枠線の色を変える (任意)
                             .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(showBack ? Color.blue.opacity(0.6) : Color.green.opacity(0.6), lineWidth: 2)
                             )


                         VStack {
                             Spacer()
                             // 表面 or 裏面
                             Text(showBack ? currentCard.backText : currentCard.frontText)
                                 .font(.system(size: 40, weight: .bold))
                                 .minimumScaleFactor(0.5) // テキストが収まるように縮小
                                 .lineLimit(nil) // 複数行対応
                                 .multilineTextAlignment(.center)
                                 .padding(30) // 内側の余白
                             Spacer()
                             // タップで裏返すヒント
                             if !showBack {
                                 Text("タップして裏面を表示")
                                     .font(.caption)
                                     .foregroundColor(.gray)
                                     .padding(.bottom)
                             }
                         }
                         .padding(.vertical) // Vstack内の上下余白
                     }
                     .frame(minHeight: 250, maxHeight: 400) // カードの高さ (可変に)
                     .padding(.horizontal, 30) // カード左右の余白
                     .padding(.top, 20) // 上部の余白
                     .onTapGesture {
                        // withAnimation(.spring()) { // 少しアニメーションを追加
                             showBack.toggle()
                         //}
                     }

                     // 進捗表示 (任意)
                     Text("\(currentIndex + 1) / \(cardsToLearn.count)")
                         .font(.caption)
                         .foregroundColor(.gray)
                         .padding(.top)

                     Spacer() // ボタンを下に配置

                     // 操作ボタン (裏面表示時のみ)
                     if showBack {
                         HStack(spacing: 20) { // ボタン間隔調整
                             // 「まだ」ボタン
                             Button {
                                 markAsLearning(card: currentCard)
                                 triggerHapticFeedback()
                                 goToNextCard()
                             } label: {
                                 Label("まだ", systemImage: "flame.fill")
                                     .font(.headline)
                                     .padding()
                                     .frame(maxWidth: .infinity)
                             }
                             .buttonStyle(.bordered)
                             .tint(.orange)

                             // 「覚えた」ボタン
                             Button {
                                 markAsMastered(card: currentCard)
                                 triggerHapticFeedback()
                                 goToNextCard()
                             } label: {
                                 Label("覚えた", systemImage: "checkmark.circle.fill")
                                     .font(.headline)
                                     .padding()
                                     .frame(maxWidth: .infinity)
                             }
                             .buttonStyle(.borderedProminent)
                             .tint(.green)
                         }
                         .padding(.horizontal, 30)
                         .padding(.bottom, 40)
                         .transition(.opacity.combined(with: .scale(scale: 0.9))) // ボタン表示アニメーション
                     } else {
                         // 裏面表示前は高さを確保するためのスペーサー
                         Spacer().frame(height: 80) // ボタン部分と同じくらいの高さを確保
                         .padding(.bottom, 40)
                     }
                 }
                 // View全体のアニメーション（カード切り替え時など）
                 .transition(.asymmetric(insertion: .scale, removal: .opacity))

             } else {
                 // cardsToLearnが空の場合やロード中の表示 (loadCardsでdismissされるため、基本ここには来ないはず)
                 VStack {
                     ProgressView() // インジケーターを表示
                         .padding(.bottom)
                     Text("学習するカードを準備中...")
                         .foregroundColor(.secondary)
                 }
                 .frame(maxWidth: .infinity, maxHeight: .infinity)
                 .onAppear {
                      // Viewが表示された時にカードをロード
                      loadCards()
                  }
             }
        }
        .navigationTitle("フラッシュカード学習")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Viewが最初に表示される時だけロードする (戻ってきた時は再ロードしない)
             if cardsToLearn.isEmpty { // showCompletion は削除
                 loadCards()
             }
        }
    }

    // 「まだ」ボタンのアクション
    private func markAsLearning(card: WordCard) {
        card.status = .learning
        card.lastReviewedAt = Date()
        // SwiftDataは変更を自動保存する傾向があるが、確実に保存したい場合は↓
        // try? modelContext.save()
    }

    // 「覚えた」ボタンのアクション
    private func markAsMastered(card: WordCard) {
        card.status = .mastered
        card.lastReviewedAt = Date()
        // try? modelContext.save()
    }

    // 次のカードへ進む
    private func goToNextCard() {
         // アニメーションのため少し遅延させる（任意）
         DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
             if currentIndex + 1 < cardsToLearn.count {
                 // 次のカードへ
                 withAnimation {
                     currentIndex += 1
                     showBack = false // 次のカードは表面から表示
                 }
             } else {
                 // 全てのカードが終了
                 wordbook.lastStudiedAt = Date() // 最終学習日時を更新

                 // --- 変更点：完了画面を表示せずに即座に前の画面に戻る ---
                 dismiss()
                 // -----------------------------------------------------

                 // 念のため保存 (学習結果を確実に反映させたい場合)
                 // try? modelContext.save()
             }
         }
     }

     private func triggerHapticFeedback(){
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
        print("motion")
     }
}

// プレビュー用
#if DEBUG
#Preview {
     // NavigationStack内でプレビューしないとタイトルが表示されない場合がある
     NavigationStack {
         // PreviewContainerからサンプルWordbookを取得して渡す
         LearningView(wordbook: PreviewContainer.sampleWordbooks[0])
     }
     // 関連データ付きのコンテナを使用
     .modelContainer(PreviewContainer.previewInMemoryWithLinkedData)
}
#endif
