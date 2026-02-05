// Cursor_Test/Views/Learning/LearningView.swift

import SwiftData
import SwiftUI

struct LearningView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss
  @Bindable var wordbook: Wordbook

  @State private var cardsToLearn: [WordCard] = []
  @State private var currentIndex: Int = 0
  @State private var showBack: Bool = false
  @State private var cardOffset: CGFloat = 0
  @State private var cardOpacity: Double = 1

  // カードをロード
  private func loadCards() {
    guard let allCards = wordbook.words, !allCards.isEmpty else {
      dismiss()
      return
    }

    let filteredCards = allCards

    if filteredCards.isEmpty {
      dismiss()
    } else {
      cardsToLearn = filteredCards.shuffled()
      currentIndex = 0
      showBack = false
      wordbook.lastStudiedAt = Date()
    }
  }

  var body: some View {
    ZStack {
      // 背景グラデーション
      LinearGradient(
        colors: [
          Color(uiColor: .systemBackground),
          Color.blue.opacity(0.05),
        ],
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()

      if currentIndex < cardsToLearn.count {
        let currentCard = cardsToLearn[currentIndex]

        VStack(spacing: 0) {
          // プログレスバー
          progressBar
            .padding(.horizontal, 20)
            .padding(.top, 8)

          Spacer()

          // フラッシュカード
          flashCard(for: currentCard)
            .offset(y: cardOffset)
            .opacity(cardOpacity)

          Spacer()

          // ボタンエリア
          if showBack {
            actionButtons(for: currentCard)
              .transition(
                .asymmetric(
                  insertion: .scale.combined(with: .opacity),
                  removal: .opacity
                ))
          } else {
            // ボタン分のスペースを確保
            Color.clear.frame(height: 100)
          }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showBack)

      } else {
        loadingView
      }
    }
    .navigationTitle("フラッシュカード")
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      if cardsToLearn.isEmpty {
        loadCards()
      }
    }
  }

  // MARK: - プログレスバー
  private var progressBar: some View {
    VStack(spacing: 8) {
      HStack {
        Text("\(currentIndex + 1) / \(cardsToLearn.count)")
          .font(.caption)
          .fontWeight(.medium)
          .foregroundStyle(.secondary)

        Spacer()

        Text("\(Int(Double(currentIndex) / Double(max(cardsToLearn.count, 1)) * 100))%")
          .font(.caption)
          .fontWeight(.bold)
          .foregroundStyle(.blue)
      }

      GeometryReader { geometry in
        ZStack(alignment: .leading) {
          RoundedRectangle(cornerRadius: 4)
            .fill(Color.gray.opacity(0.15))
            .frame(height: 6)

          RoundedRectangle(cornerRadius: 4)
            .fill(
              LinearGradient(
                colors: [.blue, .purple.opacity(0.8)],
                startPoint: .leading,
                endPoint: .trailing
              )
            )
            .frame(
              width: max(
                0, geometry.size.width * CGFloat(currentIndex) / CGFloat(max(cardsToLearn.count, 1))
              ),
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
      // カード背景
      RoundedRectangle(cornerRadius: 24)
        .fill(Color(uiColor: .systemBackground))
        .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 10)
        .overlay(
          RoundedRectangle(cornerRadius: 24)
            .stroke(
              LinearGradient(
                colors: showBack
                  ? [.blue.opacity(0.5), .purple.opacity(0.5)]
                  : [.green.opacity(0.4), .blue.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              ),
              lineWidth: 2
            )
        )

      // カードコンテンツ
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
                .fill(showBack ? Color.blue : Color.green)
            )

          Spacer()
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
    .frame(height: 350)
    .padding(.horizontal, 24)
    .contentShape(Rectangle())
    .onTapGesture {
      withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
        showBack.toggle()
      }
    }
  }

  // MARK: - アクションボタン
  private func actionButtons(for card: WordCard) -> some View {
    HStack(spacing: 16) {
      // まだボタン
      Button {
        markAsLearning(card: card)
        triggerHapticFeedback()
        goToNextCard()
      } label: {
        VStack(spacing: 6) {
          ZStack {
            Circle()
              .fill(
                LinearGradient(
                  colors: [.orange, .red.opacity(0.8)],
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                )
              )
              .frame(width: 60, height: 60)
              .shadow(color: .orange.opacity(0.4), radius: 8, x: 0, y: 4)

            Image(systemName: "flame.fill")
              .font(.system(size: 24, weight: .semibold))
              .foregroundStyle(.white)
          }

          Text("まだ")
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.primary)
        }
      }
      .buttonStyle(ScaleButtonStyle())

      Spacer()

      // 覚えたボタン
      Button {
        markAsMastered(card: card)
        triggerHapticFeedback()
        goToNextCard()
      } label: {
        VStack(spacing: 6) {
          ZStack {
            Circle()
              .fill(
                LinearGradient(
                  colors: [.green, .teal.opacity(0.8)],
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                )
              )
              .frame(width: 60, height: 60)
              .shadow(color: .green.opacity(0.4), radius: 8, x: 0, y: 4)

            Image(systemName: "checkmark")
              .font(.system(size: 24, weight: .bold))
              .foregroundStyle(.white)
          }

          Text("覚えた")
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.primary)
        }
      }
      .buttonStyle(ScaleButtonStyle())
    }
    .padding(.horizontal, 60)
    .padding(.bottom, 40)
  }

  // MARK: - ローディングビュー
  private var loadingView: some View {
    VStack(spacing: 16) {
      ProgressView()
        .scaleEffect(1.2)
      Text("学習するカードを準備中...")
        .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .onAppear {
      loadCards()
    }
  }

  // MARK: - アクション
  private func markAsLearning(card: WordCard) {
    card.status = .learning
    card.lastReviewedAt = Date()
  }

  private func markAsMastered(card: WordCard) {
    card.status = .mastered
    card.lastReviewedAt = Date()
  }

  private func goToNextCard() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      if currentIndex + 1 < cardsToLearn.count {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
          currentIndex += 1
          showBack = false
        }
      } else {
        wordbook.lastStudiedAt = Date()
        dismiss()
      }
    }
  }

  private func triggerHapticFeedback() {
    let generator = UIImpactFeedbackGenerator(style: .heavy)
    generator.prepare()
    generator.impactOccurred()
  }
}

// MARK: - スケールボタンスタイル
struct ScaleButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
      .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
  }
}

// プレビュー
#if DEBUG
  #Preview {
    NavigationStack {
      LearningView(wordbook: PreviewContainer.sampleWordbooks[0])
    }
    .modelContainer(PreviewContainer.previewInMemoryWithLinkedData)
  }
#endif
