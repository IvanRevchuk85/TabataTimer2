//
//  PresetsStoreTests.swift
//  TabataTimerTests
//
//  Created by Ivan Revchuk on 27.11.2025.
//

import XCTest
@testable import TabataTimer

// MARK: - PresetsStoreTests — Тесты хранилища пресетов (UserDefaults/JSON)
// Tests for PresetsStore backed by UserDefaults (JSON encoding/decoding).
final class PresetsStoreTests: XCTestCase {

    private var defaults: UserDefaults!
    private var store: PresetsStore!

    override func setUp() {
        super.setUp()
        // Изолированный suite, чтобы не мешать реальным данным
        defaults = UserDefaults(suiteName: "PresetsStoreTests.\(UUID().uuidString)")
        defaults.removePersistentDomain(forName: defaultsSuiteName(defaults))
        store = PresetsStore(defaults: defaults, storageKey: "test.presets.key")
    }

    override func tearDown() {
        // Чистим suite
        defaults.removePersistentDomain(forName: defaultsSuiteName(defaults))
        defaults = nil
        store = nil
        super.tearDown()
    }

    // MARK: - Пустая база: loadAll возвращает пустой массив
    func test_loadAll_initiallyEmpty() async throws {
        let all = try await store.loadAll()
        XCTAssertTrue(all.isEmpty)
    }

    // MARK: - Создание и загрузка
    func test_create_and_load() async throws {
        let preset = await Preset(name: "My Preset", config: .default)
        let saved = try await store.create(preset)

        XCTAssertEqual(saved.name, "My Preset")
        XCTAssertEqual(saved.config, .default)

        let all = try await store.loadAll()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.id, saved.id)
    }

    // MARK: - Обновление существующего пресета
    func test_update_existing() async throws {
        let p1 = try await store.create(Preset(name: "Old", config: .default))
        let updatedConfig = TabataConfig(
            prepare: 5, work: 15, rest: 10,
            cyclesPerSet: 6, sets: 3, restBetweenSets: 30
        )
        let updated = try await store.update(
            p1.renamed("New").withConfig(updatedConfig)
        )

        XCTAssertEqual(updated.name, "New")
        XCTAssertEqual(updated.config, updatedConfig)

        let reloaded = try await store.get(by: p1.id)
        XCTAssertEqual(reloaded?.name, "New")
        XCTAssertEqual(reloaded?.config, updatedConfig)
        XCTAssertEqual(reloaded?.id, p1.id, "ID must remain the same")
        XCTAssertEqual(reloaded?.createdAt, p1.createdAt, "createdAt must be preserved")
        XCTAssertTrue((reloaded?.updatedAt ?? .distantPast) >= p1.updatedAt, "updatedAt should advance")
    }

    // MARK: - Обновление несуществующего — notFound
    func test_update_nonExisting_throwsNotFound() async throws {
        let phantom = await Preset(id: UUID(), name: "Ghost", config: .default)
        do {
            _ = try await store.update(phantom)
            XCTFail("Expected notFound")
        } catch let error as PresetsStoreError {
            XCTAssertEqual(error, .notFound)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Удаление и проверка notFound
    func test_delete_existing_and_notFound() async throws {
        let p = try await store.create(Preset(name: "To Delete", config: .default))
        // Удаляем
        try await store.delete(id: p.id)
        // Повторное удаление должно дать notFound
        do {
            try await store.delete(id: p.id)
            XCTFail("Expected notFound on second delete")
        } catch let error as PresetsStoreError {
            XCTAssertEqual(error, .notFound)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Upsert: вставка и обновление
    func test_upsert_insert_and_update() async throws {
        let p = Preset(name: "Upsert", config: .default)

        // Вставка (не существовал)
        let inserted = try await store.upsert(p)
        XCTAssertEqual(inserted.name, "Upsert")

        // Обновление (существует)
        let newConfig = TabataConfig(
            prepare: 1, work: 10, rest: 5,
            cyclesPerSet: 4, sets: 2, restBetweenSets: 20
        )
        let updated = try await store.upsert(inserted.withConfig(newConfig))
        XCTAssertEqual(updated.config, newConfig)

        let all = try await store.loadAll()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.config, newConfig)
    }

    // MARK: - removeAll очищает хранилище
    func test_removeAll_clearsStorage() async throws {
        _ = try await store.create(Preset(name: "A", config: .default))
        _ = try await store.create(Preset(name: "B", config: .default))

        var all = try await store.loadAll()
        XCTAssertEqual(all.count, 2)

        try await store.removeAll()

        all = try await store.loadAll()
        XCTAssertTrue(all.isEmpty)
    }

    // MARK: - Устойчивость к пустым данным / битым данным
    func test_resilience_toEmptyOrCorruptedData() async throws {
        // Пусто — ок
        var list = try await store.loadAll()
        XCTAssertTrue(list.isEmpty)

        // Подсунем битые данные
        defaults.set(Data([0xDE, 0xAD, 0xBE, 0xEF]), forKey: "test.presets.key")
        do {
            _ = try await store.loadAll()
            XCTFail("Expected decodingFailed")
        } catch let error as PresetsStoreError {
            XCTAssertEqual(error, .decodingFailed)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Helpers
    private func defaultsSuiteName(_ defaults: UserDefaults) -> String {
        // Вытаскиваем имя suite для корректной очистки
        Mirror(reflecting: defaults)
            .children
            .first { $0.label == "suiteName" }?
            .value as? String ?? "unknown"
    }
}
