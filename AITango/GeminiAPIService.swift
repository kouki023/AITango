// Cursor_Test/Services/GeminiAPIService.swift
// (Services フォルダを新規作成して配置すると整理しやすいです)

import Foundation
import GoogleGenerativeAI // Google AI SDK をインポート

// APIキーを Info.plist から安全に読み込むヘルパー関数
func getAPIKey() -> String? {
    guard let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
          let xml = FileManager.default.contents(atPath: path),
          let plist = try? PropertyListSerialization.propertyList(from: xml, options: .mutableContainersAndLeaves, format: nil) as? [String: Any],
          let apiKey = plist["GeminiAPIKey"] as? String else {
        print("⚠️ Gemini API Key not found in Info.plist. Please add a key named 'GeminiAPIKey'.")
        return nil
    }
    // キーが空でないかもチェック (任意)
    guard !apiKey.isEmpty else {
        print("⚠️ Gemini API Key found in Info.plist but it is empty.")
        return nil
    }
    return apiKey
}

// 単語ペアを表現するシンプルな構造体
struct GeneratedWordPair: Identifiable {
    let id = UUID()
    let english: String
    let japanese: String
}

@MainActor // UI更新に関連するため MainActor を指定
class GeminiAPIService {

    // Result型で成功/失敗を表現
    enum GenerationError: Error, LocalizedError {
        case apiKeyMissing
        case apiError(Error)
        case parsingError(String)
        case unexpectedResponse

        var errorDescription: String? {
            switch self {
            case .apiKeyMissing:
                return "Gemini APIキーが見つかりません。Info.plistを確認してください。"
            case .apiError(let underlyingError):
                return "APIリクエストに失敗しました: \(underlyingError.localizedDescription)"
            case .parsingError(let details):
                return "APIレスポンスの解析に失敗しました: \(details)"
            case .unexpectedResponse:
                return "予期しないAPIレスポンスを受け取りました。"
            }
        }
    }

    private var generativeModel: GenerativeModel?

    init() {
        // APIキーを読み込んでモデルを初期化
        guard let apiKey = getAPIKey() else {
            // APIキーがない場合は、モデルを初期化しない
            print("Error: API Key is missing. GeminiAPIService cannot be initialized.")
            // 必要に応じてエラー処理を追加 (例: ユーザーに通知)
            return
        }
        // モデルを設定 (例: gemini-1.5-flash) - 必要に応じてモデル名を変更してください
        self.generativeModel = GenerativeModel(name: "gemini-2.0-flash", apiKey: apiKey)
    }

    func generateWords(count: Int, theme: String, frontContent: String, backContent: String) async -> Result<[GeneratedWordPair], GenerationError> {
        // モデルが初期化されていない場合はエラーを返す
        guard let model = generativeModel else {
            return .failure(.apiKeyMissing)
        }

        // APIに送信するプロンプトを作成
        let prompt = 
        """
        「\(theme)」に関して、\(frontContent)と\(backContent)をセットで\(count)個生成してください。
        形式は必ず「\(frontContent):\(backContent)」とし、各ペアは改行で区切ってください。
        例:
        Apple:りんご
        Book:本
        """
        // """
        // 「\(theme)」に関する英単語を\(count)個、その日本語訳とセットで生成してください。
        // 形式は必ず「英単語:日本語訳」とし、各ペアは改行で区切ってください。
        // 例:
        // Apple:りんご
        // Book:本
        // """

        do {
            // Gemini API を呼び出し
            // stream: false で一度に全結果を取得
            let response = try await model.generateContent(prompt)

            // レスポンスを解析
            guard let text = response.text else {
                print("Error: API response text is nil.")
                return .failure(.unexpectedResponse)
            }

            print("--- Gemini API Response ---")
            print(text)
            print("-------------------------")


            // 改行で分割し、各行を解析
            let lines = text.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            var wordPairs: [GeneratedWordPair] = []

            for line in lines {
                // 空行はスキップ
                if line.isEmpty { continue }

                // ":" で分割
                let components = line.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                if components.count == 2 {
                    let englishWord = String(components[0])
                    let japaneseWord = String(components[1])
                    // 単語が空でないことを確認 (任意)
                    if !englishWord.isEmpty && !japaneseWord.isEmpty {
                         wordPairs.append(GeneratedWordPair(english: englishWord, japanese: japaneseWord))
                    } else {
                        print("Skipping line due to empty word: \(line)")
                    }
                } else {
                    // 予期しない形式の行はログに出力してスキップ
                    print("Warning: Could not parse line: \(line). Expected format 'English:Japanese'.")
                    // return .failure(.parsingError("予期しない形式の行がありました: \(line)")) // エラーにする場合
                }
            }

            // 生成されたペアが0件の場合も考慮 (任意)
            if wordPairs.isEmpty && !lines.isEmpty {
                print("Warning: No valid word pairs parsed from API response.")
                // return .failure(.parsingError("有効な単語ペアを解析できませんでした。")) // エラーにする場合
            }


            return .success(wordPairs)

        } catch {
            print("Error generating words: \(error)")
            return .failure(.apiError(error))
        }
    }
}
