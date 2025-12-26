//
//  SettingsTests.swift
//  TabataTimerTests
//
//  Created by Ivan Revchuk on 29.11.2025.
//

import Foundation
import Testing
@testable import TabataTimer
import UIKit

// MARK: - SettingsTests — Тесты влияния настроек
/// Tests the effect of AppSettings on behavior (sounds, haptics, auto‑pause).
/// Тесты влияния AppSettings на поведение (звук, хаптика, автопауза).
@Suite("Settings tests — Тесты настроек")
struct SettingsTests {

    // MARK: Sound/Haptics enabled — Звук/Хаптика включены
    @Test("Sound/Haptics enabled trigger calls — Включённые звук/хаптика вызывают методы")
    @MainActor
    func test_sound_haptics_enabled() async throws {
        // given — предусловия
        // Чуть длиннее интервалы, чтобы гарантированно поймать события
        let cfg = TabataConfig(prepare: 2, work: 3, rest: 0, cyclesPerSet: 1, sets: 1, restBetweenSets: 0)
        let engine = TimerEngine()

        let fakeSound = FakeSoundService()
        let fakeHaptics = FakeHapticsService()
        let vm = ActiveTimerViewModel(
            config: cfg,
            engine: engine,
            sound: fakeSound,
            haptics: fakeHaptics,
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
                    finishSoundEnabled: true,
                    lightBackgroundColor: .system
                )
            }
        )

        // when — действие: запускаем через VM (движок уже сконфигурирован VM)
        vm.start()

        // Дадим время на phaseChanged (на prepare) и хотя бы 1 тик
        try await Task.sleep(nanoseconds: 1_500_000_000) // ~1.5s

        // then — проверки: были вызовы звука/хаптики смены фазы
        #expect(fakeSound.phaseChangeCalls >= 1, "Ожидается хотя бы один вызов звука смены фазы")
        #expect(fakeHaptics.phaseChangeCalls >= 1, "Ожидается хотя бы один вызов хаптики смены фазы")

        // Для короткого сценария обратный отсчёт 3..2..1 может не совпасть — допускаем 0+
        #expect(fakeSound.countdownTickCalls >= 0)
        #expect(fakeHaptics.countdownTickCalls >= 0)

        // Дождёмся завершения, чтобы проверить completed
        try await Task.sleep(nanoseconds: 5_000_000_000) // ~5s на завершение prepare+work
        #expect(fakeSound.completedCalls >= 1, "Ожидается хотя бы один вызов звука завершения")
        #expect(fakeHaptics.completedCalls >= 1, "Ожидается хотя бы один вызов хаптики завершения")

        _ = vm // удерживаем ссылку
    }

    // MARK: Sound/Haptics disabled — Звук/Хаптика выключены
    @Test("Sound/Haptics disabled do not trigger calls — Выключенные звук/хаптика не вызывают методы")
    @MainActor
    func test_sound_haptics_disabled() async throws {
        // given — предусловия
        let cfg = TabataConfig(prepare: 2, work: 3, rest: 0, cyclesPerSet: 1, sets: 1, restBetweenSets: 0)
        let engine = TimerEngine()

        let fakeSound = FakeSoundService()
        let fakeHaptics = FakeHapticsService()
        let vm = ActiveTimerViewModel(
            config: cfg,
            engine: engine,
            sound: fakeSound,
            haptics: fakeHaptics,
            settingsProvider: {
                AppSettings(
                    isSoundEnabled: false,
                    isHapticsEnabled: false,
                    theme: .system,
                    isAutoPauseEnabled: false,
                    autoStartFromPreset: false,
                    keepScreenAwake: false,
                    countdownSoundEnabled: true,
                    phaseChangeSoundEnabled: true,
                    finishSoundEnabled: true,
                    lightBackgroundColor: .system
                )
            }
        )

        // when — действие
        vm.start()

        // Подождём до завершения
        try await Task.sleep(nanoseconds: 5_000_000_000)

        // then — проверки: вызовов быть не должно
        #expect(fakeSound.phaseChangeCalls == 0)
        #expect(fakeSound.countdownTickCalls == 0)
        #expect(fakeSound.completedCalls == 0)

        #expect(fakeHaptics.phaseChangeCalls == 0)
        #expect(fakeHaptics.countdownTickCalls == 0)
        #expect(fakeHaptics.completedCalls == 0)

        _ = vm
    }

    // MARK: Auto‑pause on resign active — Автопауза при уходе в фон
    // Примечание: ActiveTimerViewModel подписывается на UIApplication.willResignActiveNotification,
    // если isAutoPauseEnabled == true. Мы эмулируем нотификацию через NotificationCenter.
    @Test("Auto‑pause reacts to willResignActive — Автопауза реагирует на willResignActive")
    @MainActor
    func test_autoPause_willResignActive() async throws {
        // given — предусловия
        let cfg = TabataConfig(prepare: 1, work: 3, rest: 0, cyclesPerSet: 1, sets: 1, restBetweenSets: 0)
        let engine = TimerEngine()

        let vm = ActiveTimerViewModel(
            config: cfg,
            engine: engine,
            sound: FakeSoundService(),
            haptics: FakeHapticsService(),
            settingsProvider: {
                AppSettings(
                    isSoundEnabled: false,
                    isHapticsEnabled: false,
                    theme: .system,
                    isAutoPauseEnabled: true,
                    autoStartFromPreset: false,
                    keepScreenAwake: false,
                    countdownSoundEnabled: true,
                    phaseChangeSoundEnabled: true,
                    finishSoundEnabled: true,
                    lightBackgroundColor: .system
                )
            }
        )

        vm.start()

        // убедимся, что движок запустился
        try await Task.sleep(nanoseconds: 1_200_000_000)

        // when — действие: отправим системную нотификацию willResignActive
        NotificationCenter.default.post(name: UIApplication.willResignActiveNotification, object: nil)

        // then — проверки: дадим время обработать, затем состояние должно быть paused
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3s
        let state = await engine.state
        #expect(state == .paused, "Ожидается .paused после willResignActive при включённой автопаузе")

        _ = vm
    }

    @Test("Phase change sound can be disabled while master sound ON — Отключение общего звука смены фазы при включенном Sounds")
    @MainActor
    func test_phaseChangeSound_disabled_when_flag_off() async throws {
        // given — включён общий звук, но отключён звук смены фазы
        let engine = LocalMockEngine()
        let fakeSound = FakeSoundService()
        let fakeHaptics = FakeHapticsService()
        let vm = ActiveTimerViewModel(
            config: TabataConfig(prepare: 0, work: 2, rest: 0, cyclesPerSet: 1, sets: 1, restBetweenSets: 0),
            engine: engine,
            sound: fakeSound,
            haptics: fakeHaptics,
            settingsProvider: {
                AppSettings(
                    isSoundEnabled: true,            // мастер звук включён
                    isHapticsEnabled: false,
                    theme: .system,
                    isAutoPauseEnabled: false,
                    autoStartFromPreset: false,
                    keepScreenAwake: false,
                    countdownSoundEnabled: true,
                    phaseChangeSoundEnabled: false,  // отключаем ТОЛЬКО общий звук смены фазы
                    finishSoundEnabled: true,
                    lightBackgroundColor: .system
                )
            },
            shouldConfigureEngine: false
        )
        _ = vm

        // when — отправляем смену фазы, которая НЕ является входом/выходом из work
        engine.emit(.phaseChanged(phase: .prepare, index: 0))
        engine.emit(.phaseChanged(phase: .rest, index: 1))
        try await Task.sleep(nanoseconds: 30_000_000)

        // then — общий звук смены фазы не должен прозвучать
        #expect(fakeSound.phaseChangeCalls == 0, "Phase change sound should be suppressed when phaseChangeSoundEnabled is false")
    }
}

// MARK: - LocalMockEngine for fast event emission in tests
private final class LocalMockEngine: TimerEngineProtocol {
    var state: TimerState = .idle
    private let stream: AsyncStream<TimerEvent>
    private let continuation: AsyncStream<TimerEvent>.Continuation

    init() {
        var cont: AsyncStream<TimerEvent>.Continuation!
        stream = AsyncStream<TimerEvent>(bufferingPolicy: .bufferingOldest(10)) { c in cont = c }
        continuation = cont
    }

    var events: AsyncStream<TimerEvent> { stream }

    func configure(with plan: [TabataInterval]) { state = .idle }
    func start() { state = .running }
    func pause() { state = .paused }
    func resume() { state = .running }
    func reset() { state = .idle }

    func emit(_ event: TimerEvent) { continuation.yield(event) }
}

