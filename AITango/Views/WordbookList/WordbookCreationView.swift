import SwiftData
import SwiftUI

struct WordbookCreationView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss
  @State private var wordbookTitle: String = ""
  @FocusState private var isTitleFocused: Bool

  var isSaveDisabled: Bool {
    wordbookTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        // ヘッダーイラスト
        VStack(spacing: 16) {
          ZStack {
            Circle()
              .fill(
                LinearGradient(
                  gradient: Gradient(colors: [
                    Color.blue.opacity(0.15),
                    Color.purple.opacity(0.1),
                  ]),
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                )
              )
              .frame(width: 80, height: 80)

            Image(systemName: "book.closed.fill")
              .font(.system(size: 36))
              .foregroundStyle(
                LinearGradient(
                  colors: [.blue, .purple],
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                )
              )
          }

          Text("新しい単語帳を作成")
            .font(.title3)
            .fontWeight(.semibold)
        }
        .padding(.top, 32)
        .padding(.bottom, 24)

        // 入力フォーム
        VStack(alignment: .leading, spacing: 8) {
          Text("タイトル")
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(.secondary)

          TextField("例: TOEIC英単語、日常会話フレーズ", text: $wordbookTitle)
            .font(.body)
            .padding(16)
            .background(
              RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
            )
            .overlay(
              RoundedRectangle(cornerRadius: 12)
                .stroke(
                  isTitleFocused ? Color.blue : Color.clear,
                  lineWidth: 2
                )
            )
            .focused($isTitleFocused)
        }
        .padding(.horizontal, 24)

        Spacer()

        // 保存ボタン
        Button {
          saveWordbook()
        } label: {
          HStack {
            Image(systemName: "checkmark.circle.fill")
            Text("作成する")
          }
          .font(.headline)
          .foregroundStyle(.white)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 16)
          .background(
            Group {
              if isSaveDisabled {
                Color.gray.opacity(0.4)
              } else {
                LinearGradient(
                  colors: [.blue, Color(red: 0.4, green: 0.5, blue: 0.95)],
                  startPoint: .leading,
                  endPoint: .trailing
                )
              }
            }
          )
          .clipShape(RoundedRectangle(cornerRadius: 14))
          .shadow(
            color: isSaveDisabled ? .clear : .blue.opacity(0.3),
            radius: 10,
            x: 0,
            y: 5
          )
        }
        .disabled(isSaveDisabled)
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
      }
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button {
            dismiss()
          } label: {
            Image(systemName: "xmark.circle.fill")
              .font(.title2)
              .foregroundStyle(.secondary)
          }
        }
      }
      .onAppear {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
          isTitleFocused = true
        }
      }
    }
  }

  private func saveWordbook() {
    let trimmedTitle = wordbookTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    let newWordbook = Wordbook(title: trimmedTitle)
    modelContext.insert(newWordbook)
    dismiss()
  }
}

// プレビュー
#if DEBUG
  #Preview {
    WordbookCreationView()
      .modelContainer(PreviewContainer.previewInMemory)
  }
#endif
