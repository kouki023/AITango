// Cursor_Test/Views/Learning/SpacedRepetitionLearningView.swift

import SwiftData
import SwiftUI

// 分散学習用の学習画面
struct SpacedRepetitionLearningView: View {
  @Environment(\.dismiss) private var dismiss
  // 親View (LearningTabView) から modelContext を受け取る
  @Environment(\.modelContext) private var modelContext
  // 渡されたカードリストを保持し、内部で操作可能にする
  @State var cardsToReview: [WordCard]

  @State private var currentIndex: Int = 0
  @State private var showBack: Bool = false
  @State private var showCompletion: Bool = false

  var body: some View {
    VStack {
      if showCompletion {
        // 学習完了画面
        VStack(spacing: 20) {
          Image(systemName: "checkmark.circle.fill")
            .resizable().scaledToFit().frame(width: 80, height: 80).foregroundColor(.green)
          Text("復習完了！").font(.largeTitle)
          Text("お疲れ様でした！").font(.title2)
          Button("閉じる") { dismiss() }
            .padding(.top, 30).buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)

      } else if currentIndex < cardsToReview.count {
        let currentCard = cardsToReview[currentIndex]
        // --- カード表示 ---
        ZStack {
          RoundedRectangle(cornerRadius: 20)
            .fill(.background)  // 背景色を利用
            .shadow(color: .gray.opacity(0.4), radius: 8, x: 0, y: 4)
            .overlay(
              RoundedRectangle(cornerRadius: 20)
                .stroke(showBack ? Color.blue.opacity(0.6) : Color.green.opacity(0.6), lineWidth: 2)
            )

          VStack {
            Spacer()
            Text(showBack ? currentCard.backText : currentCard.frontText)
              .font(.system(size: 40, weight: .bold))
              .minimumScaleFactor(0.5)  // 自動縮小
              .lineLimit(nil)  // 複数行
              .multilineTextAlignment(.center)
              .padding(30)  // 内側の余白
            Spacer()
            if !showBack {
              Text("タップして裏面を表示")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.bottom)
            }
          }
          .padding(.vertical)
        }
        .frame(minHeight: 250, maxHeight: 400)
        .padding(.horizontal, 30).padding(.top, 20)
        .contentShape(Rectangle())  // タップ領域を広げる
        .onTapGesture { withAnimation { showBack.toggle() } }

        // 進捗表示
        Text("\(currentIndex + 1) / \(cardsToReview.count)")
          .font(.caption).foregroundColor(.gray).padding(.top)

        Spacer()  // ボタンを下に

        // --- SRS評価ボタン ---
        if showBack {
          HStack(spacing: 10) {
            // 評価ボタン（例：難しい、普通、簡単）
            // quality は SM-2 アルゴリズムなどに応じて調整
            Button("難しい") { processAnswer(quality: 1, card: currentCard) }
              .buttonStyle(SRSButtonStyle(color: .red))
              .onTapGesture {
                triggerHapticFeedback()
              }
            Button("普通") { processAnswer(quality: 3, card: currentCard) }
              .buttonStyle(SRSButtonStyle(color: .orange))
              .onTapGesture {
                triggerHapticFeedback()
              }
            Button("簡単") { processAnswer(quality: 5, card: currentCard) }
              .buttonStyle(SRSButtonStyle(color: .green))
              .onTapGesture {
                triggerHapticFeedback()
              }
          }
          .padding(.horizontal, 20)
          .padding(.bottom, 40)  // 下部の余白
          .transition(.opacity.combined(with: .scale(scale: 0.9)))  // 表示アニメーション
        } else {
          // 裏面表示前は高さを確保
          Spacer().frame(height: 80).padding(.bottom, 40)
        }

      } else {
        // カードがない or ロード中 (初期化時にチェックする方が良い)
        VStack {
          ProgressView()
          Text("復習カードを読み込み中...")
            .foregroundColor(.secondary)
            .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        //  .onAppear {
        //      // もし初期化時に cardsToReview が空だったら閉じるなどの処理
        //      if cardsToReview.isEmpty {
        //          print("⚠️ SpacedRepetitionLearningView: No cards to review on appear.")
        //          dismiss()
        //      }
        //  }
      }
    }
    .navigationTitle("復習セッション")
    .navigationBarTitleDisplayMode(.inline)
    .navigationBarItems(leading: Button("終了") { dismiss() })  // 途中終了用
    // .interactiveDismissDisabled() // 必要であれば下スワイプでの終了を無効化
  }

  // --- SM-2 アルゴリズムに基づいた更新処理 (簡易版) ---
  // 詳細はアルゴリズムの仕様を参照してください
  func processAnswer(quality: Int, card: WordCard) {
    // quality: ユーザーの回答の質 (0-5) SM-2では3以上が正解
    //           今回は簡易的に 1:難しい, 3:普通, 5:簡単 とする

    // ガード: quality が想定外の値なら何もしない
    guard quality >= 0 else {  // SM-2では0-5の範囲だが、ここでは負でないことを確認
      print("Error: Invalid quality value: \(quality)")
      return
    }

    if quality < 3 {
      // 間違い or 難しい場合: 間隔をリセット
      card.interval = 1  // 次の復習は1日後
      // SM-2 では連続正解回数(repetitions)もリセットする
    } else {
      // 正解した場合: 新しい間隔とEaseFactorを計算
      if card.interval == 0 {  // 最初のレビューの場合
        card.interval = 1
      } else if card.interval == 1 {  // 2回目のレビューの場合
        card.interval = 6  // SM-2のデフォルトでは6日後
      } else {  // 3回目以降のレビューの場合
        // 新しい間隔 = 前回の間隔 * EaseFactor
        let newInterval = round(Double(card.interval) * card.easeFactor)
        card.interval = Int(max(1, newInterval))  // 最低1日以上
      }

      // EaseFactorの更新: 簡単なほど値が大きくなる
      // EF' = EF + [0.1 - (5 - q) * (0.08 + (5 - q) * 0.02)]
      // q は 0-5 の評価値
      let easeFactorDelta =
        (0.1 - (5.0 - Double(quality)) * (0.08 + (5.0 - Double(quality)) * 0.02))
      card.easeFactor = max(1.3, card.easeFactor + easeFactorDelta)  // EaseFactorの最小値は1.3
    }

    // 次の復習日を計算 (現在時刻を基準にする)
    let now = Date()
    // interval日後の午前0時を次の復習日とする (日付単位で管理)
    if let nextDate = Calendar.current.date(byAdding: .day, value: card.interval, to: now) {
      card.nextReviewDate = Calendar.current.startOfDay(for: nextDate)
    } else {
      // 計算失敗時のフォールバック (例: 3日後)
      card.nextReviewDate = Calendar.current.date(byAdding: .day, value: 3, to: now)
      print("Error calculating next review date, setting fallback.")
    }

    card.lastReviewedAt = now  // 最終レビュー日時を更新

    // status の更新ロジック (例)
    if quality < 3 {
      card.status = .learning  // 間違えたら学習中に戻す
    } else if card.interval > 30 {  // 例えば30日以上の間隔になったら習得済みとする
      card.status = .mastered
    } else {
      card.status = .learning
    }

    // 変更を永続化 (SwiftDataは自動保存が多いが、念のため)
    // do {
    //     try modelContext.save()
    // } catch {
    //     print("Failed to save card update: \(error)")
    // }

    // 次のカードへ (アニメーションのために少し遅延)
    goToNextCard()
  }

  // 次のカードへ進む
  private func goToNextCard() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {  // 少し遅延させて更新を反映
      if currentIndex + 1 < cardsToReview.count {
        withAnimation(.easeIn(duration: 0.2)) {  // 切り替えアニメーション
          currentIndex += 1
          showBack = false  // 次のカードは表面から
        }
      } else {
        // 全てのカードが終了
        withAnimation {
          showCompletion = true
        }
      }
    }
  }

  private func triggerHapticFeedback() {
    let generator = UIImpactFeedbackGenerator(style: .heavy)
    generator.prepare()
    generator.impactOccurred()
    print("motion")
  }

}



// SRS評価ボタンのスタイル (再掲)
struct SRSButtonStyle: ButtonStyle {
  let color: Color
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.headline)
      .padding(.vertical, 12)
      .frame(maxWidth: .infinity)
      .foregroundColor(.white)
      .background(color)
      .cornerRadius(8)
      .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
      .shadow(
        color: .black.opacity(0.1), radius: configuration.isPressed ? 1 : 3,
        y: configuration.isPressed ? 1 : 2)
  }
}

// --- プレビュー ---
#Preview("Spaced Repetition Learning View") {
  NavigationView {  // Preview 用に NavigationView でラップ
    // PreviewContainerのヘルパーを使って復習カードを取得
    SpacedRepetitionLearningView(cardsToReview: PreviewContainer.sampleCardsForReview())
  }
  // プレビュー用にコンテナとコンテキストを設定
  .modelContainer(PreviewContainer.previewInMemoryWithLinkedData)
  // .environment(\.modelContext, PreviewContainer.previewInMemoryWithLinkedData.mainContext) // この行は通常不要
}

#Preview("Spaced Repetition Learning View (Empty)") {
  NavigationView {
    SpacedRepetitionLearningView(cardsToReview: [])  // 空の配列でテスト
  }
  .modelContainer(PreviewContainer.previewInMemoryWithLinkedData)
}
