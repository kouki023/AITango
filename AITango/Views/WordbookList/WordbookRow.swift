import SwiftData
import SwiftUI

struct WordbookRow: View {
  // @Bindable を使うと View 内で直接 Wordbook のプロパティを変更できる場合に便利
  @Bindable var wordbook: Wordbook

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(wordbook.title)
            .font(.title3)  // 見出しスタイル
            .fontWeight(.bold)
            //.foregroundColor(.white) // Set title text color to white
            .padding(.horizontal)
            

      // 単語数と最終学習日を横並びで表示
      HStack {
        Label("\(wordbook.wordCount) 単語", systemImage: "list.bullet")
           //.foregroundColor(.white)// Set label text color to white
          
        Spacer()  // スペースで右寄せ
        if let lastStudied = wordbook.lastStudiedAt {

          Text("最終学習: \(formattedDate(from: lastStudied))")  // 日付のみ表示
            .font(.caption)  // フォントサイズを少し小さくする (任意)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)  // 左右の余白
            .padding(.vertical, 4)  // 上下の余白
            .background(
              RoundedRectangle(cornerRadius: 5)  // 角丸の長方形
                .fill(Color.green.opacity(0.6))  // 背景色 (薄いグレー)
            )
        } else {
          Text("未学習")
            .font(.caption)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
              RoundedRectangle(cornerRadius: 5)
                .fill(Color.orange.opacity(0.6))  // 未学習の場合も同様のスタイルを適用 (任意)
            )
        }
      }
      .padding(.horizontal)
      .font(.subheadline)  // 小さめの文字
      // .foregroundColor(.secondary) // Remove or comment out this line if all text in HStack should be white

      // 学習進捗バー
      ProgressView(value: wordbook.learningProgress)  // 計算プロパティを使用
        .progressViewStyle(.linear)
        .tint(.accentColor)  // アプリのアクセントカラーを使用
    }
      
    .padding(.vertical, 4)  // 上下の余白
//    .background(RoundedRectangle(cornerRadius: 10)
//    .fill(Color.black.opacity(0.1))
//    )
    
  }
        

  // YYYY/MM/DD 形式にフォーマットするヘルパー関数
  private func formattedDate(from date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy/MM/dd"  // フォーマットを指定
    formatter.locale = Locale(identifier: "en_US_POSIX")  // ロケールを固定 (任意)
    formatter.timeZone = TimeZone.current  // 現在のタイムゾーンを使用 (任意)
    return formatter.string(from: date)
  }


}

// プレビュー
#Preview {
  // Listの中に表示させる形でのプレビュー
  List {
    WordbookRow(wordbook: PreviewContainer.sampleWordbooks[0])
    WordbookRow(wordbook: PreviewContainer.sampleWordbooks[1])
    WordbookRow(wordbook: PreviewContainer.sampleWordbooks[2])
  }
  .modelContainer(PreviewContainer.previewInMemory)  // コンテナ設定を忘れずに
  // .modelContainer(previewContainer) // PreviewContainer.swift を使う場合
  .listStyle(.plain)  // プレビュー用のリストスタイル
}
