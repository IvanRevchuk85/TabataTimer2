//
//  NotificationService.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 29.11.2025.
//
//  MARK: Overview — Обзор
//  A thin wrapper around UNUserNotificationCenter for local notifications.
//  Тонкая обёртка над UNUserNotificationCenter для локальных уведомлений.
//

import Foundation
import UserNotifications

// MARK: - UserNotificationCenterLike — Minimal abstraction for testing/injection
/// Minimal subset of UNUserNotificationCenter we use. Internal to the module.
protocol UserNotificationCenterLike {
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func add(_ request: UNNotificationRequest) async throws
    func removeAllPendingNotificationRequests()
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
    func getPendingNotificationRequests(completionHandler: @escaping ([UNNotificationRequest]) -> Void)
}

// MARK: - UNUserNotificationCenter conformance — Adapter
extension UNUserNotificationCenter: UserNotificationCenterLike {
    func add(_ request: UNNotificationRequest) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            self.add(request) { error in
                if let error {
                    cont.resume(throwing: error)
                } else {
                    cont.resume(returning: ())
                }
            }
        }
    }
}

// MARK: - NotificationService — Implementation / Реализация
/// Concrete implementation of NotificationServiceProtocol using UNUserNotificationCenter.
/// Конкретная реализация NotificationServiceProtocol на базе UNUserNotificationCenter.
public final class NotificationService: NotificationServiceProtocol {

    // MARK: Dependencies — Зависимости
    /// Notifications center instance (injected for testability).
    /// Экземпляр центра уведомлений (инжектируется для тестируемости).
    private let center: UserNotificationCenterLike

    // MARK: - Init — Инициализация
    /// Initialize with a notifications center (defaults to .current()).
    /// Инициализация с центром уведомлений (по умолчанию .current()).
    public init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    /// Internal initializer for tests to inject a custom center-like dependency.
    /// Внутренний инициализатор для тестов, позволяющий инжектировать зависимость, похожую на центр.
    init(centerLike: UserNotificationCenterLike) {
        self.center = centerLike
    }

    // MARK: - Authorization — Разрешения
    /// Request authorization for alerts, sounds, and badges.
    /// Запросить разрешения на баннеры, звуки и бейджи.
    @discardableResult
    public func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    // MARK: - Scheduling — Планирование
    /// Schedule a batch of local notifications using time interval triggers.
    /// Запланировать пакет локальных уведомлений с триггерами по интервалу времени.
    public func schedule(_ requests: [LocalNotificationRequest]) async throws {
        guard !requests.isEmpty else { return }

        // Remove pending requests with the same identifiers to avoid duplicates.
        // Удаляем ожидающие запросы с теми же идентификаторами, чтобы избежать дублей.
        let ids = requests.map { $0.id }
        center.removePendingNotificationRequests(withIdentifiers: ids)

        // Add each request.
        // Добавляем каждый запрос.
        for req in requests {
            let content = UNMutableNotificationContent()
            content.title = req.title
            content.body = req.body
            if req.playSound {
                content.sound = .default
            }

            // Use relative time trigger — simpler and reliable for timers.
            // Используем триггер по относительному времени — проще и надёжнее для таймеров.
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: req.timeInterval, repeats: false)

            let request = UNNotificationRequest(
                identifier: req.id,
                content: content,
                trigger: trigger
            )

            try await center.add(request)
        }
    }

    // MARK: - Cancellation — Отмена
    /// Cancel all pending notification requests.
    /// Отменить все ожидающие запросы уведомлений.
    public func cancelAll() async {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - Debug/Introspection — Отладка/Инспекция
    /// Fetch identifiers of pending requests (useful for debugging/testing).
    /// Получить идентификаторы ожидающих запросов (полезно для отладки/тестов).
    public func pendingRequestIdentifiers() async -> [String] {
        await withCheckedContinuation { continuation in
            center.getPendingNotificationRequests { pending in
                continuation.resume(returning: pending.map { $0.identifier })
            }
        }
    }
}
