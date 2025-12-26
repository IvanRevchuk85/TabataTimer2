//
//  TabataConfig.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 24.11.2025.
//

import Foundation

// MARK: - Конфигурация тренировки Табата
/// Входные параметры, определяющие структуру тренировки.
/// Значения в секундах, количество циклов и сетов — целые положительные значения.
struct TabataConfig: Equatable, Hashable, Codable {
    // MARK: Параметры времени (секунды)
    let prepare: Int          // Время подготовки перед началом первого интервала работы.
    let work: Int             // Длительность одного интервала работы.
    let rest: Int             // Длительность отдыха между циклами в одном сете.
    let restBetweenSets: Int  // Длительность отдыха между сетами.

    // MARK: Повторения
    let cyclesPerSet: Int     // Количество циклов (work+rest) в одном сете.
    let sets: Int             // Количество сетов.

    // MARK: - Инициализация с валидацией
    /// Инициализатор с минимальной валидацией входных значений.
    /// Допускает prepare/rest/restBetweenSets = 0; work должен быть > 0; cyclesPerSet и sets >= 1.
    init(
        prepare: Int,
        work: Int,
        rest: Int,
        cyclesPerSet: Int,
        sets: Int,
        restBetweenSets: Int
    ) {
        self.prepare = max(0, prepare)
        self.work = max(1, work) // работа должна быть положительной
        self.rest = max(0, rest)
        self.cyclesPerSet = max(1, cyclesPerSet)
        self.sets = max(1, sets)
        self.restBetweenSets = max(0, restBetweenSets)
    }

    // MARK: - Удобные дефолты (из ТЗ)
    /// Конфигурация по умолчанию:
    /// prepare: 10, work: 20, rest: 10, cyclesPerSet: 8, sets: 4, restBetweenSets: 60
    static var `default`: TabataConfig {
        TabataConfig(
            prepare: 10,
            work: 180,
            rest: 60,
            cyclesPerSet: 12,
            sets: 1,
            restBetweenSets: 0
        )
    }

    // MARK: - Производные значения
    /// Общее количество циклов во всей тренировке.
    var totalCycles: Int {
        cyclesPerSet * sets
    }

    /// Подсчет общей длительности тренировки (секунды), без учета "finished".
    /// Формула: prepare +
    /// sets * (cyclesPerSet * work + (cyclesPerSet - 1) * rest) +
    /// (sets - 1) * restBetweenSets
    func totalDuration() -> Int {
        let perSet = (cyclesPerSet * work) + max(0, (cyclesPerSet - 1)) * rest
        let betweenSets = max(0, (sets - 1)) * restBetweenSets
        return prepare + sets * perSet + betweenSets
    }
}
