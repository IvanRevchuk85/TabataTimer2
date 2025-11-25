//
//  TabataSessionState.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 24.11.2025.
//

import Foundation

// MARK: - TabataSessionState — Состояние текущей сессии
/// Aggregate UI-facing state representing the current training session.
/// Агрегированное состояние для UI, представляющее текущую тренировочную сессию.
struct TabataSessionState: Equatable, Codable {
    // MARK: Identifiers — Идентификаторы
    /// Zero-based index of the current interval within the plan.
    /// Нулевой индекс текущего интервала в плане.
    var currentIntervalIndex: Int

    // MARK: Phase & time — Фаза и время
    /// Current phase (prepare/work/rest/restBetweenSets/finished).
    /// Текущая фаза (prepare/work/rest/restBetweenSets/finished).
    var currentPhase: TabataPhase
    /// Remaining time for the current interval (seconds).
    /// Оставшееся время текущего интервала (секунды).
    var remainingTime: Int
    /// Total duration of the whole session (seconds).
    /// Общая длительность всей сессии (секунды).
    var totalDuration: Int
    /// Elapsed time since the session started (seconds).
    /// Прошедшее время с начала сессии (секунды).
    var elapsedTime: Int

    // MARK: Progress — Прогресс
    /// Current set index (1-based for UI).
    /// Текущий номер сета (с 1 для UI).
    var currentSet: Int
    /// Total sets (for UI).
    /// Всего сетов (для UI).
    var totalSets: Int
    /// Current cycle index within the set (1-based for UI, 0 when not applicable).
    /// Текущий номер цикла в сете (с 1 для UI, 0 если не применимо).
    var currentCycle: Int
    /// Total cycles per set (for UI).
    /// Всего циклов в одном сете (для UI).
    var totalCyclesPerSet: Int

    /// Overall progress in [0, 1].
    /// Общий прогресс в диапазоне [0, 1].
    var progress: Double

    // MARK: - Initializers — Инициализаторы
    /// Creates an initial idle state.
    /// Создаёт начальное состояние idle.
    static func idle(totalSets: Int, totalCyclesPerSet: Int, totalDuration: Int) -> TabataSessionState {
        TabataSessionState(
            currentIntervalIndex: 0,
            currentPhase: .prepare,
            remainingTime: 0,
            totalDuration: totalDuration,
            elapsedTime: 0,
            currentSet: 0,
            totalSets: totalSets,
            currentCycle: 0,
            totalCyclesPerSet: totalCyclesPerSet,
            progress: 0
        )
    }
}
