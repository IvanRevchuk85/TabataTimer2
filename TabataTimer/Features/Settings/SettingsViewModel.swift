//
//  SettingsViewModel.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 27.11.2025.
//

import Foundation
import Combine

// MARK: - SettingsViewModel — Модель представления настроек
// SettingsViewModel — bridges SettingsStore to UI (load/edit/save).
// Модель представления, связывающая хранилище настроек с UI (загрузка/редактирование/сохранение).
@MainActor
final class SettingsViewModel: ObservableObject {

    // MARK: Published — Публикуемые свойства
    /// Текущие настройки (редактируемые в UI).
    /// Current editable settings for the UI.
    @Published var settings: AppSettings = .default

    /// Флаги загрузки/сохранения и сообщение об ошибке.
    /// Loading/saving flags and optional error message.
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var isSaving: Bool = false
    @Published var errorMessage: String?

    // MARK: Dependencies — Зависимости
    private let store: SettingsStoreProtocol

    // MARK: - Init — Инициализация
    init(store: SettingsStoreProtocol = SettingsStore()) {
        self.store = store
    }

    // MARK: - Load — Загрузка настроек
    /// Загрузить настройки из хранилища (или дефолты).
    /// Load settings from store (or defaults).
    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let loaded = try await store.load()
            settings = loaded
        } catch {
            settings = .default
            errorMessage = "Failed to load settings — Не удалось загрузить настройки"
        }
    }

    // MARK: - Save — Сохранение настроек
    /// Сохранить текущие настройки.
    /// Save current settings to store.
    func save() async {
        isSaving = true
        defer { isSaving = false }
        do {
            try await store.save(settings)
        } catch {
            errorMessage = "Failed to save settings — Не удалось сохранить настройки"
        }
    }

    // MARK: - Reset — Сброс к значениям по умолчанию
    /// Сбросить сохранённые настройки и загрузить дефолты.
    /// Reset persisted settings and load defaults.
    func resetToDefaults() async {
        do {
            try await store.reset()
            settings = .default
        } catch {
            errorMessage = "Failed to reset settings — Не удалось сбросить настройки"
        }
    }

    // MARK: - Toggles — Переключатели
    /// Переключить звук (глобальный мастер-переключатель).
    func toggleSound(_ isOn: Bool) {
        settings.isSoundEnabled = isOn
    }

    /// Переключить хаптику.
    func toggleHaptics(_ isOn: Bool) {
        settings.isHapticsEnabled = isOn
    }

    /// Переключить автопаузу.
    func toggleAutoPause(_ isOn: Bool) {
        settings.isAutoPauseEnabled = isOn
    }

    /// Изменить тему.
    func setTheme(_ theme: AppSettings.Theme) {
        settings.theme = theme
    }

    /// Автозапуск таймера при открытии пресета.
    func toggleAutoStartFromPreset(_ isOn: Bool) {
        settings.autoStartFromPreset = isOn
    }

    /// Не давать экрану гаснуть во время тренировки.
    func toggleKeepScreenAwake(_ isOn: Bool) {
        settings.keepScreenAwake = isOn
    }

    /// Детализация звуков — обратный отсчёт 3‑2‑1.
    func toggleCountdownSound(_ isOn: Bool) {
        settings.countdownSoundEnabled = isOn
    }

    /// Детализация звуков — смена фазы.
    func togglePhaseChangeSound(_ isOn: Bool) {
        settings.phaseChangeSoundEnabled = isOn
    }

    /// Детализация звуков — завершение.
    func toggleFinishSound(_ isOn: Bool) {
        settings.finishSoundEnabled = isOn
    }
}
