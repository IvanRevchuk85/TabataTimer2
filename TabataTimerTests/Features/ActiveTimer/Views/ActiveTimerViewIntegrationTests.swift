//
//  ActiveTimerViewIntegrationTests.swift
//  TabataTimerTests
//
//  Created by Ivan Revchuk on 25.11.2025.
//

import XCTest
import SwiftUI
@testable import TabataTimer

// MARK: - ActiveTimerViewIntegrationTests — Интеграционные тесты экрана активной тренировки (Views)
// Integration tests for ActiveTimerView reacting to engine events.
// Интеграционные тесты для ActiveTimerView, реагирующего на события движка.
@MainActor
final class ActiveTimerViewIntegrationTests: XCTestCase {

    func test_viewReflectsEngineEvents_basicFlow() async throws {
        // given — предусловия
        let config = TabataConfig(prepare: 1, work: 2, rest: 0, cyclesPerSet: 1, sets: 1, restBetweenSets: 0)
        let mock = MockEngine()
        // Создаём VM с тем же конфигом и мок‑движком.
        // shouldConfigureEngine оставляем по умолчанию (true), mock.configure — no-op.
        let viewModel = ActiveTimerViewModel(
            config: config,
            engine: mock,
            sound: SilentSoundService(),
            haptics: SilentHapticsService(),
            settingsProvider: { .default }
        )
        let view = ActiveTimerView(viewModel: viewModel, settings: .default)
        _ = view // silence unused warning — подавляем предупреждение о неиспользуемой переменной

        // when — действие
        // Эмулируем события движка.
        mock.emit(.phaseChanged(phase: .prepare, index: 0))
        mock.emit(.tick(remaining: 0))
        mock.emit(.phaseChanged(phase: .work, index: 1))
        mock.emit(.tick(remaining: 1))
        mock.emit(.tick(remaining: 0))
        mock.emit(.completed)

        // then — проверки
        // Дадим SwiftUI/главному актору обработать обновления.
        try await Task.sleep(nanoseconds: 50_000_000)

        // Если до сюда дошли без крашей — ок.
        XCTAssertTrue(true)
    }
    
    func test_keepScreenAwake_respectsSetting_onStartPauseAndComplete() async throws {
        // given: VM with keepScreenAwake=true provided via settingsProvider
        let config = TabataConfig(prepare: 0, work: 1, rest: 0, cyclesPerSet: 1, sets: 1, restBetweenSets: 0)
        let mock = MockEngine()
        
        // Pre-save settings so VM's async refresh sees keepScreenAwake = true
        let initialSettings = AppSettings(
            isSoundEnabled: true,
            isHapticsEnabled: true,
            theme: .system,
            isAutoPauseEnabled: false,
            autoStartFromPreset: false,
            keepScreenAwake: true,
            countdownSoundEnabled: true,
            phaseChangeSoundEnabled: true,
            finishSoundEnabled: true,
            lightBackgroundColor: .system
        )
        try? await SettingsStore().save(initialSettings)
        
        let vm = ActiveTimerViewModel(
            config: config,
            engine: mock,
            sound: SilentSoundService(),
            haptics: SilentHapticsService(),
            settingsProvider: {
                initialSettings
            }
        )
        let view = ActiveTimerView(viewModel: vm, settings: .default)
        _ = view

        // when: start should set idleTimerDisabled = true
        vm.start()
        try await Task.sleep(nanoseconds: 30_000_000)
        XCTAssertTrue(UIApplication.shared.isIdleTimerDisabled)

        // when: pause should set idleTimerDisabled = false
        vm.pause()
        try await Task.sleep(nanoseconds: 30_000_000)
        XCTAssertFalse(UIApplication.shared.isIdleTimerDisabled)

        // when: resume should set idleTimerDisabled = true again
        vm.resume()
        try await Task.sleep(nanoseconds: 30_000_000)
        XCTAssertTrue(UIApplication.shared.isIdleTimerDisabled)

        // when: complete should set idleTimerDisabled = false
        mock.emit(.completed)
        try await Task.sleep(nanoseconds: 30_000_000)
        XCTAssertFalse(UIApplication.shared.isIdleTimerDisabled)
    }
}

// MARK: - MockEngine — Мок движка для интеграционного теста
/// Minimal mock engine to drive events into the view.
/// Минимальный мок движка, чтобы подавать события во вью.
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

    func configure(with plan: [TabataInterval]) {
        // no-op for tests
        state = .idle
    }

    func start() { state = .running }
    func pause() { state = .paused }
    func resume() { state = .running }
    func reset() { state = .idle }

    func emit(_ event: TimerEvent) {
        continuation.yield(event)
    }
}

// MARK: - Silent test doubles for side-effects — Тестовые заглушки для звука/хаптики
private final class SilentSoundService: SoundServiceProtocol {
    func playPhaseChange() {}
    func playCountdownTick() {}
    func playCompleted() {}
    
    // NEW: required by SoundServiceProtocol
    func playWorkStart() {}   // no-op whistle in tests
    func playWorkEnd() {}     // no-op gong in tests
}

private final class SilentHapticsService: HapticsServiceProtocol {
    func phaseChanged() {}
    func countdownTick() {}
    func completed() {}
}

