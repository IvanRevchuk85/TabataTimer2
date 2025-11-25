//
//  TimerState.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 24.11.2025.
//

import Foundation

// MARK: - TimerState — Состояние таймера
/// High-level state of the timer lifecycle.
/// Высокоуровневое состояние жизненного цикла таймера.
enum TimerState: Equatable, Codable {
    /// Timer is configured but not running.
    /// Таймер сконфигурирован, но не запущен.
    case idle

    /// Timer is actively counting down.
    /// Таймер активно ведёт отсчёт.
    case running

    /// Timer is paused and can be resumed.
    /// Таймер на паузе и может быть возобновлён.
    case paused

    /// Timer has finished all intervals.
    /// Таймер завершил все интервалы.
    case finished
}

// MARK: - Helpers — Вспомогательные свойства
extension TimerState {
    /// Convenience flags — Удобные флаги
    var isActive: Bool {
        // Running is considered active — Состояние running считается активным
        self == .running
    }

    var isTerminal: Bool {
        // Finished is terminal — Состояние finished является терминальным
        self == .finished
    }

    var isPaused: Bool {
        self == .paused
    }

    var isIdle: Bool {
        self == .idle
    }
}
