//
//  FakeSoundHaptics.swift
//  TabataTimerTests
//
//  Created by Ivan Revchuk on 29.11.2025.
//

import Foundation
@testable import TabataTimer

// MARK: - FakeSoundService — фейковый звуковой сервис
/// In-memory fake that counts sound calls for assertions in tests.
/// In-memory фейк, считающий вызовы звуковых методов для проверок в тестах.
final class FakeSoundService: SoundServiceProtocol {

    // Counters for all sound kinds / Счётчики для всех видов звуков
    private(set) var phaseChangeCalls = 0
    private(set) var countdownTickCalls = 0
    private(set) var completedCalls = 0
    private(set) var workStartCalls = 0       // NEW: whistle
    private(set) var workEndCalls = 0         // NEW: gong

    func playPhaseChange() {
        phaseChangeCalls += 1
    }

    func playCountdownTick() {
        countdownTickCalls += 1
    }

    func playCompleted() {
        completedCalls += 1
    }

    // NEW: whistle at work start / свисток при начале work
    func playWorkStart() {
        workStartCalls += 1
    }

    // NEW: gong at work end / гонг при окончании work
    func playWorkEnd() {
        workEndCalls += 1
    }

    /// Reset counters to zero.
    /// Сбросить счётчики в ноль.
    func reset() {
        phaseChangeCalls = 0
        countdownTickCalls = 0
        completedCalls = 0
        workStartCalls = 0
        workEndCalls = 0
    }
}

// MARK: - FakeHapticsService — фейковый сервис хаптики
/// In-memory fake that counts haptics calls for assertions in tests.
/// In-memory фейк, считающий вызовы хаптик для проверок в тестах.
final class FakeHapticsService: HapticsServiceProtocol {

    private(set) var phaseChangeCalls = 0
    private(set) var countdownTickCalls = 0
    private(set) var completedCalls = 0

    func phaseChanged() {
        phaseChangeCalls += 1
    }

    func countdownTick() {
        countdownTickCalls += 1
    }

    func completed() {
        completedCalls += 1
    }

    func reset() {
        phaseChangeCalls = 0
        countdownTickCalls = 0
        completedCalls = 0
    }
}
