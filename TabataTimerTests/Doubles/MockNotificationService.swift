//
//  MockNotificationService.swift
//  TabataTimerTests
//
//  Created by Ivan Revchuk on 29.11.2025.
//
//  MARK: Overview — Обзор
//  A simple in-memory mock of NotificationServiceProtocol for unit tests.
//  Простой in‑memory мок NotificationServiceProtocol для модульных тестов.
//

import Foundation
@testable import TabataTimer

// MARK: - MockNotificationService — Mock / Мок
final class MockNotificationService: NotificationServiceProtocol {

    // MARK: Captured calls — Захваченные вызовы
    /// Last authorization result to return (configurable in tests).
    /// Результат авторизации, который вернёт мок (настраивается в тесте).
    var authorizationResultToReturn: Bool = true

    /// Whether requestAuthorization() was called.
    /// Был ли вызван requestAuthorization().
    private(set) var didRequestAuthorization: Bool = false

    /// All scheduled requests captured in order.
    /// Все запланированные запросы, захваченные по порядку.
    private(set) var scheduledRequests: [[LocalNotificationRequest]] = []

    /// Whether cancelAll() was called.
    /// Был ли вызван cancelAll().
    private(set) var didCancelAll: Bool = false

    /// Current pending identifiers (in-memory store).
    /// Текущие ожидающие идентификаторы (в памяти).
    private var pendingIds: Set<String> = []

    // MARK: - NotificationServiceProtocol
    @discardableResult
    func requestAuthorization() async throws -> Bool {
        didRequestAuthorization = true
        return authorizationResultToReturn
    }

    func schedule(_ requests: [LocalNotificationRequest]) async throws {
        // Save batch for assertions.
        // Сохраняем пачку для проверок.
        scheduledRequests.append(requests)

        // Emulate pending storage: add/replace by id.
        // Эмулируем pending‑хранилище: добавляем/заменяем по id.
        for r in requests {
            pendingIds.insert(r.id)
        }
    }

    func cancelAll() async {
        didCancelAll = true
        pendingIds.removeAll()
    }

    func pendingRequestIdentifiers() async -> [String] {
        Array(pendingIds)
    }

    // MARK: - Helpers for tests — Вспомогательные методы для тестов
    /// Reset captured state between tests.
    /// Сбросить захваченное состояние между тестами.
    func reset() {
        authorizationResultToReturn = true
        didRequestAuthorization = false
        scheduledRequests = []
        didCancelAll = false
        pendingIds.removeAll()
    }
}
