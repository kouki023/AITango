import SwiftData
import SwiftUI

struct WordbookListView: View {
  @Environment(\.modelContext) private var modelContext
  // @Queryでデータを取得し、作成日時の降順でソート
  @Query(sort: [SortDescriptor(\Wordbook.createdAt, order: .reverse)]) private var wordbooks:
    [Wordbook]
  @State private var showingAddWordbookSheet: Bool = false
  @State private var searchText: String = ""
  //@State private var submittedSearchText: String = ""

  // 検索テキストに基づいてフィルタリング
  var filteredWordbooks: [Wordbook] {
    if searchText.isEmpty {
      return wordbooks
    } else {
      // 大文字小文字を区別せずにタイトルを検索
      return wordbooks.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
  }

  var body: some View {

    // NavigationStackで階層構造を管理
    NavigationStack {
      Group {  // 条件分岐のためにGroupを使用
        if wordbooks.isEmpty {
            ZStack(alignment: .bottomTrailing){
                // データが空の場合の表示
                ContentUnavailableView {
                    Label("単語帳がありません", systemImage: "book.closed.fill")
                } description: {
                    Text("最初の単語帳を作成しましょう！")
                } actions: {
                    Button(" WordBookを作成") {
                        showingAddWordbookSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                NewCardAddButton(action: {
                  showingAddWordbookSheet = true
                }, titleText: "New book")
                .padding(.bottom, 30)
                .padding(.trailing, 20)
                
                
            }
        } else if filteredWordbooks.isEmpty && !searchText.isEmpty {
          // 検索結果がない場合の表示
          ContentUnavailableView.search(text: searchText)
          .searchable(text: $searchText, prompt: "Word Bookを検索")
        } else {
        ZStack(alignment: .bottomTrailing) {

          // 単語帳リスト表示
          List {
            ForEach(filteredWordbooks) { wordbook in
              // 各行をタップで詳細画面へ遷移
                Section{
                    NavigationLink(destination: WordbookDetailView(wordbook: wordbook)) {
                        
                        WordbookRow(wordbook: wordbook)  // 各行のView
                        
                    }
                }
                
              // .listRowBackground(
              //   RoundedRectangle(cornerRadius: 20)  // 角丸の四角形
              //     // 背景色と透明度を設定 (例: 緑の半透明)
              //     .fill(Color.blue.opacity(0.7))
              //     // 上下に少し余白を追加してセル間にスペースを作る
              //     .padding(.vertical, 5)
              //     // 左右にも少し余白を追加 (任意)
              //     .padding(.horizontal, 8)
              // )
              // .listRowSeparator(.hidden)
              .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive) {
                  // 削除処理 (以前の例と同様に、対象を特定して削除関数を呼び出す)
                  if let index = filteredWordbooks.firstIndex(where: { $0.id == wordbook.id }) {
                    // wordbookToDelete = filteredWordbooks[index] // 確認アラートを使う場合
                    // showingDeleteConfirm = true             // 確認アラートを使う場合
                    deleteWordbooks(offsets: IndexSet(integer: index))  // 直接削除する場合
                  }
                  // または deleteWordCards の場合も同様
                  // if let index = filteredWordCards.firstIndex(where: { $0.id == card.id }) {
                  //     deleteWordCards(offsets: IndexSet(integer: index))
                  // }

                } label: {
                  // ここでボタンの見た目をカスタマイズ
                  Label {
                    Text("削除")
                      .font(.headline)  // フォント調整
                      .foregroundColor(.white)  // 文字色
                  } icon: {
                    Image(systemName: "trash.fill")
                      .foregroundColor(.white)  // アイコン色
                  }
                  .padding(.horizontal, 20)  // 横パディング
                  .padding(.vertical, 15)  // 縦パディング (高さを調整)
                  .background(
                    RoundedRectangle(cornerRadius: 10)  // 角丸の四角形
                      .fill(.red)  // 背景色
                  )
                }
                // .tint(.red) は Button 自体の色付けなので、label をカスタマイズする場合は不要になることが多い
              }

            }

            //.onDelete(perform: deleteWordbooks)  // スワイプ削除
          }
            
            
          .listStyle(.insetGrouped)  // リストのスタイル
          .searchable(text: $searchText, prompt: "Word Bookを検索")  // 検索バーを追加
          // .onSubmit(of: .search){
          //   submittedSearchText = searchText
          // }
          
          
          NewCardAddButton(action: {
            showingAddWordbookSheet = true
          }, titleText: "New book")
          .padding(.bottom, 30)
          .padding(.trailing, 20)

        }
        }
        
      }
      .navigationTitle("Word Book")  // ナビゲーションバーのタイトル
//      .toolbar {  // ツールバーアイテム
//        ToolbarItem(placement: .navigationBarTrailing) {
//          Button {
//            showingAddWordbookSheet = true  // 作成シート表示フラグを立てる
//          } label: {
//            Label("単語帳を追加", systemImage: "plus.circle.fill")
//              .font(.title2)
//          }
//        }
//      }

      .sheet(isPresented: $showingAddWordbookSheet) {  // モーダルシート表示
        WordbookCreationView()  // 単語帳作成Viewを表示
      }
    }
  }

  // 削除処理
  private func deleteWordbooks(offsets: IndexSet) {
    withAnimation {
      offsets.map { filteredWordbooks[$0] }.forEach(modelContext.delete)
    }
  }
}

// プレビュー
#if DEBUG
#Preview("List With Data") {
  WordbookListView()
    .modelContainer(PreviewContainer.previewInMemory)  // PreviewContainerを使用
  // .modelContainer(previewContainer) // PreviewContainer.swift を使う場合
}

#Preview("List Empty") {
  WordbookListView()
    .modelContainer(PreviewContainer.empty)  // 空のコンテナを使用
  // .modelContainer(previewContainerEmpty) // PreviewContainer.swift を使う場合
}
#endif
