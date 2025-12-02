//
//  PresetsViewModel.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 27.11.2025.
//

import Foundation
import Combine

// MARK: - PresetsViewModel — Модель представления списка пресетов
// PresetsViewModel — ViewModel for managing presets: load, create, update, delete, select.
// ViewModel для управления пресетами: загрузка, создание, редактирование, удаление, выбор.
// Отдельно держит состояние экрана (список, выбранный пресет, ошибки/загрузка).
@MainActor
final class PresetsViewModel: ObservableObject {

    // MARK: Published state — Публикуемое состояние
    /// All presets sorted by updatedAt descending.
    /// Все пресеты, отсортированные по updatedAt убыв.
    @Published private(set) var presets: [Preset] = []

    /// Currently selected preset (if any).
    /// Текущий выбранный пресет (если есть).
    @Published var selected: Preset?

    /// Loading/error flags.
    /// Флаги загрузки/ошибок.
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: Dependencies — Зависимости
    private let store: PresetsStoreProtocol

    // MARK: - Init — Инициализация
    init(store: PresetsStoreProtocol) {
        self.store = store
    }

    // MARK: - Load — Загрузка
    /// Load presets from storage.
    /// Загрузить пресеты из хранилища.
    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let items = try await store.loadAll()
            presets = items
            // Drop selection if the selected preset no longer exists.
            // Сбрасываем выбор, если выбранный пресет пропал.
            if let selected = selected, !presets.contains(where: { $0.id == selected.id }) {
                self.selected = nil
            }
        } catch {
            errorMessage = "Failed to load presets — Не удалось загрузить пресеты"
        }
    }

    // MARK: - Create — Создание
    /// Create a new preset.
    /// Создать новый пресет.
    func create(name: String, config: TabataConfig) async {
        do {
            let preset = Preset(name: name, config: config)
            let saved = try await store.create(preset)
            await reloadAndSelect(saved.id)
        } catch PresetsStoreError.limitReached(let max) {
            errorMessage = "You can save up to \(max) workouts."
        } catch {
            errorMessage = "Failed to create preset — Не удалось создать пресет"
        }
    }

    // MARK: - Update — Обновление
    /// Update existing preset.
    /// Обновить существующий пресет.
    func update(_ preset: Preset) async {
        do {
            let updated = try await store.update(preset)
            await reloadAndSelect(updated.id)
        } catch PresetsStoreError.notFound {
            errorMessage = "Preset not found — Пресет не найден"
        } catch PresetsStoreError.limitReached(let max) {
            // На update лимит не должен влиять, но на всякий случай обработаем.
            errorMessage = "You can save up to \(max) workouts."
        } catch {
            errorMessage = "Failed to update preset — Не удалось обновить пресет"
        }
    }

    // MARK: - Delete — Удаление
    /// Delete preset by id.
    /// Удалить пресет по id.
    func delete(id: UUID) async {
        do {
            try await store.delete(id: id)
            if selected?.id == id { selected = nil }
            await load()
        } catch PresetsStoreError.notFound {
            errorMessage = "Preset not found — Пресет не найден"
        } catch {
            errorMessage = "Failed to delete preset — Не удалось удалить пресет"
        }
    }

    // MARK: - Select — Выбор
    /// Select preset by id.
    /// Выбрать пресет по id.
    func select(id: UUID) {
        selected = presets.first(where: { $0.id == id })
    }

    /// Clear selection.
    /// Снять выбор.
    func clearSelection() {
        selected = nil
    }

    // MARK: - Helpers — Вспомогательные методы
    private func reloadAndSelect(_ id: UUID) async {
        await load()
        select(id: id)
    }
}
