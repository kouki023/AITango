import SwiftUI
import SwiftData

struct WordCardEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    // @Bindable で編集対象のカードを受け取る
    @Bindable var wordCard: WordCard

    // 編集用の一時的な状態変数 (直接 @Bindable を使う場合は不要な場合も)
    // @State private var frontText: String
    // @State private var backText: String
    // @State private var status: LearningStatus

    // 保存ボタンの有効/無効判定 (直接 wordCard を見る)
    var isSaveDisabled: Bool {
        wordCard.frontText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        wordCard.backText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /*
    // 初期化処理 (一時的な @State を使う場合)
    init(wordCard: WordCard) {
        self.wordCard = wordCard
        _frontText = State(initialValue: wordCard.frontText)
        _backText = State(initialValue: wordCard.backText)
        _status = State(initialValue: wordCard.status)
    }
     */

    var body: some View {
        NavigationStack {
            Form {
                Section("表面") {
                    // wordCardのプロパティに直接バインド
                    TextEditor(text: $wordCard.frontText)
                        .frame(minHeight: 100)
                }
                Section("裏面") {
                    TextEditor(text: $wordCard.backText)
                        .frame(minHeight: 100)
                }
                 Section("ステータス") {
                     // 学習ステータスを選択するPicker
                     Picker("学習状況", selection: $wordCard.status) {
                         // LearningStatusの全ケースをループ
                         ForEach(LearningStatus.allCases, id: \.self) { status in
                             Text(status.label).tag(status) // .label は表示用、.tag で実際の値を設定
                         }
                     }
                     .pickerStyle(.segmented) // セグメントスタイルで見やすく
                 }
                // ToDo: 画像、発音記号、タグなどの編集欄を追加
            }
            .navigationTitle("単語カードを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") { saveChanges() }
                     .disabled(isSaveDisabled)
                }
            }
            /*
             // 一時的な @State を使う場合、変更を wordCard に反映させる処理
             .onChange(of: frontText) { _, newValue in
                 wordCard.frontText = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
             }
             .onChange(of: backText) { _, newValue in
                 wordCard.backText = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
             }
             .onChange(of: status) { _, newValue in
                 wordCard.status = newValue
             }
             */
        }
    }

    private func saveChanges() {
        // @Bindable を使用している場合、変更は自動的に wordCard に反映されている
        // SwiftDataは変更を追跡しているので、通常は明示的な保存は不要

        // 必要であれば前後の空白を除去する処理を追加
        wordCard.frontText = wordCard.frontText.trimmingCharacters(in: .whitespacesAndNewlines)
        wordCard.backText = wordCard.backText.trimmingCharacters(in: .whitespacesAndNewlines)

        // Optional: 明示的な保存
        // do {
        //     try modelContext.save()
        // } catch {
        //     print("Failed to save card changes: \(error)")
        // }
        dismiss() // 画面を閉じる
    }
}

// プレビュー
#Preview {
    // 編集対象のカードを渡す
    WordCardEditView(wordCard: PreviewContainer.sampleCards[1])
        .modelContainer(PreviewContainer.previewInMemoryWithLinkedData) // 関連データ付きコンテナ
        // .modelContainer(previewContainer) // PreviewContainer.swift を使う場合
}