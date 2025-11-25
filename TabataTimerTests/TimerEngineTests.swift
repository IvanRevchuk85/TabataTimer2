//
//  TimerEngineTests.swift
//  TabataTimerTests
//
//  Created by Tests on 25.11.2025.
//

import XCTest
@testable import TabataTimer

final class TimerEngineTests: XCTestCase {

    // Вспомогательная функция: собирает первые N событий из AsyncStream.
    private func collect(
        _ stream: AsyncStream<TimerEvent>,
        max count: Int,
        timeout: TimeInterval = 3.0
    ) async -> [TimerEvent] {
        var result: [TimerEvent] = []
        let deadline = Date().addingTimeInterval(timeout)

        var iterator = stream.makeAsyncIterator()
        while result.count < count && Date() < deadline {
            if let event = await withTaskCancellationHandler(
                operation: {
                    // ВАЖНО: локальный таймаут должен быть > интервала тика (≈1 сек)
                    try? await withTimeout(seconds: 1.2) {
                        await iterator.next()
                    }
                },
                onCancel: {}
            ) ?? nil {
                result.append(event)
            } else {
                // маленькая пауза между попытками
                try? await Task.sleep(nanoseconds: 30_000_000)
            }
        }
        return result
    }

    // Примитивный таймаут-хелпер для await ожиданий.
    private func withTimeout<T>(
        seconds: TimeInterval,
        operation: @escaping () async -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                await operation()
            }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }
            let value = try await group.next()!
            group.cancelAll()
            return value
        }
    }

    private struct TimeoutError: Error {}

    // MARK: - Тест: start эмитит phaseChanged и тики
    @MainActor
    func test_start_emitsInitialPhaseChanged_andTicks() async throws {
        // given: делаем работу подлиннее, чтобы не успевало завершиться
        let config = TabataConfig(
            prepare: 1,
            work: 5,
            rest: 0,
            cyclesPerSet: 1,
            sets: 1,
            restBetweenSets: 0
        )
        let plan = TabataPlan.build(from: config)
        let engine = TimerEngine()
        await engine.configure(with: plan)

        // when
        await engine.start()

        // then: быстро собираем только 2 события, чтобы не ждать завершения
        let stream = await engine.events
        let events = await collect(stream, max: 2, timeout: 1.5)
        XCTAssertFalse(events.isEmpty)

        let stateAfterStart = await engine.state
        XCTAssertEqual(stateAfterStart, .running)

        // Проверим, что среди событий было phaseChanged и хотя бы один тик
        let hasPhaseChanged = events.contains {
            if case .phaseChanged = $0 { return true }
            return false
        }
        XCTAssertTrue(hasPhaseChanged, "Должен прийти .phaseChanged при старте")

        let hasTick = events.contains {
            if case .tick = $0 { return true }
            return false
        }
        XCTAssertTrue(hasTick, "Должны прийти .tick события")
    }

    // MARK: - Тест: pause останавливает тики, resume не ломает состояние
    @MainActor
    func test_pause_and_resume() async {
        // given: берём план с нормальной длительностью work
        let config = TabataConfig(
            prepare: 1,
            work: 6,
            rest: 0,
            cyclesPerSet: 1,
            sets: 1,
            restBetweenSets: 0
        )
        let plan = TabataPlan.build(from: config)
        let engine = TimerEngine()
        await engine.configure(with: plan)
        await engine.start()

        // ждём хотя бы одно событие (phaseChanged или tick), чтобы убедиться что движок реально работает
        let eventsStream = await engine.events
        let firstBatch = await collect(eventsStream, max: 1, timeout: 2.0)
        XCTAssertFalse(firstBatch.isEmpty, "До паузы должны прийти события из движка")

        // when: ставим на паузу
        await engine.pause()
        let stateAfterPause = await engine.state
        XCTAssertEqual(stateAfterPause, .paused, "После pause состояние должно быть .paused")

        // when: возобновляем
        await engine.resume()
        let stateAfterResume = await engine.state
        XCTAssertEqual(stateAfterResume, .running, "После resume состояние должно быть .running")
    }


    // MARK: - Тест: завершение эмитит completed и ставит finished
    @MainActor
    func test_finish_emitsCompleted_and_setsFinished() async throws {
        // given: очень короткий план
        let config = TabataConfig(
            prepare: 0,
            work: 1,
            rest: 0,
            cyclesPerSet: 1,
            sets: 1,
            restBetweenSets: 0
        )
        let plan = TabataPlan.build(from: config)
        let engine = TimerEngine()
        await engine.configure(with: plan)

        // when
        await engine.start()

        // then: собираем события и ищем completed
        let stream = await engine.events
        let events = await collect(stream, max: 5, timeout: 3.0)

        let hasCompleted = events.contains {
            if case .completed = $0 { return true }
            return false
        }
        XCTAssertTrue(hasCompleted, "Должен прийти .completed")

        let finalState = await engine.state
        XCTAssertEqual(
            finalState,
            .finished,
            "Состояние должно быть .finished после завершения"
        )
    }

    // MARK: - Тест: reset пересоздаёт поток и сбрасывает состояние
    @MainActor
    func test_reset_recreatesStream_and_resetsState() async throws {
        // given
        let config = TabataConfig(
            prepare: 0,
            work: 2,
            rest: 0,
            cyclesPerSet: 1,
            sets: 1,
            restBetweenSets: 0
        )
        let plan = TabataPlan.build(from: config)
        let engine = TimerEngine()
        await engine.configure(with: plan)
        await engine.start()

        // Соберём немного событий
        let stream1 = await engine.events
        let eventsBeforeReset = await collect(stream1, max: 2, timeout: 2.0)
        XCTAssertFalse(eventsBeforeReset.isEmpty)

        // when
        await engine.reset()

        // then
        let stateAfterReset = await engine.state
        XCTAssertEqual(stateAfterReset, .idle)

        // После reset новый поток должен работать (события пойдут после нового старта)
        await engine.start()
        let stream2 = await engine.events
        let eventsAfterReset = await collect(stream2, max: 2, timeout: 2.0)
        XCTAssertFalse(
            eventsAfterReset.isEmpty,
            "После reset и нового start должны приходить события"
        )
    }

    // MARK: - Тест: configure сбрасывает состояние и поток
    @MainActor
    func test_configure_resetsState_and_stream() async throws {
        // given
        let config1 = TabataConfig(
            prepare: 0,
            work: 2,
            rest: 0,
            cyclesPerSet: 1,
            sets: 1,
            restBetweenSets: 0
        )
        let plan1 = TabataPlan.build(from: config1)
        let engine = TimerEngine()
        await engine.configure(with: plan1)
        await engine.start()
        let stream1 = await engine.events
        let firstBatch = await collect(stream1, max: 2, timeout: 2.0)
        XCTAssertFalse(firstBatch.isEmpty)

        // when: новая конфигурация
        let config2 = TabataConfig(
            prepare: 1,
            work: 1,
            rest: 0,
            cyclesPerSet: 1,
            sets: 1,
            restBetweenSets: 0
        )
        let plan2 = TabataPlan.build(from: config2)
        await engine.configure(with: plan2)

        // then: после configure состояние idle, и новый поток отдаёт события после старта
        let stateAfterConfigure = await engine.state
        XCTAssertEqual(stateAfterConfigure, .idle)

        await engine.start()
        let stream2 = await engine.events
        let secondBatch = await collect(stream2, max: 2, timeout: 2.0)
        XCTAssertFalse(secondBatch.isEmpty)
    }
}

