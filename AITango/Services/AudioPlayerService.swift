// AITango/Services/AudioPlayerService.swift

import AVFoundation
import NaturalLanguage

/// AVSpeechSynthesizer をラップした音声再生サービス
///
/// AVSpeechSynthesizer は stopSpeaking 後に speak を繰り返すと内部状態が壊れる
/// 既知の問題があるため、停止のたびにインスタンスを再生成して堅牢性を確保する
final class AudioPlayerService: NSObject, AVSpeechSynthesizerDelegate {

  /// synthesizer は停止するたびに再生成する（内部状態破損の回避）
  private var synthesizer: AVSpeechSynthesizer?

  /// 言語判定に使用する NLLanguageRecognizer
  private let languageRecognizer = NLLanguageRecognizer()

  /// 読み上げ完了時に呼ばれるコールバック
  var onFinishedSpeaking: (() -> Void)?

  /// 読み上げがキャンセルされた時に呼ばれるコールバック
  var onCancelledSpeaking: (() -> Void)?

  override init() {
    super.init()
    configureAudioSession()
  }

  // MARK: - Public API

  /// 指定テキストを読み上げる
  /// - Parameters:
  ///   - text: 読み上げるテキスト
  ///   - language: 言語コード（デフォルト: nil で自動判定）
  func speak(_ text: String, language: String? = nil) {
    // 前回のsynthesizerを破棄して新しいインスタンスを作成
    invalidateSynthesizer()
    let newSynthesizer = AVSpeechSynthesizer()
    newSynthesizer.delegate = self
    self.synthesizer = newSynthesizer

    let utterance = AVSpeechUtterance(string: text)
    utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
    utterance.pitchMultiplier = 1.0
    utterance.preUtteranceDelay = 0.3
    utterance.postUtteranceDelay = 0.5

    // 言語設定：明示指定 → 自動判定 → フォールバック(日本語)
    let resolvedLanguage = language ?? detectLanguage(for: text) ?? "ja-JP"
    utterance.voice = AVSpeechSynthesisVoice(language: resolvedLanguage)

    newSynthesizer.speak(utterance)
  }

  /// 再生を即座に停止し、synthesizer を無効化する
  func stop() {
    invalidateSynthesizer()
  }

  /// 現在再生中かどうか
  var isSpeaking: Bool {
    synthesizer?.isSpeaking ?? false
  }

  // MARK: - Private

  /// 現在の synthesizer を安全に停止・破棄する
  private func invalidateSynthesizer() {
    if let synth = synthesizer {
      synth.delegate = nil  // コールバックを切断
      if synth.isSpeaking || synth.isPaused {
        synth.stopSpeaking(at: .immediate)
      }
    }
    synthesizer = nil
  }

  // MARK: - Language Detection

  /// テキストの言語を NLLanguageRecognizer で自動判定する
  private func detectLanguage(for text: String) -> String? {
    languageRecognizer.reset()
    languageRecognizer.processString(text)

    guard let dominantLanguage = languageRecognizer.dominantLanguage else { return nil }
    return bcp47Code(for: dominantLanguage)
  }

  /// NLLanguage を AVSpeechSynthesisVoice が認識できる BCP 47 コードに変換
  private func bcp47Code(for language: NLLanguage) -> String {
    switch language {
    case .english: return "en-US"
    case .japanese: return "ja-JP"
    //case .chinese: return "zh-CN"
    case .korean: return "ko-KR"
    case .french: return "fr-FR"
    case .german: return "de-DE"
    case .spanish: return "es-ES"
    case .italian: return "it-IT"
    case .portuguese: return "pt-BR"
    case .russian: return "ru-RU"
    default:
      return language.rawValue
    }
  }

  // MARK: - Audio Session

  /// オーディオセッションを設定
  private func configureAudioSession() {
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
      try session.setActive(true)
    } catch {
      print("⚠️ AudioSession設定エラー: \(error.localizedDescription)")
    }
  }

  // MARK: - AVSpeechSynthesizerDelegate

  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance)
  {
    onFinishedSpeaking?()
  }

  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance)
  {
    onCancelledSpeaking?()
  }
}
