// Cursor_Test/Views/Learning/SpacedRepetitionLearningView.swift

import SwiftData
import SwiftUI

// 分散学習用の学習画面
struct SpacedRepetitionLearningView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext
  @State var cardsToReview: [WordCard]

  @State private var currentIndex: Int = 0
  @State private var showBack: Bool = false
  @State private var showCompletion: Bool = false

  var body: some View {
    ZStack {
      // 背景グラデーション
      LinearGradient(
        colors: [
          Color(uiColor: .systemBackground),
          Color.orange.opacity(0.05),
        ],
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()

      if showCompletion {
        completionView
      } else if currentIndex < cardsToReview.count {
        let currentCard = cardsToReview[currentIndex]

        VStack(spacing: 0) {
          // プログレスバー
          progressBar
            .padding(.horizontal, 20)
            .padding(.top, 8)

          Spacer()

          // フラッシュカード
          flashCard(for: currentCard)

          Spacer()

          // SRS評価ボタン
          if showBack {
            srsButtons(for: currentCard)
              .transition(
                .asymmetric(
                  insertion: .scale.combined(with: .opacity),
                  removal: .opacity
                ))
          } else {
            Color.clear.frame(height: 140)
          }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showBack)
      } else {
        loadingView
      }
    }
    .navigationTitle("復習セッション")
    .navigationBarTitleDisplayMode(.inline)
    .navigationBarItems(leading: Button("終了") { dismiss() })
  }

  // MARK: - プログレスバー
  private var progressBar: some View {
    VStack(spacing: 8) {
      HStack {
        Text("\(currentIndex + 1) / \(cardsToReview.count)")
          .font(.caption)
          .fontWeight(.medium)
          .foregroundStyle(.secondary)

        Spacer()

        Text("\(Int(Double(currentIndex) / Double(max(cardsToReview.count, 1)) * 100))%")
          .font(.caption)
          .fontWeight(.bold)
          .foregroundStyle(.orange)
      }

      GeometryReader { geometry in
        ZStack(alignment: .leading) {
          RoundedRectangle(cornerRadius: 4)
            .fill(Color.gray.opacity(0.15))
            .frame(height: 6)

          RoundedRectangle(cornerRadius: 4)
            .fill(
              LinearGradient(
                colors: [.orange, .red.opacity(0.8)],
                startPoint: .leading,
                endPoint: .trailing
              )
            )
            .frame(
              width: max(
                0,
                geometry.size.width * CGFloat(currentIndex) / CGFloat(max(cardsToReview.count, 1))),
              height: 6
            )
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentIndex)
        }
      }
      .frame(height: 6)
    }
  }

  // MARK: - フラッシュカード
  private func flashCard(for card: WordCard) -> some View {
    ZStack {
      RoundedRectangle(cornerRadius: 24)
        .fill(Color(uiColor: .systemBackground))
        .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 10)
        .overlay(
          RoundedRectangle(cornerRadius: 24)
            .stroke(
              LinearGradient(
                colors: showBack
                  ? [.blue.opacity(0.5), .purple.opacity(0.5)]
                  : [.orange.opacity(0.4), .red.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              ),
              lineWidth: 2
            )
        )

      VStack(spacing: 16) {
        // 表/裏ラベル
        HStack {
          Text(showBack ? "裏面" : "表面")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
              Capsule()
                .fill(showBack ? Color.blue : Color.orange)
            )

          Spacer()

          // 単語帳名
          if let wordbook = card.wordbook {
            Text(wordbook.title)
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)

        Spacer()

        // メインテキスト
        Text(showBack ? card.backText : card.frontText)
          .font(.system(size: 36, weight: .bold, design: .rounded))
          .minimumScaleFactor(0.4)
          .lineLimit(nil)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 24)

        Spacer()

        // タップヒント
        if !showBack {
          VStack(spacing: 4) {
            Image(systemName: "hand.tap.fill")
              .font(.system(size: 20))
              .foregroundStyle(.secondary)
            Text("タップして裏面を表示")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          .padding(.bottom, 20)
        }
      }
    }
    .frame(height: 320)
    .padding(.horizontal, 24)
    .contentShape(Rectangle())
    .onTapGesture {
      withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
        showBack.toggle()
      }
    }
  }

  // MARK: - SRS評価ボタン
  private func srsButtons(for card: WordCard) -> some View {
    VStack(spacing: 12) {
      Text("この単語の習熟度は？")
        .font(.subheadline)
        .foregroundStyle(.secondary)

      HStack(spacing: 12) {
        // 難しい
        SRSButton(
          title: "難しい",
          icon: "xmark",
          colors: [.red, .orange.opacity(0.8)],
          action: {
            processAnswer(quality: 1, card: card)
          }
        )

        // 普通
        SRSButton(
          title: "普通",
          icon: "minus",
          colors: [.orange, .yellow.opacity(0.8)],
          action: {
            processAnswer(quality: 3, card: card)
          }
        )

        // 簡単
        SRSButton(
          title: "簡単",
          icon: "checkmark",
          colors: [.green, .teal.opacity(0.8)],
          action: {
            processAnswer(quality: 5, card: card)
          }
        )
      }
    }
    .padding(.horizontal, 20)
    .padding(.bottom, 40)
  }

  // MARK: - 完了画面
  private var completionView: some View {
    VStack(spacing: 24) {
      // アイコン
      ZStack {
        Circle()
          .fill(
            LinearGradient(
              colors: [.green.opacity(0.2), .teal.opacity(0.1)],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .frame(width: 120, height: 120)

        Image(systemName: "checkmark.seal.fill")
          .font(.system(size: 56))
          .foregroundStyle(
            LinearGradient(
              colors: [.green, .teal],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
      }

      VStack(spacing: 8) {
        Text("復習完了！")
          .font(.largeTitle)
          .fontWeight(.bold)

        Text("お疲れ様でした！\n今日の復習が完了しました。")
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
      }

      // 統計
      HStack(spacing: 20) {
        completionStat(
          value: "\(cardsToReview.count)", label: "復習したカード", icon: "rectangle.stack.fill",
          color: .blue)
      }
      .padding(.top, 8)

      Button {
        dismiss()
      } label: {
        HStack(spacing: 8) {
          Image(systemName: "xmark.circle.fill")
          Text("閉じる")
        }
        .font(.headline)
        .foregroundStyle(.white)
        .padding(.vertical, 14)
        .padding(.horizontal, 40)
        .background(
          LinearGradient(
            colors: [.blue, .purple.opacity(0.8)],
            startPoint: .leading,
            endPoint: .trailing
          )
        )
        .clipShape(Capsule())
        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
      }
      .padding(.top, 16)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private func completionStat(value: String, label: String, icon: String, color: Color) -> some View
  {
    VStack(spacing: 4) {
      HStack(spacing: 4) {
        Image(systemName: icon)
          .font(.caption)
        Text(value)
          .font(.system(size: 24, weight: .bold, design: .rounded))
      }
      .foregroundStyle(color)

      Text(label)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .padding(.horizontal, 24)
    .padding(.vertical, 12)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(color.opacity(0.1))
    )
  }

  // MARK: - ローディングビュー
  private var loadingView: some View {
    VStack(spacing: 16) {
      ProgressView()
        .scaleEffect(1.2)
      Text("復習カードを読み込み中...")
        .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  // MARK: - SM-2 アルゴリズム処理
  func processAnswer(quality: Int, card: WordCard) {
    triggerHapticFeedback()

    guard quality >= 0 else {
      print("Error: Invalid quality value: \(quality)")
      return
    }

    if quality < 3 {
      card.interval = 1
    } else {
      if card.interval == 0 {
        card.interval = 1
      } else if card.interval == 1 {
        card.interval = 6
      } else {
        let newInterval = round(Double(card.interval) * card.easeFactor)
        card.interval = Int(max(1, newInterval))
      }

      let easeFactorDelta =
        (0.1 - (5.0 - Double(quality)) * (0.08 + (5.0 - Double(quality)) * 0.02))
      card.easeFactor = max(1.3, card.easeFactor + easeFactorDelta)
    }

    let now = Date()
    if let nextDate = Calendar.current.date(byAdding: .day, value: card.interval, to: now) {
      card.nextReviewDate = Calendar.current.startOfDay(for: nextDate)
    } else {
      card.nextReviewDate = Calendar.current.date(byAdding: .day, value: 3, to: now)
    }

    card.lastReviewedAt = now

    if quality < 3 {
      card.status = .learning
    } else if card.interval > 30 {
      card.status = .mastered
    } else {
      card.status = .learning
    }

    goToNextCard()
  }

  private func goToNextCard() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
      if currentIndex + 1 < cardsToReview.count {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
          currentIndex += 1
          showBack = false
        }
      } else {
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
  }
}

// MARK: - SRSボタンコンポーネント
struct SRSButton: View {
  let title: String
  let icon: String
  let colors: [Color]
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(spacing: 6) {
        ZStack {
          Circle()
            .fill(
              LinearGradient(
                colors: colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
            .frame(width: 52, height: 52)
            .shadow(color: colors[0].opacity(0.4), radius: 6, x: 0, y: 3)

          Image(systemName: icon)
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(.white)
        }

        Text(title)
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundStyle(.primary)
      }
      .frame(maxWidth: .infinity)
    }
    .buttonStyle(ScaleButtonStyle())
  }
}

// MARK: - プレビュー
#if DEBUG
  #Preview("Spaced Repetition Learning View") {
    NavigationView {
      SpacedRepetitionLearningView(cardsToReview: PreviewContainer.sampleCardsForReview())
    }
    .modelContainer(PreviewContainer.previewInMemoryWithLinkedData)
  }

  #Preview("Spaced Repetition Learning View (Empty)") {
    NavigationView {
      SpacedRepetitionLearningView(cardsToReview: [])
    }
    .modelContainer(PreviewContainer.previewInMemoryWithLinkedData)
  }
#endif
