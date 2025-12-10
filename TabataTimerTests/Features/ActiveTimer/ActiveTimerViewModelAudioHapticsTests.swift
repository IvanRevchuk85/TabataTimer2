//
//  ActiveTimerViewModelAudioHapticsTests.swift
//  TabataTimerTests
//
//  Created by Ivan Revchuk on 26.11.2025.
//

import XCTest
@testable import TabataTimer

// MARK: - ActiveTimerViewModelAudioHapticsTests — Тесты триггеров звука/хаптики
/// Verifies that sounds and haptics are triggered on phase change, countdown (3..2..1), and completion.
/// Проверяет, что звук и хаптика вызываются при смене фазы, обратном отсчёте (3..2..1) и завершении.
@MainActor
final class ActiveTimerViewModelAudioHapticsTests: XCTestCase {

    func test_phaseChanged_triggersSoundAndHaptics() async throws {
        // given
        let config = TabataConfig(prepare: 0, work: 2, rest: 0, cyclesPerSet: 1, sets: 1, restBetweenSets: 0)
        let engine = MockEngine()
        let sound = MockSoundService()
        let haptics = MockHapticsService()
        let vm = ActiveTimerViewModel(config: config, engine: engine, sound: sound, haptics: haptics)
        _ = vm // удерживаем ссылку

        // when
        engine.emit(.phaseChanged(phase: .work, index: 0))
        try await Task.sleep(nanoseconds: 20_000_000)

        // then
        XCTAssertEqual(sound.phaseChangeCount, 1)
        XCTAssertEqual(haptics.phaseChangeCount, 1)
    }

    func test_countdownTicks_321_triggerSoundAndHaptics() async throws {
        // given
        let config = TabataConfig(prepare: 0, work: 5, rest: 0, cyclesPerSet: 1, sets: 1, restBetweenSets: 0)
        let engine = MockEngine()
        let sound = MockSoundService()
        let haptics = MockHapticsService()
        let vm = ActiveTimerViewModel(config: config, engine: engine, sound: sound, haptics: haptics)
        _ = vm // удерживаем ссылку

        // when: simulate ticks with remaining 3, 2, 1
        engine.emit(.phaseChanged(phase: .work, index: 0))
        engine.emit(.tick(remaining: 3))
        engine.emit(.tick(remaining: 2))
        engine.emit(.tick(remaining: 1))
        try await Task.sleep(nanoseconds: 30_000_000)

        // then
        XCTAssertEqual(sound.countdownCount, 3)
        XCTAssertEqual(haptics.countdownCount, 3)
    }

    func test_completed_triggersSoundAndHaptics() async throws {
        // given
        let config = TabataConfig(prepare: 0, work: 1, rest: 0, cyclesPerSet: 1, sets: 1, restBetweenSets: 0)
        let engine = MockEngine()
        let sound = MockSoundService()
        let haptics = MockHapticsService()
        let vm = ActiveTimerViewModel(config: config, engine: engine, sound: sound, haptics: haptics)
        _ = vm // удерживаем ссылку

        // when
        engine.emit(.completed)
        try await Task.sleep(nanoseconds: 20_000_000)

        // then
        XCTAssertEqual(sound.completedCount, 1)
        XCTAssertEqual(haptics.completedCount, 1)
    }
}

// MARK: - Mocks — Моки сервисов и движка
private final class MockSoundService: SoundServiceProtocol {
    var phaseChangeCount = 0
    var countdownCount = 0
    var completedCount = 0
    
    // NEW: counters for whistle & gong
    var workStartCount = 0
    var workEndCount = 0

    func playPhaseChange() { phaseChangeCount += 1 }
    func playCountdownTick() { countdownCount += 1 }
    func playCompleted() { completedCount += 1 }
    
    // NEW: required by protocol
    func playWorkStart() { workStartCount += 1 }
    func playWorkEnd() { workEndCount += 1 }
}

private final class MockHapticsService: HapticsServiceProtocol {
    var phaseChangeCount = 0
    var countdownCount = 0
    var completedCount = 0

    func phaseChanged() { phaseChangeCount += 1 }
    func countdownTick() { countdownCount += 1 }
    func completed() { completedCount += 1 }
}

private final class MockEngine: TimerEngineProtocol {

    private(set) var state: TimerState = .idle

    private let stream: AsyncStream<TimerEvent>
    private let continuation: AsyncStream<TimerEvent>.Continuation

    init() {
        var cont: AsyncStream<TimerEvent>.Continuation!
        stream = AsyncStream<TimerEvent> { c in cont = c }
        continuation = cont
    }

    var events: AsyncStream<TimerEvent> { stream }

    func configure(with plan: [TabataInterval]) { state = .idle }
    func start() { state = .running }
    func pause() { state = .paused }
    func resume() { state = .running }
    func reset() { state = .idle }

    func emit(_ event: TimerEvent) {
        continuation.yield(event)
    }
}
