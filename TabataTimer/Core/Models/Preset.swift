//
//  Preset.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 26.11.2025.
//

import Foundation

// MARK: - Preset — Модель пресета тренировки
/// Сохранённый пресет с человекочитаемым именем и конфигурацией Tabata.
struct Preset: Identifiable, Equatable, Hashable, Codable {
    // Уникальный идентификатор пресета
    var id: UUID

    // Отображаемое имя пресета (например, "Classic 20/10 x8 x4")
    var name: String

    // Конфигурация тренировки
    var config: TabataConfig

    // Дата создания и последнего обновления
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Инициализация
    init(
        id: UUID = UUID(),
        name: String,
        config: TabataConfig,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.config = config
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Удобные фабрики
    /// Пресет по умолчанию на основе TabataConfig.default
    static var `default`: Preset {
        Preset(
            name: "Default",
            config: .default
        )
    }

    /// Создать пресет с автогенерацией имени по конфигурации.
    static func makeNamed(from config: TabataConfig, baseName: String? = nil) -> Preset {
        let generated = baseName ?? "Tabata \(config.work)/\(config.rest) x\(config.cyclesPerSet) • sets \(config.sets)"
        return Preset(name: generated, config: config)
    }

    // MARK: - Обновление полей
    func renamed(_ newName: String) -> Preset {
        var copy = self
        copy.name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        copy.updatedAt = Date()
        return copy
    }

    func withConfig(_ newConfig: TabataConfig) -> Preset {
        var copy = self
        copy.config = newConfig
        copy.updatedAt = Date()
        return copy
    }
}
