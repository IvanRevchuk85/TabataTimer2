//
//  SettingsViewModelNewFieldsTests.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 03.12.2025.
//

import Foundation
import Testing
@testable import TabataTimer

final class MockSettingsStore2: SettingsStoreProtocol {
    var current: AppSettings = .default
    func load() async throws -> AppSettings { current }
    func save(_ settings: AppSettings) async throws { current = settings }
    func reset() async throws { current = .default }
}

@Suite("SettingsViewModel — new fields")
struct SettingsViewModelNewFieldsTests {

    @Test("toggle and save new fields")
    @MainActor
    func test_toggleAndSave_newFields() async throws {
        let store = MockSettingsStore2()
        let vm = SettingsViewModel(store: store)
        await vm.load()

        vm.toggleAutoStartFromPreset(true)
        vm.toggleKeepScreenAwake(true)
        vm.toggleCountdownSound(false)
        vm.togglePhaseChangeSound(false)
        vm.toggleFinishSound(false)

        await vm.save()

        #expect(store.current.autoStartFromPreset == true)
        #expect(store.current.keepScreenAwake == true)
        #expect(store.current.countdownSoundEnabled == false)
        #expect(store.current.phaseChangeSoundEnabled == false)
        #expect(store.current.finishSoundEnabled == false)
    }
}
