//
//  SettingsStore.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 27.11.2025.
//

import Foundation

// MARK: - SettingsKeyValueStore — minimal key-value abstraction
/// Minimal key-value storage interface used by SettingsStore.
/// Минимальный интерфейс key-value хранилища, который использует SettingsStore.
protocol SettingsKeyValueStore {
    func data(forKey defaultName: String) -> Data?
    func set(_ value: Any?, forKey defaultName: String)
    func removeObject(forKey defaultName: String)
}

// MARK: - UserDefaults conformance / Реализация через UserDefaults
extension UserDefaults: SettingsKeyValueStore {}

// MARK: - SettingsStore — Хранилище настроек (UserDefaults/KeyValueStore)
/// SettingsStore — simple persistence layer for AppSettings.
/// Простейшее хранилище настроек приложения.
final class SettingsStore: SettingsStoreProtocol {

    // MARK: Storage — Хранилище
    /// Underlying key-value storage (UserDefaults in production, fake in tests).
    /// Подложка key-value хранилища (UserDefaults в приложении, фейк в тестах).
    private let storage: SettingsKeyValueStore

    /// Key under which settings JSON is stored.
    /// Ключ, под которым сохраняется JSON с настройками.
    private let storageKey: String

    // MARK: - Init — Инициализация
    /// Initialize with key-value storage and key.
    /// Инициализация с key-value хранилищем и ключом.
    init(
        storage: SettingsKeyValueStore = UserDefaults.standard,
        storageKey: String = "settings.storage.key.v1"
    ) {
        self.storage = storage
        self.storageKey = storageKey
    }

    // MARK: - Load — Загрузка
    /// Load settings or return defaults when nothing stored.
    /// Загрузить настройки или вернуть дефолты, если ещё не сохранены.
    func load() async throws -> AppSettings {
        // If nothing stored yet — return defaults.
        // Если ещё ничего не сохраняли — возвращаем значения по умолчанию.
        guard let data = storage.data(forKey: storageKey) else {
            return .default
        }

        do {
            return try JSONDecoder().decode(AppSettings.self, from: data)
        } catch {
            throw SettingsStoreError.decodingFailed
        }
    }

    // MARK: - Save — Сохранение
    /// Save settings to storage as JSON.
    /// Сохранить настройки в хранилище в виде JSON.
    func save(_ settings: AppSettings) async throws {
        do {
            let data = try JSONEncoder().encode(settings)
            storage.set(data, forKey: storageKey)
        } catch {
            throw SettingsStoreError.encodingFailed
        }
    }

    // MARK: - Reset — Сброс
    /// Remove stored settings (next load will return defaults).
    /// Удалить сохранённые настройки (при следующей загрузке вернутся дефолты).
    func reset() async throws {
        storage.removeObject(forKey: storageKey)
    }
}
