//
//  NotificationServiceTests.swift
//  TabataTimerTests
//
//  Created by Ivan Revchuk on 29.11.2025.
//
//  MARK: Overview — Обзор
//  Unit tests for NotificationService using a fake center adapter.
//  Модульные тесты для NotificationService с фейковым адаптером центра.
//

import Foundation
import UserNotifications
@testable import TabataTimer
import Testing

// MARK: - FakeCenter — Test double / Тестовый двойник
/// In-memory fake center that mimics needed APIs.
/// Памятный фейк центра, имитирующий нужные API.
private final class FakeCenter: UserNotificationCenterLike {

    // Authorization
    var didRequestAuthorization = false
    var requestedOptions: UNAuthorizationOptions = []
    var authorizationResultToReturn: Bool = true
    var authorizationErrorToReturn: Error?

    // Pending requests store
    var pendingRequests: [UNNotificationRequest] = []

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        didRequestAuthorization = true
        requestedOptions = options
        if let error = authorizationErrorToReturn {
            throw error
        }
        return authorizationResultToReturn
    }

    func add(_ request: UNNotificationRequest) async throws {
        pendingRequests.append(request)
    }

    func removeAllPendingNotificationRequests() {
        pendingRequests.removeAll()
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        let ids = Set(identifiers)
        pendingRequests.removeAll { ids.contains($0.identifier) }
    }

    func getPendingNotificationRequests(completionHandler: @escaping ([UNNotificationRequest]) -> Void) {
        completionHandler(pendingRequests)
    }
}

@Suite("NotificationService tests — Тесты сервиса уведомлений")
struct NotificationServiceTests {

    @Test("requestAuthorization passes options and returns result — Запрос разрешений возвращает результат")
    func test_requestAuthorization_returnsResult() async throws {
        let fake = FakeCenter()

        let service = NotificationService(centerLike: fake)

        let granted = try await service.requestAuthorization()

        #expect(fake.didRequestAuthorization == true)
        #expect(fake.requestedOptions.contains(.alert))
        #expect(fake.requestedOptions.contains(.sound))
        #expect(fake.requestedOptions.contains(.badge))
        #expect(granted == true)
    }

    @Test("schedule adds requests with correct identifiers and content — Планирование добавляет корректные запросы")
    func test_schedule_addsRequestsWithCorrectIdentifiers() async throws {
        let fake = FakeCenter()
        let service = NotificationService(centerLike: fake)

        let reqs: [LocalNotificationRequest] = [
            .init(id: "id.1", title: "Work", body: "Go!", timeInterval: 2),
            .init(id: "id.2", title: "Rest", body: "Recover", timeInterval: 5, playSound: false)
        ]

        try await service.schedule(reqs)

        let pending = fake.pendingRequests
        #expect(pending.count == 2)

        // Явно укажем тип множеств
        let pendingIds: Set<String> = Set(pending.map { $0.identifier })
        let expectedIds: Set<String> = Set(["id.1", "id.2"])
        #expect(pendingIds == expectedIds)

        let titles: [String] = pending.map { $0.content.title }
        let bodies: [String] = pending.map { $0.content.body }
        #expect(titles == ["Work", "Rest"])
        #expect(bodies == ["Go!", "Recover"])

        // Явно приводим к Int без map(Int.init)
        let intervals: [Int] = pending.compactMap { ($0.trigger as? UNTimeIntervalNotificationTrigger)?.timeInterval }
            .map { Int($0) }
        #expect(intervals == [2, 5])
    }

    @Test("schedule replaces duplicates by identifier — Повторное планирование заменяет дубликаты по идентификатору")
    func test_schedule_replacesDuplicates() async throws {
        let fake = FakeCenter()
        let service = NotificationService(centerLike: fake)

        try await service.schedule([ .init(id: "same", title: "Work", body: "Go!", timeInterval: 3) ])
        #expect(fake.pendingRequests.count == 1)

        try await service.schedule([ .init(id: "same", title: "Rest", body: "Recover", timeInterval: 4) ])

        #expect(fake.pendingRequests.count == 1)
        #expect(fake.pendingRequests.first?.identifier == "same")
        #expect(fake.pendingRequests.first?.content.title == "Rest")
        let interval = (fake.pendingRequests.first?.trigger as? UNTimeIntervalNotificationTrigger)?.timeInterval
        #expect(Int(interval ?? -1) == 4)
    }

    @Test("cancelAll removes all pending requests — Отмена очищает все ожидающие запросы")
    func test_cancelAll_removesAllPending() async throws {
        let fake = FakeCenter()
        let service = NotificationService(centerLike: fake)

        try await service.schedule([
            .init(id: "a", title: "t1", body: "b1", timeInterval: 1),
            .init(id: "b", title: "t2", body: "b2", timeInterval: 2)
        ])
        #expect(fake.pendingRequests.count == 2)

        await service.cancelAll()
        #expect(fake.pendingRequests.isEmpty)
    }

    @Test("pendingRequestIdentifiers returns identifiers — Возвращает идентификаторы ожидающих запросов")
    func test_pendingRequestIdentifiers_returnsIds() async throws {
        let fake = FakeCenter()
        let service = NotificationService(centerLike: fake)

        try await service.schedule([
            .init(id: "x", title: "t", body: "b", timeInterval: 1),
            .init(id: "y", title: "t", body: "b", timeInterval: 2)
        ])

        // Явно укажем тип результата и множеств
        let ids: [String] = await service.pendingRequestIdentifiers()
        let actual: Set<String> = Set(ids)
        let expected: Set<String> = Set(["x", "y"])
        #expect(actual == expected)
    }
}

