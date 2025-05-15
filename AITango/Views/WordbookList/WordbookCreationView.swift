import SwiftUI
import SwiftData

struct WordbookCreationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss // シートを閉じるための環境変数
    @State private var wordbookTitle: String = "" // 入力されるタイトルを保持する状態変数

    var isSaveDisabled: Bool {
        // タイトルが空か空白文字のみの場合は保存ボタンを無効化
        wordbookTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form { // フォーム形式で入力欄を配置
                TextField("単語帳のタイトル", text: $wordbookTitle)
            }
            .navigationTitle("新しい単語帳")
            .navigationBarTitleDisplayMode(.inline) // タイトルをインライン表示
            .toolbar {
                // キャンセルボタン
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss() // シートを閉じる
                    }
                }
                // 保存ボタン
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveWordbook() // 保存処理を呼び出し
                    }
                    .disabled(isSaveDisabled) // 保存無効化の条件を適用
                }
            }
        }
    }

    // 保存処理
    private func saveWordbook() {
        let trimmedTitle = wordbookTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let newWordbook = Wordbook(title: trimmedTitle) // 新しいWordbookオブジェクトを作成
        modelContext.insert(newWordbook) // ModelContextに挿入 (SwiftDataがDB保存を管理)

        // Optional: エラーハンドリングを追加する場合
        // do {
        //     try modelContext.save() // 明示的に保存
        // } catch {
        //     print("Failed to save wordbook: \(error)")
        // }

        dismiss() // シートを閉じる
    }
}

// プレビュー
#Preview {
    WordbookCreationView()
        .modelContainer(PreviewContainer.previewInMemory) // コンテナ設定
        // .modelContainer(previewContainer) // PreviewContainer.swift を使う場合
}