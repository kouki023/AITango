import SwiftData
// Views/Learning/LearningTabView.swift
import SwiftUI

// 学習モードを定義するEnum
enum LearningMode: String, CaseIterable, Identifiable {
  case normal = "フラッシュカード"
  case spacedRepetition = "分散学習"
  var id: String { self.rawValue }
}

struct LearningTabView: View {

  @Environment(\.modelContext) private var modelContext
  @Query(sort: [SortDescriptor(\Wordbook.createdAt, order: .reverse)]) private var wordbooks:
    [Wordbook]
  @Query private var allCards: [WordCard]

  @State var selectedMode: LearningMode = .normal
  @Namespace private var learningTabNamespace

  @State private var showSpacedRepetitionLearning = false
  @State private var cardsForReviewSession: [WordCard] = []

  // 今日復習すべきカード
  var dueCardsToday: [WordCard] {
    let todayStart = Calendar.current.startOfDay(for: Date())
    return allCards.filter { card in
      guard let nextReviewDate = card.nextReviewDate else { return false }
      return nextReviewDate <= todayStart
    }
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        // セグメントコントロール
        CapsuleSegmentedControl(
          items: Array(LearningMode.allCases),
          selection: $selectedMode,
          namespace: learningTabNamespace,
          highlightColor: .blue,
          font: .subheadline
        )
        .padding(.horizontal)
        .padding(.top)
        .frame(maxHeight: 50)
        .padding(.bottom, 15)

        // 選択されたモードに応じたコンテンツ
        if selectedMode == .normal {
          normalModeContent
        } else {
          spacedRepetitionModeContent
        }
      }
      .navigationTitle("学習")
      .navigationDestination(for: Wordbook.self) { selectedWordbook in
        LearningView(wordbook: selectedWordbook)
      }
    }
  }

  // MARK: - 通常学習モード
  private var normalModeContent: some View {
    Group {
      if wordbooks.isEmpty {
        emptyStateView(
          icon: "book.closed",
          title: "学習できる単語帳がありません",
          description: "まずは「単語帳」タブから\n単語帳とカードを作成しましょう。"
        )
      } else {
        ScrollView {
          LazyVStack(spacing: 12) {
            ForEach(wordbooks) { wordbook in
              NavigationLink(value: wordbook) {
                LearningWordbookCard(wordbook: wordbook)
              }
              .buttonStyle(PlainButtonStyle())
              .disabled(wordbook.wordCount == 0)
              .opacity(wordbook.wordCount == 0 ? 0.5 : 1.0)
            }
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 12)
        }
      }
    }
  }

  // MARK: - 分散学習モード
  private var spacedRepetitionModeContent: some View {
    VStack(spacing: 0) {
      if dueCardsToday.isEmpty {
        emptyStateView(
          icon: "checkmark.seal.fill",
          title: "復習完了！",
          description: "今日復習するカードはありません。\n新しいカードを学習しましょう。"
        )
      } else {
        ScrollView {
          VStack(spacing: 16) {
            // サマリーカード
            reviewSummaryCard

            // 開始ボタン
            startReviewButton

            // 復習カードリスト
            reviewCardsList
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 12)
        }
      }
    }
    .sheet(isPresented: $showSpacedRepetitionLearning) {
      NavigationView {
        SpacedRepetitionLearningView(cardsToReview: cardsForReviewSession)
          .environment(\.modelContext, modelContext)
      }
    }
    .onChange(of: showSpacedRepetitionLearning) { _, newValue in
      if newValue {
        cardsForReviewSession = dueCardsToday.shuffled()
      }
    }
  }

  // MARK: - 復習サマリーカード
  private var reviewSummaryCard: some View {
    VStack(spacing: 16) {
      HStack {
        ZStack {
          Circle()
            .fill(
              LinearGradient(
                colors: [.orange.opacity(0.3), .red.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
            .frame(width: 56, height: 56)

          Image(systemName: "flame.fill")
            .font(.system(size: 26, weight: .semibold))
            .foregroundStyle(
              LinearGradient(
                colors: [.orange, .red],
                startPoint: .top,
                endPoint: .bottom
              )
            )
        }

        VStack(alignment: .leading, spacing: 4) {
          Text("今日の復習")
            .font(.headline)
            .foregroundStyle(.primary)

          Text("復習を続けて記憶を定着させましょう")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Spacer()
      }

      HStack(spacing: 20) {
        statItem(value: "\(dueCardsToday.count)", label: "カード", color: .orange)

        let wordbookCount = Set(dueCardsToday.compactMap { $0.wordbook?.id }).count
        statItem(value: "\(wordbookCount)", label: "単語帳", color: .blue)
      }
      .padding(.top, 4)
    }
    .padding(16)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(
          LinearGradient(
            colors: [.orange.opacity(0.1), .red.opacity(0.05)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .overlay(
          RoundedRectangle(cornerRadius: 16)
            .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
    )
    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
  }

  // MARK: - 統計アイテム
  private func statItem(value: String, label: String, color: Color) -> some View {
    VStack(spacing: 2) {
      Text(value)
        .font(.system(size: 28, weight: .bold, design: .rounded))
        .foregroundStyle(color)
      Text(label)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 12)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(color.opacity(0.08))
    )
  }

  // MARK: - 開始ボタン
  private var startReviewButton: some View {
    Button {
      showSpacedRepetitionLearning = true
    } label: {
      HStack(spacing: 10) {
        Image(systemName: "play.circle.fill")
          .font(.title2)
        Text("復習を開始する")
          .font(.headline)
          .fontWeight(.bold)
      }
      .foregroundStyle(.white)
      .padding(.vertical, 16)
      .frame(maxWidth: .infinity)
      .background(
        LinearGradient(
          colors: [.orange, .red.opacity(0.9)],
          startPoint: .leading,
          endPoint: .trailing
        )
      )
      .clipShape(RoundedRectangle(cornerRadius: 14))
      .shadow(color: .orange.opacity(0.4), radius: 10, x: 0, y: 5)
    }
  }

  // MARK: - 復習カードリスト
  private var reviewCardsList: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("復習カード一覧")
        .font(.subheadline)
        .fontWeight(.semibold)
        .foregroundStyle(.secondary)
        .padding(.leading, 4)

      ForEach(dueCardsToday) { card in
        ReviewCardRow(card: card)
      }
    }
  }

  // MARK: - 空の状態ビュー
  private func emptyStateView(icon: String, title: String, description: String) -> some View {
    VStack(spacing: 24) {
      ZStack {
        Circle()
          .fill(
            LinearGradient(
              colors: [.blue.opacity(0.2), .purple.opacity(0.1)],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .frame(width: 100, height: 100)

        Image(systemName: icon)
          .font(.system(size: 40))
          .foregroundStyle(
            LinearGradient(
              colors: [.blue, .purple],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
      }

      VStack(spacing: 8) {
        Text(title)
          .font(.title3)
          .fontWeight(.bold)

        Text(description)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.bottom, 60)
  }

  private func formattedDate(from date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy/MM/dd"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone.current
    return formatter.string(from: date)
  }
}

// MARK: - 学習用単語帳カード
struct LearningWordbookCard: View {
  @Bindable var wordbook: Wordbook

  private var progressColor: Color {
    let progress = wordbook.learningProgress
    if progress >= 0.8 {
      return Color(red: 0.2, green: 0.78, blue: 0.35)
    } else if progress >= 0.5 {
      return Color(red: 0.32, green: 0.64, blue: 0.95)
    } else if progress >= 0.3 {
      return Color(red: 1.0, green: 0.7, blue: 0.15)
    } else {
      return Color(red: 0.95, green: 0.4, blue: 0.45)
    }
  }

  var body: some View {
    HStack(spacing: 14) {
      // アイコン
      ZStack {
        Circle()
          .fill(progressColor.opacity(0.2))
          .frame(width: 50, height: 50)

        Image(systemName: "play.fill")
          .font(.system(size: 20, weight: .semibold))
          .foregroundStyle(progressColor)
      }

      // コンテンツ
      VStack(alignment: .leading, spacing: 6) {
        Text(wordbook.title)
          .font(.headline)
          .fontWeight(.bold)
          .foregroundStyle(.primary)
          .lineLimit(1)

        HStack(spacing: 16) {
          Label("\(wordbook.wordCount) カード", systemImage: "rectangle.stack")
            .font(.caption)
            .foregroundStyle(.secondary)

          Label("\(Int(wordbook.learningProgress * 100))%", systemImage: "chart.bar.fill")
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(progressColor)
        }
      }

      Spacer()

      // 矢印
      Image(systemName: "chevron.right")
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(.tertiary)
    }
    .padding(14)
    .background(
      RoundedRectangle(cornerRadius: 14)
        .fill(
          LinearGradient(
            colors: [progressColor.opacity(0.1), progressColor.opacity(0.03)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .overlay(
          RoundedRectangle(cornerRadius: 14)
            .stroke(progressColor.opacity(0.2), lineWidth: 1)
        )
    )
    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
  }
}

// MARK: - 復習カード行
struct ReviewCardRow: View {
  var card: WordCard

  var body: some View {
    HStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 4) {
        Text(card.frontText)
          .font(.subheadline)
          .fontWeight(.medium)
          .foregroundStyle(.primary)
          .lineLimit(1)

        if let wordbook = card.wordbook {
          Text(wordbook.title)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }

      Spacer()

      if let nextReview = card.nextReviewDate {
        Text(formattedDate(from: nextReview))
          .font(.caption)
          .fontWeight(.medium)
          .foregroundStyle(.orange)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(
            Capsule()
              .fill(Color.orange.opacity(0.12))
          )
      }
    }
    .padding(12)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(Color(uiColor: .systemBackground))
        .overlay(
          RoundedRectangle(cornerRadius: 12)
            .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
    )
  }

  private func formattedDate(from date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MM/dd"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter.string(from: date)
  }
}

// プレビュー
#if DEBUG
  #Preview("Learning Tab View") {
    LearningTabView(selectedMode: .normal)
      .modelContainer(PreviewContainer.previewInMemoryWithLinkedData)
  }

  #Preview("Spaced Repetition Mode") {
    LearningTabView(selectedMode: .spacedRepetition)
      .modelContainer(PreviewContainer.previewInMemoryWithLinkedData)
  }
#endif
