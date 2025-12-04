//
//  ActiveTimerViewModelTests.swift
//  TabataTimerTests
//
//  Created by Ivan Revchuk on 25.11.2025.
//

import XCTest
import UIKit
@testable import TabataTimer

// MARK: - Mocks — Test doubles for dependencies / Тестовые заглушки зависимостей

/// MockTimerEngine — controllable engine mock with manual AsyncStream.
/// MockTimerEngine — управляемый мок движка таймера с ручным AsyncStream.
private final class MockTimerEngine: TimerEngineProtocol {

    // MARK: Calls tracking — Method call recording / Фиксация вызовов методов движка
    enum Call: Equatable {
        case configure(count: Int)
        case start
        case pause
        case resume
        case reset
    }

    private(set) var calls: [Call] = []
    private(set) var configuredPlanCount: Int = 0

    // MARK: Events stream — Controlled AsyncStream / Управляемый AsyncStream
    private var streamContinuation: AsyncStream<TimerEvent>.Continuation!
    private var stream: AsyncStream<TimerEvent>!

    // MARK: Engine state / Состояние движка
    var state: TimerState = .idle

    // MARK: - Init — Инициализация
    init() {
        var cont: AsyncStream<TimerEvent>.Continuation!
        // Use buffering so events are not lost before subscriber attaches.
        // Используем буфер, чтобы события не терялись до подключения подписчика.
        self.stream = AsyncStream<TimerEvent>(bufferingPolicy: .bufferingOldest(10)) { c in
            cont = c
        }
        self.streamContinuation = cont
    }

    // MARK: - TimerEngineProtocol conformance / Реализация протокола TimerEngineProtocol
    func configure(with plan: [TabataInterval]) {
        configuredPlanCount = plan.count
        calls.append(.configure(count: plan.count))
        state = .idle
    }

    func start() {
        calls.append(.start)
        state = .running
    }

    func pause() {
        calls.append(.pause)
        state = .paused
    }

    func resume() {
        calls.append(.resume)
        state = .running
    }

    func reset() {
        calls.append(.reset)
        state = .idle
    }

    var events: AsyncStream<TimerEvent> { stream }

    // MARK: - Helpers — Test utilities / Вспомогательные методы для тестов

    /// Programmatically send a single event into the stream.
    /// Программно отправить одно событие в поток.
    func send(_ event: TimerEvent) {
        streamContinuation.yield(event)
    }

    /// Finish the events stream.
    /// Завершить поток событий.
    func finish() {
        streamContinuation.finish()
    }

    /// Clear recorded calls.
    /// Очистить историю вызовов.
    func clearCalls() {
        calls.removeAll()
    }
}

/// MockSoundService — sound service mock with invocation counters.
/// MockSoundService — мок звукового сервиса со счетчиками вызовов.
private final class MockSoundService: SoundServiceProtocol {
    private(set) var phaseChangeCount = 0
    private(set) var countdownTickCount = 0
    private(set) var completedCount = 0

    func playPhaseChange() { phaseChangeCount += 1 }
    func playCountdownTick() { countdownTickCount += 1 }
    func playCompleted() { completedCount += 1 }
}

/// MockHapticsService — haptics service mock with invocation counters.
/// MockHapticsService — мок сервиса хаптик со счетчиками вызовов.
private final class MockHapticsService: HapticsServiceProtocol {
    private(set) var phaseChangeCount = 0
    private(set) var countdownTickCount = 0
    private(set) var completedCount = 0

    func phaseChanged() { phaseChangeCount += 1 }
    func countdownTick() { countdownTickCount += 1 }
    func completed() { completedCount += 1 }
}

// MARK: - ActiveTimerViewModelTests — Tests for active workout VM / Тесты ViewModel активной тренировки
/// Tests that VM reacts to engine events and maps them into TabataSessionState.
/// Тесты, что VM корректно реагирует на события движка и маппит их в TabataSessionState.
@MainActor
final class ActiveTimerViewModelTests: XCTestCase {

    // MARK: - Fixture — Common config for tests / Общий конфиг для тестов
    private func makeConfig() -> TabataConfig {
        TabataConfig(
            prepare: 3,
            work: 2,
            rest: 1,
            cyclesPerSet: 2,
            sets: 1,
            restBetweenSets: 2
        )
    }

    // MARK: - Initial state — Idle state publishing / Публикация начального idle-состояния
    func test_initialIdleState_published() throws {
        // given
        let engine = MockTimerEngine()
        let sound = MockSoundService()
        let haptics = MockHapticsService()
        let config = makeConfig()

        // when
        let vm = ActiveTimerViewModel(
            config: config,
            engine: engine,
            sound: sound,
            haptics: haptics,
            settingsProvider: { AppSettings.default }
        )

        // then
        // Engine must be configured with computed plan.
        // Движок должен быть сконфигурирован вычисленным планом.
        XCTAssertTrue(engine.calls.contains { call in
            if case .configure = call { return true }
            return false
        })

        // Check published idle state.
        // Проверяем опубликованное idle-состояние.
        let state = vm.state
        XCTAssertEqual(state.currentIntervalIndex, 0)
        XCTAssertEqual(state.currentPhase, .prepare)
        XCTAssertEqual(state.remainingTime, 0)
        XCTAssertEqual(state.elapsedTime, 0)
        XCTAssertEqual(state.progress, 0)
        XCTAssertEqual(state.totalSets, config.sets)
        XCTAssertEqual(state.totalCyclesPerSet, config.cyclesPerSet)
    }

    // MARK: - Phase change — State update and triggers / Смена фазы и триггеры
    func test_phaseChanged_updatesState_andTriggers() async throws {
        // given
        let engine = MockTimerEngine()
        let sound = MockSoundService()
        let haptics = MockHapticsService()
        let config = makeConfig()

        let vm = ActiveTimerViewModel(
            config: config,
            engine: engine,
            sound: sound,
            haptics: haptics,
            settingsProvider: {
                AppSettings(
                    isSoundEnabled: true,
                    isHapticsEnabled: true,
                    theme: .system,
                    isAutoPauseEnabled: false,
                    autoStartFromPreset: false,
                    keepScreenAwake: false,
                    countdownSoundEnabled: true,
                    phaseChangeSoundEnabled: true,
                    finishSoundEnabled: true
                )
            }
        )

        // when
        engine.send(.phaseChanged(phase: .work, index: 1))
        // Give some time for async handler.
        // Даём время асинхронному обработчику.
        try await Task.sleep(nanoseconds: 60_000_000)

        // then
        let s = vm.state
        XCTAssertEqual(s.currentPhase, .work)
        XCTAssertEqual(s.currentIntervalIndex, 1)
        // Work duration from config = 2.
        // Длительность work из config = 2.
        XCTAssertEqual(s.remainingTime, 2)

        // Triggers must fire once.
        // Триггеры должны сработать по одному разу.
        XCTAssertEqual(sound.phaseChangeCount, 1)
        XCTAssertEqual(haptics.phaseChangeCount, 1)
    }

    // MARK: - Ticks and countdown — Tick + 3-2-1 dedup / Тики и обратный отсчёт
    func test_tick_updates_and_deduplicates_countdown() async throws {
        // given
        let engine = MockTimerEngine()
        let sound = MockSoundService()
        let haptics = MockHapticsService()
        let config = makeConfig()

        let vm = ActiveTimerViewModel(
            config: config,
            engine: engine,
            sound: sound,
            haptics: haptics,
            settingsProvider: {
                AppSettings(
                    isSoundEnabled: true,
                    isHapticsEnabled: true,
                    theme: .system,
                    isAutoPauseEnabled: false,
                    autoStartFromPreset: false,
                    keepScreenAwake: false,
                    countdownSoundEnabled: true,
                    phaseChangeSoundEnabled: true,
                    finishSoundEnabled: true
                )
            }
        )

        // when
        // Move to prepare (3 sec), then send ticks 3,2,2,1,1,0.
        // Переводим в prepare (3 сек), затем шлём тики 3,2,2,1,1,0.
        engine.send(.phaseChanged(phase: .prepare, index: 0))
        try await Task.sleep(nanoseconds: 30_000_000)

        engine.send(.tick(remaining: 3))
        try await Task.sleep(nanoseconds: 15_000_000)
        engine.send(.tick(remaining: 2))
        try await Task.sleep(nanoseconds: 15_000_000)
        engine.send(.tick(remaining: 2)) // duplicate 2 — must not double-trigger / дубль 2 — не должен дублировать
        try await Task.sleep(nanoseconds: 15_000_000)
        engine.send(.tick(remaining: 1))
        try await Task.sleep(nanoseconds: 15_000_000)
        engine.send(.tick(remaining: 1)) // duplicate 1 — must not double-trigger / дубль 1 — не должен дублировать
        try await Task.sleep(nanoseconds: 15_000_000)
        engine.send(.tick(remaining: 0))
        try await Task.sleep(nanoseconds: 30_000_000)

        // then
        // Check deduplication: exactly once for 3,2,1.
        // Проверяем дедупликацию: по одному разу для 3,2,1.
        XCTAssertEqual(sound.countdownTickCount, 3)
        XCTAssertEqual(haptics.countdownTickCount, 3)

        // Elapsed must grow at least by 1 over the sequence.
        // elapsed должен увеличиться минимум на 1 за последовательность тиков.
        XCTAssertGreaterThanOrEqual(vm.state.elapsedTime, 1)
    }

    // MARK: - Completion — Completed and triggers / Завершение и триггеры
    func test_completed_transitions_to_finished_and_triggers() async throws {
        // given
        let engine = MockTimerEngine()
        let sound = MockSoundService()
        let haptics = MockHapticsService()
        let config = makeConfig()

        let vm = ActiveTimerViewModel(
            config: config,
            engine: engine,
            sound: sound,
            haptics: haptics,
            settingsProvider: {
                AppSettings(
                    isSoundEnabled: true,
                    isHapticsEnabled: true,
                    theme: .system,
                    isAutoPauseEnabled: false,
                    autoStartFromPreset: false,
                    keepScreenAwake: false,
                    countdownSoundEnabled: true,
                    phaseChangeSoundEnabled: true,
                    finishSoundEnabled: true
                )
            }
        )

        // when
        engine.send(.completed)
        try await Task.sleep(nanoseconds: 40_000_000)

        // then
        let s = vm.state
        XCTAssertEqual(s.currentPhase, .finished)
        XCTAssertEqual(s.remainingTime, 0)
        XCTAssertEqual(s.elapsedTime, s.totalDuration)
        XCTAssertEqual(s.progress, 1.0)

        XCTAssertEqual(sound.completedCount, 1)
        XCTAssertEqual(haptics.completedCount, 1)
    }

    // MARK: - Auto-pause — willResignActive => pause() / Автопауза по willResignActive
    func test_autoPause_willResignActive_pauses_engine_when_enabled() async throws {
        // given
        let engine = MockTimerEngine()
        let sound = MockSoundService()
        let haptics = MockHapticsService()
        let config = makeConfig()

        let vm = ActiveTimerViewModel(
            config: config,
            engine: engine,
            sound: sound,
            haptics: haptics,
            settingsProvider: {
                AppSettings(
                    isSoundEnabled: true,
                    isHapticsEnabled: true,
                    theme: .system,
                    isAutoPauseEnabled: true,
                    autoStartFromPreset: false,
                    keepScreenAwake: false,
                    countdownSoundEnabled: true,
                    phaseChangeSoundEnabled: true,
                    finishSoundEnabled: true
                )
            }
        )

        // when
        NotificationCenter.default.post(
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        try await Task.sleep(nanoseconds: 40_000_000)

        // then
        XCTAssertTrue(engine.calls.contains(.pause))
        _ = vm // keep strong reference / удерживаем ссылку
    }

    // MARK: - Reset — Reset state and reconfigure engine / Сброс состояния и переконфигурация движка
    func test_reset_resets_state_and_reconfigures_engine() async throws {
        // given
        let engine = MockTimerEngine()
        let sound = MockSoundService()
        let haptics = MockHapticsService()
        let config = makeConfig()

        let vm = ActiveTimerViewModel(
            config: config,
            engine: engine,
            sound: sound,
            haptics: haptics,
            settingsProvider: { AppSettings.default }
        )

        // Simulate some progress: phase change + tick.
        // Имитация некоторого прогресса: смена фазы и тик.
        engine.send(.phaseChanged(phase: .work, index: 1))
        engine.send(.tick(remaining: 1))
        try await Task.sleep(nanoseconds: 40_000_000)

        // when
        engine.clearCalls()
        vm.reset()

        // then
        // Engine must receive reset and re-configure.
        // Движок должен получить reset и повторную configure.
        XCTAssertTrue(engine.calls.contains(.reset))
        XCTAssertTrue(engine.calls.contains { call in
            if case .configure = call { return true }
            return false
        })

        // State must return to initial idle.
        // Состояние должно вернуться к начальному idle.
        let state = vm.state
        XCTAssertEqual(state.currentIntervalIndex, 0)
        XCTAssertEqual(state.currentPhase, .prepare)
        XCTAssertEqual(state.elapsedTime, 0)
        XCTAssertEqual(state.progress, 0)
    }

    // MARK: - BuildPlan — Rebuild plan and update totalDuration / Пересборка плана
    func test_buildPlan_rebuilds_plan_and_updates_totalDuration() async throws {
        // given
        let engine = MockTimerEngine()
        let sound = MockSoundService()
        let haptics = MockHapticsService()

        // Initial config.
        // Начальный конфиг.
        let config = TabataConfig(
            prepare: 1,
            work: 2,
            rest: 1,
            cyclesPerSet: 1,
            sets: 1,
            restBetweenSets: 0
        )

        let vm = ActiveTimerViewModel(
            config: config,
            engine: engine,
            sound: sound,
            haptics: haptics,
            settingsProvider: { AppSettings.default }
        )

        let initialTotal = vm.state.totalDuration
        XCTAssertGreaterThan(initialTotal, 0)

        // when
        engine.clearCalls()
        vm.buildPlan()

        // then
        // Engine must be reconfigured.
        // Движок должен быть переконфигурирован.
        XCTAssertTrue(engine.calls.contains { call in
            if case .configure = call { return true }
            return false
        })

        // State is reset to beginning of plan.
        // Состояние сброшено в начало плана.
        let state = vm.state
        XCTAssertEqual(state.currentIntervalIndex, 0)
        XCTAssertEqual(state.currentPhase, .prepare)
        XCTAssertEqual(state.elapsedTime, 0)

        // totalDuration stays consistent (non-negative).
        // totalDuration должен оставаться консистентным (неотрицательным).
        XCTAssertGreaterThanOrEqual(state.totalDuration, 0)
    }
}
