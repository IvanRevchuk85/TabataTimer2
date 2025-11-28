//
//  SettingsStoreProtocol.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 27.11.2025.
//

import Foundation

// MARK: - SettingsStoreProtocol — Контракт хранилища настроек
// SettingsStoreProtocol — abstraction over settings persistence (UserDefaults/JSON/etc).
// Абстракция поверх хранения настроек (UserDefaults/JSON и т.д.).
protocol SettingsStoreProtocol: AnyObject {

    // MARK: Load — Загрузка
    /// Load application settings (or return defaults when none are stored).
    /// Загрузить настройки приложения (или вернуть значения по умолчанию, если ещё не сохранены).
    func load() async throws -> AppSettings

    // MARK: Save — Сохранение
    /// Save application settings.
    /// Сохранить настройки приложения.
    func save(_ settings: AppSettings) async throws

    // MARK: Reset — Сброс
    /// Remove stored settings (use defaults on next load).
    /// Удалить сохранённые настройки (при следующей загрузке вернуть дефолты).
    func reset() async throws
}

// MARK: - SettingsStoreError — Ошибки хранилища настроек
// Errors for settings persistence.
// Ошибки, возникающие при сохранении/загрузке настроек.
enum SettingsStoreError: Error, Equatable {
    case decodingFailed
    case encodingFailed
    case ioFailed
}
