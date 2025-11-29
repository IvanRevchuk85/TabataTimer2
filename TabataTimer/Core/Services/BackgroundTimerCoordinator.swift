//
//  BackgroundTimerCoordinator.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 29.11.2025.
//
//  MARK: Overview — Обзор
//  Coordinates background behavior for the Tabata timer:
//  - schedules local notifications for upcoming phase boundaries when app goes to background;
//  - cancels notifications and reconciles timer position on returning to foreground.
//  Координирует поведение таймера в фоне:
//  - планирует локальные уведомления на границы фаз при уходе в фон;
//  - отменяет уведомления и пересчитывает позицию таймера при возврате на передний план.
//

import Foundation

// MARK: - BackgroundTimerCoordinator — Coordinator / Координатор
/// A small coordinator that plans notifications and reconciles position by wall-clock time.
/// Небольшой координатор, который планирует уведомления и пересчитывает позицию по реальному времени.
final class BackgroundTimerCoordinator {

    // MARK: Dependencies — Зависимости
    private let notifications: NotificationServiceProtocol
    private let dateProvider: () -> Date

    // MARK: State providers — Провайдеры состояния
    private let planProvider: () -> [TabataInterval]
    private let positionProvider: () -> (currentIndex: Int, remaining: Int, isRunning: Bool)

    // MARK: Reconcile callback — Колбэк пересинхронизации
    typealias ReconcileHandler = (_ newIndex: Int, _ newRemaining: Int, _ finished: Bool) -> Void
    private let onReconcile: ReconcileHandler

    // MARK: Snapshot — Снимок на момент ухода в фон
    private var backgroundSnapshot: (date: Date, index: Int, remaining: Int)?

    // MARK: - Init — Инициализация
    init(
        notifications: NotificationServiceProtocol,
        planProvider: @escaping () -> [TabataInterval],
        positionProvider: @escaping () -> (currentIndex: Int, remaining: Int, isRunning: Bool),
        dateProvider: @escaping () -> Date = { Date() },
        onReconcile: @escaping ReconcileHandler
    ) {
        self.notifications = notifications
        self.planProvider = planProvider
        self.positionProvider = positionProvider
        self.dateProvider = dateProvider
        self.onReconcile = onReconcile
    }

    // MARK: - Lifecycle hooks — Хуки жизненного цикла
    public func handleDidEnterBackground() async {
        let plan = planProvider()
        let pos = positionProvider()
        guard pos.isRunning, !plan.isEmpty else {
            backgroundSnapshot = nil
            return
        }
        let now = dateProvider()
        backgroundSnapshot = (date: now, index: pos.currentIndex, remaining: max(0, pos.remaining))

        let requests = buildPhaseBoundaryNotifications(
            plan: plan,
            startingIndex: pos.currentIndex,
            startingRemaining: max(0, pos.remaining)
        )

        do { try await notifications.schedule(requests) } catch { /* no-op */ }
    }

    public func handleDidBecomeActive() async {
        await notifications.cancelAll()
        guard let snapshot = backgroundSnapshot else { return }
        backgroundSnapshot = nil

        let plan = planProvider()
        guard !plan.isEmpty else { return }

        let now = dateProvider()
        let delta = max(0, Int(now.timeIntervalSince(snapshot.date).rounded()))

        let result = advancePosition(
            in: plan,
            fromIndex: snapshot.index,
            withRemaining: snapshot.remaining,
            passed: delta
        )

        onReconcile(result.newIndex, result.newRemaining, result.finished)
    }

    // MARK: - Notifications building — Построение уведомлений
    private func buildPhaseBoundaryNotifications(
        plan: [TabataInterval],
        startingIndex: Int,
        startingRemaining: Int
    ) -> [LocalNotificationRequest] {
        var requests: [LocalNotificationRequest] = []
        var accumulated: TimeInterval = TimeInterval(max(0, startingRemaining))

        var idx = startingIndex + 1
        while idx < plan.count {
            let next = plan[idx]
            if next.phase == .finished {
                let id = "tabata.completed.\(UUID().uuidString)"
                requests.append(
                    LocalNotificationRequest(
                        id: id,
                        title: "Session completed",
                        body: "Well done! Training finished.",
                        timeInterval: accumulated,
                        playSound: true
                    )
                )
                break
            } else {
                let id = "tabata.phase.\(idx).\(UUID().uuidString)"
                let (title, body) = notificationCopy(for: next)
                requests.append(
                    LocalNotificationRequest(
                        id: id,
                        title: title,
                        body: body,
                        timeInterval: accumulated,
                        playSound: true
                    )
                )
            }
            accumulated += TimeInterval(max(0, next.duration))
            idx += 1
        }
        return requests
    }

    private func notificationCopy(for interval: TabataInterval) -> (title: String, body: String) {
        switch interval.phase {
        case .prepare:         return ("Prepare", "Get ready to start.")
        case .work:            return ("Work", "Go! Focus on intensity.")
        case .rest:            return ("Rest", "Recover before next cycle.")
        case .restBetweenSets: return ("Set Break", "Recover before next set.")
        case .finished:        return ("Completed", "Training finished.")
        }
    }

    // MARK: - Position advancing — Пересчёт позиции
    private func advancePosition(
        in plan: [TabataInterval],
        fromIndex: Int,
        withRemaining remaining: Int,
        passed delta: Int
    ) -> (newIndex: Int, newRemaining: Int, finished: Bool) {
        guard !plan.isEmpty else { return (0, 0, true) }
        var index = min(max(0, fromIndex), plan.count - 1)
        var rem = max(0, remaining)
        var left = max(0, delta)

        if left == 0 {
            let isFinished = plan[index].phase == .finished
            return (index, rem, isFinished)
        }

        if left < rem {
            rem -= left
            return (index, rem, false)
        } else {
            left -= rem
            index += 1
        }

        while index < plan.count {
            let current = plan[index]
            if current.phase == .finished { return (index, 0, true) }

            if left < current.duration {
                let newRemaining = current.duration - left
                return (index, newRemaining, false)
            } else {
                left -= current.duration
                index += 1
            }
        }

        return (plan.count - 1, 0, true)
    }
}
