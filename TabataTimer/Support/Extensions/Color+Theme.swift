//
//  Color+Theme.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 26.11.2025.
//

import SwiftUI

// MARK: - Color+Theme — Маппинг цветовых ключей в SwiftUI Color
/// Maps Theme.Colors keys to actual SwiftUI Color values.
/// Маппит ключи Theme.Colors в реальные значения SwiftUI Color.
extension Color {

    // Resolve a theme color by key — Получить цвет темы по ключу
    static func theme(_ key: Theme.Colors) -> Color {
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

