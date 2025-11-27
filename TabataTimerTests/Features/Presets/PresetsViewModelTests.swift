//
//  PresetsViewModelTests.swift
//  TabataTimerTests
//
//  Created by Ivan Revchuk on 27.11.2025.
//

import XCTest
@testable import TabataTimer

// MARK: - PresetsViewModelTests — Тесты ViewModel пресетов
// Tests for PresetsViewModel: load, create, update, delete, select.
// Проверяем загрузку, создание, обновление, удаление и выбор пресетов.
@MainActor
final class PresetsViewModelTests: XCTestCase {

    private var store: InMemoryPresetsStore!
    private var vm: PresetsViewModel!

    override func setUp() async throws {
        try await super.setUp()
        store = InMemoryPresetsStore()
        vm = PresetsViewModel(store: store)
    }

    override func tearDown() async throws {
        store = nil
        vm = nil
        try await super.tearDown()
    }

    // MARK: - Load empty — Загрузка пустого списка
    func test_load_initiallyEmpty() async throws {
        await vm.load()
        XCTAssertTrue(vm.presets.isEmpty, "Presets should be empty initially — Список пресетов должен быть пустым изначально")
        XCTAssertNil(vm.selected, "Selected should be nil initially — Выбранного пресета быть не должно")
        XCTAssertFalse(vm.isLoading, "isLoading should be false after load — После загрузки isLoading должен быть false")
    }

    // MARK: - Create — Создание пресета
    func test_create_preset() async throws {
        await vm.create(name: "New", config: .default)
        XCTAssertEqual(vm.presets.count, 1, "One preset expected — Должен быть один пресет")
        XCTAssertEqual(vm.presets.first?.name, "New", "Name should match — Имя должно совпадать")
    }

    // MARK: - Update — Обновление пресета
    func test_update_preset() async throws {
        await vm.create(name: "Old", config: .default)
        guard let first = vm.presets.first else {
            return XCTFail("Preset should exist — Пресет должен существовать")
        }
        let updated = first.renamed("New name")
        await vm.update(updated)

        XCTAssertEqual(vm.presets.first?.name, "New name", "Name must be updated — Имя должно обновиться")
    }

    // MARK: - Delete — Удаление пресета
    func test_delete_preset() async throws {
        await vm.create(name: "To delete", config: .default)
        guard let id = vm.presets.first?.id else {
            return XCTFail("Preset should exist — Пресет должен существовать")
        }

        await vm.delete(id: id)
        XCTAssertTrue(vm.presets.isEmpty, "List should be empty after delete — После удаления список должен быть пустым")
        XCTAssertNil(vm.selected, "Selected must be nil after delete — Выбранного пресета быть не должно")
    }

    // MARK: - Select/Clear — Выбор и снятие выбора
    func test_select_and_clearSelection() async throws {
        await vm.create(name: "A", config: .default)
        await vm.create(name: "B", config: .default)

        guard let id = vm.presets.last?.id else {
            return XCTFail("Preset should exist — Пресет должен существовать")
        }
        vm.select(id: id)
        XCTAssertEqual(vm.selected?.id, id, "Selected id should match — Должен быть выбран нужный пресет")

        vm.clearSelection()
        XCTAssertNil(vm.selected, "Selected must be nil after clearSelection — Выбор должен быть снят")
    }

    // MARK: - Update non-existing — Ошибка при обновлении несуществующего пресета
    func test_update_nonExisting_setsErrorMessage() async throws {
        let ghost = Preset(id: UUID(), name: "Ghost", config: .default)
        await vm.update(ghost)
        XCTAssertNotNil(vm.errorMessage, "Error message should be set — Должно быть установлено сообщение об ошибке")
    }

    // MARK: - Selection clears if preset removed — Выбор очищается, если пресет удалён
    func test_selection_clears_whenPresetRemoved() async throws {
        await vm.create(name: "Keep", config: .default)
        await vm.create(name: "Remove", config: .default)
        guard let removeID = vm.presets.last?.id else {
            return XCTFail("Preset should exist — Пресет должен существовать")
        }

        vm.select(id: removeID)
        XCTAssertEqual(vm.selected?.id, removeID, "Preset must be selected — Пресет должен быть выбран")

        await vm.delete(id: removeID)
        XCTAssertNil(vm.selected, "Selection should clear after deletion — Выбор должен очиститься после удаления")
    }
}

// MARK: - InMemoryPresetsStore — простая in-memory реализация для тестов VM
// Simple in-memory store for VM tests.
// Простая in-memory реализация хранилища для тестов VM.
private final class InMemoryPresetsStore: PresetsStoreProtocol {

    private var items: [Preset] = []

    func loadAll() async throws -> [Preset] {
        items.sorted(by: { $0.updatedAt > $1.updatedAt })
    }

    func saveAll(_ presets: [Preset]) async throws {
        items = presets
    }

    func create(_ preset: Preset) async throws -> Preset {
        var p = preset
        p.createdAt = Date()
        p.updatedAt = Date()
        items.append(p)
        return p
    }

    func update(_ preset: Preset) async throws -> Preset {
        guard let idx = items.firstIndex(where: { $0.id == preset.id }) else {
            throw PresetsStoreError.notFound
        }
        var p = preset
        p.createdAt = items[idx].createdAt
        p.updatedAt = Date()
        items[idx] = p
        return p
    }

    func delete(id: UUID) async throws {
        guard let idx = items.firstIndex(where: { $0.id == id }) else {
            throw PresetsStoreError.notFound
        }
        items.remove(at: idx)
    }

    func get(by id: UUID) async throws -> Preset? {
        items.first(where: { $0.id == id })
    }

    func upsert(_ preset: Preset) async throws -> Preset {
        if let _ = items.firstIndex(where: { $0.id == preset.id }) {
            return try await update(preset)
        } else {
            return try await create(preset)
        }
    }

    func removeAll() async throws {
        items.removeAll()
    }
}
