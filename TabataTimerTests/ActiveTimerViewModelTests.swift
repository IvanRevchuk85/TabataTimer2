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

    // NEW: counters for work start / end
    private(set) var workStartCount = 0
    private(set) var workEndCount = 0

    func playPhaseChange() { phaseChangeCount += 1 }
    func playCountdownTick() { countdownTickCount += 1 }
    func playCompleted() { completedCount += 1 }

    // NEW: implement protocol methods for whistle & gong
    func playWorkStart() { workStartCount += 1 }
    func playWorkEnd() { workEndCount += 1 }
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

    // MARK: - planDisplayItems mapping — Маппинг элементов отображения плана
    func test_planDisplayItems_mapsFromPlanCorrectly() {
        // given
        let engine = MockTimerEngine()
        let sound = MockSoundService()
        let haptics = MockHapticsService()
        // Config with enough variety: prepare + two cycles + restBetweenSets + finished
        let config = TabataConfig(
            prepare: 3,
            work: 5,
            rest: 2,
            cyclesPerSet: 2,
            sets: 1,
            restBetweenSets: 4
        )

        let vm = ActiveTimerViewModel(
            config: config,
            engine: engine,
            sound: sound,
            haptics: haptics,
            settingsProvider: { AppSettings.default }
        )

        // when
        let plan = vm.currentPlan
        let items = vm.planDisplayItems

        // then
        XCTAssertEqual(items.count, plan.count, "Items count must match plan count — Количество элементов должно совпадать с планом")

        // Check first, some middle, and last items to ensure mapping of fields
        if let firstPlan = plan.first, let firstItem = items.first {
            XCTAssertEqual(firstItem.id, firstPlan.id)
            XCTAssertEqual(firstItem.phase, firstPlan.phase)
            XCTAssertEqual(firstItem.duration, firstPlan.duration)
            XCTAssertEqual(firstItem.setIndex, firstPlan.setIndex)
            XCTAssertEqual(firstItem.cycleIndex, firstPlan.cycleIndex)
        }

        if plan.count >= 3 {
            let midIndex = plan.count / 2
            let midPlan = plan[midIndex]
            let midItem = items[midIndex]
            XCTAssertEqual(midItem.id, midPlan.id)
            XCTAssertEqual(midItem.phase, midPlan.phase)
            XCTAssertEqual(midItem.duration, midPlan.duration)
            XCTAssertEqual(midItem.setIndex, midPlan.setIndex)
            XCTAssertEqual(midItem.cycleIndex, midPlan.cycleIndex)
        }

        if let lastPlan = plan.last, let lastItem = items.last {
            XCTAssertEqual(lastItem.id, lastPlan.id)
            XCTAssertEqual(lastItem.phase, lastPlan.phase)
            XCTAssertEqual(lastItem.duration, lastPlan.duration)
            XCTAssertEqual(lastItem.setIndex, lastPlan.setIndex)
            XCTAssertEqual(lastItem.cycleIndex, lastPlan.cycleIndex)
        }
    }

    // MARK: - workoutTitle format — Формат строки заголовка плана
    func test_workoutTitle_containsSetsCyclesWorkRest() {
        // given
        let engine = MockTimerEngine()
        let sound = MockSoundService()
        let haptics = MockHapticsService()
        let config = TabataConfig(
            prepare: 10,
            work: 20,
            rest: 10,
            cyclesPerSet: 8,
            sets: 4,
            restBetweenSets: 60
        )

        let vm = ActiveTimerViewModel(
            config: config,
            engine: engine,
            sound: sound,
            haptics: haptics,
            settingsProvider: { AppSettings.default }
        )

        // when
        let title = vm.workoutTitle

        // then
        // Expected substrings:
        // "Sets 4 • Cycles 8 • Work 00:20 / Rest 00:10"
        XCTAssertTrue(title.contains("Sets \(config.sets)"), "Title should contain sets — Должно содержать количество сетов")
        XCTAssertTrue(title.contains("Cycles \(config.cyclesPerSet)"), "Title should contain cycles — Должно содержать количество циклов")

        let workMMSS = String(format: "%02d:%02d", config.work / 60, config.work % 60)
        let restMMSS = String(format: "%02d:%02d", config.rest / 60, config.rest % 60)

        XCTAssertTrue(title.contains("Work \(workMMSS)"), "Title should contain work duration mm:ss — Должно содержать длительность work в формате mm:ss")
        XCTAssertTrue(title.contains("Rest \(restMMSS)"), "Title should contain rest duration mm:ss — Должно содержать длительность rest в формате mm:ss")
    }

    // MARK: - NEW: whistle & gong — свисток и гонг

    func test_workStart_playsWhistleSound() async throws {
        // given
        let engine = MockTimerEngine()
        let sound = MockSoundService()
        let haptics = MockHapticsService()

        let vm = ActiveTimerViewModel(
            config: makeConfig(),
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
            },
            shouldConfigureEngine: false   // план нам тут не важен
        )
        _ = vm

        // when: сначала любая фаза, затем переход в work
        engine.send(.phaseChanged(phase: .work, index: 1))
        try await Task.sleep(nanoseconds: 50_000_000)

        // then
        // Work start should trigger whistle, not generic phase change.
        // При старте work должен сработать свисток, а не общий звук смены фазы.
        XCTAssertEqual(sound.workStartCount, 1,
                       "Whistle should be played exactly once when entering work"
        )
        XCTAssertEqual(sound.phaseChangeCount, 0,
                       "Gong must not be played on work start"
        )
    }

    func test_workEnd_playsGongSound() async throws {
        // given
        let engine = MockTimerEngine()
        let sound = MockSoundService()
        let haptics = MockHapticsService()

        let vm = ActiveTimerViewModel(
            config: makeConfig(),
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
            },
            shouldConfigureEngine: false
        )
        _ = vm

        // when: заходим в work, затем выходим из work (например, в rest)
        engine.send(.phaseChanged(phase: .work, index: 1))
        engine.send(.phaseChanged(phase: .rest, index: 2))
        try await Task.sleep(nanoseconds: 50_000_000)

        // then
        XCTAssertEqual(sound.workEndCount, 1, "Gong should be played once when work ends")
        XCTAssertEqual(sound.workStartCount, 1, "Whistle should have been played on entering work")
    }
}
