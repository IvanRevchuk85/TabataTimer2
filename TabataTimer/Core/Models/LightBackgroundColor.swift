//
//  LightBackgroundColor.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 23.12.2025.
//

import SwiftUI
/// Preset background colors for light mode.
/// Предустановленные цвета фона для светлого режима.
enum LightBackgroundColor: String, CaseIterable, Identifiable, Codable {
    case system
    case gray
    case blue
    case green
    case yellow
    case pink

    /// Localized user-facing title (English).
    /// Локализованное имя для пользователя (англ).
    var title: String {
        switch self {
        case .system: return "System"
        case .gray:   return "Gray"
        case .blue:   return "Blue"
        case .green:  return "Green"
        case .yellow: return "Yellow"
        case .pink:   return "Pink"
        }
    }

    /// Corresponding SwiftUI Color.
    /// Соответствующий цвет SwiftUI.
    var color: Color {
        switch self {
        case .system: return Color(UIColor.systemBackground)
        case .gray:   return Color(.systemGray6)
        case .blue:   return Color(.systemBlue).opacity(0.30)
        case .green:  return Color(.systemGreen).opacity(0.30)
        case .yellow: return Color(.systemYellow).opacity(0.30)
        case .pink:   return Color(.systemPink).opacity(0.30)
        }
    }

    /// Stable identifier for ForEach, etc.
    /// Стабильный идентификатор для ForEach и прочего.
    var id: String { rawValue }
}

