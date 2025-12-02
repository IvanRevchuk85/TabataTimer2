//
//  PresetsStore.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 27.11.2025.
//

import Foundation

// MARK: - PresetsStore — Простое хранилище пресетов (UserDefaults/JSON)
// Simple presets storage backed by UserDefaults (JSON-encoded array).
// Простейшая реализация на базе UserDefaults (массив, закодированный в JSON).
final class PresetsStore: PresetsStoreProtocol {

    // MARK: Keys — Ключи хранилища
    private let defaults: UserDefaults
    private let storageKey: String

    // MARK: Limit — Лимит пресетов
    private let maxPresets: Int = 3

    // MARK: - Init — Инициализация
    /// Initialize with UserDefaults and key (for tests you can pass a suite).
    /// Инициализация с UserDefaults и ключом (в тестах можно передать suite).
    init(defaults: UserDefaults = .standard, storageKey: String = "presets.storage.key.v1") {
        self.defaults = defaults
        self.storageKey = storageKey
    }

    // MARK: - Load/Save — Загрузка/сохранение
    /// Load all presets sorted by updatedAt descending.
    /// Загрузить все пресеты, отсортированные по updatedAt по убыванию.
    func loadAll() async throws -> [Preset] {
        guard let data = defaults.data(forKey: storageKey) else {
            return []
        }
        do {
            let presets = try JSONDecoder().decode([Preset].self, from: data)
            return presets.sorted(by: { $0.updatedAt > $1.updatedAt })
        } catch {
            throw PresetsStoreError.decodingFailed
        }
    }

    /// Save full list (overwrites storage).
    /// Сохранить весь список (перезаписывает хранилище).
    func saveAll(_ presets: [Preset]) async throws {
        do {
            let data = try JSONEncoder().encode(presets)
            defaults.set(data, forKey: storageKey)
        } catch {
            throw PresetsStoreError.encodingFailed
        }
    }

    // MARK: - CRUD — Операции
    /// Create a new preset and persist.
    /// Создать новый пресет и сохранить.
    func create(_ preset: Preset) async throws -> Preset {
        var list = try await loadAll()
        // Enforce limit — Применяем лимит
        if list.count >= maxPresets {
            throw PresetsStoreError.limitReached(max: maxPresets)
        }
        // Ensure unique id — Гарантируем уникальность id
        let new = Preset(
            id: preset.id,
            name: preset.name,
            config: preset.config,
            createdAt: preset.createdAt,
            updatedAt: Date()
        )
        list.append(new)
        try await saveAll(list)
        return new
    }

    /// Update existing preset by id.
    /// Обновить существующий пресет по id.
    func update(_ preset: Preset) async throws -> Preset {
        var list = try await loadAll()
        guard let idx = list.firstIndex(where: { $0.id == preset.id }) else {
            throw PresetsStoreError.notFound
        }
        var updated = preset
        updated.updatedAt = Date()
        // Preserve createdAt — Сохраняем дату создания
        updated.createdAt = list[idx].createdAt
        list[idx] = updated
        try await saveAll(list)
        return updated
    }

    /// Delete preset by id.
    /// Удалить пресет по id.
    func delete(id: UUID) async throws {
        var list = try await loadAll()
        let newList = list.filter { $0.id != id }
        if newList.count == list.count {
            throw PresetsStoreError.notFound
        }
        try await saveAll(newList)
    }

    /// Get preset by id (nil if missing).
    /// Получить пресет по id (nil, если отсутствует).
    func get(by id: UUID) async throws -> Preset? {
        let list = try await loadAll()
        return list.first(where: { $0.id == id })
    }

    // MARK: - Utilities — Утилиты
    /// Upsert preset (insert or update by id).
    /// Заменить/вставить пресет (по id).
    func upsert(_ preset: Preset) async throws -> Preset {
        var list = try await loadAll()
        if let idx = list.firstIndex(where: { $0.id == preset.id }) {
            var updated = preset
            updated.updatedAt = Date()
            updated.createdAt = list[idx].createdAt
            list[idx] = updated
            try await saveAll(list)
            return updated
        } else {
            // Enforce limit on insert — Проверяем лимит при вставке
            if list.count >= maxPresets {
                throw PresetsStoreError.limitReached(max: maxPresets)
            }
            let created = Preset(
                id: preset.id,
                name: preset.name,
                config: preset.config,
                createdAt: Date(),
                updatedAt: Date()
            )
            list.append(created)
            try await saveAll(list)
            return created
        }
    }

    /// Remove all presets (useful for tests).
    /// Удалить все пресеты (полезно для тестов).
    func removeAll() async throws {
        defaults.removeObject(forKey: storageKey)
    }
}
