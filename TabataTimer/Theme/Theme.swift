//
//  Theme.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 26.11.2025.
//

import Foundation
import CoreGraphics

// MARK: - DesignTokens — Токены дизайна (цветовые ключи и размеры)
// App-wide design tokens: color keys and font sizes (no SwiftUI dependency here).
// Глобальные токены дизайна: ключи цветов и размеры шрифтов (без зависимости от SwiftUI).
enum DesignTokens {

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

// MARK: - Theme bridge — Мост совместимости с прежними ссылками
/// Theme — тонкая обёртка-алиас над DesignTokens для совместимости.
/// Позволяет использовать Theme.Colors и Theme.Typography, но источник данных — DesignTokens.
enum Theme {
    typealias Colors = DesignTokens.Colors

    enum Typography {
        static let titleXL = DesignTokens.Typography.titleXL
        static let titleL  = DesignTokens.Typography.titleL
        static let titleM  = DesignTokens.Typography.titleM
        static let body    = DesignTokens.Typography.body
        static let caption = DesignTokens.Typography.caption
    }
}
