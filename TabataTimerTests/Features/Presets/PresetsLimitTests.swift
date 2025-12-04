//
//  PresetsLimitTests.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 03.12.2025.
//

import Foundation
import Testing
@testable import TabataTimer

@Suite("Presets limit — max 3")
struct PresetsLimitTests {

    @Test("Create up to 3 presets succeeds; 4th fails with limitReached")
    func test_limit3_enforced_inStore() async throws {
        let suiteName = "PresetsLimitTests.\(UUID().uuidString)"
        let suite = UserDefaults(suiteName: suiteName)!
        let store = PresetsStore(defaults: suite, storageKey: "test.key")
        defer { suite.removePersistentDomain(forName: suiteName) }

        let p1 = Preset(name: "A", config: .default)
        let p2 = Preset(name: "B", config: .default)
        let p3 = Preset(name: "C", config: .default)

        _ = try await store.create(p1)
        _ = try await store.create(p2)
        _ = try await store.create(p3)

        let all = try await store.loadAll()
        #expect(all.count == 3)

        do {
            let p4 = Preset(name: "D", config: .default)
            _ = try await store.create(p4)
            Issue.record("Expected limitReached but create succeeded")
        } catch PresetsStoreError.limitReached(let max) {
            #expect(max == 3)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}
