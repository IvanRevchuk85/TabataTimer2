//
//  TimerEvent.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 24.11.2025.
//

import Foundation

// MARK: - TimerEvent — Событие таймера
/// Events emitted by the timer engine to inform about progress and state changes.
/// События, которые эмитирует движок таймера для информирования о прогрессе и смене состояний.
enum TimerEvent: Equatable, Codable {
    /// Per-second tick with remaining time for the current interval (in seconds).
    /// Ежесекундный тик с оставшимся временем для текущего интервала (в секундах).
    case tick(remaining: Int)

    /// Current phase has changed to `phase` at interval index `index`.
    /// Текущая фаза сменилась на `phase` на интервале с индексом `index`.
    case phaseChanged(phase: TabataPhase, index: Int)

    /// All intervals are completed.
    /// Все интервалы завершены.
    case completed
}
