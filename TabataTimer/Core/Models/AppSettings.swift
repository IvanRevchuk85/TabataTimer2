//
//  AppSettings.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 27.11.2025.
//

import Foundation
import SwiftUI

// MARK: - AppSettings — Модель настроек приложения
// AppSettings — application settings model (persisted via SettingsStore).
// Модель настроек приложения (сохраняется через SettingsStore).
struct AppSettings: Equatable, Hashable, Codable {

    // MARK: Sound — Звук (глобальный переключатель)
    /// Enable/disable all sounds at once (master switch).
    /// Глобальный переключатель звуков (включает/выключает все звуки разом).
    var isSoundEnabled: Bool

    // MARK: Haptics — Хаптика
    /// Enable/disable haptics feedback.
    /// Включить/выключить хаптику.
    var isHapticsEnabled: Bool

    // MARK: Theme — Тема оформления
    /// Preferred theme (system / light / dark).
    /// Предпочитаемая тема (системная / светлая / тёмная).
    var theme: Theme

    // MARK: Auto-pause — Автопауза
    /// Auto-pause timer on app going to background (if supported).
    /// Автопауза таймера при уходе приложения в фон (если поддерживается).
    var isAutoPauseEnabled: Bool

    // MARK: Behavior — Поведение таймера
    /// Auto-start the timer when opening from a preset.
    /// Автозапуск таймера при открытии из пресета.
    var autoStartFromPreset: Bool

    /// Keep screen awake during training session.
    /// Не гасить экран во время тренировки.
    var keepScreenAwake: Bool
    
    // Add near other flags
    var inWorkoutPhrasesEnabled: Bool

    // MARK: Sound details — Детализация звуков
    /// Countdown 3‑2‑1 sound.
    /// Звук обратного отсчёта 3‑2‑1.
    var countdownSoundEnabled: Bool

    /// Phase change sound.
    /// Звук смены фазы.
    var phaseChangeSoundEnabled: Bool

    /// Finish sound.
    /// Звук завершения тренировки.
    var finishSoundEnabled: Bool

    /// Preferred light mode background color (used only in light theme).
    /// Предпочтительный цвет фона для светлой темы (только для светлой темы).
    var lightBackgroundColor: LightBackgroundColor

    // MARK: - Theme — Перечисление тем
    enum Theme: String, Equatable, Hashable, Codable, CaseIterable {
        case system
        case light
        case dark

        /// Human-readable title (EN) — Человекочитаемое имя (EN)
        var title: String {
            switch self {
            case .system: return "System"
            case .light:  return "Light"
            case .dark:   return "Dark"
            }
        }
    }

    // MARK: - Defaults — Значения по умолчанию
    /// Default settings used on first launch.
    /// Значения по умолчанию при первом запуске.
    static var `default`: AppSettings {
        AppSettings(
            isSoundEnabled: true,
            isHapticsEnabled: true,
            theme: .system,
            isAutoPauseEnabled: false,
            autoStartFromPreset: false,
            keepScreenAwake: false,
            inWorkoutPhrasesEnabled: true,
            countdownSoundEnabled: true,
            phaseChangeSoundEnabled: true,
            finishSoundEnabled: true,
            lightBackgroundColor: .system,
        )
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case isSoundEnabled
        case isHapticsEnabled
        case theme
        case isAutoPauseEnabled
        case autoStartFromPreset
        case keepScreenAwake
        case inWorkoutPhrasesEnabled
        case countdownSoundEnabled
        case phaseChangeSoundEnabled
        case finishSoundEnabled
        case lightBackgroundColor
    }
}
extension AppSettings {
    // MARK: - Codable
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isSoundEnabled = try container.decode(Bool.self, forKey: .isSoundEnabled)
        isHapticsEnabled = try container.decode(Bool.self, forKey: .isHapticsEnabled)
        theme = try container.decode(Theme.self, forKey: .theme)
        isAutoPauseEnabled = try container.decode(Bool.self, forKey: .isAutoPauseEnabled)
        autoStartFromPreset = try container.decode(Bool.self, forKey: .autoStartFromPreset)
        keepScreenAwake = try container.decode(Bool.self, forKey: .keepScreenAwake)
        inWorkoutPhrasesEnabled = try container.decodeIfPresent(Bool.self, forKey: .inWorkoutPhrasesEnabled) ?? true
        countdownSoundEnabled = try container.decode(Bool.self, forKey: .countdownSoundEnabled)
        phaseChangeSoundEnabled = try container.decode(Bool.self, forKey: .phaseChangeSoundEnabled)
        finishSoundEnabled = try container.decode(Bool.self, forKey: .finishSoundEnabled)
        // NEW: decodeIfPresent fallback
        lightBackgroundColor = try container.decodeIfPresent(LightBackgroundColor.self, forKey: .lightBackgroundColor) ?? .system
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isSoundEnabled, forKey: .isSoundEnabled)
        try container.encode(isHapticsEnabled, forKey: .isHapticsEnabled)
        try container.encode(theme, forKey: .theme)
        try container.encode(isAutoPauseEnabled, forKey: .isAutoPauseEnabled)
        try container.encode(autoStartFromPreset, forKey: .autoStartFromPreset)
        try container.encode(keepScreenAwake, forKey: .keepScreenAwake)
        try container.encode(inWorkoutPhrasesEnabled, forKey: .inWorkoutPhrasesEnabled)
        try container.encode(countdownSoundEnabled, forKey: .countdownSoundEnabled)
        try container.encode(phaseChangeSoundEnabled, forKey: .phaseChangeSoundEnabled)
        try container.encode(finishSoundEnabled, forKey: .finishSoundEnabled)
        try container.encode(lightBackgroundColor, forKey: .lightBackgroundColor)
    }
}

