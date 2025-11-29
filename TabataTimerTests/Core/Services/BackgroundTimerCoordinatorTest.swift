//
//  BackgroundTimerCoordinatorTest.swift
//  TabataTimerTests
//
//  Created by Ivan Revchuk on 29.11.2025.
//
//  MARK: Overview — Обзор
//  Unit tests for BackgroundTimerCoordinator: notification graph and reconciliation logic.
//  Модульные тесты для BackgroundTimerCoordinator: граф уведомлений и логика пересинхронизации.
//

import Foundation
@testable import TabataTimer
import Testing

@Suite("BackgroundTimerCoordinator tests — Тесты координатора фона")
struct BackgroundTimerCoordinatorTests {

    // MARK: - Helpers — Вспомогательные
    private func makeCoordinator(
        plan: [TabataInterval],
        startIndex: Int,
        startRemaining: Int,
        isRunning: Bool,
        fakeDate: FakeDateProvider,
        mock: MockNotificationService,
        onReconcile: @escaping (Int, Int, Bool) -> Void
    ) -> BackgroundTimerCoordinator {
        BackgroundTimerCoordinator(
            notifications: mock,
            planProvider: { plan },
            positionProvider: { (startIndex, startRemaining, isRunning) },
            dateProvider: fakeDate.closure(),
            onReconcile: onReconcile
        )
    }

    // MARK: - Scheduling tests — Планирование уведомлений

    @Test("Schedule builds phase-boundary requests from the middle of plan — Планирование от середины плана")
    func test_schedule_buildsPhaseBoundaryRequests_fromMiddleOfPlan() async throws {
        // Plan: prepare(3) → work(5) → rest(2) → work(5) → finished
        let plan = SamplePlans.simplePlan()

        // We are in rest(2) with remaining = 2 (i.e., at index 2), timer is running.
        let startIndex = 2
        let startRemaining = 2
        let isRunning = true

        let fakeDate = FakeDateProvider(start: Date(timeIntervalSince1970: 1000))
        let mock = MockNotificationService()
        var reconciled: (Int, Int, Bool)?
        let coordinator = makeCoordinator(
            plan: plan,
            startIndex: startIndex,
            startRemaining: startRemaining,
            isRunning: isRunning,
            fakeDate: fakeDate,
            mock: mock,
            onReconcile: { i, r, f in reconciled = (i, r, f) }
        )

        // When entering background — schedule notifications.
        await coordinator.handleDidEnterBackground()

        // Expect one batch scheduled.
        #expect(mock.scheduledRequests.count == 1)

        // Requests should be at boundaries:
        // after 2s → start of work(5) [index 3]
        // after 2s + 5s = 7s → finished
        let batch = try #require(mock.scheduledRequests.first)
        #expect(batch.count == 2)

        // The time intervals should be [2, 7]
        let intervals = batch.map { Int($0.timeInterval) }
        #expect(intervals == [2, 7])

        // Titles should correspond to next phase and then completion.
        let titles = batch.map { $0.title }
        #expect(titles[0] == "Work")
        #expect(titles[1] == "Session completed")
    }

    @Test("Schedule stops at finished — Планирование останавливается на finished")
    func test_schedule_stopsAtFinished() async throws {
        let plan = SamplePlans.simplePlan()
        // We are at last work(5) with remaining = 5 (index 3), running.
        let startIndex = 3
        let startRemaining = 5
        let isRunning = true

        let fakeDate = FakeDateProvider()
        let mock = MockNotificationService()
        let coordinator = makeCoordinator(
            plan: plan,
            startIndex: startIndex,
            startRemaining: startRemaining,
            isRunning: isRunning,
            fakeDate: fakeDate,
            mock: mock,
            onReconcile: { _, _, _ in }
        )

        await coordinator.handleDidEnterBackground()

        // Only one notification: completion after 5s.
        #expect(mock.scheduledRequests.count == 1)
        let batch = try #require(mock.scheduledRequests.first)
        #expect(batch.count == 1)
        #expect(Int(batch[0].timeInterval) == 5)
        #expect(batch[0].title == "Session completed")
    }

    // MARK: - Reconcile tests — Пересинхронизация позиции

    @Test("Reconcile with no time passed returns same position — Без прошедшего времени позиция не меняется")
    func test_reconcile_noTimePassed_returnsSamePosition() async throws {
        let plan = SamplePlans.simplePlan()
        let startIndex = 1  // work(5)
        let startRemaining = 4
        let isRunning = true

        let fakeDate = FakeDateProvider(start: Date(timeIntervalSince1970: 1000))
        let mock = MockNotificationService()

        var result: (Int, Int, Bool)?
        let coordinator = makeCoordinator(
            plan: plan,
            startIndex: startIndex,
            startRemaining: startRemaining,
            isRunning: isRunning,
            fakeDate: fakeDate,
            mock: mock,
            onReconcile: { i, r, f in result = (i, r, f) }
        )

        // Enter background at t=1000
        await coordinator.handleDidEnterBackground()
        // Become active immediately at same time (delta = 0)
        await coordinator.handleDidBecomeActive()

        let res = try #require(result)
        #expect(res.0 == startIndex)
        #expect(res.1 == startRemaining)
        #expect(res.2 == false)
    }

    @Test("Reconcile with partial progress stays within current interval — Частичный прогресс внутри интервала")
    func test_reconcile_partialProgress_staysWithinCurrentInterval() async throws {
        let plan = SamplePlans.simplePlan()
        let startIndex = 1  // work(5)
        let startRemaining = 5
        let isRunning = true

        let fakeDate = FakeDateProvider(start: Date(timeIntervalSince1970: 0))
        let mock = MockNotificationService()
        var result: (Int, Int, Bool)?
        let coordinator = makeCoordinator(
            plan: plan,
            startIndex: startIndex,
            startRemaining: startRemaining,
            isRunning: isRunning,
            fakeDate: fakeDate,
            mock: mock,
            onReconcile: { i, r, f in result = (i, r, f) }
        )

        await coordinator.handleDidEnterBackground()
        // 2 seconds passed in background
        fakeDate.advance(by: 2)
        await coordinator.handleDidBecomeActive()

        let res = try #require(result)
        // Still in work(5), remaining should be 3
        #expect(res.0 == startIndex)
        #expect(res.1 == 3)
        #expect(res.2 == false)
    }

    @Test("Reconcile skips multiple intervals and stops inside — Пропуск нескольких интервалов и остановка внутри")
    func test_reconcile_skipsMultipleIntervals_andStopsInside() async throws {
        // Plan: prepare(3) → work(5) → rest(2) → work(5) → finished
        let plan = SamplePlans.simplePlan()
        // Start at prepare(3) with remaining 3
        let startIndex = 0
        let startRemaining = 3
        let isRunning = true

        let fakeDate = FakeDateProvider()
        let mock = MockNotificationService()
        var result: (Int, Int, Bool)?
        let coordinator = makeCoordinator(
            plan: plan,
            startIndex: startIndex,
            startRemaining: startRemaining,
            isRunning: isRunning,
            fakeDate: fakeDate,
            mock: mock,
            onReconcile: { i, r, f in result = (i, r, f) }
        )

        await coordinator.handleDidEnterBackground()
        // Pass 3 (finish prepare) + 5 (finish work1) + 1 (half of rest(2)) = 9 seconds
        fakeDate.advance(by: 9)
        await coordinator.handleDidBecomeActive()

        let res = try #require(result)
        // We should be inside rest(2) (index 2), remaining = 1
        #expect(res.0 == 2)
        #expect(res.1 == 1)
        #expect(res.2 == false)
    }

    @Test("Reconcile beyond plan marks finished — Дельта больше плана помечает завершение")
    func test_reconcile_beyondPlan_marksFinished() async throws {
        let plan = SamplePlans.simplePlan()
        // Start near end: last work(5) with remaining 5
        let startIndex = 3
        let startRemaining = 5
        let isRunning = true

        let fakeDate = FakeDateProvider()
        let mock = MockNotificationService()
        var result: (Int, Int, Bool)?
        let coordinator = makeCoordinator(
            plan: plan,
            startIndex: startIndex,
            startRemaining: startRemaining,
            isRunning: isRunning,
            fakeDate: fakeDate,
            mock: mock,
            onReconcile: { i, r, f in result = (i, r, f) }
        )

        await coordinator.handleDidEnterBackground()
        // Advance 6 seconds (5 to finish + 1 extra)
        fakeDate.advance(by: 6)
        await coordinator.handleDidBecomeActive()

        let res = try #require(result)
        // Should be finished; index should point to finished interval (last index), remaining = 0
        #expect(res.2 == true)
        #expect(res.1 == 0)
        #expect(res.0 == plan.count - 1)
    }
}
