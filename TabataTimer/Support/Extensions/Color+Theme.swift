//
//  Color+Theme.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 26.11.2025.
//

import SwiftUI
import SwiftUI

// MARK: - Color+Theme — Маппинг цветовых ключей в SwiftUI Color
/// Maps DesignTokens.Colors keys to actual SwiftUI Color values.
/// Маппит ключи DesignTokens.Colors в реальные значения SwiftUI Color.
extension Color {

    // Resolve a theme color by key — Получить цвет темы по ключу
    static func theme(_ key: DesignTokens.Colors) -> Color {
        switch key {
        // Phase colors — Цвета фаз
        case .phasePrepare:      return Color.orange
        case .phaseWork:         return Color.red
        case .phaseRest:         return Color.blue
        case .phaseRestBetween:  return Color.purple
        case .phaseFinished:     return Color.green

        // Neutrals — Нейтральные
        case .textPrimary:       return Color.primary
        case .textSecondary:     return Color.secondary
        case .bgPrimary:         return Color(UIColor.systemBackground)
        case .progressTrack:     return Color.gray.opacity(0.2)
        }
    }

    // Convenience for phase → color — Удобство: фаза → цвет
    static func forPhase(_ phase: TabataPhase) -> Color {
        switch phase {
        case .prepare:         return .theme(.phasePrepare)
        case .work:            return .theme(.phaseWork)
        case .rest:            return .theme(.phaseRest)
        case .restBetweenSets: return .theme(.phaseRestBetween)
        case .finished:        return .theme(.phaseFinished)
        }
    }
}
extension Color {
    /// Resolves app background color for current settings and effective theme.
    /// Возвращает фоновый цвет приложения по настройкам и текущей теме.
    /// - Parameters:
    ///   - settings: User settings containing theme and lightBackgroundColor
    ///   - colorScheme: System color scheme (from Environment)
    static func appBackground(settings: AppSettings, colorScheme: ColorScheme) -> Color {
        // Determine effective theme (system/light/dark)
        let effective: AppSettings.Theme
        switch settings.theme {
        case .system:
            effective = (colorScheme == .dark) ? .dark : .light
        case .light:
            effective = .light
        case .dark:
            effective = .dark
        }
        // Light: use chosen preset. Dark: use standard bgPrimary.
        if effective == .light {
            return settings.lightBackgroundColor.color
        } else {
            return Color.theme(.bgPrimary)
        }
    }
}

