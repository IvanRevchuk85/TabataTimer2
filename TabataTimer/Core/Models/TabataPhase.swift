//
//  TabataPhase.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 24.11.2025.


import Foundation

// MARK: - Фаза тренировки табата
/// Описывает тип текущего интервала тренировки.
/// Логика и UI будут опираться на это перечисление для выбора цвета, звука, текста и т.д.
enum TabataPhase: Equatable, Hashable, Codable {
    /// Подготовка перед стартом первого интервала работы.
    case prepare
    /// Интервал работы (высокой интенсивности).
    case work
    /// Интервал отдыха между циклами в рамках одного сета.
    case rest
    /// Интервал отдыха между сетами.
    case restBetweenSets
    /// Финальное состояние — тренировка завершена.
    case finished
}

// MARK: - Метаданные для отображения
extension TabataPhase {
    /// Короткое текстовое имя фазы — может пригодиться для UI/логов.
    var title: String {
        switch self {
        case .prepare: return "Prepare"
        case .work: return "Work"
        case .rest: return "Rest"
        case .restBetweenSets: return "Rest Between Sets"
        case .finished: return "Finished"
        }
    }

    /// Ключ цвета (без привязки к SwiftUI Color на этом этапе).
    /// Позже свяжем с палитрой в Theme.
    var colorKey: String {
        switch self {
        case .prepare: return "phase.prepare"
        case .work: return "phase.work"
        case .rest: return "phase.rest"
        case .restBetweenSets: return "phase.restBetweenSets"
        case .finished: return "phase.finished"
        }
    }
}
