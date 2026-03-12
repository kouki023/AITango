import SwiftData
import SwiftUI

struct WordCardEditView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss
  @Bindable var wordCard: WordCard

  // 保存ボタンの有効/無効判定
  var isSaveDisabled: Bool {
    wordCard.frontText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      && wordCard.backText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  var body: some View {
    NavigationStack {
      ZStack {
        // 背景グラデーション
        LinearGradient(
          colors: [
            Color(uiColor: .systemBackground),
            Color.indigo.opacity(0.03),
          ],
          startPoint: .top,
          endPoint: .bottom
        )
        .ignoresSafeArea()

        ScrollView {
          VStack(spacing: 20) {
            // 表面カード
            editCard(
              title: "表面",
              subtitle: "英語・キーワードなど",
              icon: "textformat.abc",
              color: .blue,
              text: $wordCard.frontText,
              placeholder: "単語を入力..."
            )

            // 裏面カード
            editCard(
              title: "裏面",
              subtitle: "日本語訳・説明など",
              icon: "character.book.closed",
              color: .green,
              text: $wordCard.backText,
              placeholder: "意味を入力..."
            )

            // 学習ステータスカード
            statusCard

            Spacer(minLength: 40)
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 16)
        }
        // キーボードの外をタップして閉じる
        .onTapGesture {
          hideKeyboard()
        }
      }
      .navigationTitle("単語カードを編集")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("キャンセル") { dismiss() }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("保存") { saveChanges() }
            .fontWeight(.semibold)
            .disabled(isSaveDisabled)
        }
      }
    }
  }

  // MARK: - 編集カード
  private func editCard(
    title: String,
    subtitle: String,
    icon: String,
    color: Color,
    text: Binding<String>,
    placeholder: String
  ) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      // ヘッダー
      HStack {
        ZStack {
          Circle()
            .fill(color.opacity(0.15))
            .frame(width: 36, height: 36)

          Image(systemName: icon)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(color)
        }

        VStack(alignment: .leading, spacing: 2) {
          Text(title)
            .font(.headline)
            .foregroundStyle(.primary)
          Text(subtitle)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }

      // テキストエディタ
      TextEditor(text: text)
        .frame(minHeight: 100)
        .padding(12)
        .scrollContentBackground(.hidden)
        .background(
          RoundedRectangle(cornerRadius: 12)
            .fill(Color(uiColor: .systemGray6))
        )
        .overlay(
          RoundedRectangle(cornerRadius: 12)
            .stroke(color.opacity(0.3), lineWidth: 1)
        )
        .overlay(
          Group {
            if text.wrappedValue.isEmpty {
              Text(placeholder)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
                .allowsHitTesting(false)
            }
          },
          alignment: .topLeading
        )
    }
    .padding(16)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color(uiColor: .systemBackground))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    )
  }

  // MARK: - 学習ステータスカード
  private var statusCard: some View {
    VStack(alignment: .leading, spacing: 16) {
      // ヘッダー
      HStack {
        ZStack {
          Circle()
            .fill(Color.orange.opacity(0.15))
            .frame(width: 36, height: 36)

          Image(systemName: "chart.bar.fill")
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.orange)
        }

        VStack(alignment: .leading, spacing: 2) {
          Text("学習ステータス")
            .font(.headline)
            .foregroundStyle(.primary)
          Text("現在の習熟度を選択")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }

      // ステータスセレクター
      HStack(spacing: 8) {
        ForEach(LearningStatus.allCases, id: \.self) { status in
          statusButton(for: status)
        }
      }
    }
    .padding(16)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color(uiColor: .systemBackground))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    )
  }

  // MARK: - ステータスボタン
  private func statusButton(for status: LearningStatus) -> some View {
    let isSelected = wordCard.status == status
    let (color, icon) = statusStyle(for: status)

    return Button {
      withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
        wordCard.status = status
      }
    } label: {
      VStack(spacing: 6) {
        ZStack {
          Circle()
            .fill(isSelected ? color : Color(uiColor: .systemGray5))
            .frame(width: 44, height: 44)
            .shadow(color: isSelected ? color.opacity(0.4) : .clear, radius: 6, x: 0, y: 3)

          Image(systemName: icon)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(isSelected ? .white : .secondary)
        }

        Text(status.label)
          .font(.caption2)
          .fontWeight(isSelected ? .semibold : .regular)
          .foregroundStyle(isSelected ? color : .secondary)
      }
      .frame(maxWidth: .infinity)
    }
    .buttonStyle(.plain)
  }

  // MARK: - ステータススタイル
  private func statusStyle(for status: LearningStatus) -> (Color, String) {
    switch status {
    case .new:
      return (.gray, "circle")
    case .learning:
      return (.orange, "flame.fill")
    case .mastered:
      return (.green, "checkmark.circle.fill")
    }
  }

  // MARK: - 保存処理
  private func saveChanges() {
    wordCard.frontText = wordCard.frontText.trimmingCharacters(in: .whitespacesAndNewlines)
    wordCard.backText = wordCard.backText.trimmingCharacters(in: .whitespacesAndNewlines)
    dismiss()
  }

  // MARK: - キーボードを閉じる
  private func hideKeyboard() {
    UIApplication.shared.sendAction(
      #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
  }
}

// プレビュー
#if DEBUG
  #Preview {
    // 編集対象のカードを渡す
    WordCardEditView(wordCard: PreviewContainer.sampleCards[1])
      .modelContainer(PreviewContainer.previewInMemoryWithLinkedData)  // 関連データ付きコンテナ
    // .modelContainer(previewContainer) // PreviewContainer.swift を使う場合
  }
#endif
