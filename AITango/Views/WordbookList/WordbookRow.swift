import SwiftData
import SwiftUI

struct WordbookRow: View {
  @Bindable var wordbook: Wordbook

  // 進捗に応じた色を返す
  private var progressColor: Color {
    let progress = wordbook.learningProgress
    if progress >= 0.8 {
      return Color(red: 0.2, green: 0.78, blue: 0.35)  // 緑
    } else if progress >= 0.5 {
      return Color(red: 0.32, green: 0.64, blue: 0.95)  // 青
    } else if progress >= 0.3 {
      return Color(red: 1.0, green: 0.7, blue: 0.15)  // オレンジ
    } else {
      return Color(red: 0.95, green: 0.4, blue: 0.45)  // 赤
    }
  }

  // グラデーション背景
  private var cardGradient: LinearGradient {
    LinearGradient(
      gradient: Gradient(colors: [
        progressColor.opacity(0.15),
        progressColor.opacity(0.05),
      ]),
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // ヘッダー: タイトルとステータスバッジ
      HStack(alignment: .top) {
        // 本のアイコン
        ZStack {
          Circle()
            .fill(progressColor.opacity(0.2))
            .frame(width: 44, height: 44)

          Image(systemName: "book.fill")
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(progressColor)
        }

        VStack(alignment: .leading, spacing: 4) {
          Text(wordbook.title)
            .font(.headline)
            .fontWeight(.bold)
            .foregroundStyle(.primary)
            .lineLimit(2)

          // 単語数
          HStack(spacing: 4) {
            Image(systemName: "textformat.abc")
              .font(.caption)
              .foregroundStyle(.secondary)
            Text("\(wordbook.wordCount)単語")
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }
        }

        Spacer()

        // 学習ステータスバッジ
        statusBadge
      }

      // 進捗セクション
      VStack(alignment: .leading, spacing: 6) {
        HStack {
          Text("学習進捗")
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(.secondary)

          Spacer()

          Text("\(Int(wordbook.learningProgress * 100))%")
            .font(.caption)
            .fontWeight(.bold)
            .foregroundStyle(progressColor)
        }

        // カスタム進捗バー
        GeometryReader { geometry in
          ZStack(alignment: .leading) {
            // 背景
            RoundedRectangle(cornerRadius: 4)
              .fill(Color.gray.opacity(0.15))
              .frame(height: 8)

            // 進捗
            RoundedRectangle(cornerRadius: 4)
              .fill(
                LinearGradient(
                  gradient: Gradient(colors: [
                    progressColor.opacity(0.8),
                    progressColor,
                  ]),
                  startPoint: .leading,
                  endPoint: .trailing
                )
              )
              .frame(width: max(0, geometry.size.width * wordbook.learningProgress), height: 8)
          }
        }
        .frame(height: 8)
      }
    }
    .padding(16)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(cardGradient)
        .overlay(
          RoundedRectangle(cornerRadius: 16)
            .stroke(progressColor.opacity(0.2), lineWidth: 1)
        )
    )
    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
  }

  // 学習ステータスバッジ
  private var statusBadge: some View {
    HStack(spacing: 4) {
      if let lastStudied = wordbook.lastStudiedAt {
        Image(systemName: "checkmark.circle.fill")
          .font(.caption2)
        Text(formattedDate(from: lastStudied))
          .font(.caption2)
      } else {
        Image(systemName: "exclamationmark.circle.fill")
          .font(.caption2)
        Text("未学習")
          .font(.caption2)
      }
    }
    .fontWeight(.medium)
    .foregroundStyle(wordbook.lastStudiedAt != nil ? Color.green : Color.orange)
    .padding(.horizontal, 10)
    .padding(.vertical, 6)
    .background(
      Capsule()
        .fill(
          (wordbook.lastStudiedAt != nil ? Color.green : Color.orange).opacity(0.12)
        )
    )
  }

  // YYYY/MM/DD 形式にフォーマットするヘルパー関数
  private func formattedDate(from date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MM/dd"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone.current
    return formatter.string(from: date)
  }
}

// プレビュー
#if DEBUG
  #Preview {
    List {
      WordbookRow(wordbook: PreviewContainer.sampleWordbooks[0])
      WordbookRow(wordbook: PreviewContainer.sampleWordbooks[1])
      WordbookRow(wordbook: PreviewContainer.sampleWordbooks[2])
    }
    .modelContainer(PreviewContainer.previewInMemory)
    .listStyle(.plain)
  }
#endif
