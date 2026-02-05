import SwiftData
import SwiftUI

struct WordbookDetailView: View {
  @State var wordbook: Wordbook
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss

  @State private var showingAddCardSheet = false
  @State private var searchText = ""
  @FocusState private var isSearchFocused: Bool

  // 表示用の単語カードリスト
  @State private var loadedWordCards: [WordCard]? = nil

  // フィルタリング
  var filteredWordCards: [WordCard] {
    guard let cards = loadedWordCards else { return [] }
    let sortedCards = cards.sorted { $0.createdAt < $1.createdAt }

    if searchText.isEmpty {
      return sortedCards
    } else {
      return sortedCards.filter {
        $0.frontText.localizedCaseInsensitiveContains(searchText)
          || $0.backText.localizedCaseInsensitiveContains(searchText)
      }
    }
  }

  // 統計情報
  private var masteredCount: Int {
    loadedWordCards?.filter { $0.status == .mastered }.count ?? 0
  }

  private var learningCount: Int {
    loadedWordCards?.filter { $0.status == .learning }.count ?? 0
  }

  private var newCount: Int {
    loadedWordCards?.filter { $0.status == .new }.count ?? 0
  }

  var body: some View {
    ZStack {
      if loadedWordCards == nil {
        loadingView
      } else if loadedWordCards?.isEmpty ?? true {
        emptyStateView
      } else {
        cardListView
      }
    }
    .navigationTitle(wordbook.title)
    .sheet(isPresented: $showingAddCardSheet) {
      WordCardCreationView(wordbook: wordbook)
        .onDisappear {
          Task {
            await loadAndSortCards()
          }
        }
    }
    .task(id: wordbook.words?.count) {
      await loadAndSortCards()
    }
    .onAppear {
      if loadedWordCards == nil {
        Task {
          await loadAndSortCards()
        }
      }
    }
  }

  // MARK: - ローディングビュー
  private var loadingView: some View {
    VStack(spacing: 16) {
      ProgressView()
        .scaleEffect(1.2)
      Text("単語カードを読み込み中...")
        .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  // MARK: - 空の状態ビュー
  private var emptyStateView: some View {
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

        Image(systemName: "rectangle.stack.badge.plus")
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
        Text("単語カードがありません")
          .font(.title3)
          .fontWeight(.bold)

        Text("最初の単語カードを追加して\n学習を始めましょう！")
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
      }

      Button {
        showingAddCardSheet = true
      } label: {
        HStack(spacing: 8) {
          Image(systemName: "plus.circle.fill")
          Text("単語カードを追加")
        }
        .font(.headline)
        .foregroundStyle(.white)
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(
          LinearGradient(
            colors: [.blue, Color(red: 0.4, green: 0.5, blue: 0.95)],
            startPoint: .leading,
            endPoint: .trailing
          )
        )
        .clipShape(Capsule())
        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.bottom, 60)
  }

  // MARK: - カードリストビュー
  private var cardListView: some View {
    ZStack(alignment: .bottomTrailing) {
      List {
        // 統計サマリーカード
        Section {
          statisticsSummaryCard
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 8, leading: 4, bottom: 4, trailing: 8))

        // カードリスト
        Section {
          ForEach(filteredWordCards) { card in
            NavigationLink(destination: WordCardEditView(wordCard: card)) {
              WordCardRow(card: card)
            }
          }
          .onDelete(perform: deleteWordCards)
        }
      }
      .listStyle(.insetGrouped)
      .searchable(text: $searchText, prompt: "単語を検索")
      .searchFocused($isSearchFocused)
      .opacity(filteredWordCards.isEmpty && !searchText.isEmpty ? 0 : 1)

      // 追加ボタン
      NewCardAddButton(
        action: {
          showingAddCardSheet = true
        }, titleText: "New Card"
      )
      .padding(.bottom, 30)
      .padding(.trailing, 20)

      // 検索結果なし
      if filteredWordCards.isEmpty && !searchText.isEmpty {
        ContentUnavailableView.search(text: searchText)
      }
    }
  }

  // MARK: - 統計サマリーカード
  private var statisticsSummaryCard: some View {
    HStack(spacing: 12) {
      statisticItem(
        value: "\(loadedWordCards?.count ?? 0)",
        label: "合計",
        icon: "rectangle.stack.fill",
        color: .blue
      )

      statisticItem(
        value: "\(masteredCount)",
        label: "習得",
        icon: "checkmark.circle.fill",
        color: .green
      )

      statisticItem(
        value: "\(learningCount)",
        label: "学習中",
        icon: "flame.fill",
        color: .orange
      )

      statisticItem(
        value: "\(newCount)",
        label: "新規",
        icon: "circle",
        color: .gray
      )
    }
    .padding(14)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(
          LinearGradient(
            colors: [.blue.opacity(0.08), .purple.opacity(0.04)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .overlay(
          RoundedRectangle(cornerRadius: 16)
            .stroke(Color.blue.opacity(0.15), lineWidth: 1)
        )
    )
  }

  // MARK: - 統計アイテム
  private func statisticItem(value: String, label: String, icon: String, color: Color) -> some View
  {
    VStack(spacing: 4) {
      HStack(spacing: 4) {
        Image(systemName: icon)
          .font(.caption2)
        Text(value)
          .font(.system(size: 18, weight: .bold, design: .rounded))
      }
      .foregroundStyle(color)

      Text(label)
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
  }

  // MARK: - データロード
  private func loadAndSortCards() async {
    let currentCards = wordbook.words ?? []
    let sortedCards = currentCards.sorted { $0.createdAt < $1.createdAt }
    loadedWordCards = sortedCards
  }

  // MARK: - カード削除
  private func deleteWordCards(offsets: IndexSet) {
    let cardsToDeleteIDs = offsets.map { filteredWordCards[$0].id }

    withAnimation {
      loadedWordCards?.removeAll { cardsToDeleteIDs.contains($0.id) }

      Task {
        cardsToDeleteIDs.forEach { idToDelete in
          if let cardToDelete = wordbook.words?.first(where: { $0.id == idToDelete }) {
            modelContext.delete(cardToDelete)
          }
        }
      }
    }
  }
}

// プレビュー
#if DEBUG
  #Preview {
    NavigationStack {
      WordbookDetailView(wordbook: PreviewContainer.sampleWordbooks[1])
    }
    .modelContainer(PreviewContainer.previewInMemoryWithLinkedData)
  }

  #Preview("Empty Detail") {
    NavigationStack {
      WordbookDetailView(wordbook: PreviewContainer.sampleWordbooks[2])
    }
    .modelContainer(PreviewContainer.previewInMemoryWithLinkedData)
  }
#endif
