import SwiftData
import SwiftUI

struct WordbookListView: View {
  @Environment(\.modelContext) private var modelContext
  @Query(sort: [SortDescriptor(\Wordbook.createdAt, order: .reverse)]) private var wordbooks:
    [Wordbook]
  @State private var showingAddWordbookSheet: Bool = false
  @State private var searchText: String = ""
  @FocusState private var isSearchFocused: Bool

  // 名前編集用のState
  @State private var showingRenameAlert: Bool = false
  @State private var wordbookToRename: Wordbook?
  @State private var newWordbookName: String = ""

  // 検索テキストに基づいてフィルタリング
  var filteredWordbooks: [Wordbook] {
    if searchText.isEmpty {
      return wordbooks
    } else {
      return wordbooks.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
  }

  var body: some View {
    NavigationStack {
      ZStack {
        if wordbooks.isEmpty {
          emptyStateView
        } else {
          // リストビューは常に存在させる（ビュー構造を安定化）
          wordbookListView
            .opacity(filteredWordbooks.isEmpty && !searchText.isEmpty ? 0 : 1)

          // 検索結果なしの場合のオーバーレイ
          if filteredWordbooks.isEmpty && !searchText.isEmpty {
            ContentUnavailableView.search(text: searchText)
          }
        }
      }
      .searchable(text: $searchText, prompt: "単語帳を検索")
      .searchFocused($isSearchFocused)
      .navigationTitle("Word Book")
      .sheet(isPresented: $showingAddWordbookSheet) {
        WordbookCreationView()
      }
      .alert("単語帳の名前を変更", isPresented: $showingRenameAlert) {
        TextField("新しい名前", text: $newWordbookName)
        Button("キャンセル", role: .cancel) {
          wordbookToRename = nil
          newWordbookName = ""
        }
        Button("変更") {
          renameWordbook()
        }
      } message: {
        Text("新しい名前を入力してください")
      }
    }
  }

  // 空の状態ビュー
  private var emptyStateView: some View {
    ZStack(alignment: .bottomTrailing) {
      VStack(spacing: 24) {
        // イラスト的なアイコン
        ZStack {
          Circle()
            .fill(
              LinearGradient(
                gradient: Gradient(colors: [
                  Color.blue.opacity(0.2),
                  Color.purple.opacity(0.1),
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
            .frame(width: 120, height: 120)

          Image(systemName: "books.vertical.fill")
            .font(.system(size: 50))
            .foregroundStyle(
              LinearGradient(
                colors: [.blue, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
        }

        VStack(spacing: 8) {
          Text("単語帳がありません")
            .font(.title2)
            .fontWeight(.bold)

          Text("最初の単語帳を作成して\n学習を始めましょう！")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }

        Button {
          showingAddWordbookSheet = true
        } label: {
          HStack(spacing: 8) {
            Image(systemName: "plus.circle.fill")
            Text("単語帳を作成")
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

      NewCardAddButton(
        action: {
          showingAddWordbookSheet = true
        }, titleText: "New book"
      )
      .padding(.bottom, 30)
      .padding(.trailing, 20)
    }
  }

  // 単語帳リストビュー
  private var wordbookListView: some View {
    ZStack(alignment: .bottomTrailing) {
      ScrollView {
        LazyVStack(spacing: 12) {
          ForEach(filteredWordbooks) { wordbook in
            NavigationLink(destination: WordbookDetailView(wordbook: wordbook)) {
              WordbookRow(wordbook: wordbook)
            }
            .buttonStyle(PlainButtonStyle())
            .contextMenu {
              Button {
                wordbookToRename = wordbook
                newWordbookName = wordbook.title
                showingRenameAlert = true
              } label: {
                Label("名前を変更", systemImage: "pencil")
              }

              Button(role: .destructive) {
                if let index = filteredWordbooks.firstIndex(where: { $0.id == wordbook.id }) {
                  deleteWordbooks(offsets: IndexSet(integer: index))
                }
              } label: {
                Label("削除", systemImage: "trash")
              }
            }
          }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
      }
      .searchable(text: $searchText, prompt: "単語帳を検索")

      NewCardAddButton(
        action: {
          showingAddWordbookSheet = true
        }, titleText: "New book"
      )
      .padding(.bottom, 30)
      .padding(.trailing, 20)
    }
  }

  // 削除処理
  private func deleteWordbooks(offsets: IndexSet) {
    withAnimation(.easeInOut(duration: 0.3)) {
      offsets.map { filteredWordbooks[$0] }.forEach(modelContext.delete)
    }
  }

  // 名前変更処理
  private func renameWordbook() {
    guard let wordbook = wordbookToRename else { return }
    let trimmedName = newWordbookName.trimmingCharacters(in: .whitespacesAndNewlines)
    if !trimmedName.isEmpty {
      withAnimation(.easeInOut(duration: 0.3)) {
        wordbook.title = trimmedName
      }
    }
    wordbookToRename = nil
    newWordbookName = ""
  }
}

// プレビュー
#if DEBUG
  #Preview("List With Data") {
    WordbookListView()
      .modelContainer(PreviewContainer.previewInMemory)
  }

  #Preview("List Empty") {
    WordbookListView()
      .modelContainer(PreviewContainer.empty)
  }
#endif
