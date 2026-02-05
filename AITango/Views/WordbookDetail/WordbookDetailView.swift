import SwiftData
import SwiftUI

struct WordbookDetailView: View {
  // @Bindable var wordbook: Wordbook // @Stateで管理するため変更
  @State var wordbook: Wordbook  // 変更を検知・反映しやすくするため @State に変更
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss  // 削除後の挙動などで使う可能性

  @State private var showingAddCardSheet = false
  @State private var searchText = ""
  @FocusState private var isSearchFocused: Bool

  // 表示用の単語カードリスト (ロード完了後に更新)
  @State private var loadedWordCards: [WordCard]? = nil

  // loadedWordCards を元にフィルタリング
  var filteredWordCards: [WordCard] {
    // loadedWordCards が nil (ロード未完了) の場合は空配列を返す
    guard let cards = loadedWordCards else { return [] }

    // まず作成日時でソート (元のロジックを維持)
    let sortedCards = cards.sorted { $0.createdAt < $1.createdAt }

    if searchText.isEmpty {
      return sortedCards
    } else {
      // 表面または裏面が検索テキストを含むものをフィルタリング
      return sortedCards.filter {
        $0.frontText.localizedCaseInsensitiveContains(searchText)
          || $0.backText.localizedCaseInsensitiveContains(searchText)
      }
    }
  }

  var body: some View {
    ZStack {
      if loadedWordCards == nil {
        // ロード中表示
        ProgressView("単語カードを読み込み中...")
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else if loadedWordCards?.isEmpty ?? true {
        // ロード後、データが空の場合の表示 (元のコードから復元)
        ContentUnavailableView {
          Label("単語カードがありません", systemImage: "square.stack.3d.up.slash.fill")
        } description: {
          Text("最初の単語カードを追加しましょう！")
        } actions: {
          Button("単語カードを追加") {
            showingAddCardSheet = true
          }
          .buttonStyle(.bordered)
        }
        .padding(.top, 40)  // 上部との間隔
      } else {
        // カードリスト表示 (常に存在させてビュー構造を安定化)
        ZStack(alignment: .bottomTrailing) {
          List {
            ForEach(filteredWordCards) { card in
              // 各カードをタップで編集画面へ
              if let originalCard = wordbook.words?.first(where: { $0.id == card.id }) {
                NavigationLink(destination: WordCardEditView(wordCard: originalCard)) {
                  WordCardRow(card: card)  // 表示は loaded/filtered のものでOK
                }
              } else {
                // 念のため、一致するカードが見つからない場合の表示
                WordCardRow(card: card)
                  .opacity(0.5)  // 見つからない場合は半透明にするなど
              }
            }
            .onDelete(perform: deleteWordCards)  // スワイプ削除
          }
          .listStyle(.insetGrouped)  // カードリストに適したスタイル
          .opacity(filteredWordCards.isEmpty && !searchText.isEmpty ? 0 : 1)

          NewCardAddButton(
            action: {
              showingAddCardSheet = true
            }, titleText: "New Card"
          )
          .padding(.bottom, 30)
          .padding(.trailing, 20)
        }

        // 検索結果なしの場合のオーバーレイ
        if filteredWordCards.isEmpty && !searchText.isEmpty {
          ContentUnavailableView.search(text: searchText)
            .padding(.top, 40)
        }
      }
    }
    .searchable(text: $searchText, prompt: "単語を検索")
    .searchFocused($isSearchFocused)
    .navigationTitle(wordbook.title)  // Wordbookのタイトルを表示
    // .toolbar {  // ツールバー (元のコードから復元)
    //   ToolbarItemGroup(placement: .navigationBarTrailing) {
    //     // カード追加ボタン
    //     Button {
    //       showingAddCardSheet = true
    //     } label: {
    //       Label("単語カードを追加", systemImage: "plus.circle.fill")
    //     }

    //   }
    // }
    .sheet(isPresented: $showingAddCardSheet) {  // カード追加シート
      // WordCardCreationView に渡す wordbook は @State のもの
      WordCardCreationView(wordbook: wordbook)
        // シートが閉じたときにカードリストを再読み込みする (重要)
        .onDisappear {
          Task {
            await loadAndSortCards()
          }
        }
    }
    // wordbook オブジェクト (の参照) またはその中の 'words' が変化した可能性を検知
    // .task(id: wordbook) や .task(id: wordbook.words?.count) などを試す
    .task(id: wordbook.words?.count) {  // カードの数が変わったら再ロードを試みる
      print("WordbookDetailView .task(id: wordbook.words?.count) triggered.")
      await loadAndSortCards()
    }
    // Viewが表示された時に初期ロード
    .onAppear {
      print("WordbookDetailView onAppear. Initial load check.")
      if loadedWordCards == nil {
        Task {
          await loadAndSortCards()
        }
      }
    }

  }

  // カードをロードしてソートする非同期関数
  private func loadAndSortCards() async {
    print("Executing loadAndSortCards()...")
    // wordbook.words は SwiftData のリレーションシップなので、
    // アクセス時に遅延ロードされる可能性がある
    let currentCards = wordbook.words ?? []  // アクセスしてロードをトリガー
    // ソート
    let sortedCards = currentCards.sorted { $0.createdAt < $1.createdAt }
    // @State 変数を更新してUIを再描画
    loadedWordCards = sortedCards
    print("Cards loaded and sorted. Count: \(sortedCards.count)")
  }

  // カード削除処理
  private func deleteWordCards(offsets: IndexSet) {
    // offsets は filteredWordCards に対するインデックス
    let cardsToDeleteIDs = offsets.map { filteredWordCards[$0].id }

    withAnimation {
      // loadedWordCards からも即座に削除してUIに反映（任意だがスムーズに見えるかも）
      // loadedWordCards?.remove(atOffsets: offsets) // filteredWordbooks の offsets を使うのは危険なのでIDで検索
      loadedWordCards?.removeAll { cardsToDeleteIDs.contains($0.id) }

      // バックグラウンドでSwiftDataから削除
      Task {
        // modelContext を使って実際のデータを削除
        cardsToDeleteIDs.forEach { idToDelete in
          if let cardToDelete = wordbook.words?.first(where: { $0.id == idToDelete }) {
            // wordbook.words 配列から削除 (リレーションシップの更新)
            // wordbook.words?.removeAll { $0.id == idToDelete } // 配列操作ではなく delete で CASCADE する想定
            modelContext.delete(cardToDelete)
            print("Deleted card with ID: \(idToDelete)")
          }
        }
        // SwiftDataの変更が反映されるのを少し待つ（任意）
        // try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒待機など
        // 削除後に再ロード（しなくても .task(id: count) が検知するはずだが念のため）
        // await loadAndSortCards()
      }
    }
  }
}

// WordbookDetailView のプレビュー
#if DEBUG
  #Preview {
    // NavigationStack内でプレビュー
    NavigationStack {
      // PreviewContainerから取得した wordbook を @State として渡す
      // @State を持つViewのプレビューでは、初期値を直接渡す
      WordbookDetailView(wordbook: PreviewContainer.sampleWordbooks[1])  // データがあるものを選択
    }
    .modelContainer(PreviewContainer.previewInMemoryWithLinkedData)  // 関連データ付きコンテナ
  }

  #Preview("Empty Detail") {
    NavigationStack {
      WordbookDetailView(wordbook: PreviewContainer.sampleWordbooks[2])  // カードがないWordbook
    }
    .modelContainer(PreviewContainer.previewInMemoryWithLinkedData)
  }
#endif
