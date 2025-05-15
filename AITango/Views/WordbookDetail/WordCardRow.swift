import SwiftUI
import SwiftData

struct WordCardRow: View {
    let card: WordCard // 表示するカード

    var body: some View {
        HStack {
            // 表面と裏面を縦に表示
            VStack(alignment: .leading) {
                Text(card.frontText)
                    .font(.headline)
                Text(card.backText)
                    .font(.subheadline)
                    .foregroundColor(.gray) // 裏面は少し薄く
            }
            Spacer() // 右側にスペースを空ける

            // 学習ステータスアイコン表示
            Image(systemName: statusIcon(for: card.status))
                 .foregroundColor(statusColor(for: card.status))
                 .font(.subheadline) // アイコンサイズ調整
                 .padding(.leading, 5) // 左側に少し余白
        }
        .padding(.vertical, 4) // 上下の余白
    }

     // ステータスに応じたアイコン名を返すヘルパー
     private func statusIcon(for status: LearningStatus) -> String {
         switch status {
         case .new: return "circle" // 新規
         case .learning: return "flame.fill" // 学習中
         case .mastered: return "checkmark.circle.fill" // 習得済み
         }
     }

     // ステータスに応じた色を返すヘルパー
     private func statusColor(for status: LearningStatus) -> Color {
         switch status {
         case .new: return .gray
         case .learning: return .orange
         case .mastered: return .green
         }
     }
}

// プレビュー
#Preview {
    List { // リスト内での表示を確認
        WordCardRow(card: PreviewContainer.sampleCards[0])
        WordCardRow(card: PreviewContainer.sampleCards[1])
        WordCardRow(card: PreviewContainer.sampleCards[2])
    }
    .modelContainer(PreviewContainer.previewInMemory) // コンテナ設定
    // .modelContainer(previewContainer) // PreviewContainer.swift を使う場合
    .listStyle(.plain)
}