//
//  ActiveTimerViewModelTests.swift
//  TabataTimerTests
//
//  Created by Ivan Revchuk on 25.11.2025.
//

import XCTest
@testable import TabataTimer

// MARK: - ActiveTimerViewModelTests — Тесты ViewModel активной тренировки
/// Tests that VM reacts to engine events and maps them into TabataSessionState.
/// Тесты, что VM корректно реагирует на события движка и маппит их в TabataSessionState.
@MainActor
final class ActiveTimerViewModelTests: XCTestCase {

    // MARK: - Tick reaction — Реакция на tick
    func test_reactsToTick_updatesRemaining_andElapsed_andProgress() async throws {
        // given
        let config = TabataConfig(prepare: 1, work: 3, rest: 1, cyclesPerSet: 1, sets: 1, restBetweenSets: 0)
        let mock = MockEngine()
        let vm = ActiveTimerViewModel(config: config, engine: mock)

        // when: simulate initial phase and then a tick
        mock.emit(.phaseChanged(phase: .prepare, index: 0))
        mock.emit(.tick(remaining: 0)) // prepare ticks down to 0
        mock.emit(.phaseChanged(phase: .work, index: 1))
        mock.emit(.tick(remaining: 2)) // one second elapsed in work

        // then
        // Allow main actor to process published updates.
        try await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertEqual(vm.state.currentPhase, .work)
        XCTAssertEqual(vm.state.remainingTime, 2)
        XCTAssertEqual(vm.state.elapsedTime, 2, "One tick in prepare (1s) + one tick in work (1s) = 2")
        XCTAssertGreaterThan(vm.state.progress, 0.0)
        XCTAssertLessThanOrEqual(vm.state.progress, 1.0)
    }

    // MARK: - Phase change reaction — Реакция на phaseChanged
    func test_reactsToPhaseChanged_updatesIndices_andPhase() async throws {
        // given
        let config = TabataConfig(prepare: 0, work: 2, rest: 0, cyclesPerSet: 1, sets: 1, restBetweenSets: 0)
        let mock = MockEngine()
        let vm = ActiveTimerViewModel(config: config, engine: mock)

        // when
        mock.emit(.phaseChanged(phase: .work, index: 0))

        // then
        try await Task.sleep(nanoseconds: 20_000_000)

        XCTAssertEqual(vm.state.currentIntervalIndex, 0)
        XCTAssertEqual(vm.state.currentPhase, .work)
        XCTAssertEqual(vm.state.currentSet, 1)
        XCTAssertEqual(vm.state.totalSets, 1)
        XCTAssertEqual(vm.state.currentCycle, 1)
        XCTAssertEqual(vm.state.totalCyclesPerSet, 1)
    }

    // MARK: - Completion reaction — Реакция на completed
    func test_reactsToCompleted_setsFinished_andFullProgress() async throws {
        // given
        let config = TabataConfig(prepare: 0, work: 1, rest: 0, cyclesPerSet: 1, sets: 1, restBetweenSets: 0)
        let mock = MockEngine()
        let vm = ActiveTimerViewModel(config: config, engine: mock)

        // when
        mock.emit(.completed)

        // then
        try await Task.sleep(nanoseconds: 20_000_000)

        XCTAssertEqual(vm.state.currentPhase, .finished)
        XCTAssertEqual(vm.state.remainingTime, 0)
        XCTAssertEqual(vm.state.elapsedTime, vm.state.totalDuration)
        XCTAssertEqual(vm.state.progress, 1.0)
    }
}

// MARK: - MockEngine — Мок движка таймера
/// Minimal controllable mock for TimerEngineProtocol with a manual AsyncStream.
/// Минимальный управляемый мок для TimerEngineProtocol с ручным AsyncStream.
private final class MockEngine: TimerEngineProtocol {

    // MARK: State — Состояние
    private(set) var state: TimerState = .idle

    // MARK: Stream — Поток
    private let stream: AsyncStream<TimerEvent>
    private let continuation: AsyncStream<TimerEvent>.Continuation

    init() {
        var cont: AsyncStream<TimerEvent>.Continuation!
        stream = AsyncStream<TimerEvent> { c in cont = c }
        continuation = cont
    }

    var events: AsyncStream<TimerEvent> { stream }

    // MARK: Configure — Конфигурация
    func configure(with plan: [TabataInterval]) {
        state = .idle
    }

    // MARK: Control — Управление
    func start() { state = .running }
    func pause() { state = .paused }
    func resume() { state = .running }
    func reset() { state = .idle }

    // MARK: Emit helper — Метод для эмита событий
    func emit(_ event: TimerEvent) {
        continuation.yield(event)
    }
}

