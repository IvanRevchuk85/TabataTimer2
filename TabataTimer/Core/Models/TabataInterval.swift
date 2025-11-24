//
//  TabataInterval.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 24.11.2025.
//

import Foundation

// MARK: - Элементарный интервал плана тренировки
/// Представляет отдельный интервал с фазой и длительностью.
/// Индексы setIndex и cycleIndex помогают UI и логике отслеживать прогресс.
struct TabataInterval: Equatable, Hashable, Codable, Identifiable {
    // MARK: Идентификатор для UI-списков/отладки
    let id: UUID

    // MARK: Параметры интервала
    let phase: TabataPhase      // Тип фазы
    let duration: Int           // Длительность в секундах (0 для .finished)
    let setIndex: Int           // Индекс сета (0..<(sets))
    let cycleIndex: Int         // Индекс цикла внутри сета (0..<(cyclesPerSet)) или -1 для prepare/restBetweenSets/finished
    let orderIndex: Int         // Глобальный порядковый индекс интервала (для стабильной сортировки)

    // MARK: - Инициализация
    init(
        id: UUID = UUID(),
        phase: TabataPhase,
        duration: Int,
        setIndex: Int,
        cycleIndex: Int,
        orderIndex: Int
    ) {
        self.id = id
        self.phase = phase
        self.duration = max(0, duration)
        self.setIndex = max(-1, setIndex)
        self.cycleIndex = max(-1, cycleIndex)
        self.orderIndex = orderIndex
    }
}
