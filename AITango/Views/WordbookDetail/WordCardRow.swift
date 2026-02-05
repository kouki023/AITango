import SwiftData
import SwiftUI

struct WordCardRow: View {
  let card: WordCard

  // ステータスに応じた色
  private var statusColor: Color {
    switch card.status {
    case .new: return Color.gray
    case .learning: return Color.orange
    case .mastered: return Color.green
    }
  }

  // ステータスに応じたアイコン
  private var statusIcon: String {
    switch card.status {
    case .new: return "circle"
    case .learning: return "flame.fill"
    case .mastered: return "checkmark.circle.fill"
    }
  }

  // ステータスに応じたラベル
  private var statusLabel: String {
    switch card.status {
    case .new: return "新規"
    case .learning: return "学習中"
    case .mastered: return "習得"
    }
  }

  var body: some View {
    HStack(spacing: 14) {
      // ステータスアイコン
      ZStack {
        Circle()
          .fill(statusColor.opacity(0.15))
          .frame(width: 44, height: 44)

        Image(systemName: statusIcon)
          .font(.system(size: 18, weight: .semibold))
          .foregroundStyle(statusColor)
      }

      // コンテンツ
      VStack(alignment: .leading, spacing: 4) {
        Text(card.frontText)
          .font(.headline)
          .fontWeight(.semibold)
          .foregroundStyle(.primary)
          .lineLimit(1)

        Text(card.backText)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
      .frame(height: 44, alignment: .leading)

      Spacer()

      // ステータスバッジ
      Text(statusLabel)
        .font(.caption2)
        .fontWeight(.medium)
        .foregroundStyle(statusColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
          Capsule()
            .fill(statusColor.opacity(0.12))
        )
    }
    .padding(.vertical, 8)
  }
}

// プレビュー
#if DEBUG
  #Preview {
    List {
      WordCardRow(card: PreviewContainer.sampleCards[0])
      WordCardRow(card: PreviewContainer.sampleCards[1])
      WordCardRow(card: PreviewContainer.sampleCards[2])
    }
    .modelContainer(PreviewContainer.previewInMemory)
    .listStyle(.plain)
  }
#endif
