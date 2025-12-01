//
//  TimerEngineTests.swift
//  TabataTimerTests
//
//  Created by Tests on 25.11.2025.
//

import XCTest
@testable import TabataTimer

// MARK: - TimerEngineTests — Тесты движка таймера
/// Unit tests for the timer engine (actor-based).
/// Юнит‑тесты для движка таймера (на базе actor).
final class TimerEngineTests: XCTestCase {

    // MARK: Helpers — Вспомогательные методы
    /// Collect first N events from an AsyncStream with a soft timeout.
    /// Собрать первые N событий из AsyncStream с мягким таймаутом.
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
                    // IMPORTANT: local timeout must be > tick interval (~1s).
                    // ВАЖНО: локальный таймаут должен быть > интервала тика (≈1 сек).
                    try? await withTimeout(seconds: 1.2) {
                        await iterator.next()
                    }
                },
                onCancel: {}
            ) ?? nil {
                result.append(event)
            } else {
                // Small delay between attempts.
                // Небольшая пауза между попытками.
                try? await Task.sleep(nanoseconds: 30_000_000)
            }
        }
        return result
    }

    /// Primitive timeout helper for awaiting operations.
    /// Примитивный помощник для ожидания с таймаутом.
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

    // MARK: configure → start — initial phaseChanged — Инициализация и старт: первый .phaseChanged
    @MainActor
    func test_start_emitsInitialPhaseChanged_onCorrectPhaseAndIndex() async throws {
        // given — предусловия
        let config = TabataConfig(
            prepare: 2,
            work: 3,
            rest: 0,
            cyclesPerSet: 1,
            sets: 1,
            restBetweenSets: 0
        )
        let plan = TabataPlan.build(from: config)
        let engine = TimerEngine()
        await engine.configure(with: plan)

        // when — действие
        await engine.start()

        // then — проверки
        let stream = await engine.events
        let events = await collect(stream, max: 1, timeout: 1.5)
        XCTAssertFalse(events.isEmpty)

        // The first event must be .phaseChanged with phase of the first interval.
        // Первый эвент должен быть .phaseChanged с фазой первого интервала плана.
        if case let .phaseChanged(phase, index) = events[0] {
            XCTAssertEqual(index, 0, "First index must be 0 — Первый индекс должен быть 0")
            XCTAssertEqual(phase, plan[0].phase, "Phase must match the first interval — Фаза должна соответствовать первому интервалу")
        } else {
            XCTFail("Expected .phaseChanged as the first event — Ожидался .phaseChanged как первое событие")
        }
    }

    // MARK: Ticks and advancing — Тики и переходы между интервалами
    @MainActor
    func test_ticks_decreaseRemaining_and_advanceIntervals() async throws {
        // given — предусловия: short prepare, then work=2, then finished.
        // короткий prepare, затем work=2, затем finished.
        let config = TabataConfig(
            prepare: 1,
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

        // when — действие: collect several events.
        // собираем несколько событий.
        let stream = await engine.events
        let events = await collect(stream, max: 6, timeout: 3.5)

        // then — проверки:
        // We expect: phaseChanged(.prepare) -> ticks -> phaseChanged(.work) -> ticks -> completed.
        // Ожидаем: phaseChanged(.prepare) -> тики -> phaseChanged(.work) -> тики -> completed.
        let hasTick = events.contains { if case .tick = $0 { return true } else { return false } }
        XCTAssertTrue(hasTick, "Tick events expected — Ожидаются события .tick")

        let hasWorkPhase = events.contains {
            if case .phaseChanged(let p, _) = $0, p == .work { return true } else { return false }
        }
        XCTAssertTrue(hasWorkPhase, "Phase .work expected — Ожидается смена фазы на .work")

        let hasCompleted = events.contains { if case .completed = $0 { return true } else { return false } }
        XCTAssertTrue(hasCompleted, "Completed expected — Ожидается .completed")
    }

    // MARK: Pause/Resume — только проверка состояний
    @MainActor
    func test_pause_and_resume_changesState() async {
        // given — простой план, чтобы движку было что делать
        let config = TabataConfig(
            prepare: 1,
            work: 3,
            rest: 0,
            cyclesPerSet: 1,
            sets: 1,
            restBetweenSets: 0
        )
        let plan = TabataPlan.build(from: config)
        let engine = TimerEngine()
        await engine.configure(with: plan)

        // начальное состояние
        var state = await engine.state
        XCTAssertEqual(state, .idle, "Initial state should be .idle — Начальное состояние должно быть .idle")

        // when: start
        await engine.start()
        state = await engine.state
        XCTAssertEqual(state, .running, "State should be .running after start — После start состояние должно быть .running")

        // when: pause
        await engine.pause()
        state = await engine.state
        XCTAssertEqual(state, .paused, "State should be .paused after pause — После pause состояние должно быть .paused")

        // when: resume
        await engine.resume()
        state = await engine.state
        XCTAssertEqual(state, .running, "State should be .running after resume — После resume состояние должно быть .running")
    }

    // MARK: Completion — Завершение
    @MainActor
    func test_finish_emitsCompleted_and_setsFinished() async throws {
        // given — предусловия: very short plan.
        // очень короткий план.
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

        // when — действие
        await engine.start()

        // then — проверки: expect .completed and .finished state.
        // ожидаем .completed и состояние .finished.
        let stream = await engine.events
        let events = await collect(stream, max: 5, timeout: 3.0)

        let hasCompleted = events.contains { if case .completed = $0 { return true } else { return false } }
        XCTAssertTrue(hasCompleted, "Completed expected — Должен прийти .completed")

        let finalState = await engine.state
        XCTAssertEqual(finalState, .finished, "State should be .finished — Состояние должно быть .finished")

        // No further ticks after completion.
        // После завершения новые тики не должны приходить.
        let afterFinish = await collect(stream, max: 1, timeout: 1.3)
        XCTAssertTrue(afterFinish.isEmpty, "No ticks after finish — После завершения не ожидаются новые тики")
    }

    // MARK: Reset — Сброс
    @MainActor
    func test_reset_recreatesStream_and_resetsState() async throws {
        // given — предусловия
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

        // Collect some events.
        // Собираем немного событий.
        let stream1 = await engine.events
        let eventsBeforeReset = await collect(stream1, max: 2, timeout: 2.0)
        XCTAssertFalse(eventsBeforeReset.isEmpty)

        // when — действие
        await engine.reset()

        // then — проверки
        let stateAfterReset = await engine.state
        XCTAssertEqual(stateAfterReset, .idle, "State should be .idle after reset — После reset состояние .idle")

        // After reset, new stream should work after a new start.
        // После reset новый поток должен работать после нового старта.
        await engine.start()
        let stream2 = await engine.events
        let eventsAfterReset = await collect(stream2, max: 2, timeout: 2.0)
        XCTAssertFalse(eventsAfterReset.isEmpty, "Events should arrive after reset+start — После reset и нового start должны приходить события")
    }

    // MARK: Reconfigure — Переконфигурация
    @MainActor
    func test_configure_resetsState_and_stream() async throws {
        // given — предусловия
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

        // when — действие: new configuration.
        // новая конфигурация.
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

        // then — проверки: state is idle; new stream produces events after start.
        // состояние idle; новый поток отдаёт события после старта.
        let stateAfterConfigure = await engine.state
        XCTAssertEqual(stateAfterConfigure, .idle, "State should be .idle after configure — После configure состояние .idle")

        await engine.start()
        let stream2 = await engine.events
        let secondBatch = await collect(stream2, max: 2, timeout: 2.0)
        XCTAssertFalse(secondBatch.isEmpty)
    }

    // MARK: Edge case — empty plan — Пустой план
    @MainActor
    func test_emptyPlan_startDoesNothing() async {
        // given — предусловия: empty plan.
        // пустой план.
        let engine = TimerEngine()
        await engine.configure(with: []) // explicitly empty — явно пустой

        // when — действие
        await engine.start()

        // then — проверки: state stays idle, no events.
        // состояние остаётся idle, событий нет.
        let state = await engine.state
        XCTAssertEqual(state, .idle, "Should remain .idle with empty plan — Состояние должно остаться .idle при пустом плане")

        let stream = await engine.events
        let batch = await collect(stream, max: 1, timeout: 1.2)
        XCTAssertTrue(batch.isEmpty, "No events expected — Не ожидаем событий при пустом плане")
    }

    // MARK: Edge case — no prepare/rest, final finished=0 — Без prepare/rest, финальный finished=0
    @MainActor
    func test_edge_noPrepare_noRest_and_finalFinishedZero() async {
        // given — предусловия: prepare=0, rest=0, single short work, final finished=0.
        // prepare=0, rest=0, один короткий work, финальный finished=0.
        let config = TabataConfig(
            prepare: 0,
            work: 1,
            rest: 0,
            cyclesPerSet: 1,
            sets: 1,
            restBetweenSets: 0
        )
        let plan = TabataPlan.build(from: config)
        // Sanity: last interval is .finished with duration 0.
        // Проверка: последний интервал .finished с длительностью 0.
        XCTAssertEqual(plan.last?.phase, .finished)
        XCTAssertEqual(plan.last?.duration, 0)

        let engine = TimerEngine()
        await engine.configure(with: plan)

        // when — действие
        await engine.start()

        // then — проверки: collect and assert expected sequence.
        // собираем и проверяем ожидаемую последовательность.
        let stream = await engine.events
        let events = await collect(stream, max: 4, timeout: 2.5)

        let hasPhaseWork = events.contains {
            if case .phaseChanged(let p, _) = $0, p == .work { return true } else { return false }
        }
        XCTAssertTrue(hasPhaseWork, "Should start at .work without prepare — Ожидается .work при старте без prepare")

        let hasCompleted = events.contains { if case .completed = $0 { return true } else { return false } }
        XCTAssertTrue(hasCompleted, "Completed expected — Ожидается .completed")

        let state = await engine.state
        XCTAssertEqual(state, .finished, "State .finished expected — После завершения ожидается .finished")
    }
}
