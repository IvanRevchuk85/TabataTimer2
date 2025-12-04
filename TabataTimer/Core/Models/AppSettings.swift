//
//  AppSettings.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 27.11.2025.
//

import Foundation

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
            countdownSoundEnabled: true,
            phaseChangeSoundEnabled: true,
            finishSoundEnabled: true
        )
    }
}
