//
//  PresetsStoreProtocol.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 26.11.2025.
//

import Foundation

// MARK: - PresetsStoreProtocol — Контракт хранилища пресетов
/// Абстракция поверх хранилища пресетов (UserDefaults/JSON/CoreData и т.п.)
/// Операции сделаны async для удобства расширения (диск/файл/сеть), даже если реализация локальная.
protocol PresetsStoreProtocol: AnyObject {

    // MARK: Load/Save — Загрузка/сохранение всего списка
    /// Загрузить все пресеты (упорядоченные по updatedAt убыв.)
    func loadAll() async throws -> [Preset]

    /// Сохранить полный список пресетов (перезапись).
    func saveAll(_ presets: [Preset]) async throws

    // MARK: CRUD — Операции
    /// Создать новый пресет и вернуть сохранённую версию (с датами/ID).
    func create(_ preset: Preset) async throws -> Preset

    /// Обновить существующий пресет по id, вернуть обновлённую версию.
    func update(_ preset: Preset) async throws -> Preset

    /// Удалить пресет по id.
    func delete(id: UUID) async throws

    /// Получить пресет по id (nil, если не найден).
    func get(by id: UUID) async throws -> Preset?

    // MARK: Utilities — Утилиты
    /// Заменить/вставить (upsert) пресет.
    func upsert(_ preset: Preset) async throws -> Preset

    /// Удалить все пресеты (для тестов/сброса).
    func removeAll() async throws
}

// MARK: - Ошибки хранилища
enum PresetsStoreError: Error, Equatable {
    case notFound
    case decodingFailed
    case encodingFailed
    case ioFailed
    case limitReached(max: Int)
}
