// AITango/Services/NotificationManager.swift
// 分散学習タスクのローカル通知を管理するマネージャー

import Foundation
import SwiftData
import UserNotifications

final class NotificationManager: ObservableObject {
  static let shared = NotificationManager()
  private init() {}

  // MARK: - UserDefaults キー
  private let isEnabledKey = "notification.isEnabled"
  private let hourKey = "notification.hour"
  private let minuteKey = "notification.minute"

  // MARK: - 設定プロパティ
  /// 通知が有効かどうか（デフォルト: true）
  var isEnabled: Bool {
    get {
      // 初回起動時はキーが存在しないため true をデフォルトにする
      if UserDefaults.standard.object(forKey: isEnabledKey) == nil {
        return true
      }
      return UserDefaults.standard.bool(forKey: isEnabledKey)
    }
    set {
      UserDefaults.standard.set(newValue, forKey: isEnabledKey)
      objectWillChange.send()
    }
  }

  /// 通知時刻（時）（デフォルト: 9）
  var notificationHour: Int {
    get {
      if UserDefaults.standard.object(forKey: hourKey) == nil {
        return 9
      }
      return UserDefaults.standard.integer(forKey: hourKey)
    }
    set {
      UserDefaults.standard.set(newValue, forKey: hourKey)
      objectWillChange.send()
    }
  }

  /// 通知時刻（分）（デフォルト: 0）
  var notificationMinute: Int {
    get {
      if UserDefaults.standard.object(forKey: minuteKey) == nil {
        return 0
      }
      return UserDefaults.standard.integer(forKey: minuteKey)
    }
    set {
      UserDefaults.standard.set(newValue, forKey: minuteKey)
      objectWillChange.send()
    }
  }

  /// 通知時刻を Date として取得・設定するためのヘルパー
  var notificationTime: Date {
    get {
      var components = DateComponents()
      components.hour = notificationHour
      components.minute = notificationMinute
      return Calendar.current.date(from: components) ?? Date()
    }
    set {
      let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
      notificationHour = components.hour ?? 9
      notificationMinute = components.minute ?? 0
    }
  }

  // MARK: - 通知許可のリクエスト
  /// ユーザーに通知許可を求める
  func requestPermission(completion: @escaping (Bool) -> Void = { _ in }) {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
      granted, error in
      DispatchQueue.main.async {
        if let error = error {
          print("通知許可リクエストエラー: \(error.localizedDescription)")
        }
        completion(granted)
      }
    }
  }

  // MARK: - 通知のスケジュール
  /// 復習タスクがある日にローカル通知を予約する
  /// 期限切れのカードは今日に繰り越して集計する
  /// - Parameter cards: 全てのWordCard（nextReviewDateを元に判定）
  func scheduleReviewNotifications(cards: [WordCard]) {
    let center = UNUserNotificationCenter.current()

    // 既存の通知を全てキャンセル
    center.removeAllPendingNotificationRequests()

    // 通知が無効なら何もしない
    guard isEnabled else { return }

    let today = Calendar.current.startOfDay(for: Date())
    var reviewCountByDate: [Date: Int] = [:]

    for card in cards {
      guard let nextReviewDate = card.nextReviewDate else { continue }
      let reviewDay = Calendar.current.startOfDay(for: nextReviewDate)

      if reviewDay <= today {
        // 期限切れ（過去の日付）のカードは今日に繰り越す
        reviewCountByDate[today, default: 0] += 1
      } else {
        // 未来の日付はそのまま集計
        reviewCountByDate[reviewDay, default: 0] += 1
      }
    }

    // 今日の通知時刻が既に過ぎているか判定
    let now = Date()
    var notificationTimeToday = Calendar.current.startOfDay(for: now)
    notificationTimeToday =
      Calendar.current.date(
        bySettingHour: notificationHour, minute: notificationMinute, second: 0,
        of: notificationTimeToday
      ) ?? notificationTimeToday
    let todayTimePassed = now > notificationTimeToday

    // 日付順にソートし、iOS上限の64件まで通知を予約
    let sortedDates = reviewCountByDate.keys.sorted()
    let maxNotifications = 64
    var scheduledCount = 0

    for date in sortedDates {
      guard let cardCount = reviewCountByDate[date], scheduledCount < maxNotifications else {
        break
      }

      // 今日かつ通知時刻が既に過ぎている場合はスキップ
      if date == today && todayTimePassed {
        print("⏭️ 今日の通知時刻は既に過ぎているためスキップ（\(cardCount)枚）")
        continue
      }

      scheduleNotification(for: date, cardCount: cardCount)
      scheduledCount += 1
    }

    print("📅 \(scheduledCount) 件の復習通知をスケジュールしました")
  }

  /// 指定日の指定時刻にローカル通知を予約する
  private func scheduleNotification(for date: Date, cardCount: Int) {
    let content = UNMutableNotificationContent()
    content.title = "復習の時間です 📚"
    content.body = "今日は\(cardCount)枚のカードの復習があります。復習して記憶を定着させましょう！"
    content.sound = .default

    // 指定日の指定時刻にトリガー
    var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: date)
    dateComponents.hour = notificationHour
    dateComponents.minute = notificationMinute

    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

    // ユニークなIDを生成（日付ベース）
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd"
    let dateString = formatter.string(from: date)
    let identifier = "review_notification_\(dateString)"

    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

    UNUserNotificationCenter.current().add(request) { error in
      if let error = error {
        print("通知スケジュールエラー: \(error.localizedDescription)")
      }
    }
  }

  // MARK: - 通知のキャンセル
  /// 全ての予約済み通知をキャンセルする
  func cancelAllNotifications() {
    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    print("🔕 全ての復習通知をキャンセルしました")
  }
}
