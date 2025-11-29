//
//  NotificationServiceProtocol.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 29.11.2025.
//
//  MARK: Overview — Обзор
//  A lightweight abstraction over UNUserNotificationCenter to schedule local notifications.
//  Лёгкая абстракция над UNUserNotificationCenter для планирования локальных уведомлений.
//

import Foundation

// MARK: - LocalNotificationRequest — Simple request model / Простая модель запроса уведомления
/// Minimal model to schedule a local notification (relative to "now").
/// Минимальная модель для планирования локального уведомления (относительно «сейчас»).
public struct LocalNotificationRequest: Equatable, Hashable {

    // MARK: Identity — Идентификатор
    /// Unique identifier to allow cancel/replace later.
    /// Уникальный идентификатор для последующей отмены/пере‑планирования.
    public let id: String

    // MARK: Content — Содержимое
    /// Notification title.
    /// Заголовок уведомления.
    public let title: String
    /// Notification body text.
    /// Текст уведомления.
    public let body: String

    // MARK: Trigger — Триггер
    /// Fire time interval in seconds from now (must be > 0).
    /// Время до срабатывания в секундах от текущего момента (должно быть > 0).
    public let timeInterval: TimeInterval

    // MARK: Options — Опции
    /// Whether to play default sound.
    /// Воспроизводить ли системный звук по умолчанию.
    public let playSound: Bool

    // MARK: - Init — Инициализация
    /// Creates a request with relative time-based trigger.
    /// Создаёт запрос с триггером по относительному времени.
    public init(
        id: String,
        title: String,
        body: String,
        timeInterval: TimeInterval,
        playSound: Bool = true
    ) {
        // iOS requires timeInterval > 0 — clamp to a minimal positive value.
        // iOS требует timeInterval > 0 — ограничиваем минимальным положительным значением.
        self.id = id
        self.title = title
        self.body = body
        self.timeInterval = max(0.1, timeInterval)
        self.playSound = playSound
    }
}

// MARK: - NotificationServiceProtocol — Abstraction over local notifications / Абстракция для локальных уведомлений
/// A protocol to request authorization and manage local notifications.
/// Протокол для запроса разрешений и управления локальными уведомлениями.
public protocol NotificationServiceProtocol: AnyObject {

    // MARK: Authorization — Разрешения
    /// Request user authorization for alerts, sounds, and badges.
    /// Запросить у пользователя разрешения на баннеры, звуки и бейджи.
    @discardableResult
    func requestAuthorization() async throws -> Bool

    // MARK: Scheduling — Планирование
    /// Schedule a list of local notifications.
    /// Запланировать список локальных уведомлений.
    func schedule(_ requests: [LocalNotificationRequest]) async throws

    // MARK: Cancellation — Отмена
    /// Cancel all pending notification requests.
    /// Отменить все ожидающие запросы уведомлений.
    func cancelAll() async

    // MARK: Debug/Introspection — Отладка/Инспекция
    /// Return identifiers of pending requests (for debug/testing).
    /// Вернуть идентификаторы ожидающих запросов (для отладки/тестов).
    func pendingRequestIdentifiers() async -> [String]
}
