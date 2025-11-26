//
//  SoundServiceProtocol.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 26.11.2025.
//

import Foundation

// MARK: - SoundServiceProtocol — Протокол звукового сервиса
/// Abstraction for playing short sounds (phase changes, countdown ticks).
/// Абстракция для воспроизведения коротких звуков (смена фазы, обратный отсчёт).
protocol SoundServiceProtocol: AnyObject {

    // MARK: Phase sounds — Звуки смены фаз
    /// Play sound when phase changes (e.g., prepare → work).
    /// Проиграть звук при смене фазы (например, prepare → work).
    func playPhaseChange()

    // MARK: Countdown tick — Звук тика обратного отсчёта
    /// Play short tick for countdown (3…2…1).
    /// Проиграть короткий тик для обратного отсчёта (3…2…1).
    func playCountdownTick()

    // MARK: Completion — Завершение
    /// Play sound when session is completed.
    /// Проиграть звук при завершении сессии.
    func playCompleted()
}

