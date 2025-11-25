//
//  TimerProtocolsTests.swift
//  TabataTimerTests
//
//  Created by Ivan Revchuk on 24.11.2025.
//

import XCTest
@testable import TabataTimer

// MARK: - TimerProtocolsTests — Тесты протоколов и моделей состояния
/// Contract-level tests for timer protocols and session models.
/// Контрактные тесты для протоколов таймера и моделей состояния.
final class TimerProtocolsTests: XCTestCase {

    // MARK: - Session state basics — Базовая проверка состояния сессии
    func testSessionStateIdleFactory() throws {
        // given — предусловия
        let sets = 4
        let cycles = 8
        let total = 300

        // when — действие
        let state = TabataSessionState.idle(totalSets: sets, totalCyclesPerSet: cycles, totalDuration: total)

        // then — проверки
        XCTAssertEqual(state.currentIntervalIndex, 0, "Index should start at 0 — Индекс должен начинаться с 0")
        XCTAssertEqual(state.currentPhase, .prepare, "Default phase is prepare — Дефолтная фаза prepare")
        XCTAssertEqual(state.remainingTime, 0, "Remaining is 0 at idle — На idle remaining = 0")
        XCTAssertEqual(state.totalDuration, total, "Total duration must match — totalDuration должен совпадать")
        XCTAssertEqual(state.elapsedTime, 0, "Elapsed is 0 at idle — На idle elapsed = 0")
        XCTAssertEqual(state.currentSet, 0, "Current set is 0 at idle — Текущий сет 0 на idle")
        XCTAssertEqual(state.totalSets, sets, "Total sets must match — totalSets должен совпадать")
        XCTAssertEqual(state.currentCycle, 0, "Current cycle is 0 at idle — Текущий цикл 0 на idle")
        XCTAssertEqual(state.totalCyclesPerSet, cycles, "Total cyclesPerSet must match — totalCyclesPerSet должен совпадать")
        XCTAssertEqual(state.progress, 0, "Progress is 0 at idle — Прогресс 0 на idle")
    }

    // MARK: - TimerEvent encoding/decoding — Кодирование/декодирование событий
    func testTimerEventCodableRoundtrip() throws {
        // given — предусловия
        let events: [TimerEvent] = [
            .tick(remaining: 5),
            .phaseChanged(phase: .work, index: 3),
            .completed
        ]

        // when — действие
        let data = try JSONEncoder().encode(events)
        let decoded = try JSONDecoder().decode([TimerEvent].self, from: data)

        // then — проверки
        XCTAssertEqual(events, decoded, "Events must round-trip via Codable — События должны корректно кодироваться/декодироваться")
    }

    // MARK: - TimerState helpers — Вспомогательные флаги состояния
    func testTimerStateHelperFlags() {
        // given/when/then — проверяем булевые флаги
        XCTAssertTrue(TimerState.idle.isIdle, "idle.isIdle must be true — idle.isIdle должен быть true")
        XCTAssertTrue(TimerState.running.isActive, "running.isActive must be true — running.isActive должен быть true")
        XCTAssertTrue(TimerState.paused.isPaused, "paused.isPaused must be true — paused.isPaused должен быть true")
        XCTAssertTrue(TimerState.finished.isTerminal, "finished.isTerminal must be true — finished.isTerminal должен быть true")
    }

    // MARK: - Protocol conformance via mock — Проверка протокола через мок
    func testTimerEngineProtocolMock() async throws {
        // given — предусловия
        let config = TabataConfig(
            prepare: 2, work: 3, rest: 1,
            cyclesPerSet: 2, sets: 1, restBetweenSets: 0
        )
        let plan = TabataPlan.build(from: config)
        let engine = MockTimerEngine()

        // when — действие
        engine.configure(with: plan)
        engine.start()

        // Collect first few events from the stream.
        // Соберём первые несколько событий из потока.
        var received: [TimerEvent] = []
        for await event in engine.events.prefix(2) {
            received.append(event)
        }

        // then — проверки
        XCTAssertEqual(engine.state, .running, "Engine should be running after start — После start состояние должно быть running")
        XCTAssertFalse(received.isEmpty, "Should receive some events — Должны прийти события")
    }
}

// MARK: - MockTimerEngine — Мок движка таймера
/// Minimal mock of TimerEngineProtocol to validate protocol usage and AsyncStream.
/// Минимальный мок TimerEngineProtocol для проверки использования протокола и AsyncStream.
private final class MockTimerEngine: TimerEngineProtocol {

    // MARK: State — Состояние
    private(set) var state: TimerState = .idle

    // MARK: Events stream — Поток событий
    private let stream: AsyncStream<TimerEvent>
    private let continuation: AsyncStream<TimerEvent>.Continuation
    
    init() {
        var cont: AsyncStream<TimerEvent>.Continuation!
        stream = AsyncStream { continuation in
            cont = continuation
        }
        continuation = cont
    }

    var events: AsyncStream<TimerEvent> { stream }

    // MARK: Internals — Внутреннее
    private var plan: [TabataInterval] = []
    private var started = false

    // MARK: Configuration — Конфигурация
    func configure(with plan: [TabataInterval]) {
        self.plan = plan
        self.state = .idle
        self.started = false
    }

    // MARK: Control — Управление
    func start() {
        state = .running
        started = true

        // Emit a couple of synthetic events asynchronously.
        // Асинхронно эмитим пару синтетических событий.
        Task {
            continuation.yield(.phaseChanged(phase: .prepare, index: 0))
            continuation.yield(.tick(remaining: max(1, plan.first?.duration ?? 0)))
            continuation.yield(.completed)     // третье событие
            continuation.finish()              // закрываем стрим
        }
    }

    func pause() {
        guard started else { return }
        state = .paused
    }

    func resume() {
        guard started else { return }
        state = .running
        Task { continuation.yield(.tick(remaining: 1)) }
    }

    func reset() {
        state = .idle
        started = false
        continuation.finish()
    }
}
