// AITango/ViewModels/AudioPlayerViewModel.swift

import Foundation
import SwiftUI

/// 音声読み上げに使用する言語
enum SpeechLanguage: String, CaseIterable, Identifiable {
  case english = "en-US"
  case japanese = "ja-JP"
  case korean = "ko-KR"
  case french = "fr-FR"
  case german = "de-DE"
  case spanish = "es-ES"
  case italian = "it-IT"
  case portuguese = "pt-BR"
  case russian = "ru-RU"

  var id: String { rawValue }

  /// 表示用ラベル
  var displayName: String {
    switch self {
    case .english: return "英語"
    case .japanese: return "日本語"
    case .korean: return "韓国語"
    case .french: return "フランス語"
    case .german: return "ドイツ語"
    case .spanish: return "スペイン語"
    case .italian: return "イタリア語"
    case .portuguese: return "ポルトガル語"
    case .russian: return "ロシア語"
    }
  }
}

/// 音声再生機能の ViewModel（MVVM パターン）
/// プレイリスト形式でカードの表→裏を順に読み上げる
@Observable
final class AudioPlayerViewModel {

  // MARK: - UserDefaults キー
  private static let frontLanguageKey = "audioPlayer.frontLanguage"
  private static let backLanguageKey = "audioPlayer.backLanguage"

  // MARK: - 再生状態

  enum PlaybackState {
    case idle  // 待機中（未選択 or 一時停止中）
    case playing  // 再生中
    case finished  // 全カード再生完了
  }

  /// 表/裏 どちらを読み上げ中か
  enum ReadingSide {
    case front
    case back
  }

  // MARK: - Published プロパティ

  /// 現在の再生状態
  var playbackState: PlaybackState = .idle

  /// 選択中の単語帳
  var selectedWordbook: Wordbook?

  /// 再生対象のカードリスト
  var cards: [WordCard] = []

  /// 現在再生中のカードインデックス
  var currentIndex: Int = 0

  /// 現在読んでいる面（表 or 裏）
  var currentSide: ReadingSide = .front

  /// 表面の言語設定（UserDefaults で永続化）
  var frontLanguage: SpeechLanguage {
    didSet { UserDefaults.standard.set(frontLanguage.rawValue, forKey: Self.frontLanguageKey) }
  }

  /// 裏面の言語設定（UserDefaults で永続化）
  var backLanguage: SpeechLanguage {
    didSet { UserDefaults.standard.set(backLanguage.rawValue, forKey: Self.backLanguageKey) }
  }

  // MARK: - Private

  private let audioService = AudioPlayerService()

  /// 連打防止用フラグ
  private var isProcessingToggle = false

  // MARK: - Computed

  /// 現在再生中のカード（安全にアクセス）
  var currentCard: WordCard? {
    guard currentIndex >= 0, currentIndex < cards.count else { return nil }
    return cards[currentIndex]
  }

  /// 進捗テキスト（例: "3 / 10"）
  var progressText: String {
    guard !cards.isEmpty else { return "0 / 0" }
    return "\(currentIndex + 1) / \(cards.count)"
  }

  /// 進捗率（0.0 〜 1.0）
  var progressValue: Double {
    guard !cards.isEmpty else { return 0.0 }
    // 裏面読み上げ中は半分進んだ扱い
    let base = Double(currentIndex) / Double(cards.count)
    let half = 0.5 / Double(cards.count)
    return currentSide == .back ? base + half : base
  }

  /// 再生中かどうか
  var isPlaying: Bool {
    playbackState == .playing
  }

  // MARK: - Init

  init() {
    // UserDefaults から言語設定を復元（デフォルト: 表=英語、裏=日本語）
    let savedFront = UserDefaults.standard.string(forKey: Self.frontLanguageKey)
    let savedBack = UserDefaults.standard.string(forKey: Self.backLanguageKey)
    self.frontLanguage = SpeechLanguage(rawValue: savedFront ?? "") ?? .english
    self.backLanguage = SpeechLanguage(rawValue: savedBack ?? "") ?? .japanese

    setupCallbacks()
  }

  // MARK: - Public API

  /// 単語帳を選択してカードを読み込む
  func selectWordbook(_ wordbook: Wordbook) {
    // 再生中なら停止
    stopCompletely()

    selectedWordbook = wordbook
    cards = wordbook.words?.sorted(by: { $0.createdAt < $1.createdAt }) ?? []
    currentIndex = 0
    currentSide = .front
    playbackState = .idle
  }

  /// 再生/一時停止をトグルする
  func togglePlayPause() {
    // 連打防止: 処理中なら無視
    guard !isProcessingToggle else { return }
    isProcessingToggle = true

    switch playbackState {
    case .playing:
      // 再生中 → 一時停止（現在位置を保持したまま停止）
      audioService.stop()
      playbackState = .idle

    case .idle:
      // 一時停止/待機中 → 現在位置から再生再開
      guard !cards.isEmpty else {
        isProcessingToggle = false
        return
      }
      playbackState = .playing
      speakCurrent()

    case .finished:
      // 完了 → 最初から再生
      currentIndex = 0
      currentSide = .front
      playbackState = .playing
      speakCurrent()
    }

    // 短い遅延後にフラグをリセット（連打防止）
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
      self?.isProcessingToggle = false
    }
  }

  /// 単語帳選択をクリアする
  func clearSelection() {
    stopCompletely()
    selectedWordbook = nil
    cards = []
    currentIndex = 0
    currentSide = .front
  }

  // MARK: - Private

  /// 完全停止（位置もリセット）
  private func stopCompletely() {
    audioService.stop()
    playbackState = .idle
  }

  /// AudioPlayerService のコールバックを設定
  private func setupCallbacks() {
    audioService.onFinishedSpeaking = { [weak self] in
      DispatchQueue.main.async {
        self?.onSpeechFinished()
      }
    }

    audioService.onCancelledSpeaking = { [weak self] in
      DispatchQueue.main.async {
        // キャンセル時は何もしない（stop()で状態管理済み）
        _ = self
      }
    }
  }

  /// 現在のカード・面を読み上げる
  private func speakCurrent() {
    guard let card = currentCard, playbackState == .playing else { return }

    let text: String
    switch currentSide {
    case .front:
      text = card.frontText
    case .back:
      text = card.backText
    }

    // 空テキストの場合はスキップ
    guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      onSpeechFinished()
      return
    }

    // 現在の面に応じた言語を指定して読み上げ
    let language = currentSide == .front ? frontLanguage.rawValue : backLanguage.rawValue
    audioService.speak(text, language: language)
  }

  /// 読み上げ完了後の処理（次の面またはカードへ進む）
  private func onSpeechFinished() {
    guard playbackState == .playing else { return }

    switch currentSide {
    case .front:
      // 表→裏へ
      currentSide = .back
      speakCurrent()

    case .back:
      // 裏→次のカードの表へ
      currentIndex += 1
      currentSide = .front

      if currentIndex >= cards.count {
        // 全カード再生完了
        playbackState = .finished
      } else {
        speakCurrent()
      }
    }
  }
}
