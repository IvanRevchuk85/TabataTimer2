//
//  PresetsViewModelLimitTests.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 03.12.2025.
//

import Foundation
import Testing
@testable import TabataTimer

// Лимит-осведомлённый in-memory стор для тестов лимита
final class LimitAwareInMemoryPresetsStore: PresetsStoreProtocol {
    var items: [Preset] = []
    let max = 3

    func loadAll() async throws -> [Preset] { items.sorted(by: { $0.updatedAt > $1.updatedAt }) }
    func saveAll(_ presets: [Preset]) async throws { items = presets }
    func create(_ preset: Preset) async throws -> Preset {
        if items.count >= max { throw PresetsStoreError.limitReached(max: max) }
        var p = preset
        p.updatedAt = Date()
        items.append(p)
        return p
    }
    func update(_ preset: Preset) async throws -> Preset {
        guard let i = items.firstIndex(where: { $0.id == preset.id }) else { throw PresetsStoreError.notFound }
        var p = preset
        p.updatedAt = Date()
        p.createdAt = items[i].createdAt
        items[i] = p
        return p
    }
    func delete(id: UUID) async throws {
        let before = items.count
        items.removeAll { $0.id == id }
        if items.count == before { throw PresetsStoreError.notFound }
    }
    func get(by id: UUID) async throws -> Preset? { items.first(where: { $0.id == id }) }
    func upsert(_ preset: Preset) async throws -> Preset {
        if let _ = items.firstIndex(where: { $0.id == preset.id }) {
            return try await update(preset)
        } else {
            return try await create(preset)
        }
    }
    func removeAll() async throws { items.removeAll() }
}

@Suite("PresetsViewModel — limit handling")
struct PresetsViewModelLimitTests {

    @Test("create() sets errorMessage on 4th item")
    @MainActor
    func test_vm_setsError_onLimitReached() async throws {
        let store = LimitAwareInMemoryPresetsStore()
        let vm = PresetsViewModel(store: store)

        await vm.create(name: "A", config: .default)
        await vm.create(name: "B", config: .default)
        await vm.create(name: "C", config: .default)

        #expect(vm.errorMessage == nil)

        await vm.create(name: "D", config: .default)
        let msg = try #require(vm.errorMessage)
        #expect(msg == "You can save up to 3 workouts.")
    }
}
