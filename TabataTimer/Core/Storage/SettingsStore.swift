//
//  SettingsStore.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 27.11.2025.
//

import Foundation

// MARK: - SettingsStore — Хранилище настроек (UserDefaults)
// SettingsStore — simple UserDefaults-backed persistence for AppSettings.
// Простейшая реализация хранилища настроек на базе UserDefaults.
final class SettingsStore: SettingsStoreProtocol {

    // MARK: Keys — Ключи хранилища
    private let defaults: UserDefaults
    private let storageKey: String

    // MARK: - Init — Инициализация
    /// Initialize with UserDefaults and a storage key (tests can pass custom suite/key).
    /// Инициализация с UserDefaults и ключом (в тестах можно передать отдельный suite/ключ).
    init(defaults: UserDefaults = .standard, storageKey: String = "settings.storage.key.v1") {
        self.defaults = defaults
        self.storageKey = storageKey
    }

    // MARK: - Load — Загрузка
    /// Load settings or return defaults when nothing stored.
    /// Загрузить настройки или вернуть дефолты, если ещё не сохранены.
    func load() async throws -> AppSettings {
        guard let data = defaults.data(forKey: storageKey) else {
            return .default
        }
        do {
            return try JSONDecoder().decode(AppSettings.self, from: data)
        } catch {
            throw SettingsStoreError.decodingFailed
        }
    }

    // MARK: - Save — Сохранение
    /// Save settings to UserDefaults as JSON.
    /// Сохранить настройки в UserDefaults в виде JSON.
    func save(_ settings: AppSettings) async throws {
        do {
            let data = try JSONEncoder().encode(settings)
            defaults.set(data, forKey: storageKey)
        } catch {
            throw SettingsStoreError.encodingFailed
        }
    }

    // MARK: - Reset — Сброс
    /// Remove stored settings (next load will return defaults).
    /// Удалить сохранённые настройки (при следующей загрузке вернутся дефолты).
    func reset() async throws {
        defaults.removeObject(forKey: storageKey)
    }
}
