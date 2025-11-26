//
//  Theme.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 26.11.2025.
//

import Foundation

// MARK: - Theme — Тема приложения (ключи и размеры)
// App-wide design tokens: color keys and font sizes (no SwiftUI dependency here).
// Глобальные токены дизайна: ключи цветов и размеры шрифтов (без зависимости от SwiftUI).
enum Theme {

    // MARK: Colors — Цветовые ключи
    enum Colors: String {
        // Phase-based colors — Цвета по фазам
        case phasePrepare       = "phase.prepare"
        case phaseWork          = "phase.work"
        case phaseRest          = "phase.rest"
        case phaseRestBetween   = "phase.restBetweenSets"
        case phaseFinished      = "phase.finished"

        // Neutrals — Нейтральные
        case textPrimary        = "text.primary"
        case textSecondary      = "text.secondary"
        case bgPrimary          = "bg.primary"
        case progressTrack      = "progress.track"
    }

    // MARK: Typography — Размеры шрифтов
    enum Typography {
        // Base sizes in points — Базовые размеры в пунктах
        static let titleXL: CGFloat = 64    // большой таймер
        static let titleL: CGFloat  = 28    // заголовок фазы
        static let titleM: CGFloat  = 20    // подзаголовки
        static let body: CGFloat    = 16    // основной текст
        static let caption: CGFloat = 13    // подписи
    }
}

